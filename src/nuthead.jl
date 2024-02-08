module nuthead

    include("constants.jl")
    include("board.jl")
    include("move.jl")
    include("movegen.jl")
    include("helpers.jl")
    include("perft.jl")
    
    export Board, set_by_fen!, extract_fen, perft!
end 
