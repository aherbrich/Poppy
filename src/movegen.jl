function add_castle_move!(board, moves, from_sq, to_sq, piece, castling)
    push!(moves, Move(piece, from_sq, to_sq, NO_PIECE, false, NO_PIECE, castling, NO_SQUARE, board.castling_rights, board.ep_square))
end

function add_en_passant_move!(board, moves, from_sq, to_sq, piece)
    captured_piece = board.side_to_move == WHITE ? BLACK_PAWN : WHITE_PAWN
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, true, NO_PIECE, NO_CASTLING, NO_SQUARE, board.castling_rights, board.ep_square))
end

function add_promotion_move!(board, moves, from_sq, to_sq, piece)
    captured_piece = board.squares[to_sq]
    color = @piece_color(piece)
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, false, QUEEN | color, NO_CASTLING, NO_SQUARE, board.castling_rights, board.ep_square))
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, false, ROOK | color, NO_CASTLING, NO_SQUARE, board.castling_rights, board.ep_square))
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, false, BISHOP | color, NO_CASTLING, NO_SQUARE, board.castling_rights, board.ep_square))
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, false, KNIGHT | color, NO_CASTLING, NO_SQUARE, board.castling_rights, board.ep_square))
end

function add_double_pawn_push!(board, moves, from_sq, to_sq, piece)
    ep_sqr = board.side_to_move == WHITE ? to_sq - 8 : to_sq + 8
    push!(moves, Move(piece, from_sq, to_sq, NO_PIECE, false, NO_PIECE, NO_CASTLING, ep_sqr, board.castling_rights, board.ep_square))
end

function add_capture_move!(board, moves, from_sq, to_sq, piece)
    captured_piece = board.squares[to_sq]
    push!(moves, Move(piece, from_sq, to_sq, captured_piece, false, NO_PIECE, NO_CASTLING, NO_SQUARE, board.castling_rights, board.ep_square))
end

function add_quiet_move!(board, moves, from_sq, to_sq, piece)
    push!(moves, Move(piece, from_sq, to_sq, NO_PIECE, false, NO_PIECE, NO_CASTLING, NO_SQUARE, board.castling_rights, board.ep_square))
end

function add_knight_moves!(board, moves, sqr, piece)
    piece_color = @piece_color(piece)
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

    captured_bb = board.side_to_move == WHITE ? dest_sqr_bb & (board.black_pieces & ~board.bb_for[BLACK_KING]) : dest_sqr_bb & (board.white_pieces & ~board.bb_for[WHITE_KING])

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
end # add_knight_moves!()

function add_bishop_moves!(board, moves, sqr, piece)
    piece_color = @piece_color(piece)
    if piece_color != board.side_to_move
        return
    end

    dest_sqr_bb = UInt64(0)
    all_bb = (board.white_pieces | board.black_pieces) & ~(UInt64(1) << (sqr - 1))

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

    captured_bb = board.side_to_move == WHITE ? dest_sqr_bb & (board.black_pieces & ~board.bb_for[BLACK_KING]) : dest_sqr_bb & (board.white_pieces & ~board.bb_for[WHITE_KING])

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
end # add_bishop_moves!()

function add_rook_moves!(board, moves, sqr, piece)
    piece_color = @piece_color(piece)
    if piece_color != board.side_to_move
        return
    end

    dest_sqr_bb = UInt64(0)
    all_bb = (board.white_pieces | board.black_pieces) & ~(UInt64(1) << (sqr - 1))

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

    captured_bb = board.side_to_move == WHITE ? dest_sqr_bb & (board.black_pieces & ~board.bb_for[BLACK_KING]) : dest_sqr_bb & (board.white_pieces & ~board.bb_for[WHITE_KING])
        
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
end # add_rook_moves!()

function add_queen_moves!(board, moves, sqr, piece)
    add_bishop_moves!(board, moves, sqr, piece)
    add_rook_moves!(board, moves, sqr, piece)
