function greedy_coloring(adj::Matrix{Int}, k::Int, colors::Vector{Int})::Vector{Int}
    n = size(adj)[1]

    for u in 1:n
        c_available = trues(k)
        for v = 1:n
            if adj[u,v] == 1
                c_available[colors[v]] = false
            end
        end
        
        new_c = findfirst(c_available)
        if isnothing(new_c)
            colors[u] = rand(1:k)
        else
            colors[u] = new_c
        end
    end
    
    return colors
end