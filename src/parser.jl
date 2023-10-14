function parse_file(file_path::String)::Tuple{Matrix{Int}, Int}
    file = open(file_path, "r")
    adj = Matrix{Int}(undef, 0, 0)
    m = 0

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
    return adj, m
end