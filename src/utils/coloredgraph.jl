include("parser.jl")

mutable struct ColoredGraph
    adj     ::Matrix{Int}
    n       ::Int
    m       ::Int
    k       ::Int
    colors  ::Vector{Int}
end

function init_graph(graph_path::String, k_path::String, k_idx::Int=1)::ColoredGraph
    adj, m, file_name = parse_file(graph_path)
    n = size(adj)[1]
    k_dict = k_parser(k_path)
    k = k_dict[file_name][k_idx]
    colors = ones(Int, n)

    return ColoredGraph(adj, n, m, k, colors)
end
