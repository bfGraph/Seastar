import torch
from seastar.compiler.backend.kernel_wrapper import KernelWrapper

class KernelWrapperTorch(KernelWrapper, torch.autograd.Function):
    def __init__(self):
        super().__init__()