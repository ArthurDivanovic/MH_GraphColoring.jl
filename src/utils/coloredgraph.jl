abstract type Heuristic end

"""
    mutable struct ColoredGraph

Main Graph structure containing all informations on its coloration.

# Arguments 

- name                ::String              : Graph's file name
- adj                 ::Matrix{Int}         : Adjacency matrix
- n                   ::Int                 : Vertice number
- m                   ::Int                 : Edge number

- k                   ::Int                 : Color number
- colors              ::Vector{Int}         : Current vertice coloration
- best_colors         ::Vector{Int}         : Best coloration so far

- heuristics_applied  ::Vector{Heuristic}   : Coloration heuristics applied on the graph
- resolution_time     ::Float64             : Current time processed by the heuristics applied
- time_to_best        ::Float64             : Time needed to get the best coloration so far

- nb_conflict         ::Int                 : Current conflict number (linked to 'colors')
- nb_conflict_min     ::Int                 : Minimum conflict number so far (linked to 'best_colors')
- save_conflict       ::Bool                : Boolean to update conflict number history through the different colorations
- conflict_history    ::Vector{Int}         : Conflict number history
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

Initialize a GraphColored structure with a txt file.

# Arguments 
- graph_path    ::String        : File path for graph instance
- k_path        ::String        : File path for coloration max number k
- k_idx         ::Int           : Parameter k chosen for coloration 
- save_conflict ::Bool          : Boolean to update conflict number history through the different colorations

# Outputs
- g             ::ColoredGraph   
"""

function init_graph(graph_path::String, k_path::String, k_idx::Int=1, save_conflict::Bool=false)::ColoredGraph
    adj, m, file_name = parse_file(graph_path)
    n = size(adj)[1]
    k_dict = k_parser(k_path)
    k = k_dict[file_name][k_idx]

    colors = rand(1:k, n)
    best_colors = deepcopy(colors)

    heuristics_applied = Vector{Heuristic}()

    resolution_time = 0.0
    time_to_best = 0.0

    nb_conflict = 0
    nb_conflict_min = 0
    conflict_history = Vector{Int}()

    g = ColoredGraph(file_name, adj, n, m, k, colors, best_colors, heuristics_applied, resolution_time, time_to_best, nb_conflict, nb_conflict_min, save_conflict, conflict_history)

    g.nb_conflict = eval(g)
    g.nb_conflict_min = g.nb_conflict

    return g
end

"""
    save_coloration(g::ColoredGraph)

Save the best coloration so far 'g.best_colors' with all parameters.

# Arguments 
- g             ::ColoredGraph 

"""

function save_coloration(g::ColoredGraph)
    
    file = open("results/$(g.name)", "a")
    write(file, "k $(g.k)\n")
    write(file, "o $(g.nb_conflict_min)\n")
    write(file, "t $(g.resolution_time)\n")
    write(file, "b $(g.time_to_best)\n")
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

Return a random neighbor of 'g.colors', i.e. the same coloration but one vertice with a different color

# Arguments 
- g         ::ColoredGraph  : Graph instance

# Outputs
- v         ::Int           : Vertice from g
- new_c     ::Int           : New color for v (different than 'g.colors[v]')
- delta     ::Int           : Delta between g.nb_conflict and the conflict number from the neighbor generated
"""

function random_neighbor(g::ColoredGraph)::Tuple{Int,Int,Int}
    v = rand(1:g.n)

    current_c = g.colors[v]
    new_c_idx = rand(1:(g.k-1))

    new_c = 0
    if new_c_idx < current_c
        new_c = new_c_idx
    else
        new_c = new_c_idx + 1
    end

    delta = eval_delta_modif(g, v, new_c)

    return v, new_c, delta
end

"""
    is_tabu(g::ColoredGraph, v::Int, c::Int, tabu_table::Matrix{Int}, iter::Int)::Bool

Returns true if changing the color of vertice v to c is tabu, and false otherwise.

# Arguments 
- g             ::ColoredGraph  : Graph instance
- v             ::Int           : Index of the vertice under scrutiny 
- c             ::Int           : Index of the color under scrutiny 
- tabu_table    ::Matrix{Int}   : Tabu table with tabu_table[v,c] = the minimum algorithm iteration number allowed to put colors[v] = c

