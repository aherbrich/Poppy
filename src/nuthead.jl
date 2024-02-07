module nuthead

    include("constants.jl")
    include("board.jl")

    export Board, set_by_fen!, extract_fen
end
