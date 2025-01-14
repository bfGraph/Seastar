<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/bfGraph/STGraph/blob/main/assets/STGraph%20Banner%20%E2%80%93%20Dark.png?raw=true">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/bfGraph/STGraph/blob/main/assets/STGraph%20Banner%20New.png?raw=true">
  <img alt="STGraph Banner" src="https://github.com/bfGraph/STGraph/blob/main/assets/STGraph%20Banner%20New.png?raw=true">  
</picture>


[![Documentation Status](https://readthedocs.org/projects/stgraph/badge/?version=latest)](https://stgraph.readthedocs.io/en/latest/?badge=latest)
[![TGL Workshop - @ NeurIPS'23](https://img.shields.io/badge/TGL_Workshop-%40_NeurIPS'23-6d4a8f)](https://neurips.cc/virtual/2023/76335)
[![GrAPL - @IPDPS'24](https://img.shields.io/badge/GrAPL-%40IPDPS'24-282792)](https://ieeexplore.ieee.org/abstract/document/10596405)
[![PyPI - 1.1.0](https://img.shields.io/static/v1?label=PyPI&message=1.1.0&color=%23ffdf76&logo=Python)](https://pypi.org/project/stgraph/)

<div align="center">
  <p align="center">
    <a href="https://stgraph.readthedocs.io/en/latest/"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://stgraph.readthedocs.io/en/latest/install/index.html">Installation guide</a>
    ·
    <a href="https://github.com/bfGraph/STGraph/issues">Report Bug</a>
    ·
    <a href="https://github.com/bfGraph/STGraph/discussions">View Discussions</a>
    .
    <a href="https://openreview.net/forum?id=8PRRNv81qB">Paper</a>
  </p>
</div>


# 🌟 STGraph

STGraph is a framework designed for deep-learning practitioners to write and train Graph Neural Networks (GNNs) and Temporal Graph Neural Networks (TGNNs). It is built on top of _Seastar_ and utilizes the vertex-centric approach to produce highly efficient fused GPU kernels for forward and backward passes. It achieves better usability, faster computation time and consumes less memory than state-of-the-art graph deep-learning systems like DGL, PyG and PyG-T.

_NOTE: If the contents of this repository are used for research work, kindly cite the paper linked above._

## Why STGraph

![Seastar GCN Formula](https://github.com/bfGraph/STGraph/blob/main/assets/Seastar%20GCN%20Formula.png?raw=true)



The primary goal of _Seastar_ is more natural GNN programming so that the users learning curve is flattened. Our key observation lies in recognizing that the equation governing a GCN layer, as shown above, takes the form of vertex-centric computation and can be implemented succinctly with only one line of code. Moreover, we can see a clear correspondence between the GNN formulas and the vertex-centric implementations. The benefit is two-fold: users can effortlessly implement GNN models, while simultaneously understanding these models by inspecting their direct implementations.

The _Seastar_ system outperforms state-of-the-art GNN frameworks but lacks support for TGNNs. STGraph bridges that gap and enables users to to develop TGNN models through a vertex-centric approach. STGraph has shown to be significantly faster and more memory efficient that state-of-the-art frameworks like PyG-T for training TGNN models.

## Getting Started

### Installation for STGraph Package Users

This guide is tailored for users of the STGraph package, designed for constructing GNN and TGNN models. We recommend creating a new virtual environment with Python version `3.8` and installing `stgraph` inside that dedicated environment.

**Installing STGraph from PyPI**

```bash
pip install stgraph
```

**Installing PyTorch**

In addition, STGraph relies on PyTorch. Ensure it is installed in your virtual environment with the following command

```bash
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

Upon completion of the above steps, you have successfully installed STGraph. Proceed to write and train your first GNN model by referring to the provided [tutorial](examples/README.md).

### Installation for STGraph Package Developers

This guide is intended for those interested in developing and contributing to STGraph.

**Download source files from GitHub**

```bash
git clone https://github.com/bfGraph/STGraph.git
cd STGraph
```

**Create a dedicated virtual environment**

Inside the STGraph directory create and activate a dedicated virtual environment named `dev-stgraph` with Python version `3.8`.

```bash
python3.8 -m venv dev-stgraph
source dev-stgraph/bin/activate
```

**Install STGraph in editable mode**

Make sure to install the STGraph package in editable mode to ease your development process. 

```bash
pip install -e .[dev]
pip list
```

**Install PyTorch**

Ensure to install PyTorch as well for development

```bash
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

With this you have successfully installed STGraph locally to make development changes and contribute to the project. Head out to our [Pull Requests](https://github.com/bfGraph/STGraph/pulls) page and get started with your first contribution.

## Running your first STGraph Program

Please have a look inside the `tutorials/` directory to write and train your own GNNs using STGraph

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct, and the process for submitting pull requests, issues, etc to us.

## How to contribute to Documentation

We follow the PEP-8 format. [Black](https://pypi.org/project/black/) is used as the formatter and [pycodestyle](https://pypi.org/project/pycodestyle/) as the linter. The linter is is configure to work properly with black (set line length to 88)

Tutorial for Python Docstrings can be found [here](https://sphinx-rtd-tutorial.readthedocs.io/en/latest/docstrings.html)

```
sphinx-apidoc -o docs/developers_guide/developer_manual/package_reference/ python/stgraph/ -f
cd docs/
make clean
make html
```
## Authors

| Author                            | Bio                                                                   |
| --------------------------------- | --------------------------------------------------------------------- |
| `Joel Mathew Cherian`             | Computer Science Student at National Institute of Technology Calicut  |
| `Nithin Puthalath Manoj`          | Computer Science Student at National Institute of Technology Calicut  |
| `Dr. Unnikrishnan Cheramangalath` | Assistant Professor in CSED at Indian Institue of Technology Palakkad |
| `Kevin Jude`                      | Ph.D. in CSED at Indian Institue of Technology Palakkad               |

## References

| Author(s)                                                                                                                                                                         | Title                                                                                                    | Link(s)                                                                                                                          |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `Wu, Yidi and Ma, Kaihao and Cai, Zhenkun and Jin, Tatiana and Li, Boyang and Zheng, Chenguang and Cheng, James and Yu, Fan`                                                      | `Seastar: vertex-centric programming for graph neural networks, 2021`                                    | [paper](https://doi.org/10.1145/3447786.3456247), [code](https://zenodo.org/record/4988602)                                      |
| `Wheatman, Brian and Xu, Helen`                                                                                                                                                   | `Packed Compressed Sparse Row: A Dynamic Graph Representation, 2018`                                     | [paper](https://ieeexplore.ieee.org/abstract/document/8547566), [code](https://github.com/wheatman/Packed-Compressed-Sparse-Row) |
| `Sha, Mo and Li, Yuchen and He, Bingsheng and Tan, Kian-Lee`                                                                                                                      | `Accelerating Dynamic Graph Analytics on GPUs, 2017`                                                     | [paper](http://www.vldb.org/pvldb/vol11/p107-sha.pdf), [code](https://github.com/desert0616/gpma_demo)                           |
| `Benedek Rozemberczki, Paul Scherer, Yixuan He, George Panagopoulos, Alexander Riedel, Maria Astefanoaei, Oliver Kiss, Ferenc Beres, Guzmán López, Nicolas Collignon, Rik Sarkar` | `PyTorch Geometric Temporal: Spatiotemporal Signal Processing with Neural Machine Learning Models, 2021` | [paper](https://arxiv.org/pdf/2104.07788.pdf), [code](https://github.com/benedekrozemberczki/pytorch_geometric_temporal)         |