# Outputs
- tabu_neighbor ::Bool          : Boolean describing if the change is tabu or not
"""

function is_tabu(g::ColoredGraph, v::Int, c::Int, tabu_table::Matrix{Int}, iter::Int)::Bool
    tabu_neighbor = true
    if tabu_table[v, c] <= iter
        tabu_neighbor = false
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
    random_neighbor(g::ColoredGraph)::Tuple{Int,Int,Int}

Return a random neighbor of 'g.colors', i.e. the same coloration but one vertice with a different color if it's not forbidden by tabu_table. 
Update tabu_table.

# Arguments 
- g             ::ColoredGraph  : Graph instance
- tabu_table    ::Matrix{Int}   : Tabu table with tabu_table[v,c] = the minimum algorithm iteration number allowed to put colors[v] = c
- tabu_iter     ::Int           : Number of iterations forbidden for a neighboor (v,c) visited
- iter          ::Int           : Current algorithm iteration number 

# Outputs
- v             ::Int           : Vertice from g
- new_c         ::Int           : New color for v (different than 'g.colors[v]')
- delta         ::Int           : Delta between g.nb_conflict and the conflict number from the neighbor generated
"""

function random_neighbor(g::ColoredGraph, tabu_table::Matrix{Int}, iter::Int)::Tuple{Int,Int,Union{Nothing,Int}}
    v = rand(1:g.n)

    current_c = g.colors[v]
    new_c_idx = rand(1:(g.k-1))

    new_c = 0
    if new_c_idx < current_c
        new_c = new_c_idx
    else
        new_c = new_c_idx + 1
    end

    delta = nothing

    if !is_tabu(g, v, new_c, tabu_table, iter)
        delta = eval_delta_modif(g, v, new_c)
    end
    
    return v, new_c, delta
end


"""
    update!(g::ColoredGraph, v::Int, c::Int, delta::Int)

Update g from one coloration to one of its neighbor.

Update g.colors                 : g.colors[v] = c.
Update g.nb_conflict            : g.nb_conflict += delta.
Update g.conflict_history       : if g.save_conflict then push!(g.conflict_history, g.nb_conflict)

# Arguments 
- g             ::ColoredGraph  : Graph instance
- v             ::Int           : Vertice from g
- new_c         ::Int           : New color for v (different than 'g.colors[v]')
- delta         ::Int           : Delta between g.nb_conflict and the conflict number from the neighbor generated

"""

function update!(g::ColoredGraph, v::Int, c::Int, delta::Int)
    g.colors[v] = c

    g.nb_conflict += delta

    if g.save_conflict
        push!(g.conflict_history, g.nb_conflict)
    end
end

function update!(g::ColoredGraph, v::Int, c::Int, delta::Int, tabu_table::Matrix{Int}, iter::Int, tabu_iter::Int)
    g.colors[v] = c

    g.nb_conflict += delta

    if g.save_conflict
        push!(g.conflict_history, g.nb_conflict)
    end

    for i = 1:g.n
        tabu_table[i,g.colors[i]] =  iter + tabu_iter
    end
end

"""
    update_min!(g::ColoredGraph, start_time::Float64, copy_best::Bool=true)

Function called when a new optimum is found. Update the optimum parameters of g.

Update g.best_colors            : if copy_best then g.best_colors = deepcopy(g.colors)
Update g.nb_conflict_min        : g.nb_conflict_min = g.nb_conflict.
Update g.time_to_best           : if g.save_conflict then push!(g.conflict_history, g.nb_conflict)

# Arguments 
- g             ::ColoredGraph  : Graph instance
- start_time    ::Float64       : Algorithm starting time 
- copy_best     ::Bool          : Boolean for changing 'g.best_colors'

"""

function update_min!(g::ColoredGraph, start_time::Float64, copy_best::Bool=true)
    if copy_best
        g.best_colors = deepcopy(g.colors)
    end
    
    g.nb_conflict_min = g.nb_conflict

    g.time_to_best = g.resolution_time + time() - start_time
end


function reinitialize_coloration(g::ColoredGraph)
    g.colors = rand(1:g.k,g.n)
    g.heuristics_applied = Vector{Heuristic}()
end