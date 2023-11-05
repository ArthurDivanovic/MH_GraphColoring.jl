include("simulatedannealing.jl")


mutable struct RepeatedSimulatedAnnealing <: Heuristic
    T0          ::Union{Float64,Nothing}
    n_samples   ::Union{Int,Nothing}
    target_prob ::Union{Float64, Nothing}

    nb_iter     ::Int 
    mu          ::Float64
    Tmin        ::Float64

    nb_repeat   ::Int
end


"""
    (heuristic::RepeatedSimulatedAnnealing)(g::ColoredGraph)::Nothing

Applies the RepeatedSimulatedAnnealing heuristic object to the graph g and adds it to the list of heuristics applied.
Updates the graph g.

# Arguments 
- g                     ::ColoredGraph      : Graph instance

# Outputs
None
"""

function (heuristic::RepeatedSimulatedAnnealing)(g::ColoredGraph)
    
    initialization_time = @elapsed begin 
        if isnothing(heuristic.T0)
            heuristic.T0 = init_temp(g, heuristic.n_samples, heuristic.target_prob)
        end
    end

    g.resolution_time += initialization_time

    solving_time = @elapsed begin
        for i = 1:heuristic.nb_repeat
            simulated_annealing(g, heuristic.nb_iter, heuristic.T0, heuristic.mu, heuristic.Tmin)
        end
    end

    g.resolution_time += solving_time

    push!(g.heuristics_applied, heuristic)
end


"""
    save_parameters(heuristic::RepeatedSimulatedAnnealing, file_name::String)::Nothing

Saves the parameters of the RepeatedSimulatedAnnealing heuristic in the file called 'file_name'.

# Arguments 
- heuristic             ::RepeatedSimulatedAnnealing        : SimulatedAnnealing heuristic employed
- file_name             ::String                            : Name of the file to save results in

# Outputs
None
"""

function save_parameters(heuristic::SimulatedAnnealing,file_name::String)
    file = open("results/$file_name", "a")

    write(file, "h RepeatedSimulatedAnnealing = nb_iter:$(heuristic.nb_iter) T0:$(heuristic.T0) mu:$(heuristic.T0) Tmin:$(heuristic.Tmin) nb_repeat:$(heuristic.nb_repeat)\n")

    close(file)
end
