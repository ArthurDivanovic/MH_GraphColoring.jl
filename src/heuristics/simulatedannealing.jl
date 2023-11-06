"""
    init_temp(g::ColoredGraph, n_samples::Int, target_prob::Float64)::Float64

Temperature initialization for simulated annealing (T0). T0 is computed so that an initial rate of 
acceptance (target_prob) of degrading solutions is reached.

# Arguments 
- g                 ::ColoredGraph      : Graph instance
- n_samples         ::Int               : Number of neighboors tested to estimate T0
- target_prob       ::Float64           : Target probability of accepting a degrading solution 

# Outputs
- T0                ::Float64           : Initial temperature for the simulated annealing heuristic
"""

function init_temp(g::ColoredGraph, n_samples::Int, target_prob::Float64)::Float64
    n = g.n
    k = g.k

    # Estimate the proportion of degrading solutions
    delta_mean = 0
    degrade_count = 0
    for i = 1:n_samples
        v = rand(1:n)
        c = rand(1:k)
        delta = eval_delta_modif(g, v, c)

        if delta > 0
            delta_mean += delta
            degrade_count += 1
        end
    end
    delta_mean /= degrade_count 
    
    # Compute T0 so that the proportion of these accepted degrading solutions is higher than target_prob
    return -delta_mean / log(target_prob)
end


"""
    simulated_annealing(g::ColoredGraph, nb_iter::Int, T0::Float64, mu::Float64, Tmin::Float64)

Simulated annealing algorithm on a ColoredGraph with a random neighbour generation. 

# Arguments 
- g                 ::ColoredGraph      : Graph instance
- nb_iter           ::Int               : Number of iterations at each temperature level
- T0                ::Float64           : Initial temperature
- mu                ::Float64           : Temperature update factor
- Tmin              ::Float64           : Minimum temperature allowed. The algorithm stops if T < Tmin

# Outputs
None
"""

function simulated_annealing(g::ColoredGraph, nb_iter::Int, T0::Float64, mu::Float64, Tmin::Float64)
    start_time = time()
    
    T = T0

    while T > Tmin

        # A temperature level is fixed, exploration of new solutions generated randomly.
        for i = 1:nb_iter

            v, c, delta = random_neighbor(g)

            # If a solution is not degrading, accept it 
            if delta <= 0

                update!(g, v, c, delta)

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
                    update!(g, v, c, delta)
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



mutable struct SimulatedAnnealing <: Heuristic
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

function (heuristic::SimulatedAnnealing)(g::ColoredGraph)
    
    initialization_time = @elapsed begin 
        if isnothing(heuristic.T0)
            heuristic.T0 = init_temp(g, heuristic.n_samples, heuristic.target_prob)
        end
    end

    g.resolution_time += initialization_time

    solving_time = @elapsed begin
        simulated_annealing(g, heuristic.nb_iter, heuristic.T0, heuristic.mu, heuristic.Tmin)
    end

    g.resolution_time += solving_time

    push!(g.heuristics_applied, heuristic)
end


"""
    save_parameters(heuristic::SimulatedAnnealing, file_name::String)::Nothing

Saves the parameters of the SimulatedAnnealing heuristic in the file called 'file_name'.

# Arguments 
- heuristic             ::SimulatedAnnealing        : SimulatedAnnealing heuristic employed
- file_name             ::String                    : Name of the file to save results in

# Outputs
None
"""

function save_parameters(heuristic::SimulatedAnnealing,file_name::String)
    file = open("results/$file_name", "a")

    write(file, "h SimulatedAnnealing = nb_iter:$(heuristic.nb_iter) T0:$(heuristic.T0) mu:$(heuristic.T0) Tmin:$(heuristic.Tmin)\n")

    close(file)
end