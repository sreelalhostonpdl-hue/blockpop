extends Node
## Headless logic tests.  Run:  godot --headless --import   (once)
##                           godot --headless res://tests/TestRunner.tscn
var fails := 0

func check(cond: bool, msg: String) -> void:
    if cond:
        print("  PASS  ", msg)
    else:
        print("  FAIL  ", msg)
        fails += 1

func _ready() -> void:
    await get_tree().process_frame
    test_shapes()
    test_board()
    test_intersecting_clear()
    test_scoring()
    test_generation()
    test_game_over_and_session()
    print("\nRESULT: %s (%d failures)" % ["OK" if fails == 0 else "FAILED", fails])
    get_tree().quit(1 if fails > 0 else 0)

func test_shapes() -> void:
    print("shapes")
    check(PieceManager.shapes.size() >= 20, "at least 20 shapes (%d)" % PieceManager.shapes.size())
    var keys := {}
    var dup := false
    for s in PieceManager.shapes:
        var k := PieceManager._key(s.cells)
        if keys.has(k):
            dup = true
        keys[k] = true
    check(not dup, "no duplicate shapes")

func test_board() -> void:
    print("board")
    BoardManager.reset()
    var cells := [Vector2i(0, 0), Vector2i(1, 0)]
    check(BoardManager.can_place(cells, 8, 0), "fits at right edge")
    check(not BoardManager.can_place(cells, 9, 0), "rejects out of bounds")
    BoardManager.place(cells, 0, 0, 1)
    check(not BoardManager.can_place(cells, 1, 0), "rejects overlap")
    check(BoardManager.filled_count() == 2, "filled count")

func test_intersecting_clear() -> void:
    print("intersecting clear")
    BoardManager.reset()
    for i in 10:
        BoardManager.grid[3][i] = 1
        BoardManager.grid[i][4] = 2
    var lines := BoardManager.find_full_lines()
    check(lines.rows == [3] and lines.cols == [4], "detects 1 row + 1 col")
    var info := BoardManager.clear_lines(lines.rows, lines.cols)
    check(info.size() == 19, "19 unique cells (intersection counted once): %d" % info.size())
    check(BoardManager.filled_count() == 0, "board empty after simultaneous clear")

func test_scoring() -> void:
    print("scoring")
    var expected := [0, 100, 250, 450, 700]
    for n in [1, 2, 3, 4]:
        ScoreManager.reset(0)
        check(ScoreManager.on_clear(n) == expected[n], "%d line(s) = %d" % [n, expected[n]])
    ScoreManager.reset(0)
    ScoreManager.on_clear(1)
    check(ScoreManager.on_clear(1) == 150, "second consecutive clear gets +50 combo bonus")
    ScoreManager.reset(0)
    check(ScoreManager.on_place(4) == 40, "10 points per placed block")

func test_generation() -> void:
    print("generation")
    var rng := RandomNumberGenerator.new()
    rng.seed = 42
    var ok := true
    for t in 300:
        BoardManager.reset()
        var n := rng.randi() % 70
        for k in n:
            BoardManager.grid[rng.randi() % 10][rng.randi() % 10] = 1
        var set := PieceManager.generate_three(rng)
        if set.size() != 3:
            ok = false
    check(ok, "always returns 3 pieces")
    BoardManager.reset()
    var fair := true
    for t in 200:
        var set := PieceManager.generate_three(rng)
        var any := false
        for p in set:
            if BoardManager.can_fit_anywhere(PieceManager.cells_of(p.id)):
                any = true
        if not any:
            fair = false
    check(fair, "at least one generated piece fits an empty board")

func test_game_over_and_session() -> void:
    print("game over + session")
    GameManager.new_game("classic")
    for y in 10:
        for x in 10:
            BoardManager.grid[y][x] = 1
    BoardManager.grid[5][5] = 0
    GameManager.pieces = [{"id": 1, "color": 1}, null, null]  # id 1 is a 2-cell piece
    check(not GameManager.has_valid_move(), "no valid move detected when only a 1-cell hole remains")
    GameManager.new_game("classic")
    var single_id := -1
    for i in PieceManager.shapes.size():
        if PieceManager.shapes[i].n == 1:
            single_id = i
    GameManager.pieces = [{"id": single_id, "color": 2}, null, null]
    GameManager.place_piece(0, 0, 0)
    GameManager.save_session()
    var saved_score := ScoreManager.score
    BoardManager.reset()
    ScoreManager.reset(0)
    check(GameManager.resume_session("classic"), "session resumes")
    check(BoardManager.grid[0][0] == 2 and ScoreManager.score == saved_score, "board + score restored")
    SaveManager.clear_session("classic")
