include("parser.jl")

struct ColoredGraph
    adj     ::Matrix{Int}
    k       ::Int
    colors  ::Vector{Int}
end

function init_graph(graph_path::String, k_path::String, k_idx::Int=1)::ColoredGraph
    adj, m, file_name = parse_file(graph_path)
    k_dict = k_parser(k_path)
    k = k_dict[file_name]
    colors = ones(Int, size(adj)[1])

    return ColoredGraph(adj, k, colors)
end
