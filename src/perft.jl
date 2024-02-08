function perft!(board::Board, depth::Int)
    if depth == 0 return 1 end
    moves = generate_moves(board)
    nodes = 0
    for move in moves
        old_color = board.side_to_move
        make_move!(board, move)
        if in_check(board, old_color) == false
            nodes += perft!(board, depth-1)
        end
        unmake_move!(board, move)
    end
    return nodes
end

function perft_divide!(board::Board, depth::Int)
    moves = generate_moves(board)
    global_nodes = 0
    for move in moves
        old_color = board.side_to_move
        make_move!(board, move)
        if in_check(board, old_color) == false
            nodes = perft!(board, depth-1)
            println(move, ": ", nodes)
            global_nodes += nodes
        end
        unmake_move!(board, move)
    end
    return global_nodes
end