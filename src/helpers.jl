function print_bb(bb)
    mask = 0xff00000000000000
    shift = 56
    for _ in 1:8
        println(join(c * " " for c in reverse(string(((bb & mask) >> shift), base=2, pad=8))))
        mask >>= 8
        shift -= 8
    end
end