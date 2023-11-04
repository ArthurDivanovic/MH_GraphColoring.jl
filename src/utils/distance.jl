function day_bipartite_graph(colors1::Vector{Int}, colors2::Vector{Int}, k::Int)
    @assert length(colors1) == length(colors2)
    
    n = length(colors1)

    weights = zeros(Int, k, k)

    for i = 1:n 
        weights[colors1[i], :] .+= 1
        weights[:, colors2[i]] .+= 1
        weights[colors1[i], colors2[i]] -= 2
    end
    
    return weights
end


function hungarian_algorithm(original_cost_matrix::Matrix{Int})::Matrix{Bool}
    
    cost_matrix = deepcopy(original_cost_matrix)

    # Phase 1 : Réduction des lignes
    row_min = minimum(cost_matrix, dims=2)
    cost_matrix .-= row_min

    # Phase 2 : Réduction des colonnes
    col_min = minimum(cost_matrix, dims=1)
    cost_matrix .-= col_min

    # Initialisation du marquage des lignes et colonnes
    num_rows, num_cols = size(cost_matrix)
    row_covered = falses(num_rows)
    col_covered = falses(num_cols)

    # Tableau d'adjacence du couplage
    matching = zeros(Bool, num_rows, num_cols)

    while true
        # Phase 3 : Marquage des zéros et recherche d'un couplage
        for i in 1:num_rows
            if any(cost_matrix[i, :] .== 0) && !row_covered[i]
                j = findfirst(cost_matrix[i, :] .== 0)
                row_covered[i] = true
                col_covered[j] = true
                matching[i, j] = true
            end
        end

        # Phase 4 : Réduction des lignes non couvertes
        uncov_rows = findall(.!row_covered)
        if isempty(uncov_rows)
            break
        end

        min_uncovered = minimum(cost_matrix[uncov_rows, :], dims=2)
        cost_matrix[uncov_rows, :] .-= min_uncovered

        # Phase 5 : Réduction des colonnes couvertes
        col_min = minimum(cost_matrix, dims=1)
        cost_matrix .-= col_min

        # Démarquage des lignes
        row_covered .= false
        col_covered .= false
    end

    return matching
end

function get_distance(colors1::Vector{Int}, colors2::Vector{Int}, k::Int)::Int
    cost_matrix = day_bipartite_graph(colors1, colors2, k)

    matching = hungarian_algorithm(cost_matrix)

    w2 = sum(cost_matrix .* matching) 

    return div(w2,2)
end