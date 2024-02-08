mutable struct Board
    # one 64 field array for the board  
    squares::Vector{UInt8}

    # twelve bitboards, one for each piece type
    bb_for::Vector{UInt64}

    # two bitboards, one for each side
    white_pieces::UInt64
    black_pieces::UInt64

    # flags
    ep_square::UInt8
    castling_rights::UInt8
    side_to_move::UInt8

    # counters
    halfmove_clock::UInt16
    fullmove_number::UInt16

end # Board

function Board()
    return Board(fill(0x00, 64), fill(0x0000000000000000, 16),  0x00000000, 0x00000000,  0x00, 0x00, 0x00,  0x0000, 0x0000)
end # Board()

function clear!(board::Board)
    for i in 1:64
        board.squares[i] = EMPTY
    end

    for i in 1:16
        board.bb_for[i] = 0x0000000000000000
    end

    board.white_pieces = 0x0000000000000000
    board.black_pieces = 0x0000000000000000

    board.ep_square = 0x00
    board.castling_rights = 0x00
    board.side_to_move = 0x00

    board.halfmove_clock = 0x0000
    board.fullmove_number = 0x0000
end # clear!

function set_piece!(board::Board, piece::UInt8, file::Int, rank::Int)
    square = (rank - 1) * 8 + file
    board.squares[square] = piece

    if @is_white(piece)
        board.white_pieces |= 1 << (square - 1)
    else
        board.black_pieces |= 1 << (square - 1)
    end

    board.bb_for[piece] |= 1 << (square - 1)
end # set_piece!

function set_by_fen!(board::Board, fen::String)
    fen = strip(fen)

    split_fen = split(fen, " ")
    if length(split_fen) != 6
        error("Invalid FEN string")
    end

    # CLEAR BOARD
    clear!(board)

    # BOARD POSITION
    position = split_fen[1]

    file = 1
    rank = 8
    for c in position
        if c == 'P' set_piece!(board, WHITE_PAWN, file, rank)
        elseif c == 'N' set_piece!(board, WHITE_KNIGHT, file, rank)
        elseif c == 'B' set_piece!(board, WHITE_BISHOP, file, rank)
        elseif c == 'R' set_piece!(board, WHITE_ROOK, file, rank)
        elseif c == 'Q' set_piece!(board, WHITE_QUEEN, file, rank)
        elseif c == 'K' set_piece!(board, WHITE_KING, file, rank)
        elseif c == 'p' set_piece!(board, BLACK_PAWN, file, rank)
        elseif c == 'n' set_piece!(board, BLACK_KNIGHT, file, rank)
        elseif c == 'b' set_piece!(board, BLACK_BISHOP, file, rank)
        elseif c == 'r' set_piece!(board, BLACK_ROOK, file, rank)
        elseif c == 'q' set_piece!(board, BLACK_QUEEN, file, rank)
        elseif c == 'k' set_piece!(board, BLACK_KING, file, rank)
        elseif isdigit(c) file += parse(Int, c)-1   
        elseif c == '/' rank -= 1; file = 0
        else error("Invalid FEN string")
        end
        file += 1
    end
    
    # SIDE TO MOVE
    side_to_move = split_fen[2]
    if side_to_move == "w" board.side_to_move = WHITE
    elseif side_to_move == "b" board.side_to_move = BLACK
    else error("Invalid FEN string")
    end

    # CASTLING RIGHTS
    castling_rights = split_fen[3]
    if castling_rights == "-" board.castling_rights = 0x00
    else
        board.castling_rights = 0x00
        for c in castling_rights
            if c == 'K' board.castling_rights |= CASTLING_WK
            elseif c == 'Q' board.castling_rights |= CASTLING_WQ
            elseif c == 'k' board.castling_rights |= CASTLING_BK
            elseif c == 'q' board.castling_rights |= CASTLING_BQ
            else error("Invalid FEN string")
            end
        end
    end

    # EN PASSANT SQUARE
    ep_square = split_fen[4]
    if ep_square == "-" board.ep_square = 0x00
    else
        if ep_square[1] < 'a' || ep_square[1] > 'h' || ep_square[2] < '1' || ep_square[2] > '8'
            error("Invalid FEN string")
        end
        
        file = ep_square[1] - 'a' + 1
        rank = ep_square[2] - '1' + 1
        board.ep_square = (rank - 1) * 8 + file
    end

    # HALFMOVE CLOCK
    halfmove_clock = split_fen[5]
    try
        board.halfmove_clock = parse(Int, halfmove_clock)
    catch
        error("Invalid FEN string")
    end

    # FULLMOVE NUMBER
    fullmove_number = split_fen[6]
    try
        board.fullmove_number = parse(Int, fullmove_number)
    catch
        error("Invalid FEN string")
    end
