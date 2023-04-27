import copy
import numpy as np
from rich import inspect

from seastar.graph.dynamic.DynamicGraph import DynamicGraph
from gpma import GPMA, init_gpma, print_gpma_info, edge_update_list, label_edges, copy_label_edges, build_reverse_gpma, get_csr_ptrs, get_graph_attr


class GPMAGraph(DynamicGraph):
    def __init__(self, graph_updates, max_num_nodes):
        super().__init__(graph_updates, max_num_nodes)
        
        # forward and backward graphs for GPMA
        self.forward_graph = GPMA()
        self.backward_graph = GPMA()
        
        init_gpma(self.forward_graph, max_num_nodes)
        init_gpma(self.backward_graph, max_num_nodes)
        
        # initialise the graph for the first time stamp
        initial_graph_additions = graph_updates["0"]["add"]

        edge_update_list(self.forward_graph, initial_graph_additions, is_reverse_edge=True)
        label_edges(self.forward_graph)

        self._get_graph_csr_ptrs()
        # self._get_graph_attributes()  # NOTE:
        self._update_graph_cache()
        
    def in_degrees(self):
        return np.array(self.forward_graph.out_degree, dtype='int32')
    
    def out_degrees(self):
        return np.array(self.forward_graph.in_degree, dtype='int32')
        
    # TODO: Need to figure out the GPU pointer bug
    def _get_graph_csr_ptrs(self):
        pass    
    
    def _update_graph_forward(self):
        # if we went through the entire time-stamps
        if str(self.current_time_stamp + 1) not in self.graph_updates:
            raise Exception("⏰ Invalid timestamp during SeastarGraph.update_graph_forward()")
        
        self.current_time_stamp += 1
        
        # getting the graph edge modifications in 
        # the following form list[tuple(int, int)]
        graph_additions = self.graph_updates[str(self.current_time_stamp)]["add"]
        graph_deletions = self.graph_updates[str(self.current_time_stamp)]["delete"]

        edge_update_list(self.forward_graph, graph_additions, is_reverse_edge=True)
        edge_update_list(self.forward_graph, graph_deletions, is_delete=True, is_reverse_edge=True)

        label_edges(self.forward_graph)
        self._get_graph_csr_ptrs()
        # self._get_graph_attributes()  # NOTE:
        
    def _init_reverse_graph(self):
        ''' Generates the reverse of the base graph'''

        # checking if the reverse base graph exists in the cache
        # we can load it from there instead of building it each time
        if 'reverse' in self.graph_cache:
            self.backward_graph = self._get_cached_graph(is_reverse=True)
        else:
            build_reverse_gpma(self.backward_graph, self.forward_graph)

            # storing the reverse base graph in cache after building
            # it for the first time
            self._update_graph_cache(is_reverse=True)

        self._is_reverse_graph = True

        self._get_graph_csr_ptrs()
        # self._get_graph_attributes() # NOTE:
        
    def _update_graph_backward(self):
        if self.current_time_stamp < 0:
            raise Exception("⏰ Invalid timestamp during SeastarGraph.update_graph_backward()")
        
        self.current_time_stamp -= 1
        
        graph_additions = self.graph_updates[str(self.current_time_stamp + 1)]["delete"]
        graph_deletions = self.graph_updates[str(self.current_time_stamp + 1)]["add"]

        edge_update_list(self.backward_graph, graph_additions)
        edge_update_list(self.backward_graph, graph_deletions, is_delete=True)

        edge_update_list(self.forward_graph, graph_additions, is_reverse_edge=True)
        edge_update_list(self.forward_graph, graph_deletions, is_delete=True, is_reverse_edge=True)

        label_edges(self.forward_graph)
        copy_label_edges(self.backward_graph, self.forward_graph)

        self._get_graph_csr_ptrs()
        # self._get_graph_attributes()  # NOTE: