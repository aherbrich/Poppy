mutable struct Move 
    piece::UInt8
    from_sqr::UInt8
    to_sqr::UInt8
    captured_piece::UInt8
    is_ep_capture::Bool
    promoted_piece::UInt8
    castling::UInt8
    ep_sqr::UInt8
end

function Move(piece::UInt8, from_sqr::UInt8, to_sqr::UInt8, captured_piece::UInt8, is_ep_capture::Bool, promoted_piece::UInt8, castling::UInt8, ep_sqr::UInt8)
    return Move(piece, from_sqr, to_sqr, captured_piece, is_ep_capture, promoted_piece, castling, ep_sqr)
end

function Base.show(io::IO, move::Move)
    piece_type = move.piece & ~0x03
    if piece_type == PAWN print(io, '♙')
    elseif piece_type == KNIGHT print(io, '♘')
    elseif piece_type == BISHOP print(io, '♗')
    elseif piece_type == ROOK print(io, '♖')
    elseif piece_type == QUEEN print(io, '♕')
    elseif piece_type == KING print(io, '♔')
    end
    
    print(io, string('a' + ((move.from_sqr-1) & 0x07)), string('1' + ((move.from_sqr-1) >> 0x03)))
    print(io, string('a' + ((move.to_sqr-1) & 0x07)), string('1' + ((move.to_sqr-1) >> 0x03)))
    if move.promoted_piece != NO_PIECE
        piece_type = move.promoted_piece & ~0x03
        if piece_type == PAWN print(io, '♙')
        elseif piece_type == KNIGHT print(io, '♘')
        elseif piece_type == BISHOP print(io, '♗')
        elseif piece_type == ROOK print(io, '♖')
        elseif piece_type == QUEEN print(io, '♕')
        elseif piece_type == KING print(io, '♔')
        end
    end
end