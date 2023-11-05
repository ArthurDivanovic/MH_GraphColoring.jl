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
    write(file, "n $(length(g.conflict_history))")
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
    random_neighbor(g::ColoredGraph)::Tuple{Int,Int,Int}

Given a graph g, returns a vertice index and the color to assign to it (both generated randomly), 
as well as the number of conflicts variation induced by this change.

# Arguments 
- g         ::ColoredGraph      : Graph instance

# Outputs
- v         ::Int               : Vertice of g
- new_c     ::Int               : New color to assign to v (new_c is not equal to 'g.colors[v]')
- delta     ::Int               : Variation of the number of conflicts induced by this change
"""

function random_neighbor(g::ColoredGraph)::Tuple{Int,Int,Int}
    # Select a random vertice index
    v = rand(1:g.n)

    # Select a random color 
    current_c = g.colors[v]
    new_c_idx = rand(1:(g.k-1))

    # Make sure the new color to assign is not equal to the previous one
    new_c = 0
    if new_c_idx < current_c
        new_c = new_c_idx
    else
        new_c = new_c_idx + 1
    end

    # Evaluate the variation of the number of conflicts induced by the change
    delta = eval_delta_modif(g, v, new_c)

    return v, new_c, delta
end


"""
    random_swap_neighbor(g::ColoredGraph)::Tuple{Int,Int,Int,Int,Int,Int}

Given a graph g, exchanges the colors of two vertices chosen randomly (only if the colors are different). 
Computes the variation of number of conflicts induced.

# Arguments 
- g         ::ColoredGraph      : Graph instance

# Outputs
- v1         ::Int               : Vertice of g
- new_c1     ::Int               : New color to assign to v1 (new_c is not equal to 'g.colors[v]')
- v2         ::Int               : Vertice of g
- new_c2     ::Int               : New color to assign to v2 (new_c is not equal to 'g.colors[v]')
- delta1     ::Int               : Variation of the number of conflicts induced by the first change 
- delta2     ::Int               : Variation of the number of conflicts induced by the second change 
"""

function random_swap_neighbor(g::ColoredGraph)::Tuple{Int,Int,Int,Int,Int,Int}
    colors = deepcopy(g.colors)
    nb_conflict = g.nb_conflict

    # Select two random vertice index, that have distinct colors
    v1 = rand(1:g.n)

    same_color = true
    v2 = v1

    while same_color
        v2 = rand(1:g.n)
        if g.colors[v1] != g.colors[v2]
            same_color = false
        end
    end

    new_c1 = g.colors[v2]
    new_c2 = g.colors[v1]

    # Evaluate the variation of the number of conflicts induced by the swap
    delta1 = eval_delta_modif(g, v1, new_c1) 
    new_g = simulate_update(g, v1, new_c1, delta1)
    delta2 = eval_delta_modif(new_g, v2, new_c2)

    return v1, new_c1, v2, new_c2, delta1, delta2
end


"""
    is_tabu(g::ColoredGraph, v::Int, c::Int, tabu_table::Matrix{Int}, iter::Int)::Bool

Returns true if changing the color of vertice v to c is tabu, and false otherwise.

# Arguments 
- g             ::ColoredGraph      : Graph instance
- v             ::Int               : Index of the vertice under scrutiny 
- c             ::Int               : Index of the color under scrutiny 
- tabu_table    ::Matrix{Int}       : Tabu table (tabu_table[v,c] = minimum iteration index for which it is allowed to put colors[v] = c)

# Outputs
- tabu_neighbor ::Bool              : Boolean. Equal to true if the change is tabu
"""

function is_tabu(g::ColoredGraph, v::Int, c::Int, tabu_table::Matrix{Int}, iter::Int)::Bool
    tabu_neighbor = true

    # Look in the tabu table if the assignation of the color c to v is tabu
    if tabu_table[v, c] <= iter
        tabu_neighbor = false

    # Look in the tabu table if at least one association vertice-color is not tabu (here the tabus are complet graphs)
    else
        for i = 1:g.n
            if tabu_table[i,g.colors[i]] <= iter 
                tabu_neighbor = false
                break
            end
        end
    end
    return tabu_neighbor
end


"""
    random_neighbor(g::ColoredGraph, tabu_table::Matrix{Int}, iter::Int)::Tuple{Int,Int,Union{Nothing,Int}}

Given a graph g, returns a vertice index and the color to assign to it (if non-tabu), 
as well as the number of conflicts variation induced by this change. 

# Arguments 
- g                 ::ColoredGraph          : Graph instance
- tabu_table        ::Matrix{Int}           : Tabu table
- iter              ::Int                   : Index of the current iteration

# Outputs
- v                 ::Int                   : Vertice of g
- new_c             ::Int                   : New color to assign to v (new_c is not equal to 'g.colors[v]')
- delta             ::Int                   : Variation of the number of conflicts induced by this change
"""

function random_neighbor(g::ColoredGraph, tabu_table::Matrix{Int}, iter::Int)::Tuple{Int,Int,Union{Nothing,Int}}
    # Select a random vertice
    v = rand(1:g.n)

    # Pick a random color, different from the one already assigned to v
    current_c = g.colors[v]
    new_c_idx = rand(1:(g.k-1))

    new_c = 0
    if new_c_idx < current_c
        new_c = new_c_idx
    else
        new_c = new_c_idx + 1
    end

    delta = nothing

    # Check if the change is tabu. If it is, delta is nothing.
    if !is_tabu(g, v, new_c, tabu_table, iter)
        delta = eval_delta_modif(g, v, new_c)
    end
    
    return v, new_c, delta
end


"""
    random_swap_neighbor(g::ColoredGraph, tabu_table::Matrix{Int}, iter::Int)::Tuple{Int,Int,Union{Nothing,Int},Int,Int,Union{Nothing,Int}}

Given a graph g, returns a vertice index and the color to assign to it (if non-tabu), 
as well as the number of conflicts variation induced by this change. 

# Arguments 
- g                 ::ColoredGraph          : Graph instance
- tabu_table        ::Matrix{Int}           : Tabu table
- iter              ::Int                   : Index of the current iteration

# Outputs
- v                 ::Int                   : Vertice of g
- new_c             ::Int                   : New color to assign to v (new_c is not equal to 'g.colors[v]')
- delta             ::Int                   : Variation of the number of conflicts induced by this change
"""

function random_swap_neighbor(g::ColoredGraph, tabu_table::Matrix{Int}, iter::Int)::Tuple{Int,Int,Union{Nothing,Int},Int,Int,Union{Nothing,Int}}
    # Select two random vertice index, that have distinct colors
    v1 = rand(1:g.n)

    same_color = true
    v2 = v1

    while same_color
        v2 = rand(1:g.n)
        if g.colors[v1] != g.colors[v2]
            same_color = false
        end
    end

    new_c1 = g.colors[v2]
    new_c2 = g.colors[v1]

    delta1 = nothing
    delta2 = nothing

    # Check if the change is tabu. If it is, delta is nothing.
    if !is_tabu(g, v1, new_c1, tabu_table, iter) && !is_tabu(g, v2, new_c2, tabu_table, iter)
        delta1 = eval_delta_modif(g, v1, new_c1) 
        new_g = simulate_update(g, v1, new_c1, delta1)
        delta2 = eval_delta_modif(new_g, v2, new_c2)
    end
    
    return v1, new_c1, delta1, v2, new_c2, delta2
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
