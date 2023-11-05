mutable struct TabuSearch <: Heuristic
    nb_iter             ::Int
    neigh_iter          ::Int
    distance_threshold  ::Float64

    tabu_iter           ::Union{Int, Nothing}
    A                   ::Union{Int, Nothing}
    alpha               ::Union{Float64, Nothing}
    m_max               ::Union{Int, Nothing}
    tabu_iter_function  ::Union{Function, Nothing}

    swap                ::Bool
end


"""
    tabu_search(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter::Int)::Tuple{Vector{Int}, Int}

Tabu search over a Colored Graph with a random neighboor generation. 

# Arguments 
- g                     ::ColoredGraph  : Graph instance
- nb_iter               ::Int           : Number of iterations for the global algorithm 
- neigh_iter            ::Int           : Number of neighboors generated at each iteration
- tabu_iter             ::Int           : Number of iterations forbidden for a neighboor (v,c) visited
- R                     ::Float64       : Diversification if distance(g.colors, plateau) <= R 

"""

function tabu_search(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter_function::Function, R::Int)
    start_time = time()

    # Create tabu table
    T = init_tabu_table(g, tabu_iter_function)

    @showprogress dt=1 desc="Computing..." for i in 1:nb_iter

        # Find best neighbor with tabu restrictions
        best_v, best_c, best_delta = best_neighbor_with_tabu(g, T.tabu_table, neigh_iter, i)

        # Update graph
        update!(g, best_v, best_c, best_delta)

        # Update tabu table
        update_tabu_table!(g, best_delta, T, i, R)

        # Update best solution if needed
        if g.nb_conflict < g.nb_conflict_min
            update_min!(g, start_time)
            # Cut execution if there are no conflicts: an optimal coloration has been found
            if g.nb_conflict_min == 0
                break
            end
        end
    end
end

"""
    swap_tabu_search(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter::Int)::Tuple{Vector{Int}, Int}

Tabu search over a Colored Graph with a random neighboor generation (using swap operator). 

# Arguments 
- g                     ::ColoredGraph  : Graph instance
- nb_iter               ::Int           : Number of iterations for the global algorithm 
- neigh_iter            ::Int           : Number of neighboors generated at each iteration
- tabu_iter             ::Int           : Number of iterations forbidden for a neighboor (v,c) visited
- R                     ::Float64       : Diversification if distance(g.colors, plateau) <= R 

"""


function swap_tabu_search(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter_function::Function, R::Int)
    start_time = time()

    # Create tabu table
    T = init_tabu_table(g, tabu_iter_function)

    @showprogress dt=1 desc="Computing..." for i in 1:nb_iter

        # Find best neighbor with tabu restrictions
        best_v1, best_c1, best_delta1, best_v2, best_c2, best_delta2 = best_swap_neighbor_with_tabu(g, T.tabu_table, neigh_iter, i)

        # Update graph
        update!(g, best_v1, best_c1, best_delta1)
        update!(g, best_v2, best_c2, best_delta2)

        # Update tabu table
        update_tabu_table!(g, best_delta1 + best_delta2, T, i, R)

        # Update best solution if needed
        if g.nb_conflict < g.nb_conflict_min
            update_min!(g, start_time)
            # Cut execution if there are no conflicts: an optimal coloration has been found
            if g.nb_conflict_min == 0
                break
            end
        end
    end
end


"""
    best_neighbor_with_tabu(g::ColoredGraph, tabu_table::Matrix{Int}, neigh_iter::Int, iter::Int)::Tuple{Int, Int, Int}

Searches the best non-tabu neighbour in the neighbourhood of the current graph.

# Arguments 
- g                     ::ColoredGraph      : Graph instance
- tabu_table            ::Matrix{Int}       : Tabu table
- neigh_iter            ::Int               : Number of neighboors generated at each iteration
- iter                  ::Int               : Current iteration number in the tabu search process

# Outputs
- best_v                ::Int               :Index of the vertice whose color should be changed to obtained the best neighbour
- best_c                ::Int               :Index of the color to assign to best_v
- best_delta            ::Int               :Variation of the number of conflicts induced by this change 
"""

