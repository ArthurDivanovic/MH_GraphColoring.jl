"""
    tabu_search(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter::Int)::Tuple{Vector{Int}, Int}

Tabu search over a Colored Graph with a random neighboor generation. 

# Arguments 
- g                     ::ColoredGraph  : Graph instance
- nb_iter               ::Int           : Number of iterations for the global algorithm 
- neigh_iter            ::Int           : Number of neighboors generated at each iteration
- tabu_iter             ::Int           : Number of iterations forbidden for a neighboor (v,c) visited
- distance_threshold    ::Float64       : Diversification if distance(g.colors, plateau) <= distance_threshold*|V| 

"""
function tabu_search(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter::Int, distance_threshold::Float64)
    start_time = time()

    tabu_table = ones(Int, g.n, g.k)

    plateau = Dict{Int, Vector{Vector{Int}}}()
    distance_plateau =  Dict{Int, Vector{Int}}()
    # iter_plateau = Dict{Int, Vector{Int}}()
    # iter_diversification = Vector{Int}()
    # println("first_update : ", length(g.conflict_history) + 1)

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

            if best_delta >= 0
                if haskey(plateau, g.nb_conflict)
                    # push!(distance_plateau[g.nb_conflict], get_distance(plateau[g.nb_conflict], g.colors, g.k))
                    # push!(iter_plateau[g.nb_conflict], i)

                    dist = minimum([get_distance(plateau[g.nb_conflict][i], g.colors, g.k) for i = 1:length(plateau[g.nb_conflict])])
                    
                    if dist < Int(floor(distance_threshold*g.n))
                        color_diversification(g, distance_threshold)
                        # push!(iter_diversification, length(g.conflict_history))
                    else
                        push!(plateau[g.nb_conflict], deepcopy(g.colors)) # nouveau plateau identifié
                    end
                else
                    plateau[g.nb_conflict] = Vector{Int}()
                    push!(plateau[g.nb_conflict], deepcopy(g.colors))
                    distance_plateau[g.nb_conflict] = Vector{Int}()
                    # iter_plateau[g.nb_conflict] = Int[i]
                end
            end
        end

        
    end
    # println("plateaux : ", keys(plateau))
    # println("distance_plateau : ", distance_plateau)
    # println("iter_plateau : ", iter_plateau)
    # println("iter_diversification : ", iter_diversification)
end


mutable struct TabuSearch <: Heuristic
    nb_iter             ::Int
    neigh_iter          ::Int
    tabu_iter           ::Int
    distance_threshold  ::Float64
end

function (heuristic::TabuSearch)(g::ColoredGraph)
    solving_time = @elapsed begin
        tabu_search(g, heuristic.nb_iter, heuristic.neigh_iter, heuristic.tabu_iter, heuristic.distance_threshold)
    end
    
    g.resolution_time += solving_time

    push!(g.heuristics_applied, heuristic)
end

function save_parameters(heuristic::TabuSearch, file_name::String)
    file = open("results/$file_name", "a")

    write(file, "h TabuSearch = nb_iter:$(heuristic.nb_iter) neigh_iter:$(heuristic.neigh_iter) tabu_iter:$(heuristic.tabu_iter)\n")

    close(file)
end


function color_diversification(g::ColoredGraph, distance_threshold::Float64)
    nb_iter = Int(floor(distance_threshold*g.n))

    for i = 1:nb_iter
        v, c, delta = random_neighbor(g)
        update!(g, v, c, delta)
    end
end