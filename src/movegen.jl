function add_castle_move!(board, moves, from_sq, to_sq, piece)
    # TODO
end

function add_en_passant_move!(board, moves, from_sq, to_sq, piece)
    captured_piece = board.side_to_move == WHITE ? BLACK_PAWN : WHITE_PAWN
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, true, NO_PIECE, NO_CASTLING, NO_SQUARE))
end

function add_promotion_move!(board, moves, from_sq, to_sq, piece)
    captured_piece = board.squares[to_sq]
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, false, QUEEN, NO_CASTLING, NO_SQUARE))
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, false, ROOK, NO_CASTLING, NO_SQUARE))
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, false, BISHOP, NO_CASTLING, NO_SQUARE))
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, false, KNIGHT, NO_CASTLING, NO_SQUARE))
end

function add_double_pawn_push!(board, moves, from_sq, to_sq, piece)
    ep_sqr = board.side_to_move == WHITE ? to_sq - 8 : to_sq + 8
    push!(moves, Move(piece, from_sq, to_sq, NO_PIECE, false, NO_PIECE, NO_CASTLING, ep_sqr))
end

function add_capture_move!(board, moves, from_sq, to_sq, piece)
    captured_piece = board.squares[to_sq]
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, false, NO_PIECE, NO_CASTLING, NO_SQUARE))
end

function add_quiet_move!(board, moves, from_sq, to_sq, piece)
    push!(moves, Move(piece, from_sq, to_sq, NO_PIECE, false, NO_PIECE, NO_CASTLING, NO_SQUARE))
end

function add_knight_moves!(board, moves, sqr, piece)
    piece_color = piece & 0x03
    if piece_color != board.side_to_move
        return
    end

    sqr_bb = UInt64(1) << (sqr - 1)

    dest_sqr_bb = ((sqr_bb & CLEAR_FILE_A & CLEAR_FILE_B) << 6) |
                ((sqr_bb & CLEAR_FILE_A & CLEAR_FILE_B) >> 10)  |
                ((sqr_bb & CLEAR_FILE_G & CLEAR_FILE_H) << 10) |
                ((sqr_bb & CLEAR_FILE_G & CLEAR_FILE_H) >> 6)  |
                ((sqr_bb & CLEAR_FILE_A) << 15) |
                ((sqr_bb & CLEAR_FILE_H) << 17) |
                ((sqr_bb & CLEAR_FILE_A) >> 17) |
                ((sqr_bb & CLEAR_FILE_H) >> 15)

    captured_bb = board.side_to_move == WHITE ? dest_sqr_bb & board.black_pieces : dest_sqr_bb & board.white_pieces

    while captured_bb != 0
        to_sqr = trailing_zeros(captured_bb) + 1
        add_capture_move!(board, moves, sqr, to_sqr, piece)
        captured_bb &= captured_bb - 1
    end

    quiet_bb = dest_sqr_bb & ~(board.white_pieces | board.black_pieces)

    while quiet_bb != 0
        to_sqr = trailing_zeros(quiet_bb)  + 1
        add_quiet_move!(board, moves, sqr, to_sqr, piece)
        quiet_bb &= quiet_bb - 1
    end
end

function add_bishop_moves!(boad, moves, sqr, piece)
    piece_color = piece & 0x03
    if piece_color != board.side_to_move
        return
    end

    dest_sqr_bb = UInt64(0)
    all_bb = (board.white_pieces | board.black_pieces) & ~UInt64(1 << (sqr - 1))

    # northeast
    sqr_bb = UInt64(1) << (sqr - 1)
    while sqr_bb != 0 && (sqr_bb & CLEAR_FILE_A) != 0 && (sqr_bb & all_bb) == 0
        dest_sqr_bb |= sqr_bb << 7
        sqr_bb <<= 7
    end

    # southeast
    sqr_bb = UInt64(1) << (sqr - 1)
    while sqr_bb != 0 && (sqr_bb & CLEAR_FILE_A) != 0 && (sqr_bb & all_bb) == 0
        dest_sqr_bb |= sqr_bb >> 9
        sqr_bb >>= 9
    end

    # northwest
    sqr_bb = UInt64(1) << (sqr - 1)
    while sqr_bb != 0 && (sqr_bb & CLEAR_FILE_H) != 0 && (sqr_bb & all_bb) == 0
        dest_sqr_bb |= sqr_bb << 9
        sqr_bb <<= 9
    end

    # southwest
    sqr_bb = UInt64(1) << (sqr - 1)
    while sqr_bb != 0 && (sqr_bb & CLEAR_FILE_H) != 0 && (sqr_bb & all_bb) == 0
        dest_sqr_bb |= sqr_bb >> 7
        sqr_bb >>= 7
    end

    captured_bb = board.side_to_move == WHITE ? dest_sqr_bb & board.black_pieces : dest_sqr_bb & board.white_pieces

    while captured_bb != 0
        to_sqr = trailing_zeros(captured_bb)  + 1
        add_capture_move!(board, moves, sqr, to_sqr, piece)
        captured_bb &= captured_bb - 1
    end

    quiet_bb = dest_sqr_bb & ~(board.white_pieces | board.black_pieces)

    while quiet_bb != 0
        to_sqr = trailing_zeros(quiet_bb)  + 1
        add_quiet_move!(board, moves, sqr, to_sqr, piece)
        quiet_bb &= quiet_bb - 1
    end
