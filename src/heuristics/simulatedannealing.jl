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
                    end
                end
            else
                if rand() < exp(-delta / T)
                    colors[v] = c
                    nb_conflict += delta
                end
            end
        end
        T *= mu
    end
    return best_colors, nb_conflict_min
end