end # add_queen_moves!()

function add_king_moves!(board, moves, sqr, piece)
    piece_color = @piece_color(piece)
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

    captured_bb = board.side_to_move == WHITE ? dest_sqr_bb & (board.black_pieces & ~board.bb_for[BLACK_KING]) : dest_sqr_bb & (board.white_pieces & ~board.bb_for[WHITE_KING])

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
end # add_king_moves!()

function add_pawn_moves!(board, moves, sqr, piece)
    piece_color = @piece_color(piece)
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
    end # end single & double push

    # captures
    dest_sqr_bb = board.side_to_move == WHITE ? ((sqr_bb & CLEAR_FILE_A) << 7) | ((sqr_bb & CLEAR_FILE_H) << 9) : ((sqr_bb & CLEAR_FILE_A) >> 9) | ((sqr_bb & CLEAR_FILE_H) >> 7)
    captured_bb = board.side_to_move == WHITE ? dest_sqr_bb & (board.black_pieces & ~board.bb_for[BLACK_KING]) : dest_sqr_bb & (board.white_pieces & ~board.bb_for[WHITE_KING])

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

end # add_pawn_moves!()

function rook_attacks(board, sqr)
    dest_sqr_bb = UInt64(0)
    all_bb = (board.white_pieces | board.black_pieces) & ~(UInt64(1) << (sqr - 1))

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

    return dest_sqr_bb
end # rook_attacks()

function bishop_attacks(board, sqr)
    dest_sqr_bb = UInt64(0)
    all_bb = (board.white_pieces | board.black_pieces) & ~(UInt64(1) << (sqr - 1))

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

    return dest_sqr_bb
end # bishop_attacks()

function knight_attacks(board, sqr)
    sqr_bb = UInt64(1) << (sqr - 1)

    dest_sqr_bb = ((sqr_bb & CLEAR_FILE_A & CLEAR_FILE_B) << 6) |
                ((sqr_bb & CLEAR_FILE_A & CLEAR_FILE_B) >> 10)  |
                ((sqr_bb & CLEAR_FILE_G & CLEAR_FILE_H) << 10) |
                ((sqr_bb & CLEAR_FILE_G & CLEAR_FILE_H) >> 6)  |
                ((sqr_bb & CLEAR_FILE_A) << 15) |
                ((sqr_bb & CLEAR_FILE_H) << 17) |
                ((sqr_bb & CLEAR_FILE_A) >> 17) |
                ((sqr_bb & CLEAR_FILE_H) >> 15)

    return dest_sqr_bb
end # knight_attacks()

function king_attacks(board, sqr)
    sqr_bb = UInt64(1) << (sqr - 1)

    dest_sqr_bb = ((sqr_bb & CLEAR_FILE_A) >> 1) | 
                    ((sqr_bb & CLEAR_FILE_A) << 7) |
                    ((sqr_bb & CLEAR_FILE_A) >> 9) |
                    ((sqr_bb & CLEAR_FILE_H) << 1) |
                    ((sqr_bb & CLEAR_FILE_H) << 9) |
                    ((sqr_bb & CLEAR_FILE_H) >> 7) |
                    (sqr_bb >> 8) |
                    (sqr_bb << 8)

    return dest_sqr_bb
end # king_attacks()

function pawn_attacks(board, sqr, own_color)
    sqr_bb = UInt64(1) << (sqr - 1)

    dest_sqr_bb = own_color == WHITE ? ((sqr_bb & CLEAR_FILE_A) << 7) | ((sqr_bb & CLEAR_FILE_H) << 9) : ((sqr_bb & CLEAR_FILE_A) >> 9) | ((sqr_bb & CLEAR_FILE_H) >> 7)
    return dest_sqr_bb
end # pawn_attacks()

