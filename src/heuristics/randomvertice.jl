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
    colors = g.colors
    adj = g.adj
    n = g.n
    k = g.k
    
    for i = 1:nb_iter
        u = rand(1:n)

        neigh_colors = zeros(Int, k)
        for v = 1:n
            if adj[u,v] == 1
                neigh_colors[colors[v]] += 1
            end
        end

        colors[u] = argmin(neigh_colors)
    end
    return g.colors
end

struct RandomVerticeDescent <: Heuristic 
    nb_iter ::Int
end

function (heuristic::RandomVerticeDescent)(g::ColoredGraph)::Vector{Int}
    colors = random_vertice_descent(g, heuristic.nb_iter)
    push!(g.heuristics_applied, heuristic)
    return colors
end

function save_parameters(heuristic::RandomVerticeDescent, file_name::String)::Nothing
    file = open("results/$file_name", "a")

    write(file, "h RandomVerticeDescent = nb_iter:$(heuristic.nb_iter)\n")

    close(file)
end