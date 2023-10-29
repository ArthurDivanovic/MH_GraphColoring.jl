include("../utils/coloredgraph.jl")

function (heuristic::Heuristic)(g::ColoredGraph)
    @error "A coloration method must be implemented for each specific heuristic."
end

function save_parameters(heuristic::Heuristic, file_name::String)::Nothing
    @error "The save_parameters method must be implemented for each specific heuristic."
end

include("greedy.jl")
include("randomvertice.jl")
include("simulatedannealing.jl")
include("tabusearch.jl")