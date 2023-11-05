mutable struct TabuTable
    tabu_table          ::Matrix{Int}
    tabu_iter_function  ::Function

    m                   ::Int
    Tc                  ::Int

    colors_pivot        ::Vector{Int}
    nb_conflict_pivot   ::Int
    colors_recorded     ::Vector{Vector{Int}}
end


"""
    init_tabu_table(g::ColoredGraph, tabu_iter_function::Function)::TabuTable

Initializes a TabuTable structure thanks to a graph and its tabu_iter function.

# Arguments 
- g                         ::ColoredGraph      : Graph instance
- tabu_iter_function        ::Function          : Function to determine tabu_iter

# Outputs
- tabu_table                ::TabuTable         : The tabu table associated with the graph g   
"""

function init_tabu_table(g::ColoredGraph, tabu_iter_function::Function)::TabuTable
    tabu_table = ones(Int, g.n, g.k)
    m = 0
    Tc = 0
    colors_pivot = deepcopy(g.colors)
    nb_conflict_pivot = g.nb_conflict
    colors_recorded = Vector{Vector{Int}}()

    tabu_table = TabuTable(tabu_table, tabu_iter_function, m, Tc, colors_pivot, nb_conflict_pivot, colors_recorded)
    return tabu_table
end


"""
    update_tabu_table!(g::ColoredGraph, delta::Int, T::TabuTable, iter::Int, R::Int)

Updates tabu matrix, making the new graph g tabu.

# Arguments 
- g                     ::ColoredGraph          : Graph instance
- delta                 ::Int                   : Variation of number of conflicts
- T                     ::TabuTable             : Tabu table 
- iter                  ::Int                   : Current iteration number
- R                     ::Int                   : Radius of the spheres considered

# Outputs
None
"""

function update_tabu_table!(g::ColoredGraph, delta::Int, T::TabuTable, iter::Int, R::Int)
    #Update T.m
    if delta == 0
        T.m += 1
    else
        T.m = 0
    end

    #Update T.Tc, T.colors_pivot, T.nb_conflict_pivot and T.colors_recorded
    if !in_sphere(g.colors, T.colors_pivot, g.k, R)
        T.colors_pivot = deepcopy(g.colors)
        T.nb_conflict_pivot = g.nb_conflict

        if already_visited(T, g.k, R)
            T.Tc += 1
        else
            T.Tc = 0
            push!(T.colors_recorded, T.colors_pivot)
        end
    end
    
    #Update T.tabu_table
    tabu_iter = Int(floor(T.tabu_iter_function(g, T.m) + T.Tc))
    for i = 1:g.n
        T.tabu_table[i,g.colors[i]] =  iter + tabu_iter
    end

    #Update T.colors_pivot and T.nb_conflict_pivot (i.e. ‘‘recentering’’ the current sphere)
    if g.nb_conflict < T.nb_conflict_pivot
        T.colors_pivot = deepcopy(g.colors)
        T.nb_conflict_pivot = g.nb_conflict
    end
end


"""
    already_visited(colors_pivot::Vector{Int}, colors_recorded::Vector{Vector{Int}}, k::Int, R::Int)::Bool

Returns true if the current coloration is R-close to a previously recorded coloration, and false otherwise.

# Arguments 
- colors_pivot          ::Vector{Int}               : current coloration
- colors_recorded       ::Vector{Vector{Int}}       : vector of all the previously recorded colorations

# Outputs
Boolean
"""

function already_visited(T::TabuTable, k::Int, R::Int)::Bool

    for colors in T.colors_recorded
        if in_sphere(colors, T.colors_pivot, k, R)
            return true
        end
    end
    return false
end
