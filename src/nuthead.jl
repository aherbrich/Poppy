module nuthead

    include("macros.jl")
    include("constants.jl")
    include("board.jl")
    include("move.jl")
    include("movegen.jl")
    include("perft.jl")

    
    export Board, set_by_fen!, extract_fen, perft!
end 
