"""
    init_temp(g::ColoredGraph, n_samples::Int, target_prob::Float64)::Float64

    Temperature initialization for simulated annealing (T0).

# Arguments 
- g             ::ColoredGraph  : Graph instance
- n_samples     ::Int           : Number of neighboors tested to estimate T0
- target_prob   ::Float64       : Probability targeted of accepting a degrading solution 

# Outputs
- T0            ::Float64   : initial temperature for simulated annealing
"""


function init_temp(g::ColoredGraph, n_samples::Int, target_prob::Float64)::Float64
    n = g.n
    k = g.k

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
    
    return -delta_mean / log(target_prob)
end

"""
    simulated_annealing(g::ColoredGraph, nb_iter::Int, T0::Float64, mu::Float64, Tmin::Float64)::Tuple{Vector{Int}, Int}

Simulated annealing algorithm on a Colored Graph with a random neighboor generation. 

# Arguments 
- g                 ::ColoredGraph  : Graph instance
- nb_iter           ::Int           : Number of iterations for the global algorithm 
- T0                ::Float64       : Initial temperature
- mu                ::Float64       : Temperature decrease factor
- Tmin              ::Float64       : Minimum temperature allowed, stop if T < Tmin

# Outputs
- best_colors       ::Vector{Int}   : best coloration found (not copied in ColoredGraph g)
- nb_conflict_min   ::Int           : Number of conflicts according to best_colors
"""

function simulated_annealing(g::ColoredGraph, nb_iter::Int, T0::Float64, mu::Float64, Tmin::Float64)::Tuple{Vector{Int}, Int}
    n = g.n
    k = g.k
    colors = g.colors
    best_colors = deepcopy(colors)
    nb_conflict = eval(g)
    nb_conflict_min = nb_conflict
    T = T0

    while T > Tmin
        for i = 1:nb_iter
            v = rand(1:n)
            c = rand(1:k)
            delta = eval_delta_modif(g, v, c)
            if delta <= 0
                colors[v] = c
                nb_conflict += delta
                if delta < 0 
                    if nb_conflict < nb_conflict_min
                        nb_conflict_min = nb_conflict
                        best_colors = deepcopy(colors)
                        if nb_conflict_min == 0
                            break
                        end
                    end
                end
            else
                if rand() < exp(-delta / T)
                    colors[v] = c
                    nb_conflict += delta
                end
            end
        end
        if nb_conflict_min == 0
            break
        end
        T *= mu
    end
    return best_colors, nb_conflict_min
end

mutable struct SimulatedAnnealing <: Heuristic
    T0          ::Union{Float64,Nothing}
    n_samples   ::Union{Int,Nothing}
    target_prob ::Union{Float64, Nothing}

    nb_iter     ::Int 
    mu          ::Float64
    Tmin        ::Float64
end

function (heuristic::SimulatedAnnealing)(g::ColoredGraph)::Vector{Int}
    if isnothing(heuristic.T0)
        heuristic.T0 = init_temp(g, heuristic.n_samples, heuristic.target_prob)
    end
    colors, nb_conflict = simulated_annealing(g, heuristic.nb_iter, heuristic.T0, heuristic.mu, heuristic.Tmin)
    push!(g.heuristics_applied, heuristic)
    return colors
end

function save_parameters(heuristic::SimulatedAnnealing,file_name::String)::Nothing
    file = open("results/$file_name", "a")

    write(file, "h SimulatedAnnealing = nb_iter:$(heuristic.nb_iter) T0:$(heuristic.T0) mu:$(heuristic.T0) Tmin:$(heuristic.Tmin)\n")

    close(file)
end