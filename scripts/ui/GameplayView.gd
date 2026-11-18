extends Control
## Board + tray rendering and all touch interaction (drag & drop, tap-select + tap-place),
## placement preview, snap/pop animation, line-clear ghosts, particles and score pop-ups.
const UI = preload("res://scripts/ui/UITheme.gd")

const TOP_MARGIN := 430.0
const GHOST_TIME := 0.38

var cell := 80.0
var board_pos := Vector2.ZERO
var board_px := 800.0
var tray_cell := 50.0
var tray_y := 1500.0
var slot_w := 360.0

var dragging := -1
var selected := -1
var drag_pos := Vector2.ZERO
var press_pos := Vector2.ZERO
var moved := false
var prev_origin := Vector2i(-100, -100)
var prev_valid := false

var particles: Array = []
var ghosts: Array = []
var pops: Dictionary = {}
var tray_anim := 1.0
var _last_cell := Vector2(5, 5)
var _cache: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    resized.connect(_recalc)
    _recalc()
    GameManager.piece_placed.connect(_on_piece_placed)
    GameManager.lines_cleared.connect(_on_lines_cleared)
    GameManager.pieces_refilled.connect(_on_refilled)
    GameManager.state_changed.connect(queue_redraw)

func _recalc() -> void:
    var w := size.x
    var h := size.y
    board_px = maxf(200.0, minf(w - 80.0, (h - TOP_MARGIN) * 0.64))
    cell = board_px / 10.0
    board_pos = Vector2((w - board_px) * 0.5, TOP_MARGIN)
    var bottom := board_pos.y + board_px
    tray_y = bottom + minf((h - bottom) * 0.5, 280.0) + 10.0
    slot_w = w / 3.0
    tray_cell = minf(cell * 0.62, slot_w / 5.4)
    _cache.clear()
    queue_redraw()

# ------------------------------------------------------------------ drawing helpers
func _box(key: String, bg: Color, radius: float, border_b: float = 0.0, border_col: Color = Color.BLACK) -> StyleBoxFlat:
    bg.a = snappedf(bg.a, 0.1)
    var k := "%s_%s_%d_%d" % [key, bg.to_html(true), int(radius), int(border_b)]
    if _cache.has(k):
        return _cache[k]
    if _cache.size() > 400:
        _cache.clear()
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.set_corner_radius_all(int(radius))
    if border_b > 0.0:
        sb.border_width_bottom = int(border_b)
        sb.border_color = border_col
    _cache[k] = sb
    return sb

func _draw_block(p: Vector2, s: float, col: Color, scale_f: float = 1.0, alpha: float = 1.0) -> void:
    var gap := s * 0.05
    var sz := s - gap * 2.0
    var rect := Rect2(p + Vector2(gap, gap), Vector2(sz, sz))
    if scale_f != 1.0:
        var c := rect.get_center()
        rect = Rect2(c - rect.size * 0.5 * scale_f, rect.size * scale_f)
    var base := Color(col.r, col.g, col.b, alpha)
    var dark := Color(col.r * 0.5, col.g * 0.5, col.b * 0.6, alpha)
    draw_style_box(_box("b", base, rect.size.x * 0.24, rect.size.x * 0.08, dark), rect)
    var hl := Rect2(rect.position + rect.size * Vector2(0.14, 0.09), rect.size * Vector2(0.72, 0.32))
    draw_style_box(_box("h", Color(1, 1, 1, 0.3 * alpha), hl.size.x * 0.28), hl)

func _draw_piece(cells: Array, top_left: Vector2, s: float, col: Color, scale_f: float = 1.0, alpha: float = 1.0, size_px: Vector2 = Vector2.ZERO) -> void:
    var center := top_left + size_px * 0.5
    for c in cells:
        var p := top_left + Vector2(c.x, c.y) * s
        if scale_f != 1.0:
            p = center + (p - center) * scale_f
        _draw_block(p, s * scale_f if scale_f != 1.0 else s, col, 1.0, alpha)

func _slot_rect(i: int) -> Rect2:
    return Rect2(i * slot_w, tray_y - 175.0, slot_w, 350.0)