# generate all moves including pseudo-legal moves
function generate_moves(board::Board)
    moves = []
    for sqr in 1:64
        if board.squares[sqr] == EMPTY
            continue
        end
        
        piece = board.squares[sqr]
        piece_type = @piece_type(piece)

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

    all_bb = board.white_pieces | board.black_pieces

    # shortside castling
    oo_mask = board.side_to_move == WHITE ? 0x0000000000000060 : 0x6000000000000000
    oo_allowed = board.side_to_move == WHITE ? (board.castling_rights & CASTLING_WK) != 0 : (board.castling_rights & CASTLING_BK) != 0
    if (all_bb & oo_mask) == 0 && oo_allowed
        if board.side_to_move == WHITE
            attackers = (bishop_attacks(board, 5) & (board.bb_for[BLACK_BISHOP] | board.bb_for[BLACK_QUEEN])) |
                    (bishop_attacks(board, 6) & (board.bb_for[BLACK_BISHOP] | board.bb_for[BLACK_QUEEN])) |
                    (rook_attacks(board, 5) & (board.bb_for[BLACK_ROOK] | board.bb_for[BLACK_QUEEN])) |
                    (rook_attacks(board, 6) & (board.bb_for[BLACK_ROOK] | board.bb_for[BLACK_QUEEN])) |
                    (knight_attacks(board, 5) & board.bb_for[BLACK_KNIGHT]) |
                    (knight_attacks(board, 6) & board.bb_for[BLACK_KNIGHT]) |
                    (pawn_attacks(board, 5, WHITE) & board.bb_for[BLACK_PAWN]) |
                    (pawn_attacks(board, 6, WHITE) & board.bb_for[BLACK_PAWN]) |
                    (king_attacks(board, 5) & board.bb_for[BLACK_KING]) |
                    (king_attacks(board, 6) & board.bb_for[BLACK_KING])
            if attackers == 0
                add_castle_move!(board, moves, 5, 7, WHITE_KING, CASTLING_WK)
            end
        # end if board.side_to_move == WHITE
        else
            attackers = (bishop_attacks(board, 61) & (board.bb_for[WHITE_BISHOP] | board.bb_for[WHITE_QUEEN])) |
                    (bishop_attacks(board, 62) & (board.bb_for[WHITE_BISHOP] | board.bb_for[WHITE_QUEEN])) |
                    (rook_attacks(board, 61) & (board.bb_for[WHITE_ROOK] | board.bb_for[WHITE_QUEEN])) |
                    (rook_attacks(board, 62) & (board.bb_for[WHITE_ROOK] | board.bb_for[WHITE_QUEEN])) |
                    (knight_attacks(board, 61) & board.bb_for[WHITE_KNIGHT]) |
                    (knight_attacks(board, 62) & board.bb_for[WHITE_KNIGHT]) |
                    (pawn_attacks(board, 61, BLACK) & board.bb_for[WHITE_PAWN]) |
                    (pawn_attacks(board, 62, BLACK) & board.bb_for[WHITE_PAWN]) |
                    (king_attacks(board, 61) & board.bb_for[WHITE_KING]) |
                    (king_attacks(board, 62) & board.bb_for[WHITE_KING])
            if attackers == 0
                add_castle_move!(board, moves, 61, 63, BLACK_KING, CASTLING_BK)
            end
        end # end if board.side_to_move == BLACK
    end # end shortside castling

    # longside castling
    ooo_mask = board.side_to_move == WHITE ? 0x000000000000000E : 0x0E00000000000000
    ooo_allowed = board.side_to_move == WHITE ? (board.castling_rights & CASTLING_WQ) != 0 : (board.castling_rights & CASTLING_BQ) != 0
    if (all_bb & ooo_mask) == 0 && ooo_allowed
        if board.side_to_move == WHITE
            attackers = (bishop_attacks(board, 5) & (board.bb_for[BLACK_BISHOP] | board.bb_for[BLACK_QUEEN])) |
                    (bishop_attacks(board, 4) & (board.bb_for[BLACK_BISHOP] | board.bb_for[BLACK_QUEEN])) |
                    (rook_attacks(board, 5) & (board.bb_for[BLACK_ROOK] | board.bb_for[BLACK_QUEEN])) |
                    (rook_attacks(board, 4) & (board.bb_for[BLACK_ROOK] | board.bb_for[BLACK_QUEEN])) |
                    (knight_attacks(board, 5) & board.bb_for[BLACK_KNIGHT]) |
                    (knight_attacks(board, 4) & board.bb_for[BLACK_KNIGHT]) |
                    (pawn_attacks(board, 5, WHITE) & board.bb_for[BLACK_PAWN]) |
                    (pawn_attacks(board, 4, WHITE) & board.bb_for[BLACK_PAWN]) |
                    (king_attacks(board, 5) & board.bb_for[BLACK_KING]) |
                    (king_attacks(board, 4) & board.bb_for[BLACK_KING])
            if attackers == 0
                add_castle_move!(board, moves, 5, 3, WHITE_KING, CASTLING_WQ)
            end
        # end if board.side_to_move == WHITE
        else
            attackers = (bishop_attacks(board, 61) & (board.bb_for[WHITE_BISHOP] | board.bb_for[WHITE_QUEEN])) |
                    (bishop_attacks(board, 60) & (board.bb_for[WHITE_BISHOP] | board.bb_for[WHITE_QUEEN])) |
                    (rook_attacks(board, 61) & (board.bb_for[WHITE_ROOK] | board.bb_for[WHITE_QUEEN])) |
                    (rook_attacks(board, 60) & (board.bb_for[WHITE_ROOK] | board.bb_for[WHITE_QUEEN])) |
                    (knight_attacks(board, 61) & board.bb_for[WHITE_KNIGHT]) |
                    (knight_attacks(board, 60) & board.bb_for[WHITE_KNIGHT]) |
                    (pawn_attacks(board, 61, BLACK) & board.bb_for[WHITE_PAWN]) |
                    (pawn_attacks(board, 60, BLACK) & board.bb_for[WHITE_PAWN]) |
                    (king_attacks(board, 61) & board.bb_for[WHITE_KING]) |
                    (king_attacks(board, 60) & board.bb_for[WHITE_KING])
            if attackers == 0
                add_castle_move!(board, moves, 61, 59, BLACK_KING, CASTLING_BQ)
            end
        end # end if board.side_to_move == WHITE
    end # end longside castling

    return moves
