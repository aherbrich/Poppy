module nuthead

    include("constants.jl")
    include("board.jl")
    include("move.jl")
    include("movegen.jl")
    include("helpers.jl")

    board = Board()
    set_by_fen!(board, "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1")
    
    function perft(board::Board, depth::Int)
        if depth == 0 return 1 end
        moves = generate_moves(board)
        nodes = 0
        for move in moves
            old_board = extract_fen(board)
            old_color = board.side_to_move
            make_move!(board, move)
            if in_check(board, old_color) == false
                nodes += perft(board, depth-1)
            end
            set_by_fen!(board, old_board)
        end
        return nodes
    end

    function perft_divide(board::Board, depth::Int)
        moves = generate_moves(board)
        global_nodes = 0
        for move in moves
            old_board = extract_fen(board)
            old_color = board.side_to_move
            make_move!(board, move)
            if in_check(board, old_color) == false
                nodes = perft(board, depth-1)
                println(move, ": ", nodes)
                global_nodes += nodes
            end
            set_by_fen!(board, old_board)
        end
        println("Total nodes: ", global_nodes)
    end

    println(perft(board, 4))
    export Board, set_by_fen!, extract_fen
end 
