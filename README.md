# JuliaQCD tutorials

Notebooks for the JuliaQCD video tutorials: [LatticeQCD.jl](https://github.com/akio-tomiya/LatticeQCD.jl) and related packages, ready to run on Google Colab or Jupyter.

JuliaQCD の動画チュートリアルのためのノートブックです。Google Colab や Jupyter でそのまま動かせます。

## Notebooks

| Notebook | Language | Open |
|---|---|---|
| Getting started with LatticeQCD.jl v2 | English | [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/akio-tomiya/JuliaQCD-tutorials/blob/main/notebooks/LatticeQCD_v2_quickstart_en.ipynb) |
| LatticeQCD.jl v2 入門 | 日本語 | [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/akio-tomiya/JuliaQCD-tutorials/blob/main/notebooks/LatticeQCD_v2_quickstart_ja.ipynb) |

Contents:

1. Installing LatticeQCD.jl and Plots.jl
2. HMC with two flavors of Wilson fermions on a 4⁴ lattice, using the v2 workflow (`load_simulation_spec` → `build_simulation` → `run!`), and plotting the plaquette history
3. A quenched (heat bath) run on a 4³×16 lattice, measuring the pion correlator, the effective mass, and jackknife errors

## How to run

- **Google Colab**: open a notebook with the badge above, then choose **Julia** under *Runtime → Change runtime type*. The first cell installs the packages (a few minutes).
- **Jupyter**: install [IJulia](https://github.com/JuliaLang/IJulia.jl) and open the notebook with a Julia 1.11 or 1.12 kernel.

Tested with LatticeQCD.jl 2.0.3 on Julia 1.11 (one CPU thread, Apple M-series). There, section 2 took about 1.5 minutes and section 3 about 2.5 minutes, excluding package installation. A Colab CPU may be slower.

## Videos

- Getting started with LatticeQCD.jl v2 (English / 日本語): coming soon
- Measuring the pion mass with LatticeQCD.jl (English / 日本語): coming soon

## Links

- LatticeQCD.jl: https://github.com/akio-tomiya/LatticeQCD.jl
- JuliaQCD paper: Y. Nagai and A. Tomiya, "JuliaQCD: Portable lattice QCD package in Julia language", [arXiv:2409.03030](https://arxiv.org/abs/2409.03030)
- Questions: [JuliaQCD discussions (English)](https://github.com/orgs/JuliaQCD/discussions/2), [日本語](https://github.com/orgs/JuliaQCD/discussions/7)

## License

MIT License. See [LICENSE](LICENSE).
