"""
    tabu_search(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter::Int)::Tuple{Vector{Int}, Int}

Tabu search over a Colored Graph with a random neighboor generation. 

# Arguments 
- g                 ::ColoredGraph  : Graph instance
- nb_iter           ::Int           : Number of iterations for the global algorithm 
- neigh_iter        ::Int           : Number of neighboors generated at each iteration
- tabu_iter         ::Int           : Number of iterations forbidden for a neighboor (v,c) visited

# Outputs
- best_colors       ::Vector{Int}   : best coloration found (not copied in ColoredGraph g)
- nb_conflict_min   ::Int           : Number of conflicts according to best_colors
"""
function tabu_search(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter::Int)
    start_time = time()

    tabu_table = ones(Int, g.n, g.k)

    for i = 1:nb_iter

        v0, c0, delta0 = random_neighbor(g)

        best_v, best_c, best_delta = v0, c0, delta0

        still_v0_c0 = true
        for j = 1:neigh_iter
            v, c, delta = random_neighbor_with_tabu!(g, tabu_table, tabu_iter, i)
            
            if !isnothing(delta) && delta <= best_delta
                still_v0_c0 = false
                best_v, best_c, best_delta = v, c, delta
            end
        end

        if still_v0_c0 && tabu_table[v0,c0] >= i
            continue
        else
            update!(g, best_v, best_c, best_delta)
            if g.nb_conflict < g.nb_conflict_min
                update_min!(g, start_time)
                if g.nb_conflict_min == 0
                    break
                end
            end
        end
    end
end


mutable struct TabuSearch <: Heuristic
    nb_iter::Int
    neigh_iter::Int
    tabu_iter::Int
end

function (heuristic::TabuSearch)(g::ColoredGraph)
    solving_time = @elapsed begin
        tabu_search(g, heuristic.nb_iter, heuristic.neigh_iter, heuristic.tabu_iter)
    end
    
    g.resolution_time += solving_time

    push!(g.heuristics_applied, heuristic)
end

function save_parameters(heuristic::TabuSearch, file_name::String)
    file = open("results/$file_name", "a")

    write(file, "h TabuSearch = nb_iter:$(heuristic.nb_iter) neigh_iter:$(heuristic.neigh_iter) tabu_iter:$(heuristic.tabu_iter)\n")

    close(file)
end