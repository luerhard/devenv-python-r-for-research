# What is this repository?

It gives an environment which is designed for research purposes.
It ships with R and Python (uv) and ensures the reproducibility of an enviroment.

It also comes with a jupyter server which has both R and Python kernels.

# Using R

R packages are managed from within the flake.
R can just be used normally or from within the shipped jupyter server.

# Using Python

Python packages and it's runtime are handled outside of the flake within the pyproject.toml (and uv).
Packages can be added using `uv add <packagename>`.

This comes with several advantages: 1) Support for python in nix is not good, so it takes a lot of pain away. 2) torch can use the system CUDA libraries for GPU acceleration. This also is a big pain point in nix otherwise.

# Using Jupyter

It can be started from within the shell using `jupyter-start`

```
nix develop . --impure
jupyter-start
```

then go to `http://localhost:8888`or use vscode with the existing jupyter server at this adress.