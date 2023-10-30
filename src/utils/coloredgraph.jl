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


function reinitialize_coloration(g::ColoredGraph)
    g.colors = rand(1:g.k,g.n)
    g.heuristics_applied = Vector{Heuristic}()
end


function random_neighbor(g::ColoredGraph, tabu_table::Union{Matrix{Int},Nothing}=nothing)::Tuple{Int,Int,Int}
    v = rand(1:g.n)
    c = rand(1:g.k)
    delta = eval_delta_modif(g, v, c)

    return v, c, delta
end


function random_neighbor_with_tabu!(g::ColoredGraph, tabu_table::Matrix{Int}, tabu_iter::Int, iter::Int)::Tuple{Int,Int,Union{Nothing,Int}}
    v = rand(1:g.n)
    c = rand(1:g.k)
    delta = nothing

    if tabu_table[v,c] <= iter
        delta = eval_delta_modif(g, v, c)
        tabu_table[v,c] = iter + tabu_iter
    end
    
    return v, c, delta
end

function update!(g::ColoredGraph, v::Int, c::Int, delta::Int)
    g.colors[v] = c

    g.nb_conflict += delta

    if g.save_conflict
        push!(g.conflict_history, g.nb_conflict)
    end
end

function update_min!(g::ColoredGraph, start_time::Float64, copy_best::Bool=true)
    if copy_best
        g.best_colors = deepcopy(g.colors)
    end
    
    g.nb_conflict_min = g.nb_conflict

    g.time_to_best = g.resolution_time + time() - start_time
end