function best_neighbor_with_tabu(g::ColoredGraph, tabu_table::Matrix{Int}, neigh_iter::Int, iter::Int)::Tuple{Int, Int, Int}
    
    # Initialize a random non-tabu neighbor
    v0, c0, delta0 = nothing, nothing, nothing
    while isnothing(delta0)
        v0, c0, delta0 = random_neighbor(g, tabu_table, iter)
    end

    # Initialize the attributes of the best non-tabu neighbour found so far
    best_v, best_c, best_delta = v0, c0, delta0

    for j = 1:neigh_iter
        #Get a new neighbor according to the tabu table
        v, c, delta = random_neighbor(g, tabu_table, iter)
        
        #If this neighbor is not forbidden and is the best one so far : change best neighbor
        if !isnothing(delta) && delta <= best_delta
            best_v, best_c, best_delta = v, c, delta
        end
    end

    return best_v, best_c, best_delta
end




"""
    best_swap_neighbor_with_tabu(g::ColoredGraph, tabu_table::Matrix{Int}, neigh_iter::Int, iter::Int)::Tuple{Int, Int, Int, Int, Int, Int}

Searches the best non-tabu swap neighbour in the neighbourhood of the current graph.

# Arguments 
- g                     ::ColoredGraph      : Graph instance
- tabu_table            ::Matrix{Int}       : Tabu table
- neigh_iter            ::Int               : Number of neighboors generated at each iteration
- iter                  ::Int               : Current iteration number in the tabu search process

# Outputs
- v1                ::Int               :Index of the vertice whose color should be changed to obtained the best neighbour
- c1                ::Int               :Index of the color to assign to best_v
- delta1            ::Int               :Variation of the number of conflicts induced by this change 
- v2                ::Int               :Index of the vertice whose color should be changed to obtained the best neighbour
- c2                ::Int               :Index of the color to assign to best_v
- delta2            ::Int               :Variation of the number of conflicts induced by this change
"""

function best_swap_neighbor_with_tabu(g::ColoredGraph, tabu_table::Matrix{Int}, neigh_iter::Int, iter::Int)::Tuple{Int, Int, Int,Int, Int, Int}
    
    # Initialize a random non-tabu neighbor
    v1, c1, delta1, v2, c2, delta2 = nothing, nothing, nothing, nothing, nothing, nothing
    while isnothing(delta1) || isnothing(delta2)
        v1, c1, delta1, v2, c2, delta2 = random_swap_neighbor(g, tabu_table, iter)
    end

    # Initialize the attributes of the best non-tabu neighbour found so far
    best_v1, best_c1, best_delta1, best_v2, best_c2, best_delta2 = v1, c1, delta1, v2, c2, delta2

    for j = 1:neigh_iter
        #Get a new neighbor according to the tabu table
        v1, c1, delta1, v2, c2, delta2 = random_swap_neighbor(g, tabu_table, iter)
        
        #If this neighbor is not forbidden and is the best one so far : change best neighbor
        if !isnothing(delta1) && !isnothing(delta2) && (delta1 + delta2 <= best_delta1 + best_delta2)
            best_v1, best_c1, best_delta1, best_v2, best_c2, best_delta2 = v1, c1, delta1, v2, c2, delta2
        end
    end

    return best_v1, best_c1, best_delta1, best_v2, best_c2, best_delta2
end


"""
    (heuristic::TabuSearch)(g::ColoredGraph)

Applies the TabuSearch heuristic object to the graph g and adds it to the list of heuristics applied.

# Arguments 
- g                     ::ColoredGraph      : Graph instance

# Outputs
None, the attributes of the graph g are updated.
"""

