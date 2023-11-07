# Metaheuristics - Graph Coloring

This repository presents a collaborative work by Axel Navarro and Arthur Divanovic.

It contains all the necessary files for designing, using, and testing various metaheuristics applied to a graph coloring problem. The instances used for performance assessment, as well as the obtained results, are also included in the project.

## Table of Contents

1. [Introduction](#1-introduction)
2. [Installation](#2-installation)
3. [Structure and Documentation](#3-structure-and-documentation)
4. [Use](#4-use)

## 1. Introduction

The goal of this repository is to gather all the functions required to solve the graph coloring problem thanks to two big categories of metaheuristics: the simulated annealing method and the tabu search method. 

This repository can be divided into three main folders:

- **src**: functions used for the solving of the graph coloring problem.
- **Data**: graph instances on which the performance of the heuristic proposed is assessed.
- **Results**: results of the tests.

## 2. Installation

This repository can be cloned directly from this webpage. The required packages to run the code can be found in the `Project.toml` file.

## 3. Structure and Documentation

### 3.1 src folder

This folder contains all the useful files to launch and evaluate the proposed heuristics.

The file `graphcoloring.jl` gathers all the necessary imports used throughout the project.

The rest of the folder is divided into two sub-folders:

#### 3.1.a Heuristics

- `greedy.jl`: Greedy heuristics. These functions are useful for providing initial colorations, which serve as a starting point for more complex metaheuristics.
- `heuristics.jl`: Gathers all the imports from the Heuristics folder.
- `randomvertice.jl`: Random descent heuristics.
- `simulatedannealing.jl`: Implementation of the simulated annealing heuristic.
- `tabusearch.jl`: Implementation of the tabu search heuristic.

#### 3.1.b Utils

- `coloredgraph.jl`: Definition of the ColoredGraph structure. Gathers the functions necessary for graph initialization and update, as well as neighborhood exploration.
- `distance.jl`: Functions used to compute the distance between two graphs using the Hungarian method.
- `eval.jl`: Functions used to evaluate the number of conflicts in a graph, identify the conflicts, or even evaluate the cost variation of a change of color in the graph.
- `parser.jl`: A parser useful for the performance assessment of the method.
- `utils.jl`: Gathers all the imports from the Utils folder.

### 3.2 Data

This folder contains the instances used for performance assessment. They are represented as `.txt` files that contain information about the number of vertices, the number of edges, and the edges between the vertices. There is also a file `kcolors.txt` containing the k studied for each instance.

### 3.3 Results

The Results folder also contains `.txt` files. The names of the files correspond to the instances in the Data folder. In each result file, the best coloration obtained is stored, along with the heuristics employed and the parameters used to obtain this coloration.

This repository presents a joint work done by Axel Navarro and Arthur Divanovic.

It contains all the files necessary for the design, use, and testing of some metaheuristics applied to a graph coloring problem. The instances used for performance assessment as well as the results obatined are also attached to the project.

## 4. Use

Here is an example. 

1. Initialize a ColoredGraph

```julia
g = init_graph("data/dsjc125.1.col.txt", "data/kcolors.txt")
```

2.Initialize a heuristic
```julia
T0 = 12
nb_iter = 100000
mu = 0.95
Tmin = 0.01

heuristic = SimulatedAnnealing(T0, nothing, nothing, nb_iter, mu, Tmin)
```

3.Apply the heuristic
```julia
simulatedannealing(g)
```

4. Get best coloration and the corresponding conflict number
```julia
println(g.best_colors)
println(g.nb_conflict_min)
```