func _draw() -> void:
    # board panel
    var pr := Rect2(board_pos - Vector2(18, 18), Vector2(board_px + 36, board_px + 36))
    var panel := _box("panel", Color(0.04, 0.05, 0.17, 0.85), 38.0, 6.0, Color(1, 1, 1, 0.08))
    draw_style_box(panel, pr)
    var empty := _box("e", Color(1, 1, 1, 0.07), cell * 0.2)
    var inset := cell * 0.05
    for y in BoardManager.SIZE:
        for x in BoardManager.SIZE:
            var p := board_pos + Vector2(x, y) * cell
            var v: int = BoardManager.grid[y][x]
            if v == 0:
                draw_style_box(empty, Rect2(p + Vector2(inset, inset), Vector2(cell - inset * 2.0, cell - inset * 2.0)))
            else:
                var sc := 1.0
                var key := Vector2i(x, y)
                if pops.has(key):
                    sc = 1.0 + 0.2 * float(pops[key])
                _draw_block(p, cell, PieceManager.color_of(v), sc)

    # placement preview (+ highlight lines that would complete)
    if dragging >= 0 and moved and prev_valid and GameManager.pieces[dragging] != null:
        var pc = GameManager.pieces[dragging]
        var cells := PieceManager.cells_of(pc.id)
        var col := PieceManager.color_of(pc.color)
        for e in _preview_lines(cells, prev_origin):
            var rp := board_pos + Vector2(e.x, e.y) * cell
            draw_style_box(_box("glow", Color(1, 1, 1, 0.2), cell * 0.2), Rect2(rp + Vector2(inset, inset), Vector2(cell - inset * 2.0, cell - inset * 2.0)))
        for c in cells:
            var p := board_pos + Vector2(prev_origin.x + c.x, prev_origin.y + c.y) * cell
            _draw_block(p, cell, col, 1.0, 0.45)

    # tray
    for i in 3:
        var pc = GameManager.pieces[i]
        if pc == null:
            continue
        var sh = PieceManager.shapes[pc.id]
        var col := PieceManager.color_of(pc.color)
        var local := clampf(tray_anim * 1.7 - i * 0.2, 0.0, 1.0)
        var sc := local + sin(local * PI) * 0.14
        if selected == i:
            sc *= 1.12
        var alpha := 0.25 if (i == dragging and moved) else 1.0
        var sz := Vector2(sh.w, sh.h) * tray_cell
        var center := Vector2(slot_w * (i + 0.5), tray_y)
        _draw_piece(sh.cells, center - sz * 0.5, tray_cell, col, sc, alpha, sz)

    # dragged piece (with soft shadow)
    if dragging >= 0 and moved and GameManager.pieces[dragging] != null:
        var pc = GameManager.pieces[dragging]
        var sh = PieceManager.shapes[pc.id]
        var tl := _drag_topleft(dragging)
        _draw_piece(sh.cells, tl + Vector2(0, cell * 0.16), cell, Color(0, 0, 0), 1.0, 0.28, Vector2(sh.w, sh.h) * cell)
        _draw_piece(sh.cells, tl, cell, PieceManager.color_of(pc.color), 1.0, 1.0, Vector2(sh.w, sh.h) * cell)

    # line-clear ghosts
    for g in ghosts:
        if g.t < 0.0:
            continue
        var pr2: float = clampf(g.t / GHOST_TIME, 0.0, 1.0)
        var gc: Color = g.color
        gc = gc.lerp(Color.WHITE, 0.7 * (1.0 - pr2))
        var gs := 1.0 - pr2 * 0.75 + sin(pr2 * PI) * 0.3
        _draw_block(board_pos + Vector2(g.cell.x, g.cell.y) * cell, cell, gc, gs, 1.0 - pr2)

    # particles
    for q in particles:
        if q.d > 0.0:
            continue
        var a: float = clampf(q.life / q.max, 0.0, 1.0)
        var pcol: Color = q.c
        draw_circle(q.p, q.s * (0.4 + 0.6 * a), Color(pcol.r, pcol.g, pcol.b, a))

