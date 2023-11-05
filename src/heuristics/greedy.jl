"""
    greedy_coloring(adj::Matrix{Int}, k::Int, colors::Vector{Int})::Vector{Int}

Greedy heuristic that iterates over the vertices and chooses the first available color. 
If no color is available, a random one is picked.

# Arguments 
- g         ::ColoredGraph  : Graph instance

# Outputs
- colors    ::Vector{Int}   : Updated color table
"""

function greedy_coloring(g::ColoredGraph)::Vector{Int}
    adj = g.adj
    colors = g.colors
    k = g.k
    n = g.n

    for u in 1:n

        # Find all the color availables for u, by considering the color of its neighbours
        c_available = trues(k)
        for v = 1:n
            if adj[u,v] == 1
                c_available[colors[v]] = false
            end
        end
        
        # Assign the first available color to u. If no color is available, choose a random one
        new_c = findfirst(c_available)
        if isnothing(new_c)
            colors[u] = rand(1:k)
        else
            colors[u] = new_c
        end
    end
    return colors
end


struct GreedyColoring <: Heuristic end


"""
    (heuristic::GreedyColoring)(g::ColoredGraph)::Vector{Int}

Applies the GreedyColoring heuristic object to the graph g and adds it to the list of heuristics applied.
Returns the colors of the vertices of the graph g.

# Arguments 
- g                     ::ColoredGraph      : Graph instance

# Outputs
- colors                ::Vector{Int}       : Coloration obtained
"""

function (heuristic::GreedyColoring)(g::ColoredGraph)::Vector{Int}
    solving_time = @elapsed begin 
        colors = greedy_coloring(g)
    end
    
    g.resolution_time += solving_time
    
    push!(g.heuristics_applied, heuristic)
    return colors
end


"""
    save_parameters(heuristic::GreedyColoring, file_name::String)::Nothing

Saves the parameters of the GreedyColoring heuristic in the file called 'file_name'

# Arguments 
- heuristic             ::GreedyColoring        : GreedyColoring heuristic employed
- file_name             ::String                : Name of the file to save results in

# Outputs
None
"""

function save_parameters(heuristic::GreedyColoring, file_name::String)::Nothing
    file = open("results/$file_name", "a")

    write(file, "h GreedyColoring\n")

    close(file)
end


"""
    greedy_proportion(adj::Matrix{Int}, k::Int, colors::Vector{Int})::Vector{Int}

Greedy heuristic that iterates over the vertices and chooses the available color that is used by a minimimum number of vertices. 
If no color is available, a random one is picked.

# Arguments 
- g         ::ColoredGraph      : Graph instance

# Outputs
- colors    ::Vector{Int}       : updated color table
"""
function greedy_proportion(g::ColoredGraph)::Vector{Int}
    adj = g.adj
    colors = g.colors
    k = g.k
    n = g.n
    
    indices = collect(1:k)
    
    # Compute the proportion  of each color in the graph
    props = zeros(k)
    for u = 1:n
        props[colors[u]] += 1
    end

    for u = 1:n
        old_c = colors[u]

        # Find all the available colors for the vertice u, depending on the colors of its neighbours
        c_available = trues(k)
        for v = 1:n
            if adj[u,v] == 1
                c_available[colors[v]] = false
            end
        end
        
        new_c = 1
        # If a color is available, pick the one with the smallest proportion in the graph
        if any(c_available)
            idx = argmin(props[c_available])
            new_c = indices[c_available][idx]
        # If no color is available, pick a random one
        else
            new_c = rand(1:k)
        end

        colors[u] = new_c
        props[new_c] += 1
        props[old_c] -= 1
    end
    
    return colors
end


struct GreedyProportion <: Heuristic end


"""
    (heuristic::GreedyProportion)(g::ColoredGraph)::Vector{Int}

Applies the GreedyProportion heuristic object to the graph g and adds it to the list of heuristics applied.
Returns the colors of the vertices of the graph g.

# Arguments 
- g                     ::ColoredGraph      : Graph instance

# Outputs
- colors                ::Vector{Int}       : Coloration obtained
"""

function (heuristic::GreedyProportion)(g::ColoredGraph)::Vector{Int}
    solving_time = @elapsed begin 
        colors = greedy_proportion(g)
    end

    g.resolution_time += solving_time

    push!(g.heuristics_applied, heuristic)
    return colors
end


"""
    save_parameters(heuristic::GreedyProportion, file_name::String)::Nothing

Saves the parameters of the GreedyProportion heuristic in the file called 'file_name'.

# Arguments 
- heuristic             ::GreedyProportion          : GreedyProportion heuristic employed
- file_name             ::String                    : Name of the file to save results in

# Outputs
None
"""

function save_parameters(heuristic::GreedyProportion, file_name::String)::Nothing
    file = open("results/$file_name", "a")

    write(file, "h GreedyProportion\n")

    close(file)
end