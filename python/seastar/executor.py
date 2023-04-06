import torch
import snoop
from collections import deque

class Stack:
    def __init__(self, val=None):
        self.content = deque()
        if val is not None:
            self.content.append(val)
    
    def push(self, val):
        self.content.append(val)
    
    def pop(self):
        self.content.pop()
    
    def top(self):
        return self.content[-1]
    
    def print(self):
        for elem in self.content:
            print(elem)
        

from .utils import is_const_scalar, ParallelMode
from .code_gen.cuda_python.cuda_result import init_result_tensors, free_result_tensors, add_cuda_result_tensor_info, get_kernel_return_tensor

class ExeState(object):
    def __init__(self):

        # contains tensors for all previous execution of nb_compute
        self.tensor_map_stack = Stack()

        # contains arg tensors for the current execution of nb_compute only
        self.current_tensor_map = {}

        self.dep_map = {}
        self.executed_bunit = set()
    
    def reset(self, input_map, f_merged_units, bunits):
        self.dep_map = {}
        #for mu in f_merged_units:
        #    if mu.compiled():
        #        for ret in mu.union_of_rets():
        #            self.dep_map[ret.id] = 0
        #        #for arg in mu.joint_inputs():
        #        #    self.dep_map[arg.id] = -1
        for bu in bunits:
            for arg in bu.unit_args():
                if arg.id in self.dep_map:
                    self.dep_map[arg.id] += 1
                else:
                    self.dep_map[arg.id] = 1
        #print('dependency map', self.dep_map)
        self.num_bunits = len(bunits)
        # deletes all tensors that were previously stored here (verified)
        self.current_tensor_map = {key: val for key,val in input_map.items()}
        self.executed_bunit.clear()
    
    def track_executed_bu(self, bu):
        self.executed_bunit.add(bu)
    
    def is_executed_bu(self, bu):
        return bu in self.executed_bunit
    
    def all_bu_executed(self):
        return len(self.executed_bunit) == self.num_bunits
    
    def track_tensor(self, key, val):
            self.current_tensor_map[key] = val
    
    # def clear_cache(self):
    #     rmv_list = []
    #     for k in self.tensor_map:
    #         if not k in self.dep_map:
    #             rmv_list.append(k)
    #     #print('clear cache', rmv_list, self.tensor_map.keys())
    #     for k in rmv_list:
    #         self.tensor_map.pop(k)

class MergedUnit(object):
    def __init__(self, units):
        self.units = units
        self._joint_inputs = None
        self._joint_args = None
        self._joint_rets = None 
        self._kernel_args = None
        self._union_of_rets = None
    
    def append(self, unit):
        self.units.append(unit)
        return self
    
    def last(self):
        return self.units[-1]
    
    def compiled(self):
        return self.units[-1].compiled
    
    def joint_inputs(self):
        if not self._joint_inputs:
            var_set = set()
            for u in self.units:
                var_set = var_set.union(u._args)
            for u in self.units:
                var_set = var_set - u._rets
            self._joint_inputs = set([var for var in var_set])
        return self._joint_inputs

    def joint_rets(self):
        if not self._joint_rets:
            var_set = set()
            for u in self.units:
                var_set = var_set.union(u._rets)
            for u in self.units:
                var_set = var_set - u._args
            self._joint_rets = [var for var in var_set]
        return self._joint_rets
    
    def joint_args(self):
        if not self._joint_args:
            var_set = set()
            for u in self.units:
                var_set = var_set.union(u._args)
            self._joint_args= [var for var in var_set] + self.joint_rets()
        return self._joint_args
    
    def union_of_rets(self):
        if not self._union_of_rets:
            var_set = set()
            for u in self.units:
                var_set = var_set.union(u._rets)
            self._union_of_rets = var_set
        return self._union_of_rets
    
    def kernel_arg_list(self):
        if not self._kernel_args:
            args = self.joint_args()
            self._kernel_args = []
            for unit in self.units:
                kernel_arg = []
                for arg in unit.kernel_args():
                    for i in range(len(args)):
                        if arg == args[i]:
                            kernel_arg.append(i)
                self._kernel_args.append(kernel_arg)
        return self._kernel_args
    
    def __str__(self):
        return str(self.units)
    
    def __repr__(self):
        return self.__str__()
    
    def  __iter__(self):
        for unit in self.units:
            yield unit

