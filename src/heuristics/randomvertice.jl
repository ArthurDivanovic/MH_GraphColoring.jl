"""
    random_vertice_descent(g::ColoredGraph, nb_iter::Int)::Vector{Int}

    Classic neighborhood search with random vertice generated. 
    Color is attributed according to the less represented color among the adjacent vertices.

# Arguments 
- g         ::ColoredGraph  : Graph instance
 nb_iter    ::Int           : Number of iterations for the global algorithm 

# Outputs
- colors    ::Vector{Int}   : best coloration found (copied in ColoredGraph g)
"""


function random_vertice_descent(g::ColoredGraph, nb_iter::Int)::Vector{Int}
    start_time = time()
    
    
    for i = 1:nb_iter
        u = rand(1:g.n)

        neigh_colors = zeros(Int, g.k)
        for v = 1:g.n
            if g.adj[u,v] == 1
                neigh_colors[g.colors[v]] += 1
            end
        end
        c = argmin(neigh_colors)
        delta = eval_delta_modif(g, u, c)

        update!(g, u, c, delta)

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

function (heuristic::RandomVerticeDescent)(g::ColoredGraph)::Vector{Int}
    solving_time = @elapsed begin 
        colors = random_vertice_descent(g, heuristic.nb_iter)
    end
    
    g.resolution_time += solving_time
    
    push!(g.heuristics_applied, heuristic)
    return colors
end

function save_parameters(heuristic::RandomVerticeDescent, file_name::String)::Nothing
    file = open("results/$file_name", "a")

    write(file, "h RandomVerticeDescent = nb_iter:$(heuristic.nb_iter)\n")

    close(file)
end