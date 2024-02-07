using nuthead
using Test

macro namedtest(name, test)
    esc(:(@testset $name begin @test $test end))
end

@testset "nuthead.jl" begin
    @testset "board.jl" begin
        @testset "Set & Extract FEN" begin
            positions = readlines("data/perft.txt")
            for position in positions
                fen, _ = split(position, ";")
                fen = string(strip(fen))
                @namedtest "$fen" begin
                    board = Board()
                    set_by_fen!(board, fen)
                    extract_fen(board) == fen
                end
            end
        end
    end
end
