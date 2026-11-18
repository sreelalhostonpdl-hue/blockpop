extends Node
## Scoring: 10/placed block, line-clear table, combo bonus for consecutive clearing moves.

const LINE_POINTS := [0, 100, 250, 450, 700]
const POINTS_PER_BLOCK := 10
const COMBO_STEP := 50

var score := 0
var combo := 0

func reset(start_score: int = 0) -> void:
    score = start_score
    combo = 0

func on_place(block_count: int) -> int:
    var p := POINTS_PER_BLOCK * block_count
    score += p
    return p

## Returns total points awarded for clearing `lines` lines in one move (base + combo bonus).
func on_clear(lines: int) -> int:
    var base: int = LINE_POINTS[lines] if lines < LINE_POINTS.size() else LINE_POINTS[4] + (lines - 4) * 300
    combo += 1
    var bonus := (combo - 1) * COMBO_STEP
    var total := base + bonus
    score += total
    return total

func on_no_clear() -> void:
    combo = 0
