"""
    random_vertice_descent(g::ColoredGraph, nb_iter::Int)::Vector{Int}

Classic neighborhood search with random colors generated. 
A color is attributed according to the less represented color among the adjacent vertices.

# Arguments 
- g             ::ColoredGraph      : Graph instance
- nb_iter       ::Int               : Number of iterations for the global algorithm 

# Outputs
- colors        ::Vector{Int}       : best coloration found (copied in ColoredGraph g)
"""

function random_vertice_descent(g::ColoredGraph, nb_iter::Int)::Vector{Int}
    start_time = time()
    
    for i = 1:nb_iter
        u = rand(1:g.n)

        # Compute the number of neighbours of u assigned to each color 
        neigh_colors = zeros(Int, g.k)
        for v = 1:g.n
            if g.adj[u,v] == 1
                neigh_colors[g.colors[v]] += 1
            end
        end

        # Pick the less represented color (ideally, we can have zero neighbours in that color)
        c = argmin(neigh_colors)

        # Evaluate the variation of number of conflicts induced
        delta = eval_delta_modif(g, u, c)

        # Update the graph g
        update!(g, u, c, delta)

        # If the number of conflicts is strictly disminuished, update the best coloration found so far
        if delta < 0
            update_min!(g, start_time, false)
        end
        
    end
    
    update_min!(g, start_time)
    return g.colors
end


struct RandomVerticeDescent <: Heuristic 
    nb_iter ::Int
end


"""
    (heuristic::RandomVerticeDescent)(g::ColoredGraph)::Vector{Int}

Applies the RandomVerticeDescent heuristic object to the graph g and adds it to the list of heuristics applied.
Returns the colors of the vertices of the graph g.

# Arguments 
- g                     ::ColoredGraph      : Graph instance

# Outputs
- colors                ::Vector{Int}       : Coloration obtained
"""

function (heuristic::RandomVerticeDescent)(g::ColoredGraph)::Vector{Int}
    solving_time = @elapsed begin 
        colors = random_vertice_descent(g, heuristic.nb_iter)
    end
    
    g.resolution_time += solving_time
    
    push!(g.heuristics_applied, heuristic)
    return colors
end


"""
    save_parameters(heuristic::RandomVerticeDescent, file_name::String)::Nothing

Saves the parameters of the RandomVerticeDescent heuristic in the file called 'file_name'.

# Arguments 
- heuristic             ::RandomVerticeDescent      : RandomVerticeDescent heuristic employed
- file_name             ::String                    : Name of the file to save results in

# Outputs
None
"""

function save_parameters(heuristic::RandomVerticeDescent, file_name::String)::Nothing
    file = open("results/$file_name", "a")

    write(file, "h RandomVerticeDescent = nb_iter:$(heuristic.nb_iter)\n")

    close(file)
end