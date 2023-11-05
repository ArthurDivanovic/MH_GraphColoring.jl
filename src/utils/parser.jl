"""
    parse_file(file_path::String)::Tuple{Matrix{Int}, Int, String}

Parser to create a graph instance from a .txt file.

# Arguments 
- file_path        ::String        : File path for the description of the graph instance

# Outputs
- adj              ::Matrix{Int}   : Adjacency matrix  
- m                ::Int           : Number of edges
- file_name        ::Int           : Base name of the file that describes the graph
"""

function parse_file(file_path::String)::Tuple{Matrix{Int}, Int, String}
    file = open(file_path, "r")
    adj = Matrix{Int}(undef, 0, 0)
    m = 0
    file_name = basename(file_path)

    for line in eachline(file)
        l = line[1]

        if l == 'c'
            continue
        end
        
        list = split(line, " ")
        if l == 'p'
            n = parse(Int, list[3])
            m = parse(Int, list[4])
            adj = zeros(Int, n, n)
        end

        if l == 'e'
            i = parse(Int, list[2])
            j = parse(Int, list[3])
            adj[i,j] = 1
            adj[j,i] = 1
        end
    end

    close(file)
    return adj, m, file_name
end


"""
    k_parser(file_path::String)::Dict{String, Vector{Int}}

Parser to obtain the number of colors (k) to consider for each instance.

# Arguments 
- file_path        ::String                       : File path for the number of colors

# Outputs
- k_dict           ::Dict{String, Vector{Int}}    : Dictionnary linking an instance name to the k to test.  
"""

function k_parser(file_path::String)::Dict{String, Vector{Int}}
    file = open(file_path, "r")

    k_dict = Dict{String, Vector{Int}}()

    for line in eachline(file)
        
        list = split(line, " ")
        k_dict[list[1]] = [parse(Int, s) for s in list[2:end]]

    end

    return k_dict
end
