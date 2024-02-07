const CHARACTERS = ['E', 'E', 'E', 'E', 'P', 'p', 'E', 'E', 'N', 'n','E', 'E', 'B', 'b', 'E', 'E', 'R', 'r','E', 'E', 'Q', 'q','E', 'E', 'K', 'k']

const WHITE = 0x01
const BLACK = 0x02

const EMPTY = 0x00

const PAWN = 0x01 << 0x02
const KNIGHT = 0x02 << 0x02
const BISHOP = 0x03 << 0x02
const ROOK = 0x04 << 0x02
const QUEEN = 0x05 << 0x02
const KING = 0x06 << 0x02

const WHITE_PAWN = PAWN | WHITE
const WHITE_KNIGHT = KNIGHT | WHITE
const WHITE_BISHOP = BISHOP | WHITE
const WHITE_ROOK = ROOK | WHITE
const WHITE_QUEEN = QUEEN | WHITE
const WHITE_KING = KING | WHITE

const BLACK_PAWN = PAWN | BLACK
const BLACK_KNIGHT = KNIGHT | BLACK
const BLACK_BISHOP = BISHOP | BLACK
const BLACK_ROOK = ROOK | BLACK
const BLACK_QUEEN = QUEEN | BLACK
const BLACK_KING = KING | BLACK

const CASTLING_WK = 0x01 << 0x0
const CASTLING_WQ = 0x01 << 0x01
const CASTLING_BK = 0x01 << 0x02
const CASTLING_BQ = 0x01 << 0x03
