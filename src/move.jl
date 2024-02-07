mutable struct Move 
    piece::UInt8
    from_sqr::UInt8
    to_sqr::UInt8
    captured_piece::UInt8
    promoted_piece::UInt8
    castling_rights_delta::Int8
    ep_sqr_delta::Int8
end

function Move(piece::UInt8, from_sqr::UInt8, to_sqr::UInt8, captured_piece::UInt8, promoted_piece::UInt8, castling_rights_delta::Int8, ep_sqr_delta::Int8)
    return Move(piece, from_sqr, to_sqr, captured_piece, promoted_piece, castling_rights_delta, ep_sqr_delta)
end