end # set_by_fen!

function Base.copy(board::Board)
    return Board(
        copy(board.squares),
        copy(board.bb_for),
        board.white_pieces,
        board.black_pieces,
        board.ep_square,
        board.castling_rights,
        board.side_to_move,
        board.halfmove_clock,
        board.fullmove_number
    )
end # copy

function Base.show(io::IO, board::Board) 
    println(io, "")
    println(io, "Board:\n")
    rank = 8
    while rank >= 1
        file = 1
        while file <= 8
            square = (rank - 1) * 8 + file
            piece = board.squares[square]
            if piece == EMPTY
                print(io, "- ")
            else
                print(io, CHARACTERS[piece], " ")
            end
            file += 1
        end
        if rank != 1
            println(io, "")
        end
        rank -= 1
    end

    println(io, "")

    if io == stderr
        println(io, "")
        println(io, "White Pawns:        White Knights:      White Bishops:      White Rooks:        White Queens:       White King:       White Pieces:\n")
        mask::UInt64 = 0xff00000000000000
        shift = 56
        for _ in 1:8
            println(io, join(c * " " for c in reverse(string(((board.bb_for[WHITE_PAWN] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.bb_for[WHITE_KNIGHT] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.bb_for[WHITE_BISHOP] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.bb_for[WHITE_ROOK] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.bb_for[WHITE_QUEEN] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.bb_for[WHITE_KING] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.white_pieces & mask) >> shift), base=2, pad=8))))
            mask >>= 8
            shift -= 8
        end

        println(io, "")
        println(io, "Black Pawns:        Black Knights:      Black Bishops:      Black Rooks:        Black Queens:       Black King:       Black Pieces:\n")
        mask = 0xff00000000000000
        shift = 56
        for _ in 1:8
            println(io, join(c * " " for c in reverse(string(((board.bb_for[BLACK_PAWN] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.bb_for[BLACK_KNIGHT] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.bb_for[BLACK_BISHOP] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.bb_for[BLACK_ROOK] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.bb_for[BLACK_QUEEN] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.bb_for[BLACK_KING] & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.black_pieces & mask) >> shift), base=2, pad=8))))
            mask >>= 8
            shift -= 8
        end
        
        println(io, "")
        println(io, "Side to move: ", board.side_to_move == WHITE ? "White" : "Black")
        println(io, "Castling rights: ", string(board.castling_rights, base=2, pad=4))
        println(io, "En passant square: ", board.ep_square == 0x00 ? "-" : 'a' + (board.ep_square - 1) % 8, '1' + (board.ep_square - 1) ÷ 8)

    end
end # show

function extract_fen(board::Board)
    fen = ""
    for rank in 8:-1:1
        empty = 0
        for file in 1:8
            square = (rank - 1) * 8 + file
            piece = board.squares[square]
            if piece == EMPTY
                empty += 1
            else
                if empty != 0
                    fen *= string(empty)
                    empty = 0
                end
                fen *= CHARACTERS[piece]
            end
        end
        if empty != 0
            fen *= string(empty)
        end
        if rank != 1
            fen *= "/"
        end
    end

    fen *= " "
    fen *= board.side_to_move == WHITE ? "w" : "b"
    fen *= " "
    if board.castling_rights == 0x00
        fen *= "-"
    else
        if board.castling_rights & CASTLING_WK != 0 fen *= "K" end
        if board.castling_rights & CASTLING_WQ != 0 fen *= "Q" end
        if board.castling_rights & CASTLING_BK != 0 fen *= "k" end
        if board.castling_rights & CASTLING_BQ != 0 fen *= "q" end
    end
    fen *= " "
    fen *= board.ep_square == 0x00 ? '-' : begin ('a' + (board.ep_square - 1) % 8) * ('1' + (board.ep_square - 1) ÷ 8) end
    fen *= " "
    fen *= string(board.halfmove_clock)
    fen *= " "
    fen *= string(board.fullmove_number)

    return fen
end # extract_fen