func _preview_lines(cells: Array, o: Vector2i) -> Array:
    var occ := {}
    for c in cells:
        occ[Vector2i(o.x + c.x, o.y + c.y)] = true
    var out: Array = []
    for y in BoardManager.SIZE:
        var full := true
        for x in BoardManager.SIZE:
            if BoardManager.grid[y][x] == 0 and not occ.has(Vector2i(x, y)):
                full = false
                break
        if full:
            for x in BoardManager.SIZE:
                out.append(Vector2i(x, y))
    for x in BoardManager.SIZE:
        var full := true
        for y in BoardManager.SIZE:
            if BoardManager.grid[y][x] == 0 and not occ.has(Vector2i(x, y)):
                full = false
                break
        if full:
            for y in BoardManager.SIZE:
                out.append(Vector2i(x, y))
    return out

# ------------------------------------------------------------------ animation loop
func _process(delta: float) -> void:
    var active := dragging >= 0 and moved
    if not particles.is_empty():
        active = true
        var i := particles.size() - 1
        while i >= 0:
            var q = particles[i]
            if q.d > 0.0:
                q.d -= delta
            else:
                q.life -= delta
                if q.life <= 0.0:
                    particles.remove_at(i)
                else:
                    var v: Vector2 = q.v
                    v.y += 1900.0 * delta
                    q.v = v
                    q.p = q.p + v * delta
            i -= 1
    if not ghosts.is_empty():
        active = true
        var i := ghosts.size() - 1
        while i >= 0:
            ghosts[i].t += delta
            if ghosts[i].t > GHOST_TIME:
                ghosts.remove_at(i)
            i -= 1
    if not pops.is_empty():
        active = true
        for k in pops.keys():
            pops[k] -= delta / 0.22
            if pops[k] <= 0.0:
                pops.erase(k)
    if tray_anim < 1.0:
        active = true
    if active:
        queue_redraw()

# ------------------------------------------------------------------ game signals
func _on_piece_placed(cells: Array, _color: int) -> void:
    var sum := Vector2.ZERO
    for c in cells:
        pops[c] = 1.0
        sum += Vector2(c)
    _last_cell = sum / maxf(1.0, float(cells.size()))
    AudioManager.play("place", randf_range(0.95, 1.08))
    AudioManager.haptic(18)

func _on_refilled() -> void:
    tray_anim = 0.0
    create_tween().tween_property(self, "tray_anim", 1.0, 0.45)

func _on_lines_cleared(info: Array, lines: int, combo: int, gained: int) -> void:
    if info.is_empty():
        return
    var per_cell := 4 if info.size() <= 30 else 2
    var sum := Vector2.ZERO
    for e in info:
        var c: Vector2i = e.cell
        var col: Color = PieceManager.color_of(e.color)
        var dist := Vector2(c).distance_to(_last_cell)
        var delay := 0.022 * dist
        ghosts.append({"cell": c, "color": col, "t": -delay})
        var cp := board_pos + (Vector2(c) + Vector2(0.5, 0.5)) * cell
        sum += cp
        for k in per_cell:
            var ang := randf() * TAU
            var spd := randf_range(250.0, 800.0)
            particles.append({
                "p": cp, "v": Vector2(cos(ang), sin(ang)) * spd - Vector2(0, 250),
                "c": col.lerp(Color.WHITE, randf() * 0.4), "life": randf_range(0.45, 0.9),
                "max": 0.9, "s": randf_range(5.0, 11.0), "d": delay})
    var center := sum / float(info.size())
    if gained == 0:
        _popup("FRESH START!", center, UI.CYAN, 80)
        AudioManager.play("clear")
        return
    var title := ""
    match lines:
        1: title = "NICE!"
        2: title = "DOUBLE!"
        3: title = "TRIPLE!"
        _: title = "AMAZING!"
    _popup(title, center - Vector2(0, 40), UI.GOLD if lines < 3 else UI.PINK, 84 + lines * 6)
    _popup("+%d" % gained, center + Vector2(0, 50), Color.WHITE, 64)
    if combo >= 2:
        _popup("COMBO x%d" % combo, center + Vector2(0, 130), UI.ORANGE, 56)
    AudioManager.play("combo" if (lines >= 2 or combo >= 2) else "clear")
    AudioManager.haptic(30 + 15 * mini(lines, 4))
    if lines >= 3:
        _shake()

