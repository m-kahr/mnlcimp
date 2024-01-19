# mnlcimp
This is an updated version of the code from the paper: [Kahr Michael, Leitner Markus, Ljubic Ivana. The impact of passive social media viewers in influence maximization, 2024](https://doi.org/10.1287/ijoc.2023.0047). For usage instructions see [accompanying repository](https://github.com/INFORMSJoC/2023.0047), and the comments below.

The main changes compared to the original code include:
- `CPLEX.jl` > than `0.6.6` is used which enables to use newer IBM CPLEX versions.
- Generic callbacks are implemented (instead of the outdated legacy callbacks).
- The outdated `LightGraphs.jl` package is updated to the `Graph.jl` package.
- The code now works on Windows, however, without tracking the memory consumption. This means that a memory limit is just set as `CPXPARAM_WorkMem`, without further memory consumption tracking within a callback.

The code is briefly tested with:
- Ubuntu 22.04, Windows 11
- Julia 1.9.0, Julia 1.10.0
- CPLEX 22.1

For the used package versions see, the files `Project.toml` and `Manifest.toml`.

**Please cite as**
```
@article{kahr2024imp,
  author =        {Kahr Michael, Leitner Markus, Ljubic Ivana},
  publisher =     {INFORMS Journal on Computing},
  title =         {{The impact of passive social media viewers in influence maximization}},
  year =          {2024},
  doi =           {10.1287/ijoc.2023.0047},
  url =           {https://github.com/INFORMSJoC/2023.0047},
}  
```


