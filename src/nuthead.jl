module nuthead

    include("constants.jl")
    include("board.jl")
    include("move.jl")
    include("movegen.jl")
    include("helpers.jl")

    # board = Board()
    # set_by_fen!(board, "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1")
    # moves = generate_moves(board)
    # for move in moves
    #     println(move)
    # end

    export Board, set_by_fen!, extract_fen
end 
