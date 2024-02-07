function add_castle_move!(board, moves, from_sq, to_sq, piece)
    # TODO
end

function add_en_passant_move!(board, moves, from_sq, to_sq, piece)
    # TODO
end

function add_promotion_move!(board, moves, from_sq, to_sq, piece)
    # TODO
end

function add_double_pawn_push!(board, moves, from_sq, to_sq, piece)
    # TODO
end

function add_capture_move!(board, moves, from_sq, to_sq, piece, new_castling_rights)
    castle_rights_delta = Int8(new_castling_rights) - Int8(board.castling_rights)
    ep_square_delta = -Int8(board.ep_square)
    move = Move(piece, from_sq, to_sq, board.squares[to_sq], NO_PIECE, castle_rights_delta, ep_square_delta)
    push!(moves, move)
end

function add_quiet_move!(board, moves, from_sq, to_sq, piece, new_castling_rights)
    castle_rights_delta = Int8(new_castling_rights) - Int8(board.castling_rights)
    ep_square_delta = -Int8(board.ep_square)
    move = Move(piece, from_sq, to_sq, NO_PIECE, NO_PIECE, castle_rights_delta, ep_square_delta)
    push!(moves, move)
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
        to_sqr = trailing_zeros(captured_bb)
        add_capture_move!(board, moves, sqr, to_sqr, piece, board.castling_rights)
        captured_bb &= captured_bb - 1
    end

    quiet_bb = dest_sqr_bb & ~(board.white_pieces | board.black_pieces)

    while quiet_bb != 0
        to_sqr = trailing_zeros(quiet_bb)
        add_quiet_move!(board, moves, sqr, to_sqr, piece, board.castling_rights)
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
        to_sqr = trailing_zeros(captured_bb)
        add_capture_move!(board, moves, sqr, to_sqr, piece, board.castling_rights)
        captured_bb &= captured_bb - 1
    end

    quiet_bb = dest_sqr_bb & ~(board.white_pieces | board.black_pieces)

    while quiet_bb != 0
        to_sqr = trailing_zeros(quiet_bb)
        add_quiet_move!(board, moves, sqr, to_sqr, piece, board.castling_rights)
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

    new_castling_rights = sqr == 1 ? board.castling_rights & ~CASTLING_WQ : sqr == 8 ? board.castling_rights & ~CASTLING_WK : 
                        sqr == 57 ? board.castling_rights & ~CASTLING_BQ : sqr == 64 ? board.castling_rights & ~CASTLING_BK : board.castling_rights

    captured_bb = board.side_to_move == WHITE ? dest_sqr_bb & board.black_pieces : dest_sqr_bb & board.white_pieces
    print_bb(captured_bb)
        
    while captured_bb != 0
        to_sqr = trailing_zeros(captured_bb)
        add_capture_move!(board, moves, sqr, to_sqr, piece, new_castling_rights)
        captured_bb &= captured_bb - 1
    end

    quiet_bb = dest_sqr_bb & ~(board.white_pieces | board.black_pieces)
    print_bb(quiet_bb)
    while quiet_bb != 0
        to_sqr = trailing_zeros(quiet_bb)
        add_quiet_move!(board, moves, sqr, to_sqr, piece, new_castling_rights)
        quiet_bb &= quiet_bb - 1
    end
end

function add_queen_moves!(board, moves, sqr, piece)
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
        to_sqr = trailing_zeros(captured_bb)
        add_capture_move!(board, moves, sqr, to_sqr, piece, board.castling_rights)
        captured_bb &= captured_bb - 1
    end

    quiet_bb = dest_sqr_bb & ~(board.white_pieces | board.black_pieces)

    while quiet_bb != 0
        to_sqr = trailing_zeros(quiet_bb)
        add_quiet_move!(board, moves, sqr, to_sqr, piece, board.castling_rights)
        quiet_bb &= quiet_bb - 1
    end
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
        to_sqr = trailing_zeros(captured_bb)
        add_capture_move!(board, moves, sqr, to_sqr, piece, board.castling_rights)
        captured_bb &= captured_bb - 1
    end

    quiet_bb = dest_sqr_bb & ~(board.white_pieces | board.black_pieces)
    
    while quiet_bb != 0
        to_sqr = trailing_zeros(quiet_bb)
        add_quiet_move!(board, moves, sqr, to_sqr, piece, board.castling_rights)
        quiet_bb &= quiet_bb - 1
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
            # add_knight_moves!(board, moves, sqr, piece)
        elseif piece_type == BISHOP
            # add_bishop_moves!(board, moves, sqr, piece)
        elseif piece_type == ROOK
            # add_rook_moves!(board, moves, sqr, piece)
        elseif piece_type == QUEEN
            # add_queen_moves!(board, moves, sqr, piece)
        elseif piece_type == KING
            add_king_moves!(board, moves, sqr, piece)
        elseif piece_type == PAWN
            # TODO
        end

    end # end for i in 1:64
    
    # filter out illegal moves

    return moves
end