end

function add_rook_moves!(board, moves, sqr, piece)
    piece_color = piece & 0x03
    if piece_color != board.side_to_move
        return
    end

    dest_sqr_bb = UInt64(0)
    all_bb = (board.white_pieces | board.black_pieces) & ~UInt64(1 << (sqr - 1))

    # north
    sqr_bb = UInt64(1) << (sqr - 1)
    while sqr_bb != 0 && (sqr_bb & CLEAR_RANK_8) != 0 && (sqr_bb & all_bb) == 0
        dest_sqr_bb |= sqr_bb << 8
        sqr_bb <<= 8
    end

    # south
    sqr_bb = UInt64(1) << (sqr - 1)
    while sqr_bb != 0 && (sqr_bb & CLEAR_RANK_1) != 0 && (sqr_bb & all_bb) == 0
        dest_sqr_bb |= sqr_bb >> 8
        sqr_bb >>= 8
    end

    # east
    sqr_bb = UInt64(1) << (sqr - 1)
    while sqr_bb != 0 && (sqr_bb & CLEAR_FILE_H) != 0 && (sqr_bb & all_bb) == 0
        dest_sqr_bb |= sqr_bb << 1
        sqr_bb <<= 1
    end

    # west
    sqr_bb = UInt64(1) << (sqr - 1)
    while sqr_bb != 0 && (sqr_bb & CLEAR_FILE_A) != 0 && (sqr_bb & all_bb) == 0
        dest_sqr_bb |= sqr_bb >> 1
        sqr_bb >>= 1
    end

    captured_bb = board.side_to_move == WHITE ? dest_sqr_bb & board.black_pieces : dest_sqr_bb & board.white_pieces
        
    while captured_bb != 0
        to_sqr = trailing_zeros(captured_bb)  + 1
        add_capture_move!(board, moves, sqr, to_sqr, piece)
        captured_bb &= captured_bb - 1
    end

    quiet_bb = dest_sqr_bb & ~(board.white_pieces | board.black_pieces)

    while quiet_bb != 0
        to_sqr = trailing_zeros(quiet_bb)  + 1
        add_quiet_move!(board, moves, sqr, to_sqr, piece)
        quiet_bb &= quiet_bb - 1
    end
end

function add_queen_moves!(board, moves, sqr, piece)
    add_bishop_moves!(board, moves, sqr, piece)
    add_rook_moves!(board, moves, sqr, piece)
end

function add_king_moves!(board, moves, sqr, piece)
    piece_color = piece & 0x03
    if piece_color != board.side_to_move
        return
    end

    sqr_bb = UInt64(1) << (sqr - 1)

    dest_sqr_bb = UInt64(0)
    dest_sqr_bb |= ((sqr_bb & CLEAR_FILE_A) >> 1) | 
                    ((sqr_bb & CLEAR_FILE_A) << 7) |
                    ((sqr_bb & CLEAR_FILE_A) >> 9) |
                    ((sqr_bb & CLEAR_FILE_H) << 1) |
                    ((sqr_bb & CLEAR_FILE_H) << 9) |
                    ((sqr_bb & CLEAR_FILE_H) >> 7) |
                    (sqr_bb >> 8) |
                    (sqr_bb << 8)

    captured_bb = board.side_to_move == WHITE ? dest_sqr_bb & board.black_pieces : dest_sqr_bb & board.white_pieces

    while captured_bb != 0
        to_sqr = trailing_zeros(captured_bb)  + 1
        add_capture_move!(board, moves, sqr, to_sqr, piece)
        captured_bb &= captured_bb - 1
    end

    quiet_bb = dest_sqr_bb & ~(board.white_pieces | board.black_pieces)

    while quiet_bb != 0
        to_sqr = trailing_zeros(quiet_bb)  + 1
        add_quiet_move!(board, moves, sqr, to_sqr, piece)
        quiet_bb &= quiet_bb - 1
    end
