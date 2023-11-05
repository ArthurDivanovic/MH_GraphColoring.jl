abstract type Heuristic end


"""
    mutable struct ColoredGraph

Main Graph structure. It contains all the information necessary to solve the graph coloring problem.

# Arguments 
- name                ::String              : Name of the file gathering the information on the graph instance.
- adj                 ::Matrix{Int}         : Adjacency matrix of the graph
- n                   ::Int                 : Number of vertices  
- m                   ::Int                 : Number of edges

- k                   ::Int                 : Number of colors that can be used in a coloration
- colors              ::Vector{Int}         : Current vertice coloration
- best_colors         ::Vector{Int}         : Best coloration found so far

- heuristics_applied  ::Vector{Heuristic}   : Vector of all the coloration heuristics applied to the graph
- resolution_time     ::Float64             : Solving time taken by the heuristics applied
- time_to_best        ::Float64             : Time needed to obtain the best coloration so far

- nb_conflict         ::Int                 : Current number of conflicts (associated with the coloration 'colors')
- nb_conflict_min     ::Int                 : Minimum number of conflicts found so far (associated with the coloration 'best_colors')
- save_conflict       ::Bool                : Boolean. If equal to true, an history of the number of conflicts encountered is kept
- conflict_history    ::Vector{Int}         : History of the number of conflicts
"""


mutable struct ColoredGraph
    name                ::String
    adj                 ::Matrix{Int}
    n                   ::Int
    m                   ::Int
    
    k                   ::Int
    colors              ::Vector{Int}
    best_colors         ::Vector{Int}

    heuristics_applied  ::Vector{Heuristic}
    resolution_time     ::Float64
    time_to_best        ::Float64

    nb_conflict         ::Int
    nb_conflict_min     ::Int
    save_conflict       ::Bool
    conflict_history    ::Vector{Int}
end


"""
    init_graph(graph_path::String, k_path::String, k_idx::Int=1, save_conflict::Bool=false)::ColoredGraph

Initialize a ColoredGraph structure with a txt file.

# Arguments 
- graph_path        ::String        : File path for graph instance
- k_path            ::String        : File path to find the number of colors allowed (k)
- k_idx             ::Int           : For some instances, more than one k could be provided. Index of the k to consider.
- save_conflict     ::Bool          : Boolean. If equal to true, an history of the number of conflicts encountered is kept

# Outputs
- g                 ::ColoredGraph   
"""

function init_graph(graph_path::String, k_path::String, k_idx::Int=1, save_conflict::Bool=false)::ColoredGraph
    adj, m, file_name = parse_file(graph_path)
    n = size(adj)[1]
    k_dict = k_parser(k_path)
    k = k_dict[file_name][k_idx]

    # Initialize a random coloration
    colors = rand(1:k, n)
    best_colors = deepcopy(colors)

    # Initialize the vector of heuristics applied
    heuristics_applied = Vector{Heuristic}()

    resolution_time = 0.0
    time_to_best = 0.0

    nb_conflict = 0
    nb_conflict_min = 0
    conflict_history = Vector{Int}()

    # Creation of the ColoredGraph object
    g = ColoredGraph(file_name, adj, n, m, k, colors, best_colors, heuristics_applied, resolution_time, time_to_best, nb_conflict, nb_conflict_min, save_conflict, conflict_history)

    g.nb_conflict = eval(g)
    g.nb_conflict_min = g.nb_conflict

    return g
end


"""
    save_coloration(g::ColoredGraph)

Save the best coloration 'g.best_colors' found so far, with all the parameters used.

# Arguments 
- g             ::ColoredGraph 

"""

function save_coloration(g::ColoredGraph)
    
    file = open("results/$(g.name)", "a")
    write(file, "k $(g.k)\n")
    write(file, "o $(g.nb_conflict_min)\n")
    write(file, "t $(g.resolution_time)\n")
    write(file, "b $(g.time_to_best)\n")
    write(file, "n $(length(g.conflict_history))\n")
    write(file, "c $(g.best_colors)\n")
    close(file)

    for h in g.heuristics_applied
        save_parameters(h, g.name)
    end

    file = open("results/$(g.name)", "a")
    write(file, "\n")
    close(file)
end


"""
    update!(g::ColoredGraph, v::Int, c::Int, delta::Int)

Updates g according to the following change: the color c is assigned to the vertice v. 

# Arguments 
- g             ::ColoredGraph      : Graph instance
- v             ::Int               : index of a vertice of g
- new_c         ::Int               : New color to assign to v (not equal to 'g.colors[v]')
- delta         ::Int               : Variation of the number of conflicts induced by the change
# Outputs
None
"""

function update!(g::ColoredGraph, v::Int, c::Int, delta::Int)
    # Updates g.colors
    g.colors[v] = c

    # Update g.nb_conflict
    g.nb_conflict += delta

    # Update g.conflict_history
    if g.save_conflict
        push!(g.conflict_history, g.nb_conflict)
    end
end


"""
    simulate_update(g::ColoredGraph, v::Int, c::Int, delta::Int)

Simulates the updates of g according to the following change: the color c is assigned to the vertice v. 

# Arguments 
- g             ::ColoredGraph      : Graph instance
- v             ::Int               : index of a vertice of g
- new_c         ::Int               : New color to assign to v (not equal to 'g.colors[v]')
- delta         ::Int               : Variation of the number of conflicts induced by the change

# Outputs
- new_g         ::ColoredGraph      : New Graph instance
"""

function simulate_update(g::ColoredGraph, v::Int, c::Int, delta::Int)
    new_g = deepcopy(g)
    # Updates g.colors
    new_g.colors[v] = c

    # Update g.nb_conflict
    new_g.nb_conflict += delta

    return new_g
end


"""
    update_min!(g::ColoredGraph, start_time::Float64, copy_best::Bool=true)

Function called when a new optimum is found. Updates the optimum parameters of the instance.

# Arguments 
- g                 ::ColoredGraph      : Graph instance
- start_time        ::Float64           : Algorithm starting time 
- copy_best         ::Bool              : Boolean for changing 'g.best_colors'

# Outputs 
None
"""

function update_min!(g::ColoredGraph, start_time::Float64, copy_best::Bool=true)
    # Update g.best_colors
    if copy_best
        g.best_colors = deepcopy(g.colors)
    end
    
    # Update g.nb_conflict_min 
    g.nb_conflict_min = g.nb_conflict

    # Updates g.time_to_best  
    g.time_to_best = g.resolution_time + time() - start_time
end


"""
    reinitialize_coloration(g::ColoredGraph)

Reinitializes the coloration of the graph g to a randomly generated one. 
Reinitializes the historic of the heuristics applied to an empty vector.

# Arguments 
- g             ::ColoredGraph      : Graph instance

# Outputs 
None
"""

function reinitialize_coloration(g::ColoredGraph)
    g.colors = rand(1:g.k,g.n)
    g.heuristics_applied = Vector{Heuristic}()
    g.nb_conflict = eval(g)
end
