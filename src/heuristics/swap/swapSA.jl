"""
    simulated_swap_annealing(g::ColoredGraph, nb_iter::Int, T0::Float64, mu::Float64, Tmin::Float64)::Tuple{Vector{Int}, Int}

Simulated annealing algorithm on a ColoredGraph with a random neighbour generation (using the swap operator). 

# Arguments 
- g                 ::ColoredGraph      : Graph instance
- nb_iter           ::Int               : Number of iterations at each temperature level
- T0                ::Float64           : Initial temperature
- mu                ::Float64           : Temperature update factor
- Tmin              ::Float64           : Minimum temperature allowed. The algorithm stops if T < Tmin

# Outputs
None
"""

function swap_simulated_annealing(g::ColoredGraph, nb_iter::Int, T0::Float64, mu::Float64, Tmin::Float64)
    start_time = time()
    
    T = T0

    while T > Tmin

        # A temperature level is fixed, exploration of new solutions generated randomly.
        for i = 1:nb_iter

            v1, c1, v2, c2, delta = random_swap_neighbor(g)

            # If a solution is not degrading, accept it 
            if delta <= 0

                update!(g, v1, c1, delta)
                update!(g, v2, c2, 0)

                # If the number of conflicts strictly decreases, update the best solution found so far
                if delta < 0 
                    if g.nb_conflict < g.nb_conflict_min
                        update_min!(g, start_time)
                        if g.nb_conflict_min == 0
                            break
                        end
                    end
                end
            
            # If a solution is degrading, accept it with a probability exp(-delta/T)
            else
                if rand() < exp(-delta / T)
                    update!(g, v1, c1, delta)
                    update!(g, v2, c2, 0)
                end
            end
        end

        # Stop the algorithm if the coloration obtained has zero conflicts
        if g.nb_conflict_min == 0
            break
        end

        # Update the temperature 
        T *= mu
    end
end


mutable struct SwapSimulatedAnnealing <: Heuristic
    T0          ::Union{Float64,Nothing}
    n_samples   ::Union{Int,Nothing}
    target_prob ::Union{Float64, Nothing}

    nb_iter     ::Int 
    mu          ::Float64
    Tmin        ::Float64
end


"""
    (heuristic::SimulatedAnnealing)(g::ColoredGraph)::Nothing

Applies the SimulatedAnnealing heuristic object to the graph g and adds it to the list of heuristics applied.
Updates the graph g.

# Arguments 
- g                     ::ColoredGraph      : Graph instance

# Outputs
None
"""

function (heuristic::SwapSimulatedAnnealing)(g::ColoredGraph)
    
    initialization_time = @elapsed begin 
        if isnothing(heuristic.T0)
            heuristic.T0 = init_temp(g, heuristic.n_samples, heuristic.target_prob)
        end
    end

    g.resolution_time += initialization_time

    solving_time = @elapsed begin
        swap_simulated_annealing(g, heuristic.nb_iter, heuristic.T0, heuristic.mu, heuristic.Tmin)
    end

    g.resolution_time += solving_time

    push!(g.heuristics_applied, heuristic)
end

"""
    save_parameters(heuristic::SwapSimulatedAnnealing, file_name::String)::Nothing

Saves the parameters of the SwapSimulatedAnnealing heuristic in the file called 'file_name'.

# Arguments 
- heuristic             ::SimulatedAnnealing        : SimulatedAnnealing heuristic employed
- file_name             ::String                    : Name of the file to save results in

# Outputs
None
"""

function save_parameters(heuristic::SwapSimulatedAnnealing,file_name::String)
    file = open("results/$file_name", "a")

    write(file, "h SwapSimulatedAnnealing = nb_iter:$(heuristic.nb_iter) T0:$(heuristic.T0) mu:$(heuristic.T0) Tmin:$(heuristic.Tmin)\n")

    close(file)
end