end # generate_moves()

function make_move!(board::Board, move::Move)
    from_bb = UInt64(1) << (move.from_sqr - 1)
    to_bb = UInt64(1) << (move.to_sqr - 1)
    board.ep_square = NO_SQUARE

    if board.side_to_move == WHITE
        # update squares array
        board.squares[move.from_sqr] = NO_PIECE
        board.squares[move.to_sqr] = move.piece

        # update white pieces bitboard
        board.white_pieces &= ~from_bb
        board.white_pieces |= to_bb
        board.bb_for[move.piece] &= ~from_bb
        board.bb_for[move.piece] |= to_bb

        # update black pieces bitboard
        board.black_pieces &= ~to_bb
        board.bb_for[BLACK_PAWN] &= ~to_bb
        board.bb_for[BLACK_KNIGHT] &= ~to_bb
        board.bb_for[BLACK_BISHOP] &= ~to_bb
        board.bb_for[BLACK_ROOK] &= ~to_bb
        board.bb_for[BLACK_QUEEN] &= ~to_bb

        # adjust castle rights if rook was captured
        if move.captured_piece != NO_PIECE
            if move.to_sqr == 57
                board.castling_rights &= ~CASTLING_BQ
            elseif move.to_sqr == 64
                board.castling_rights &= ~CASTLING_BK
            elseif move.to_sqr == 1
                board.castling_rights &= ~CASTLING_WQ
            elseif move.to_sqr == 8
                board.castling_rights &= ~CASTLING_WK
            end
        end

        # update castling rights if king or rook was moved
        if move.piece == WHITE_KING
            board.castling_rights &= ~(CASTLING_WK | CASTLING_WQ)
        elseif move.piece == WHITE_ROOK
            if move.from_sqr == 1
                board.castling_rights &= ~CASTLING_WQ
            elseif move.from_sqr == 8
                board.castling_rights &= ~CASTLING_WK
            end
        # update bitboard + flags for special pawn moves
        elseif move.piece == WHITE_PAWN
            if move.is_ep_capture
                ep_sqr = move.to_sqr - 8
                board.squares[ep_sqr] = NO_PIECE
                board.black_pieces &= ~(UInt64(1) << (ep_sqr - 1))
                board.bb_for[BLACK_PAWN] &= ~(UInt64(1) << (ep_sqr - 1))
            elseif move.promoted_piece != NO_PIECE
                board.squares[move.to_sqr] = move.promoted_piece
                board.bb_for[WHITE_PAWN] &= ~from_bb
                board.bb_for[move.promoted_piece] |= to_bb
            elseif move.ep_sqr != NO_SQUARE
                board.ep_square = move.ep_sqr
            end
        end
    # end if board.side_to_move == WHITE
    else 
        # update squares array
        board.squares[move.from_sqr] = NO_PIECE
        board.squares[move.to_sqr] = move.piece

        # update black pieces bitboard
        board.black_pieces &= ~from_bb
        board.black_pieces |= to_bb
        board.bb_for[move.piece] &= ~from_bb
        board.bb_for[move.piece] |= to_bb

        # update white pieces bitboard
        board.white_pieces &= ~to_bb
        board.bb_for[WHITE_PAWN] &= ~to_bb
        board.bb_for[WHITE_KNIGHT] &= ~to_bb
        board.bb_for[WHITE_BISHOP] &= ~to_bb
        board.bb_for[WHITE_ROOK] &= ~to_bb
        board.bb_for[WHITE_QUEEN] &= ~to_bb

        # adjust castle rights if rook was captured
        if move.captured_piece != NO_PIECE
            if move.to_sqr == 1
                board.castling_rights &= ~CASTLING_WQ
            elseif move.to_sqr == 8
                board.castling_rights &= ~CASTLING_WK
            end
        end

        # update castling rights if king or rook was moved
        if move.piece == BLACK_KING
            board.castling_rights &= ~(CASTLING_BK | CASTLING_BQ)
        elseif move.piece == BLACK_ROOK
            if move.from_sqr == 57
                board.castling_rights &= ~CASTLING_BQ
            elseif move.from_sqr == 64
                board.castling_rights &= ~CASTLING_BK
            end
        # update bitboard + flags for special pawn moves
        elseif move.piece == BLACK_PAWN
            if move.is_ep_capture
                ep_sqr = move.to_sqr + 8
                board.squares[ep_sqr] = NO_PIECE
                board.white_pieces &= ~(UInt64(1) << (ep_sqr - 1))
                board.bb_for[WHITE_PAWN] &= ~(UInt64(1) << (ep_sqr - 1))
            elseif move.promoted_piece != NO_PIECE
                board.squares[move.to_sqr] = move.promoted_piece
                board.bb_for[BLACK_PAWN] &= ~to_bb
                board.bb_for[move.promoted_piece] |= to_bb
            elseif move.ep_sqr != NO_SQUARE
                board.ep_square = move.ep_sqr
            end
        end
    end # end if board.side_to_move == BLACK

    # additionally update rook position if castling
    if move.castling == CASTLING_WK
        board.squares[6] = WHITE_ROOK
        board.squares[8] = NO_PIECE
        board.white_pieces &= ~(UInt64(1) << 7)
        board.white_pieces |= UInt64(1) << 5
        board.bb_for[WHITE_ROOK] &= ~(UInt64(1) << 7)
        board.bb_for[WHITE_ROOK] |= UInt64(1) << 5
        board.castling_rights &= ~(CASTLING_WK | CASTLING_WQ)
    elseif move.castling == CASTLING_WQ
        board.squares[4] = WHITE_ROOK
        board.squares[1] = NO_PIECE
        board.white_pieces &= ~(UInt64(1) << 0)
        board.white_pieces |= UInt64(1) << 3
        board.bb_for[WHITE_ROOK] &= ~(UInt64(1) << 0)
        board.bb_for[WHITE_ROOK] |= UInt64(1) << 3
        board.castling_rights &= ~(CASTLING_WK | CASTLING_WQ)
    elseif move.castling == CASTLING_BK
        board.squares[62] = BLACK_ROOK
        board.squares[64] = NO_PIECE
        board.black_pieces &= ~(UInt64(1) << 63)
        board.black_pieces |= UInt64(1) << 61
        board.bb_for[BLACK_ROOK] &= ~(UInt64(1) << 63)
        board.bb_for[BLACK_ROOK] |= UInt64(1) << 61
        board.castling_rights &= ~(CASTLING_BK | CASTLING_BQ)
    elseif move.castling == CASTLING_BQ
        board.squares[60] = BLACK_ROOK
        board.squares[57] = NO_PIECE
        board.black_pieces &= ~(UInt64(1) << 56)
        board.black_pieces |= UInt64(1) << 59
        board.bb_for[BLACK_ROOK] &= ~(UInt64(1) << 56)
        board.bb_for[BLACK_ROOK] |= UInt64(1) << 59
        board.castling_rights &= ~(CASTLING_BK | CASTLING_BQ)
    end # end if move.castling == ???

    board.side_to_move = board.side_to_move == WHITE ? BLACK : WHITE
    
