include("coloredgraph.jl")

function eval(g::ColoredGraph)::Int
    adj = g.adj
    n = size(adj)[1]
    colors = g.colors

    nb_conflict = 0

    for u in 1:n
        for v = 1:n
            if adj[u,v] == 1 && colors[u] == colors[v]
                nb_conflict += 1
            end
        end
    end

    return nb_conflict
end


function get_edge_conflicts(g::ColoredGraph)::Vector{Tuple{Int, Int}}
    adj = g.adj
    colors = g.colors
    n = size(adj)[1]

    conflicts = Vector{Tuple{Int, Int}}()

    for u = 1:n
        for v = 1:n
            if adj[u,v] == 1 && colors[u] == colors[v]
                push!(conflicts, (u,v))
            end
        end
    end

    return conflicts
end

function eval_vertice(g::ColoredGraph, v::Int)::Int
    adj = g.adj
    colors = g.colors
    n = size(adj)[1]

    nb_conflict = 0
    for u = 1:n
        if adj[u,v] == 1 && colors[u] == colors[v]
            nb_conflict += 1
        end   
    end

    return nb_conflict
end

function eval_all_vertices(g::ColoredGraph)::Vector{Int}
    conflicts = Vector{Int}

    adj = g.adj
    n = size(adj)[1]
    
    for u = 1:n
        push!(conflicts, eval_vertice(g, u))
    end

    return conflicts
end

