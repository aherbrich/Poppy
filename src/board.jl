mutable struct Board
    # one 64 field array for the board  
    squares::Array{UInt8, 1}

    # twelve bitboards, one for each piece type
    white_pawns::UInt64
    white_knights::UInt64
    white_bishops::UInt64
    white_rooks::UInt64
    white_queens::UInt64
    white_king::UInt64
    black_pawns::UInt64
    black_knights::UInt64
    black_bishops::UInt64
    black_rooks::UInt64
    black_queens::UInt64
    black_king::UInt64

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
    return Board(
        fill(0x00, 64),
        0x00000000,
        0x00000000,
        0x00000000,
        0x00000000,
        0x00000000,
        0x00000000,
        0x00000000,
        0x00000000,
        0x00000000,
        0x00000000,
        0x00000000,
        0x00000000,

        0x00000000,
        0x00000000,

        0x00,
        0x00,
        0x00,

        0x0000,
        0x0000
    )
end # Board


function clear!(board::Board)
    for i in 1:64
        board.squares[i] = EMPTY
    end

    board.white_pawns = 0x0000000000000000
    board.white_knights = 0x0000000000000000
    board.white_bishops = 0x0000000000000000
    board.white_rooks = 0x0000000000000000
    board.white_queens = 0x0000000000000000
    board.white_king = 0x0000000000000000
    board.black_pawns = 0x0000000000000000
    board.black_knights = 0x0000000000000000
    board.black_bishops = 0x0000000000000000
    board.black_rooks = 0x0000000000000000
    board.black_queens = 0x0000000000000000
    board.black_king = 0x0000000000000000

    board.white_pieces = 0x0000000000000000
    board.black_pieces = 0x0000000000000000

    board.ep_square = 0x00
    board.castling_rights = 0x00
    board.side_to_move = 0x00

    board.halfmove_clock = 0x0000
    board.fullmove_number = 0x0000
end

function set_piece!(board::Board, piece::UInt8, file::Int, rank::Int)
    square = (rank - 1) * 8 + file
    board.squares[square] = piece

    if piece & WHITE != 0
        board.white_pieces |= 1 << (square - 1)
    else
        board.black_pieces |= 1 << (square - 1)
    end

    if piece == WHITE_PAWN
        board.white_pawns |= 1 << (square - 1)
    elseif piece == WHITE_KNIGHT
        board.white_knights |= 1 << (square - 1)
    elseif piece == WHITE_BISHOP
        board.white_bishops |= 1 << (square - 1)
    elseif piece == WHITE_ROOK
        board.white_rooks |= 1 << (square - 1)
    elseif piece == WHITE_QUEEN
        board.white_queens |= 1 << (square - 1)
    elseif piece == WHITE_KING
        board.white_king |= 1 << (square - 1)
    elseif piece == BLACK_PAWN
        board.black_pawns |= 1 << (square - 1)
    elseif piece == BLACK_KNIGHT
        board.black_knights |= 1 << (square - 1)
    elseif piece == BLACK_BISHOP
        board.black_bishops |= 1 << (square - 1)
    elseif piece == BLACK_ROOK
        board.black_rooks |= 1 << (square - 1)
    elseif piece == BLACK_QUEEN
        board.black_queens |= 1 << (square - 1)
    elseif piece == BLACK_KING
        board.black_king |= 1 << (square - 1)
    end
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
        board.white_pawns,
        board.white_knights,
        board.white_bishops,
        board.white_rooks,
        board.white_queens,
        board.white_king,
        board.black_pawns,
        board.black_knights,
        board.black_bishops,
        board.black_rooks,
        board.black_queens,
        board.black_king,
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
            println(io, join(c * " " for c in reverse(string(((board.white_pawns & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.white_knights & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.white_bishops & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.white_rooks & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.white_queens & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.white_king & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.white_pieces & mask) >> shift), base=2, pad=8))))
            mask >>= 8
            shift -= 8
        end

        println(io, "")
        println(io, "Black Pawns:        Black Knights:      Black Bishops:      Black Rooks:        Black Queens:       Black King:       Black Pieces:\n")
        mask = 0xff00000000000000
        shift = 56
        for _ in 1:8
            println(io, join(c * " " for c in reverse(string(((board.black_pawns & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.black_knights & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.black_bishops & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.black_rooks & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.black_queens & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.black_king & mask) >> shift), base=2, pad=8))), "    ", join(c * " " for c in reverse(string(((board.black_pieces & mask) >> shift), base=2, pad=8))))
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