end # make_move!()

function unmake_move!(board::Board, move::Move)
    from_bb = UInt64(1) << (move.from_sqr - 1)
    to_bb = UInt64(1) << (move.to_sqr - 1)

    if board.side_to_move == BLACK
        # update squares array
        board.squares[move.from_sqr] = move.piece

        if move.captured_piece != NO_PIECE && move.is_ep_capture == false
            board.squares[move.to_sqr] = move.captured_piece
        else
            board.squares[move.to_sqr] = EMPTY
        end

        # update white pieces bitboard
        board.white_pieces &= ~to_bb
        board.white_pieces |= from_bb
        board.bb_for[move.piece] &= ~to_bb
        board.bb_for[move.piece] |= from_bb

        # update black pieces bitboard
        if move.captured_piece != NO_PIECE && move.is_ep_capture == false
            board.black_pieces |= to_bb
            board.bb_for[move.captured_piece] |= to_bb
        end

        # special handling for pawn unmake
        if move.piece == WHITE_PAWN
            if move.is_ep_capture
                ep_sqr = move.to_sqr - 8
                board.squares[ep_sqr] = BLACK_PAWN
                board.black_pieces |= UInt64(1) << (ep_sqr - 1)
                board.bb_for[BLACK_PAWN] |= UInt64(1) << (ep_sqr - 1)
            elseif move.promoted_piece != NO_PIECE
                board.bb_for[move.promoted_piece] &= ~to_bb
            end
        end
    # end if board.side_to_move == BLACK
    else
        # update squares array
        board.squares[move.from_sqr] = move.piece
        if move.captured_piece != NO_PIECE && move.is_ep_capture == false
            board.squares[move.to_sqr] = move.captured_piece
        else
            board.squares[move.to_sqr] = EMPTY
        end

        # update black pieces bitboard
        board.black_pieces &= ~to_bb
        board.black_pieces |= from_bb
        board.bb_for[move.piece] &= ~to_bb
        board.bb_for[move.piece] |= from_bb

        # update white pieces bitboard
        if move.captured_piece != NO_PIECE && move.is_ep_capture == false
            board.white_pieces |= to_bb
            board.bb_for[move.captured_piece] |= to_bb
        end

        # special handling for pawn unmake
        if move.piece == BLACK_PAWN
            if move.is_ep_capture
                ep_sqr = move.to_sqr + 8
                board.squares[ep_sqr] = WHITE_PAWN
                board.white_pieces |= UInt64(1) << (ep_sqr - 1)
                board.bb_for[WHITE_PAWN] |= UInt64(1) << (ep_sqr - 1)
            elseif move.promoted_piece != NO_PIECE
                board.bb_for[move.promoted_piece] &= ~to_bb
            end
        end
    end # end if board.side_to_move == WHITE

    if move.castling == CASTLING_WK
        board.squares[8] = WHITE_ROOK
        board.squares[6] = NO_PIECE
        board.white_pieces &= ~(UInt64(1) << 5)
        board.white_pieces |= UInt64(1) << 7
        board.bb_for[WHITE_ROOK] &= ~(UInt64(1) << 5)
        board.bb_for[WHITE_ROOK] |= UInt64(1) << 7
    elseif move.castling == CASTLING_WQ
        board.squares[1] = WHITE_ROOK
        board.squares[4] = NO_PIECE
        board.white_pieces &= ~(UInt64(1) << 3)
        board.white_pieces |= UInt64(1) << 0
        board.bb_for[WHITE_ROOK] &= ~(UInt64(1) << 3)
        board.bb_for[WHITE_ROOK] |= UInt64(1) << 0
    elseif move.castling == CASTLING_BK
        board.squares[64] = BLACK_ROOK
        board.squares[62] = NO_PIECE
        board.black_pieces &= ~(UInt64(1) << 61)
        board.black_pieces |= UInt64(1) << 63
        board.bb_for[BLACK_ROOK] &= ~(UInt64(1) << 61)
        board.bb_for[BLACK_ROOK] |= UInt64(1) << 63
    elseif move.castling == CASTLING_BQ
        board.squares[57] = BLACK_ROOK
        board.squares[60] = NO_PIECE
        board.black_pieces &= ~(UInt64(1) << 59)
        board.black_pieces |= UInt64(1) << 56
        board.bb_for[BLACK_ROOK] &= ~(UInt64(1) << 59)
        board.bb_for[BLACK_ROOK] |= UInt64(1) << 56
    end # end if move.castling == ???

    board.side_to_move = board.side_to_move == WHITE ? BLACK : WHITE
    board.castling_rights = move.prior_castling_rights
    board.ep_square = move.prior_ep_sqr
