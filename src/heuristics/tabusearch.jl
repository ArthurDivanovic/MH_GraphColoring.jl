mutable struct TabuSearch <: Heuristic
    nb_iter             ::Int
    neigh_iter          ::Int
    distance_threshold  ::Float64

    tabu_iter           ::Union{Int, Nothing}
    A                   ::Union{Int, Nothing}
    alpha               ::Union{Float64, Nothing}
    m_max               ::Union{Int, Nothing}
    tabu_iter_function  ::Union{Function, Nothing}
end

"""
    tabu_search(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter::Int)::Tuple{Vector{Int}, Int}

Tabu search over a Colored Graph with a random neighboor generation. 

# Arguments 
- g                     ::ColoredGraph  : Graph instance
- nb_iter               ::Int           : Number of iterations for the global algorithm 
- neigh_iter            ::Int           : Number of neighboors generated at each iteration
- tabu_iter             ::Int           : Number of iterations forbidden for a neighboor (v,c) visited
- R                     ::Float64       : Diversification if distance(g.colors, plateau) <= R 

"""

function tabu_search(g::ColoredGraph, nb_iter::Int, neigh_iter::Int, tabu_iter_function::Function, R::Int)
    start_time = time()

    T = init_tabu_table(g, tabu_iter_function)

    @showprogress dt=1 desc="Computing..." for i in 1:nb_iter

        best_v, best_c, best_delta = best_neighbor_with_tabu(g, T.tabu_table, neigh_iter, i)

        update!(g, best_v, best_c, best_delta)

        update_tabu_table!(g, best_delta, T, i, R)

        if g.nb_conflict < g.nb_conflict_min
            update_min!(g, start_time)
            if g.nb_conflict_min == 0
                break
            end
        end
    end
end


function best_neighbor_with_tabu(g::ColoredGraph, tabu_table::Matrix{Int}, neigh_iter::Int, iter::Int)::Tuple{Int, Int, Int}
    #initialize a random neighbor
    v0, c0, delta0 = nothing, nothing, nothing
    while isnothing(delta0)
        v0, c0, delta0 = random_neighbor(g, tabu_table, iter)
    end

    best_v, best_c, best_delta = v0, c0, delta0

    for j = 1:neigh_iter
        #Get a new neighbor according to the tabu table
        v, c, delta = random_neighbor(g, tabu_table, iter)
        
        #If this neighbor is not forbidden and is the best one so far : change best neighbor
        if !isnothing(delta) && delta <= best_delta
            best_v, best_c, best_delta = v, c, delta
        end
    end

    return best_v, best_c, best_delta
end


function (heuristic::TabuSearch)(g::ColoredGraph)
    if isnothing(heuristic.tabu_iter)
        heuristic.tabu_iter_function = dynamic_tabu_iter_function(heuristic.A, heuristic.alpha, heuristic.m_max)
    else
        heuristic.tabu_iter_function = constant_tabu_iter_function(heuristic.tabu_iter)
    end

    solving_time = @elapsed begin
        R = Int(floor(distance_threshold*g.n))
        tabu_search(g, heuristic.nb_iter, heuristic.neigh_iter, heuristic.tabu_iter_function, R)
    end
    
    g.resolution_time += solving_time

    push!(g.heuristics_applied, heuristic)
end


function save_parameters(heuristic::TabuSearch, file_name::String)
    file = open("results/$file_name", "a")

    write(file, "h TabuSearch = nb_iter:$(heuristic.nb_iter) neigh_iter:$(heuristic.neigh_iter) tabu_iter:$(heuristic.tabu_iter) A:$(heuristic.A) alpha:$(heuristic.alpha) m_max:$(heuristic.m_max)\n")

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
    dynamic_tabu_iter(A::Int=10, alpha::Float64=0.6, m_max::Int=1000)::Function

Returns the function that allows to dynamically adjust tabu_iter during the tabu search heuristic

# Arguments 
- A                     ::Int                   : Parameter A of the heuristic
- alpha                 ::Float64               : Parameter alpha of the heuristic
- m_max                 ::Int                   : Parameter m_max of the heuristic

# Outputs
- f                     ::Function              :function that can be called during the execution of the heuristic to compute tabu_iter
"""


function dynamic_tabu_iter_function(A::Int=10, alpha::Float64=0.6, m_max::Int=1000)::Function
    function f(g::ColoredGraph, m::Int)
        return A + alpha * g.nb_conflict + Int(floor(m / m_max))
    end
    return f
end


"""
    constant_tabu_iter(cst::Int)::Function

Returns the function that allows to fix tabu_iter to a constant for all the duration of the tabu search heuristic

# Arguments 
- cst                   ::Int                  : Contant chosen by the user for tabu_iter

# Outputs
- f                     ::Function              :function that can be called during the execution of the heuristic to compute tabu_iter
"""


function constant_tabu_iter_function(cst::Int)::Function
    function f(g::ColoredGraph, m::Int)
        return cst
    end
    return f
end