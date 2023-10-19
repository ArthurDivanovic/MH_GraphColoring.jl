function eval(adj::Matrix{Int}, colors::Vector{Int})::Int
    n = size(adj)[1]

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


function get_edge_conflicts(adj::Matrix{Int}, colors::Vector{Int})::Vector{Tuple{Int, Int}}
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

function eval_vertice(adj::Matrix{Int}, colors::Vector{Int}, v::Int)::Int
    n = size(adj)[1]

    nb_conflict = 0
    for u = 1:n
        if adj[u,v] == 1 && colors[u] == colors[v]
            nb_conflict += 1
        end   
    end

    return nb_conflict
end

function eval_all_vertices(adj::Matrix{Int}, colors::Vector{Int})::Vector{Int}
    conflicts = Vector{Int}

    n = size(adj)[1]
    for u = 1:n
        push!(conflicts, eval_vertice(adj, colors, u))
    end

    return conflicts
end

