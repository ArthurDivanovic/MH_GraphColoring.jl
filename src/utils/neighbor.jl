"""
    random_neighbor(g::ColoredGraph)::Tuple{Int,Int,Int}

Given a graph g, returns a vertice index and the color to assign to it (both generated randomly), 
as well as the number of conflicts variation induced by this change.

# Arguments 
- g         ::ColoredGraph      : Graph instance

# Outputs
- v         ::Int               : Vertice of g
- new_c     ::Int               : New color to assign to v (new_c is not equal to 'g.colors[v]')
- delta     ::Int               : Variation of the number of conflicts induced by this change
"""

function random_neighbor(g::ColoredGraph)::Tuple{Int,Int,Int}
    # Select a random vertice index
    v = rand(1:g.n)

    # Select a random color 
    current_c = g.colors[v]
    new_c_idx = rand(1:(g.k-1))

    # Make sure the new color to assign is not equal to the previous one
    new_c = 0
    if new_c_idx < current_c
        new_c = new_c_idx
    else
        new_c = new_c_idx + 1
    end

    # Evaluate the variation of the number of conflicts induced by the change
    delta = eval_delta_modif(g, v, new_c)

    return v, new_c, delta
end


"""
    random_swap_neighbor(g::ColoredGraph)::Tuple{Int,Int,Int,Int,Int,Int}

Given a graph g, exchanges the colors of two vertices chosen randomly (only if the colors are different). 
Computes the variation of number of conflicts induced.

# Arguments 
- g         ::ColoredGraph      : Graph instance

# Outputs
- v1         ::Int               : Vertice of g
- new_c1     ::Int               : New color to assign to v1 (new_c is not equal to 'g.colors[v]')
- v2         ::Int               : Vertice of g
- new_c2     ::Int               : New color to assign to v2 (new_c is not equal to 'g.colors[v]')
- delta1     ::Int               : Variation of the number of conflicts induced by the first change 
- delta2     ::Int               : Variation of the number of conflicts induced by the second change 
"""

function random_swap_neighbor(g::ColoredGraph)::Tuple{Int,Int,Int,Int,Int,Int}
    colors = deepcopy(g.colors)
    nb_conflict = g.nb_conflict

    # Select two random vertice index, that have distinct colors
    v1 = rand(1:g.n)

    same_color = true
    v2 = v1

    while same_color
        v2 = rand(1:g.n)
        if g.colors[v1] != g.colors[v2]
            same_color = false
        end
    end

    new_c1 = g.colors[v2]
    new_c2 = g.colors[v1]

    # Evaluate the variation of the number of conflicts induced by the swap
    delta1 = eval_delta_modif(g, v1, new_c1) 
    new_g = simulate_update(g, v1, new_c1, delta1)
    delta2 = eval_delta_modif(new_g, v2, new_c2)

    return v1, new_c1, v2, new_c2, delta1, delta2
end

"""
    random_neighbor(g::ColoredGraph, tabu_table::Matrix{Int}, iter::Int)::Tuple{Int,Int,Union{Nothing,Int}}

Given a graph g, returns a vertice index and the color to assign to it (if non-tabu), 
as well as the number of conflicts variation induced by this change. 

# Arguments 
- g                 ::ColoredGraph          : Graph instance
- tabu_table        ::Matrix{Int}           : Tabu table
- iter              ::Int                   : Index of the current iteration

# Outputs
- v                 ::Int                   : Vertice of g
- new_c             ::Int                   : New color to assign to v (new_c is not equal to 'g.colors[v]')
- delta             ::Int                   : Variation of the number of conflicts induced by this change
"""

function random_neighbor(g::ColoredGraph, tabu_table::Matrix{Int}, iter::Int)::Tuple{Int,Int,Union{Nothing,Int}}
    # Select a random vertice
    v = rand(1:g.n)

    # Pick a random color, different from the one already assigned to v
    current_c = g.colors[v]
    new_c_idx = rand(1:(g.k-1))

    new_c = 0
    if new_c_idx < current_c
        new_c = new_c_idx
    else
        new_c = new_c_idx + 1
    end

    delta = nothing

    # Check if the change is tabu. If it is, delta is nothing.
    if !is_tabu(g, v, new_c, tabu_table, iter)
        delta = eval_delta_modif(g, v, new_c)
    end
    
    return v, new_c, delta
end


"""
    random_swap_neighbor(g::ColoredGraph, tabu_table::Matrix{Int}, iter::Int)::Tuple{Int,Int,Union{Nothing,Int},Int,Int,Union{Nothing,Int}}

Given a graph g, returns a vertice index and the color to assign to it (if non-tabu), 
as well as the number of conflicts variation induced by this change. 

# Arguments 
- g                 ::ColoredGraph          : Graph instance
- tabu_table        ::Matrix{Int}           : Tabu table
- iter              ::Int                   : Index of the current iteration

# Outputs
- v                 ::Int                   : Vertice of g
- new_c             ::Int                   : New color to assign to v (new_c is not equal to 'g.colors[v]')
- delta             ::Int                   : Variation of the number of conflicts induced by this change
"""

function random_swap_neighbor(g::ColoredGraph, tabu_table::Matrix{Int}, iter::Int)::Tuple{Int,Int,Union{Nothing,Int},Int,Int,Union{Nothing,Int}}
    # Select two random vertice index, that have distinct colors
    v1 = rand(1:g.n)

    same_color = true
    v2 = v1

    while same_color
        v2 = rand(1:g.n)
        if g.colors[v1] != g.colors[v2]
            same_color = false
        end
    end

    new_c1 = g.colors[v2]
    new_c2 = g.colors[v1]

    delta1 = nothing
    delta2 = nothing

    # Check if the change is tabu. If it is, delta is nothing.
    if !is_tabu(g, v1, new_c1, tabu_table, iter) && !is_tabu(g, v2, new_c2, tabu_table, iter)
        delta1 = eval_delta_modif(g, v1, new_c1) 
        new_g = simulate_update(g, v1, new_c1, delta1)
        delta2 = eval_delta_modif(new_g, v2, new_c2)
    end
    
    return v1, new_c1, delta1, v2, new_c2, delta2
end
