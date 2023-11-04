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

    # plateau = Dict{Int, Vector{Vector{Int}}}()

    colors_pivot = deepcopy(g.colors)
    nb_conflict_pivot = g.nb_conflict
    colors_recorded = Vector{Vector{Int}}()
    Tc = 0

    R = Int(floor(distance_threshold*g.n))

    @showprogress dt=1 desc="Computing..." for i in 1:nb_iter

        #initialize a random neighbor
        v0, c0, delta0 = nothing, nothing, nothing
        while isnothing(delta0)
            v0, c0, delta0 = random_neighbor(g, tabu_table, i)
        end

        best_v, best_c, best_delta = v0, c0, delta0

        for j = 1:neigh_iter
            #Get a new neighbor according to the tabu table
            v, c, delta = random_neighbor(g, tabu_table, i)
            
            #If this neighbor is not forbidden and is the best one so far : change best neighbor
            if !isnothing(delta) && delta <= best_delta
                best_v, best_c, best_delta = v, c, delta
            end
        end

        update!(g, best_v, best_c, best_delta)

        if !in_sphere(g.colors, colors_pivot, g.k, R)
            colors_pivot = deepcopy(g.colors)
            nb_conflict_pivot = g.nb_conflict

            if already_visited(colors_pivot, colors_recorded, g.k, R)
                Tc += 1
            else
                Tc = 0
                push!(colors_recorded, colors_pivot)
            end
                
        end
        
        new_tabu_iter = tabu_iter + Tc
        update_tabu_table!(g, tabu_table, i, new_tabu_iter)

        if g.nb_conflict < g.nb_conflict_min
            update_min!(g, start_time)
            if g.nb_conflict_min == 0
                break
            end
        end

        if g.nb_conflict < nb_conflict_pivot
            colors_pivot = deepcopy(g.colors)
            nb_conflict_pivot = g.nb_conflict
        end

        # If the new coloration is not improving g.nb_conflict 
        # if best_delta >= 0
        #     if haskey(plateau, g.nb_conflict)
        
        #         dist = minimum([get_distance(plateau[g.nb_conflict][i], g.colors, g.k) for i = 1:length(plateau[g.nb_conflict])])
                
        #         if dist < Int(floor(distance_threshold*g.n))
        #             color_diversification(g, distance_threshold)
        #         else
        #             push!(plateau[g.nb_conflict], deepcopy(g.colors)) # new plateau identified
        #         end
        #     else
        #         plateau[g.nb_conflict] = Vector{Int}()
        #         push!(plateau[g.nb_conflict], deepcopy(g.colors))
        #     end
        # end
    end
    # println("plateaux : ", keys(plateau))
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
    nb_iter = Int(floor(distance_threshold*g.n))

    for i = 1:nb_iter
        v, c, delta = random_neighbor(g)
        update!(g, v, c, delta)
    end
end

"""
    already_visited(colors_pivot::Vector{Int}, colors_recorded::Vector{Vector{Int}}, k::Int, R::Int)::Bool

Returns true if the current coloration is R-close to a previously recorded coloration, and false otherwise.

# Arguments 
- colors_pivot          ::vector{Int}           : current coloration
- colors_recorded       ::Vector{Vector{Int}}   : vector of all the previously recorded colorations

# Outputs
Boolean
"""
function already_visited(colors_pivot::Vector{Int}, colors_recorded::Vector{Vector{Int}}, k::Int, R::Int)::Bool

    for colors in colors_recorded
        if in_sphere(colors, colors_pivot, k, R)
            return true
        end
    end
    return false
end

function update_tabu_table!(g::ColoredGraph, tabu_table::Matrix{Int}, tabu_iter::Int, iter::Int)
    for i = 1:g.n
        tabu_table[i,g.colors[i]] =  iter + tabu_iter
    end
end