extends Node
## Game flow: new game / resume / placement / clearing / game over / revive / daily challenge.

signal state_changed
signal score_changed(score: int, delta: int)
signal piece_placed(cells: Array, color: int)
signal lines_cleared(info: Array, lines: int, combo: int, gained: int)
signal pieces_refilled
signal game_over(final_score: int, new_best: bool)
signal daily_completed

const DAILY_TARGET := 2000
const SCORE_PER_LEVEL := 1500

var pieces: Array = [null, null, null]
var mode := "classic"
var playing := false
var revive_used := false
var daily_key := ""
var rng := RandomNumberGenerator.new()
var _best_at_start := 0

func level() -> int:
    return 1 + floori(ScoreManager.score / float(SCORE_PER_LEVEL))

func saved_level(m: String) -> int:
    var s := SaveManager.get_session(m)
    if s.is_empty():
        return 1
    return 1 + floori(int(s.get("score", 0)) / float(SCORE_PER_LEVEL))

func today_key() -> String:
    var d := Time.get_date_dict_from_system()
    return "%04d-%02d-%02d" % [d.year, d.month, d.day]

func daily_done() -> bool:
    return str(SaveManager.data.get("daily_done", "")) == today_key()

func has_session(m: String) -> bool:
    var s := SaveManager.get_session(m)
    if s.is_empty():
        return false
    if m == "daily" and str(s.get("daily_key", "")) != today_key():
        SaveManager.clear_session(m)
        return false
    return true

func new_game(m: String = "classic") -> void:
    mode = m
    BoardManager.reset()
    ScoreManager.reset(0)
    revive_used = false
    if mode == "daily":
        daily_key = today_key()
        rng.seed = hash(daily_key)
    else:
        rng.randomize()
    pieces = PieceManager.generate_three(rng)
    playing = true
    _best_at_start = SaveManager.get_best()
    save_session()
    state_changed.emit()
    score_changed.emit(0, 0)

func resume_session(m: String) -> bool:
    if not has_session(m):
        return false
    var s := SaveManager.get_session(m)
    if not BoardManager.from_array(s.get("board", [])):
        SaveManager.clear_session(m)
        return false
    var loaded: Array = []
    for p in s.get("pieces", []):
        if p == null:
            loaded.append(null)
        else:
            var id := int(p["id"])
            if id < 0 or id >= PieceManager.shapes.size():
                SaveManager.clear_session(m)
                return false
            loaded.append({"id": id, "color": clampi(int(p["color"]), 1, 5)})
    if loaded.size() != 3:
        SaveManager.clear_session(m)
        return false
    mode = m
    pieces = loaded
    ScoreManager.reset(int(s.get("score", 0)))
    ScoreManager.combo = int(s.get("combo", 0))
    revive_used = bool(s.get("revive_used", false))
    daily_key = str(s.get("daily_key", ""))
    rng.seed = str(s.get("rng_seed", "1")).to_int()
    rng.state = str(s.get("rng_state", "1")).to_int()
    _best_at_start = int(s.get("best_at_start", SaveManager.get_best()))
    if not has_valid_move():
        SaveManager.clear_session(m)
        return false
    playing = true
    state_changed.emit()
    score_changed.emit(ScoreManager.score, 0)
    return true

func save_session() -> void:
    if not playing:
        return
    _update_best()
    var plist: Array = []
    for p in pieces:
        plist.append(null if p == null else {"id": p.id, "color": p.color})
    SaveManager.set_session(mode, {
        "score": ScoreManager.score,
        "combo": ScoreManager.combo,
        "board": BoardManager.to_array(),
        "pieces": plist,
        "revive_used": revive_used,
        "daily_key": daily_key,
        "rng_seed": str(rng.seed),
        "rng_state": str(rng.state),
        "best_at_start": _best_at_start,
    })
    SaveManager.save_data()

func has_valid_move() -> bool:
    for p in pieces:
        if p != null and BoardManager.can_fit_anywhere(PieceManager.cells_of(p.id)):
            return true
    return false

func place_piece(slot: int, ox: int, oy: int) -> bool:
    if not playing or slot < 0 or slot > 2 or pieces[slot] == null:
        return false
    var p = pieces[slot]
    var cells := PieceManager.cells_of(p.id)
    if not BoardManager.can_place(cells, ox, oy):
        return false
    BoardManager.place(cells, ox, oy, p.color)
    var placed: Array = []
    for c in cells:
        placed.append(Vector2i(ox + c.x, oy + c.y))
    pieces[slot] = null
    piece_placed.emit(placed, p.color)

    var gained := ScoreManager.on_place(cells.size())
    # Detect every complete row/column BEFORE clearing anything.
    var lines := BoardManager.find_full_lines()
    var n: int = lines.rows.size() + lines.cols.size()
    if n > 0:
        var info := BoardManager.clear_lines(lines.rows, lines.cols)
        var pts := ScoreManager.on_clear(n)
        gained += pts
        lines_cleared.emit(info, n, ScoreManager.combo, pts)
    else:
        ScoreManager.on_no_clear()
    score_changed.emit(ScoreManager.score, gained)

    if pieces[0] == null and pieces[1] == null and pieces[2] == null:
        pieces = PieceManager.generate_three(rng)
        pieces_refilled.emit()
    state_changed.emit()

    if mode == "daily" and ScoreManager.score >= DAILY_TARGET and not daily_done():
        SaveManager.data["daily_done"] = today_key()
        SaveManager.save_data()
        daily_completed.emit()

    if not has_valid_move():
        _end_game()
    else:
        save_session()
    return true

func _update_best() -> void:
    if ScoreManager.score > SaveManager.get_best():
        SaveManager.set_best(ScoreManager.score)

func _end_game() -> void:
    playing = false
    var new_best := ScoreManager.score > _best_at_start and ScoreManager.score > 0
    _update_best()
    SaveManager.clear_session(mode)
    SaveManager.data["games_played"] = int(SaveManager.data.get("games_played", 0)) + 1
    SaveManager.save_data()
    AdManager.register_session_end()
    game_over.emit(ScoreManager.score, new_best)

func can_revive() -> bool:
    return not revive_used and not playing and ScoreManager.score > 0

## Fair revive (one per game): clears the 3 fullest rows and deals pieces that can be placed.
func revive() -> void:
    if not can_revive():
        return
    revive_used = true
    var counts: Array = []
    for y in BoardManager.SIZE:
        var n := 0
        for x in BoardManager.SIZE:
            if BoardManager.grid[y][x] != 0:
                n += 1
        counts.append({"y": y, "n": n})
    counts.sort_custom(func(a, b): return a.n > b.n)
    var info: Array = []
    for i in 3:
        var y: int = counts[i].y
        for x in BoardManager.SIZE:
            if BoardManager.grid[y][x] != 0:
                info.append({"cell": Vector2i(x, y), "color": BoardManager.grid[y][x]})
                BoardManager.grid[y][x] = 0
    lines_cleared.emit(info, 0, 0, 0)
    for attempt in 50:
        pieces = PieceManager.generate_three(rng)
        if has_valid_move():
            break
    playing = true
    pieces_refilled.emit()
    state_changed.emit()
    save_session()