func _shake() -> void:
    var tw := create_tween()
    for i in 5:
        tw.tween_property(self, "position", Vector2(randf_range(-10, 10), randf_range(-10, 10)), 0.035)
    tw.tween_property(self, "position", Vector2.ZERO, 0.05)

func _popup(text: String, at: Vector2, col: Color, fsize: int) -> void:
    var l := UI.label(text, fsize, col)
    UI.outline(l, 14, Color(0.1, 0.05, 0.25))
    add_child(l)
    var sz := l.get_combined_minimum_size()
    var x := clampf(at.x - sz.x * 0.5, 10.0, maxf(10.0, size.x - sz.x - 10.0))
    l.position = Vector2(x, at.y - sz.y * 0.5)
    l.pivot_offset = sz * 0.5
    l.scale = Vector2(0.4, 0.4)
    var tw := l.create_tween()
    tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_interval(0.35)
    tw.set_parallel(true)
    tw.tween_property(l, "position:y", l.position.y - 110.0, 0.55)
    tw.tween_property(l, "modulate:a", 0.0, 0.55)
    tw.chain().tween_callback(l.queue_free)

# ------------------------------------------------------------------ input
func _drag_topleft(slot: int) -> Vector2:
    var sh = PieceManager.shapes[GameManager.pieces[slot].id]
    var sz := Vector2(sh.w, sh.h) * cell
    var center := drag_pos + Vector2(0, -(cell * 1.5 + sz.y * 0.5))
    return center - sz * 0.5

func _slot_at(pos: Vector2) -> int:
    for i in 3:
        if GameManager.pieces[i] != null and _slot_rect(i).has_point(pos):
            return i
    return -1

func _board_rect() -> Rect2:
    return Rect2(board_pos, Vector2(board_px, board_px))

func _update_preview() -> void:
    prev_valid = false
    prev_origin = Vector2i(-100, -100)
    if dragging < 0 or not moved or GameManager.pieces[dragging] == null:
        return
    var tl := _drag_topleft(dragging)
    var o := Vector2i(roundi((tl.x - board_pos.x) / cell), roundi((tl.y - board_pos.y) / cell))
    prev_origin = o
    prev_valid = BoardManager.can_place(PieceManager.cells_of(GameManager.pieces[dragging].id), o.x, o.y)

func _commit(slot: int, origin: Vector2i) -> void:
    if GameManager.place_piece(slot, origin.x, origin.y):
        selected = -1
    else:
        AudioManager.play("invalid")

func _gui_input(event: InputEvent) -> void:
    if not GameManager.playing:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            var slot := _slot_at(event.position)
            if slot >= 0:
                dragging = slot
                press_pos = event.position
                drag_pos = event.position
                moved = false
                AudioManager.play("pickup")
            elif selected >= 0 and GameManager.pieces[selected] != null and _board_rect().has_point(event.position):
                var c := Vector2i(floori((event.position.x - board_pos.x) / cell), floori((event.position.y - board_pos.y) / cell))
                var sh = PieceManager.shapes[GameManager.pieces[selected].id]
                _commit(selected, c - Vector2i(sh.w / 2, sh.h / 2))
            queue_redraw()
        elif dragging >= 0:
            var slot := dragging
            dragging = -1
            if moved:
                if prev_valid:
                    _commit(slot, prev_origin)
                else:
                    AudioManager.play("invalid")
            else:
                selected = -1 if selected == slot else slot
            moved = false
            prev_valid = false
            queue_redraw()
    elif event is InputEventMouseMotion and dragging >= 0:
        drag_pos = event.position
        if not moved and event.position.distance_to(press_pos) > 18.0:
            moved = true
            selected = -1
        _update_preview()
        queue_redraw()