function (heuristic::TabuSearch)(g::ColoredGraph)

    # If no fixed tabu_iter number is given, a dynamic function would be utilized
    if isnothing(heuristic.tabu_iter)
        heuristic.tabu_iter_function = dynamic_tabu_iter_function(heuristic.A, heuristic.alpha, heuristic.m_max)
    else
        heuristic.tabu_iter_function = constant_tabu_iter_function(heuristic.tabu_iter)
    end

    # Perform the tabu search
    solving_time = @elapsed begin
        R = Int(floor(heuristic.distance_threshold*g.n))

        if !heuristic.swap
            tabu_search(g, heuristic.nb_iter, heuristic.neigh_iter, heuristic.tabu_iter_function, R)
        else
            swap_tabu_search(g, heuristic.nb_iter, heuristic.neigh_iter, heuristic.tabu_iter_function, R)
        end
    end
    
    # Compute solving time
    g.resolution_time += solving_time

    # Update the list of heuristics applied to the graph g
    push!(g.heuristics_applied, heuristic)
end


"""
    save_parameters(heuristic::TabuSearch, file_name::String)

Saves the parameters of the TabuSearch heuristic in the file called 'file_name'

# Arguments 
- heuristic             ::TabuSearch        : TabuSearch heuristic employed
- file_name             ::String            : Name of the file to save results in

# Outputs
None
"""

function save_parameters(heuristic::TabuSearch, file_name::String)
    file = open("results/$file_name", "a")

    write(file, "h TabuSearch = nb_iter:$(heuristic.nb_iter) neigh_iter:$(heuristic.neigh_iter) tabu_iter:$(heuristic.tabu_iter) A:$(heuristic.A) alpha:$(heuristic.alpha) m_max:$(heuristic.m_max) Swap:$(heuristic.swap)\n")

    close(file)
end


"""
    color_diversification(g::ColoredGraph, distance_threshold::Float64)

This step belongs to the diversification process of the tabu search. It updates the colors of a percentage of the vertices of the graph.

# Arguments 
- g                     ::ColoredGraph  : Graph instance
- distance_threshold    ::Float64       : Distance threshold used in the diversification process. It represents the percentage of |V| 
                                            used to define a configuration as close to another.

# Outputs
None, the function only updates the graph.
"""
function color_diversification(g::ColoredGraph, distance_threshold::Float64)
    # Number of color changes to perform
    nb_iter = Int(floor(distance_threshold*g.n))

    for i = 1:nb_iter
        v, c, delta = random_neighbor(g)
        update!(g, v, c, delta)
    end
end


"""
    dynamic_tabu_iter(A::Int=10, alpha::Float64=0.6, m_max::Int=1000)::Function

Returns the function that allows to dynamically adjust tabu_iter during the tabu search heuristic

# Arguments 
- A                     ::Int                   : Parameter A of the heuristic
- alpha                 ::Float64               : Parameter alpha of the heuristic
- m_max                 ::Int                   : Parameter m_max of the heuristic

# Outputs
- f                     ::Function              :function that can be called during the execution of the heuristic to compute tabu_iter
"""

function dynamic_tabu_iter_function(A::Int=10, alpha::Float64=0.6, m_max::Int=1000)::Function
    function f(g::ColoredGraph, m::Int)
        return A + alpha * g.nb_conflict + Int(floor(m / m_max))
    end
    return f
end


"""
    constant_tabu_iter(cst::Int)::Function

Returns the function that allows to fix tabu_iter to a constant for all the duration of the tabu search heuristic

# Arguments 
- cst                   ::Int                  : Contant chosen by the user for tabu_iter

# Outputs
- f                     ::Function              :function that can be called during the execution of the heuristic to compute tabu_iter
"""

function constant_tabu_iter_function(cst::Int)::Function
    function f(g::ColoredGraph, m::Int)
        return cst
    end
    return f
end