end # unmake_move!()

function in_check(board::Board, color)
    if color == WHITE
        king_sqr = trailing_zeros(board.bb_for[WHITE_KING]) + 1
        attackers = (bishop_attacks(board, king_sqr) & (board.bb_for[BLACK_BISHOP] | board.bb_for[BLACK_QUEEN])) |
                    (rook_attacks(board, king_sqr) & (board.bb_for[BLACK_ROOK] | board.bb_for[BLACK_QUEEN])) |
                    (knight_attacks(board, king_sqr) & board.bb_for[BLACK_KNIGHT]) |
                    (pawn_attacks(board, king_sqr, WHITE) & board.bb_for[BLACK_PAWN]) |
                    (king_attacks(board, king_sqr) & board.bb_for[BLACK_KING])
        if attackers != 0
            return true
        end
    else 
        king_sqr = trailing_zeros(board.bb_for[BLACK_KING]) + 1
        attackers = (bishop_attacks(board, king_sqr) & (board.bb_for[WHITE_BISHOP] | board.bb_for[WHITE_QUEEN])) |
                    (rook_attacks(board, king_sqr) & (board.bb_for[WHITE_ROOK] | board.bb_for[WHITE_QUEEN])) |
                    (knight_attacks(board, king_sqr) & board.bb_for[WHITE_KNIGHT]) |
                    (pawn_attacks(board, king_sqr, BLACK) & board.bb_for[WHITE_PAWN]) |
                    (king_attacks(board, king_sqr) & board.bb_for[WHITE_KING])
        if attackers != 0
            return true
        end
    end
    return false
end # in_check()
