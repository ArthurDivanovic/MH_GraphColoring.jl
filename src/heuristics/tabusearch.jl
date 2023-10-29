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
function tabu_search(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter::Int)::Tuple{Vector{Int}, Int}
    n = g.n
    k = g.k
    colors = g.colors

    tabu_table = ones(Int, n, k)

    best_colors = deepcopy(colors)
    nb_conflict = eval(g)
    nb_conflict_min = nb_conflict

    for i = 1:nb_iter

        v0 = rand(1:n)
        c0 = rand(1:k)
        delta0 = eval_delta_modif(g, v0, c0)

        best_v = v0
        best_c = c0
        best_delta = delta0

        still_v0_c0 = true
        for j = 1:neigh_iter
            v = rand(1:n)
            c = rand(1:k)
            if tabu_table[v,c] < i
                delta = eval_delta_modif(g, v, c)
                tabu_table[v,c] = i + tabu_iter

                if delta <= best_delta
                    still_v0_c0 = false
                    best_v = v
                    best_c = c
                    best_delta = delta
                end
            end
        end

        if still_v0_c0 && tabu_table[v0,c0] >= i
            continue
        else
            colors[best_v] = best_c #modify g.colors by colors (object oriented)
            nb_conflict += best_delta
            if nb_conflict < nb_conflict_min
                best_colors = deepcopy(colors)
                nb_conflict_min = nb_conflict
            end
        end
    end
    return best_colors, nb_conflict_min
end


mutable struct TabuSearch <: Heuristic
    nb_iter::Int
    neigh_iter::Int
    tabu_iter::Int
end

function (heuristic::TabuSearch)(g::ColoredGraph)::Vector{Int}
    colors, nb_conflict = tabu_search(g, heuristic.nb_iter, heuristic.neigh_iter, heuristic.tabu_iter)
    push!(g.heuristics_applied, heuristic)
    return colors
end

function save_parameters(heuristic::TabuSearch, file_name::String)::Nothing
    file = open("results/$file_name", "a")

    write(file, "h TabuSearch = nb_iter:$(heuristic.nb_iter) neigh_iter:$(heuristic.neigh_iter) tabu_iter:$(heuristic.tabu_iter)\n")

    close(file)
end