class Executor(object):
    def __init__(self, graph, forward_exec_units, backward_exec_units, compiled_module, rets):
        self.forward_exec_units = self.merge_units(forward_exec_units)
        self.bulist = backward_exec_units
        self.var2bu = self.construct_backward_mappping(self.forward_exec_units,backward_exec_units)
        self._rets = rets
        self.ts = ExeState()
        self.new_zeros = None
        self.raw_ptr = None
        self.num_nodes = graph.num_nodes
        self.num_edges = graph.num_edges
        self.graph = graph
        for mu in self.forward_exec_units:
            for u in mu:
                if u.compiled:
                    u.prepare_compiled_kernel(graph, compiled_module)
        for u in self.bulist:
            if u.compiled:
                u.prepare_compiled_kernel(graph, compiled_module)
    
    def construct_backward_mappping(self, funits, bunits):
        ret = {}
        for mu in funits:
            if mu.compiled():
                for arg in mu.joint_inputs():
                    if arg.requires_grad:
                        for bu in bunits:
                            if arg._grad in bu.unit_rets():
                                ret[arg] = bu
        for k, v in ret.items():
            print('k', k, 'v', v.kernel_name)
            init_result_tensors(v._kernel_name, list(v._rets)) 

        return ret
    
    def merge_units(self, exec_units):
        print('start merging', len(exec_units))
        assert len(exec_units) > 0, 'Error: empty exec units'
        grouped_unit = [MergedUnit([exec_units[0]])]
        for i in range(1, len(exec_units)):
            if exec_units[i].compiled == grouped_unit[-1].last().compiled:
                grouped_unit[-1].append(exec_units[i])
            else:
                grouped_unit.append(MergedUnit([exec_units[i]]))
        print('merged units', len(grouped_unit), grouped_unit)
        return grouped_unit
  
    def restart(self, input_map):
        self.ts.reset(input_map, self.forward_exec_units, self.bulist)
        if self.graph != None:
            for mu in self.forward_exec_units:
                for u in mu:
                    if u.compiled:
                        # TODO: (Joel) Feel like this is going to be problematic for dynamic graphs
                        u.reset_graph_info(self.graph)
            for u in self.bulist:
                if u.compiled:
                    u.reset_graph_info(self.graph)
            self.num_nodes = self.graph.num_nodes
            self.num_edges = self.graph.num_edges

    
    def set_raw_ptr_cb(self, cb):
        self.raw_ptr = cb

    def set_new_zeros_cb(self, cb):
        self.new_zeros = cb
    
    def execute(self, FuncWrapper):
        ''' Execute forward pass'''

        # init_result_tensors(self._rets)

        for i,unit in enumerate(self.forward_exec_units):
            if unit.last().compiled:
                self.execute_compiled(i, FuncWrapper)
            else:
                self.execute_prog(unit)
        ret = tuple([self.ts.current_tensor_map[ret.id] for ret in self._rets])
        
        # TODO: Will need to uncomment this one line
        # self.ts.clear_cache()


        # bytes_list = [v.numel() *4 for k,v in self.ts.tensor_map.items()]
        #print('after forward', self.ts.tensor_map.keys(), ' bytes ', bytes_list, sum(bytes_list))
        self.ts.tensor_map_stack.push(self.ts.current_tensor_map)
        self.graph.update_graph_forward()

        # print("🔴 After ForwardProp status of tensor_map")
        # for index in range(len(self.ts.tensor_map_stack.content)):
        #     print("Index: {}".format(index))
        #     print(self.ts.tensor_map_stack.content[index])

        return  ret
    
    def create_tensor_for_vars(self, var_list, kernel_name):
        ret_tensors = {var.id : self.new_zeros(size=[self.num_edges if var.is_edgevar() else self.num_nodes] + list(var.var_shape),
                                               dtype=var.var_dtype,
                                               device=var.device,
                                               requires_grad=var.requires_grad) for var in var_list if var.id not in self.ts.current_tensor_map}
        for ret_arg_name, ret_arg_tensor in ret_tensors.items():
            add_cuda_result_tensor_info(
                kernel_name, 
                ret_arg_name, 
                ret_arg_tensor.device, 
                ret_arg_tensor.size(),
                ret_arg_tensor.requires_grad)
        self.ts.current_tensor_map = {**self.ts.current_tensor_map, **ret_tensors}

    @snoop
    def create_tensor_for_grad_vars(self, var_list, tensor_map):
        ret_tensors = {var.id : self.new_zeros(size=[self.num_edges if var.is_edgevar() else self.num_nodes] + list(var.var_shape),
                                               dtype=var.var_dtype,
                                               device=var.device,
                                               requires_grad=var.requires_grad) for var in var_list if var.id not in tensor_map}
        tensor_map = {**tensor_map, **ret_tensors}
        return tensor_map

   # NOTE: Original Code
    # def execute_unit(self, unit, tensor_list):
    #     ()
    #     arg_ptr = [self.raw_ptr(arg) for arg in tensor_list]
    #     unit.kernel_run(arg_ptr)

    def execute_unit(self, unit, tensor_list):
        unit.kernel_run(tensor_list)

    def execute_compiled(self, uid, FuncWrapper):
        units = self.forward_exec_units[uid]
        args = units.joint_args()
        rets =  units.joint_rets()
        for unit in units:
            init_result_tensors(unit._kernel_name, list(unit._rets))
            self.create_tensor_for_vars(unit.unit_rets(), unit._kernel_name)

        kernel_arg_list = units.kernel_arg_list()
        ret_tensors = FuncWrapper.apply(self, uid, kernel_arg_list, rets, *[self.ts.current_tensor_map[var.id] for var in args])
        # Only the return values returned by the function will have grad_fn set properly.
        # Therefore we need to replace the tensors in self.tensor_map with the return values

        # NOTE: This is where the return values are updated in the
        # tensor map. So all we have to do is create the return tensor
        # after getting the output from the CUDA code and save it
        # in the tensor_map using this function

        for i,ret in enumerate(rets):
            self.ts.track_tensor(ret.id, get_kernel_return_tensor(unit._kernel_name, ret.id))

        # breakpoint()
        # TODO: FIX CALLING OF free_result_tensor at the right place
        # free_result_tensors()
    
    @snoop
    def forward_cb(self, uid, kernel_args, rets, tensor_list):
        '''FuncWrapper will call this function in forward pass'''
        units = self.forward_exec_units[uid]
        for i,unit in enumerate(units):
            self.execute_unit(unit, [tensor_list[tidx] for tidx in kernel_args[i]])

        return tuple([self.ts.current_tensor_map[ret.id] for ret in rets])

    @snoop
    def backward_cb(self, kid, grad_list):
        '''FuncWrapper will call this function in backward pass'''
        # which backward kernel to call? un-executed kernel that has all dependency satisfied. 
        # We need to get the grad_map in order to properly set the variables in compiled kernels.
        funits = self.forward_exec_units[kid]
        args = funits.joint_args()
        rets = funits.joint_rets()
        inputs = funits.joint_inputs()
        ret_grads = [ret._grad for ret in rets] # ret_grads corresponds vars in grad_list

        tensor_map = self.ts.tensor_map_stack.top()

        for i,grad in enumerate(ret_grads):
            # We track the ret_grads as its value is fixed to grad_list
            tensor_map[grad.id] = grad_list[i]
        arg_grads = [arg._grad if arg in inputs and arg.requires_grad else None for arg in args] # arg_grads corresponds to the grads of funit.unit_args
        for bu in self.bulist:
            if bu.compiled:

                # if self.ts.is_executed_bu(bu):
                #     continue
                self.create_tensor_for_vars(bu.unit_rets(), bu._kernel_name)
                tensor_map = self.create_tensor_for_grad_vars(bu.unit_rets(),tensor_map)

                self.execute_unit(bu, [tensor_map[arg.id] for arg in bu.kernel_args()])
                
                # self.ts.track_executed_bu(bu)
            else:
                # The backward pass of some forward unit may be splitted into compiled and uncompiled parts
                self.execute_prog([bu])

        ret = tuple([tensor_map[grad.id] if grad != None else None for grad in arg_grads] + [None for grad in ret_grads])
        
        del tensor_map
        self.ts.tensor_map_stack.pop()

        # print("🔴 After Backprop status of tensor_map")
        # for index in range(len(self.ts.tensor_map_stack.content)):
        #     print("Index: {}".format(index))
        #     print(self.ts.tensor_map_stack.content[index])
        return ret

    def execute_prog(self, units):
        for unit in  units:
            for stmt in unit.program:
                self.ts.track_tensor(stmt.ret.id, stmt.execute([self.ts.current_tensor_map[arg.id] if not is_const_scalar(arg) else arg for arg in stmt.args]))