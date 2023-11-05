"""
    day_bipartite_graph(colors1::Vector{Int}, colors2::Vector{Int}, k::Int)::Matrix{Int}

Computes the weights useful for the computation of the distance between two colorations 
(seen as a distance between partition), according to Day's Theorem.

# Arguments 
- colors1             ::Vector{Int}         : First coloration
- colors2             ::Vector{Int}         : Second coloration
- k                   ::Int                 : Number of colors 

# Outputs 
- weights             ::Matrix{Int}         :weights used in the affectation problem
"""

function day_bipartite_graph(colors1::Vector{Int}, colors2::Vector{Int}, k::Int)::Matrix{Int}
    @assert length(colors1) == length(colors2)
    
    n = length(colors1)

    weights = zeros(Int, k, k)

    for i = 1:n 
        weights[colors1[i], colors2[i]] += 1
    end
    
    return weights
end


"""
    hungarian_algorithm(original_cost_matrix::Matrix{Int})::Matrix{Bool}

Computes a matching of minimum weight between two partitions. This matching is used when computing 
the distance between two colorations.

# Arguments 
- original_cost_matrix            ::Matrix{Int}         : Weights used in the matching

# Outputs 
- matching                        ::Matrix{Bool}        : Matching of minimum weight
"""

function hungarian_algorithm(original_cost_matrix::Matrix{Int})::Matrix{Bool}
    cost_matrix = deepcopy(original_cost_matrix)

    # Phase 1: Row Reduction
    row_max = maximum(cost_matrix, dims=2)
    cost_matrix .-= row_max

    # Phase 2: Column Reduction
    col_max = maximum(cost_matrix, dims=1)
    cost_matrix .-= col_max

    # Initialize row and column covers
    num_rows, num_cols = size(cost_matrix)
    row_covered = falses(num_rows)
    col_covered = falses(num_cols)

    # Matching matrix
    matching = zeros(Bool, num_rows, num_cols)

    while true
        # Phase 3: Mark Zeros and Find Maximum Weighted Matching
        for i in 1:num_rows
            if !row_covered[i]
                # Find the maximum value in the row
                max_in_row = maximum(cost_matrix[i, :])
                if any(cost_matrix[i, :] .== max_in_row)
                    j = findfirst(cost_matrix[i, :] .== max_in_row)
                    row_covered[i] = true
                    col_covered[j] = true
                    matching[i, j] = true
                end
            end
        end

        # Phase 4: Reduce Uncovered Rows
        uncov_rows = findall(.!row_covered)
        if isempty(uncov_rows)
            break
        end

        min_uncovered = minimum(cost_matrix[uncov_rows, :], dims=2)
        cost_matrix[uncov_rows, :] .-= min_uncovered

        # Phase 5: Reduce Covered Columns
        col_min = minimum(cost_matrix, dims=1)
        cost_matrix .-= col_min

        # Uncover rows and columns
        row_covered .= false
        col_covered .= false
    end

    return matching
end


"""
    get_distance(colors1::Vector{Int}, colors2::Vector{Int}, k::Int)::Int

Computes the distance between two colorations. 

# Arguments 
- colors1             ::Vector{Int}         : First coloration
- colors2             ::Vector{Int}         : Second coloration
- k                   ::Int                 : Number of colors 

# Outputs 
- distance            ::Int                 : Distance between the two colorations
"""

function get_distance(colors1::Vector{Int}, colors2::Vector{Int}, k::Int)::Int
    n = length(colors1)

    cost_matrix = day_bipartite_graph(colors1, colors2, k)

    matching = hungarian_algorithm(cost_matrix)

    w1 = sum(cost_matrix .* matching) 

    distance = n - w1

    return distance
end


"""
    in_sphere(colors1::Vector{Int}, colors2::Vector{Int}, k::Int, R::Int)

Using the distance function above, determines wether a coloration is in the sphere of radius R around another coloration.

# Arguments 
- colors1            ::Vector{Int}       : First coloration
- colors2            ::Vector{Int}       : Second coloration
- k                  ::Int               : Number of colors 
- R                  ::Int               : Radius of the sphere

# Outputs 
- a Boolean          ::Boolean           : Equal to true if the first coloration is R-close to the other, false otherwise. 
"""

function in_sphere(colors1::Vector{Int}, colors2::Vector{Int}, k::Int, R::Int)
    n = length(colors1)

    cost_matrix = day_bipartite_graph(colors1, colors2, k)

    M = sum(maximum!(ones(Int,k,1), cost_matrix))

    # Avoid computing a distance if the colorations are trivially far from each other
    if M < n - R
        return false

    else
        matching = hungarian_algorithm(cost_matrix)

        w1 = sum(cost_matrix .* matching) 

        return !(w1 < n - R)
    end
end
