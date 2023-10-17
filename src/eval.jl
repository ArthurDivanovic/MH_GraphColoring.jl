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


function get_conflicts(adj::Matrix{Int}, colors::Vector{Int})::Vector{Tuple{Int, Int}}
    n = size(adj)[1]

    conflicts = Vector{Tuple{Int, Int}}()

    for u in 1:n
        for v = 1:n
            if adj[u,v] == 1 && colors[u] == colors[v]
                push!(conflicts, (u,v))
            end
        end
    end

    return conflicts
end