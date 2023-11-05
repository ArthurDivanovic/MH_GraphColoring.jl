function tabu_search_int(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter_function::Function, distance_threshold::Float64)
    start_time = time()

    Q = PriorityQueue{Vector{Int}, Int}()
    enqueue!(Q, g.colors, g.nb_conflict)

    T = init_tabu_table(g, tabu_iter_function)

    R = Int(floor(distance_threshold*g.n))

    while !isempty(Q)
        Cs, nb_conflict = peek(Q)
        g.colors, g.nb_conflict = deepcopy(Cs), nb_conflict
        
        i = 1
        while in_sphere(g.colors, Cs, g.k, R)
            best_v, best_c, best_delta = best_neighbor_with_tabu(g, T.tabu_table, neigh_iter, i)

            update!(g, best_v, best_c, best_delta)
            
            update_tabu_table!(g, best_delta, T, i, R)

            if g.nb_conflict < g.nb_conflict_min
                update_min!(g, start_time)
                if g.nb_conflict_min == 0
                    return
                end
            end

            i += 1
        end
        
        new_plateau = true
        for (C, nb_conflict) in Q
            if in_sphere(g.colors, C, g.k, R)
                new_plateau = false
                break
            end
        end

        if new_plateau
            enqueue!(Q, deepcopy(g.colors), g.nb_conflict)
        end

        #If a specific condition
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
end

function (heuristic::TSint)(g::ColoredGraph)
    if isnothing(heuristic.tabu_iter)
        heuristic.tabu_iter_function = dynamic_tabu_iter(heuristic.A, heuristic.alpha, heuristic.m_max)
    else
        heuristic.tabu_iter_function = constant_tabu_iter(heuristic.tabu_iter)
    end

    solving_time = @elapsed begin
        tabu_search_int(g, heuristic.nb_iter, heuristic.neigh_iter, heuristic.tabu_iter_function, heuristic.distance_threshold)
    end
    
    g.resolution_time += solving_time

    push!(g.heuristics_applied, heuristic)
end
