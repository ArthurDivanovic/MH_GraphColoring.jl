include("parser.jl")

abstract type Heuristic end

mutable struct ColoredGraph
    name                ::String
    adj                 ::Matrix{Int}
    n                   ::Int
    m                   ::Int
    k                   ::Int
    colors              ::Vector{Int}
    heuristics_applied  ::Vector{Heuristic}
end

function init_graph(graph_path::String, k_path::String, k_idx::Int=1)::ColoredGraph
    adj, m, file_name = parse_file(graph_path)
    n = size(adj)[1]
    k_dict = k_parser(k_path)
    k = k_dict[file_name][k_idx]
    colors = rand(1:k, n)
    heuristics_applied = Vector{Heuristic}()

    return ColoredGraph(file_name, adj, n, m, k, colors, heuristics_applied)
end

function save_coloration(g::ColoredGraph)::Nothing
    file_name = g.name
    nb_conflict = eval(g)
    
    file = open("results/$file_name", "a")
    write(file, "k $(g.k)\n")
    write(file, "o $nb_conflict\n")
    write(file, "c $colors\n")
    close(file)

    for h in g.heuristics_applied
        save_parameters(h, file_name)
    end

    file = open("results/$file_name", "a")
    write(file, "\n")
    close(file)
end

function reinitialize_coloration(g::ColoredGraph)::Nothing
    g.colors = rand(1:k, n)
    g.heuristics_applied = Vector{Heuristic}()
end
