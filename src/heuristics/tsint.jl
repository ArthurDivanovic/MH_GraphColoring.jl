include("tabusearch.jl")


"""
    tabu_search_int(g::ColoredGraph, neigh_iter::Int, tabu_iter_function::Function, distance_threshold::Float64)::Nothing

TS-int algorithm applied to a ColoredGraph object. 

# Arguments 
- g                         ::ColoredGraph      : Graph instance
- neigh_iter                ::Int               : Number of neighboors generated at each iteration
- tabu_iter_function        ::Function          : Function to determine the duration of a tabu 
- distance_threshold        ::Float64           : Distance threshold (used as a percentage of the number of vertices)

# Outputs
None
"""

function tabu_search_int(g::ColoredGraph, neigh_iter::Int, tabu_iter_function::Function, distance_threshold::Float64, stopping_criterion::Int)
    start_time = time()

    visited = 0

    # Intialize a priority queue of colorations
    Q = PriorityQueue{Vector{Int}, Int}()
    enqueue!(Q, g.colors, g.nb_conflict)

    # Initialize tabu table
    T = init_tabu_table(g, tabu_iter_function)

    # Initialize radius of the spheres
    R = Int(floor(distance_threshold*g.n))

    while !isempty(Q) && visited < stopping_criterion
        # Take the first element in the queue, with highest priority
        Cs, nb_conflict = peek(Q)
        g.colors, g.nb_conflict = deepcopy(Cs), nb_conflict
        
        i = 1
        
        while in_sphere(g.colors, Cs, g.k, R)
            # Start a tabu search from Cs
            best_v, best_c, best_delta = best_neighbor_with_tabu(g, T.tabu_table, neigh_iter, i)

            # Update graph 
            update!(g, best_v, best_c, best_delta)
            
            # Update tabu table
            update_tabu_table!(g, best_delta, T, i, R)

            # Update best solution if necessary
            if g.nb_conflict < g.nb_conflict_min
                update_min!(g, start_time)
                if g.nb_conflict_min == 0
                    return
                end
            end

            i += 1
        end
        visited += 1
        
        # Did we find a new coloration outside of the plateaus that have already been identified?
        new_plateau = true
        for (C, nb_conflict) in Q
            if in_sphere(g.colors, C, g.k, R)
                new_plateau = false
                break
            end
        end

        # If a new plateau has been discovered, add the current coloration to Q
        if new_plateau
            enqueue!(Q, deepcopy(g.colors), g.nb_conflict)
        end

        # Pop Q
        dequeue!(Q)
    end

end


mutable struct TSint <: Heuristic
    nb_iter             ::Int
    neigh_iter          ::Int
    distance_threshold  ::Float64

    tabu_iter           ::Union{Int, Nothing}
    A                   ::Union{Int, Nothing}
    alpha               ::Union{Float64, Nothing}
    m_max               ::Union{Int, Nothing}
    tabu_iter_function  ::Union{Function, Nothing}

    stopping_criterion  ::Int
end


"""
    (heuristic::TSint)(g::ColoredGraph)::Nothing

Applies the TSint heuristic object to the graph g and adds it to the list of heuristics applied.
Updates the graph g.

# Arguments 
- g                     ::ColoredGraph      : Graph instance

# Outputs
None
"""

function (heuristic::TSint)(g::ColoredGraph)
    if isnothing(heuristic.tabu_iter)
        heuristic.tabu_iter_function = dynamic_tabu_iter_function(heuristic.A, heuristic.alpha, heuristic.m_max)
    else
        heuristic.tabu_iter_function = constant_tabu_iter_function(heuristic.tabu_iter)
    end

    solving_time = @elapsed begin
        tabu_search_int(g, heuristic.neigh_iter, heuristic.tabu_iter_function, heuristic.distance_threshold, heuristic.stopping_criterion)
    end
    
    g.resolution_time += solving_time

    push!(g.heuristics_applied, heuristic)
end


"""
    save_parameters(heuristic::TSint, file_name::String)

Saves the parameters of the TSint heuristic in the file called 'file_name'

# Arguments 
- heuristic             ::TSint             : TSint heuristic employed
- file_name             ::String            : Name of the file to save results in

# Outputs
None
"""

function save_parameters(heuristic::TSint, file_name::String)
    file = open("results/$file_name", "a")

    write(file, "h TSint = nb_iter:$(heuristic.nb_iter) neigh_iter:$(heuristic.neigh_iter) tabu_iter:$(heuristic.tabu_iter) A:$(heuristic.A) alpha:$(heuristic.alpha) m_max:$(heuristic.m_max) criterion:$(heuristic.stopping_criterion)\n")

    close(file)
end
