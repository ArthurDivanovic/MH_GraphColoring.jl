include("coloredgraph.jl")

function eval(g::ColoredGraph)::Int
    adj = g.adj
    n = g.n
    colors = g.colors

    nb_conflict = 0

    for u in 1:n
        for v = u+1:n
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
    n = g.n

    conflicts = Vector{Tuple{Int, Int}}()

    for u = 1:n
        for v = u+1:n
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

    nb_conflict = 0
    for u = 1:g.n
        if adj[u,v] == 1 && colors[u] == colors[v]
            nb_conflict += 1
        end   
    end

    return nb_conflict
end

function eval_all_vertices(g::ColoredGraph)::Vector{Int}
    conflicts = Vector{Int}

    adj = g.adj
    
    for u = 1:g.n
        push!(conflicts, eval_vertice(g, u))
    end

    return conflicts
end

function eval_delta_modif(g::ColoredGraph, u::Int, c::Int)::Int
    conflicts = Vector{Int}
    colors = g.colors
    adj = g.adj

    old_vertice_eval = eval_vertice(g, u)
    
    new_vertice_eval = 0
    for v = 1:g.n
        if adj[u,v] == 1 && c == colors[v]
            new_vertice_eval += 1
        end   
    end

    return new_vertice_eval - old_vertice_eval
end

