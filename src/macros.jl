macro print_as_bb(bb)
    quote
        println("")
        mask = 0xff00000000000000
        shift = 56
        for _ in 1:8
            println(join(c * " " for c in reverse(string((($bb & mask) >> shift), base=2, pad=8))))
            mask >>= 8
            shift -= 8
        end
    end
end

macro is_white(piece)
    esc(:((piece & 0b1000) == 0))
end

macro piece_type(piece)
    esc(:(piece & 0b0111))
end

macro piece_color(piece)
    esc(:(piece & 0b1000))
end