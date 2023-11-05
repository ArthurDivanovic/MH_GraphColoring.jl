include("coloredgraph.jl")


"""
    eval(g::ColoredGraph)::Int  

Evaluates the number of conflicts in a colored graph g.

# Arguments 
- g                  ::ColoredGraph      : Graph 

# Outputs 
- nb_conflict        ::Int               : Number of conflicts iduced by the coloration of g
"""

function eval(g::ColoredGraph)::Int
    adj = g.adj
    n = g.n
    colors = g.colors

    nb_conflict = 0

    for u in 1:n
        for v = u+1:n # Avoid counting two times the same conflicts
            if adj[u,v] == 1 && colors[u] == colors[v]
                nb_conflict += 1
            end
        end
    end

    return nb_conflict
end


"""
    get_edge_conflicts(g::ColoredGraph)::Vector{Tuple{Int, Int}}  

Returns a vector of edges involved in a coloration conflict.

# Arguments 
- g                  ::ColoredGraph                     : Graph 

# Outputs 
- conflicts          ::Vector{Tuple{Int, Int}}          :Vector of conflictual edges
"""

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


"""
    eval_vertice(g::ColoredGraph, v::Int)::Int

Evaluates the number of conflicts induced by the color of the vertice v in the ColoredGraph g.

# Arguments 
- g                  ::ColoredGraph         : Graph 
- v                  ::Int                  : Index of the vertice under scrutiny

# Outputs 
- nb_conflicts       ::Int                  : Number of conflicts induced by the coloration of v
"""

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


"""
    eval_all_vertices(g::ColoredGraph)::Vector{Int}

Returns the vector of the number of conflicts induced by the color of the vertice v in the ColoredGraph g, 
for all v.

# Arguments 
- g                  ::ColoredGraph         : Graph 

# Outputs 
- conflicts          ::Vector{Int}          : Vector of the number of conflicts induced by each vertice
"""

function eval_all_vertices(g::ColoredGraph)::Vector{Int}
    conflicts = Vector{Int}

    adj = g.adj
    
    for u = 1:g.n
        push!(conflicts, eval_vertice(g, u))
    end

    return conflicts
end


"""
    eval_delta_modif(g::ColoredGraph, v::Int, c::Int)::Int

Evaluates the variation of number of conflicts induced by changing the color of the vertice v to c.

# Arguments 
- g                  ::ColoredGraph         : Graph 
- v                  ::Int                  : Index of the vertice under scrutiny
- c                  ::Int                  : Color to assign to v

# Outputs 
- delta              ::Int                  : Variation of number of conflicts induced by the change
"""

function eval_delta_modif(g::ColoredGraph, v::Int, c::Int)::Int
    conflicts = Vector{Int}
    colors = g.colors
    adj = g.adj

    old_vertice_eval = eval_vertice(g, v)
    
    new_vertice_eval = 0
    for u = 1:g.n
        if adj[u,v] == 1 && c == colors[u]
            new_vertice_eval += 1
        end   
    end

    delta = new_vertice_eval - old_vertice_eval

    return delta
end


"""
    eval_delta_swap_modif(g::ColoredGraph, v1::Int, v2::Int)::Int

Evaluates the variation of number of conflicts induced by changing the color of the vertice v to c.

# Arguments 
- g                   ::ColoredGraph         : Graph 
- v1                  ::Int                  : Index of the first vertice to swap
- v2                  ::Int                  : Index of the second vertice to swap

# Outputs 
- delta               ::Int                  : Variation of number of conflicts induced by the swap
"""

function eval_delta_swap_modif(g::ColoredGraph, v1::Int, v2::Int)::Int

    sum_of_deltas = eval_delta_modif(g, v1, g.colors[v2]) + eval_delta_modif(g, v2, g.colors[v1])

    if g.adj[v1,v2] == 0
        return sum_of_deltas
    end

    return sum_of_deltas - 1
end