end

function add_pawn_moves!(board, moves, sqr, piece)
    piece_color = piece & 0x03
    if piece_color != board.side_to_move
        return
    end

    sqr_bb = UInt64(1) << (sqr - 1)
    all_bb = board.white_pieces | board.black_pieces
    
    # single push
    dest_sqr_bb = board.side_to_move == WHITE ? (sqr_bb << 8) & ~all_bb : (sqr_bb >> 8) & ~all_bb

    if dest_sqr_bb != 0
        is_promotion = board.side_to_move == WHITE ? (dest_sqr_bb & RANK_8) != 0 : (dest_sqr_bb & RANK_1) != 0
        to_sqr = trailing_zeros(dest_sqr_bb)  + 1
        if is_promotion
            add_promotion_move!(board, moves, sqr, to_sqr, piece)
        else
            add_quiet_move!(board, moves, sqr, to_sqr, piece)

            # double push
            on_second_rank = board.side_to_move == WHITE ? (sqr_bb & RANK_2) != 0 : (sqr_bb & RANK_7) != 0

            if on_second_rank 
                dest_sqr_bb = board.side_to_move == WHITE ? ((dest_sqr_bb) << 8) & ~all_bb : ((dest_sqr_bb) >> 8) & ~all_bb

                if dest_sqr_bb != 0
                    to_sqr = trailing_zeros(dest_sqr_bb)  + 1
                    add_double_pawn_push!(board, moves, sqr, to_sqr, piece)
                end
            end
        end
    end

    # captures
    dest_sqr_bb = board.side_to_move == WHITE ? ((sqr_bb & CLEAR_FILE_A) << 7) | ((sqr_bb & CLEAR_FILE_H) << 9) : ((sqr_bb & CLEAR_FILE_A) >> 9) | ((sqr_bb & CLEAR_FILE_H) >> 7)
    captured_bb = board.side_to_move == WHITE ? dest_sqr_bb & board.black_pieces : dest_sqr_bb & board.white_pieces

    while captured_bb != 0
        to_sqr = trailing_zeros(captured_bb)  + 1
        is_promotion = board.side_to_move == WHITE ? (dest_sqr_bb & RANK_8) != 0 : (dest_sqr_bb & RANK_1) != 0
        if is_promotion
            add_promotion_move!(board, moves, sqr, to_sqr, piece)
        else
            add_capture_move!(board, moves, sqr, to_sqr, piece)
        end
        captured_bb &= captured_bb - 1
    end

    # en passant
    if board.ep_square != NO_SQUARE
        dest_sqr_bb = board.side_to_move == WHITE ? ((sqr_bb & CLEAR_FILE_A) << 7) | ((sqr_bb & CLEAR_FILE_H) << 9) : ((sqr_bb & CLEAR_FILE_A) >> 9) | ((sqr_bb & CLEAR_FILE_H) >> 7)
        if dest_sqr_bb & (UInt64(1) << (board.ep_square - 1)) != 0
            add_en_passant_move!(board, moves, sqr, board.ep_square, piece)
        end
    end

end

# generate all legal moves
function generate_moves(board::Board)
    moves = []
    for sqr in 1:64
        if board.squares[sqr] == EMPTY
            continue
        end
        
        piece = board.squares[sqr]
        piece_type = piece & ~0x03

        if piece_type == KNIGHT
            add_knight_moves!(board, moves, sqr, piece)
        elseif piece_type == BISHOP
            add_bishop_moves!(board, moves, sqr, piece)
        elseif piece_type == ROOK
            add_rook_moves!(board, moves, sqr, piece)
        elseif piece_type == QUEEN
            add_queen_moves!(board, moves, sqr, piece)
        elseif piece_type == KING
            add_king_moves!(board, moves, sqr, piece)
        elseif piece_type == PAWN
            add_pawn_moves!(board, moves, sqr, piece)
        end

    end # end for i in 1:64
    
    # filter out illegal moves

    return moves
end

