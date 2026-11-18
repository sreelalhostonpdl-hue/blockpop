extends RefCounted
## Shared styling helpers (colours, font, buttons, labels, background, logo).

const NAVY := Color(0.043, 0.063, 0.188)
const PURPLE := Color(0.165, 0.071, 0.388)
const PINK := Color(1.0, 0.31, 0.64)
const CYAN := Color(0.133, 0.827, 0.933)
const ORANGE := Color(1.0, 0.62, 0.11)
const GOLD := Color(1.0, 0.85, 0.24)
const VIOLET := Color(0.61, 0.36, 1.0)
const GREEN := Color(0.20, 0.78, 0.50)
const PANEL := Color(0.08, 0.08, 0.25, 0.92)

static var _font: SystemFont = null

static func font() -> SystemFont:
    if _font == null:
        _font = SystemFont.new()
        _font.font_names = PackedStringArray(["Poppins", "Montserrat", "Nunito", "Roboto", "Arial"])
        _font.font_weight = 800
    return _font

static func fill(c: Control) -> void:
    c.anchor_left = 0.0
    c.anchor_top = 0.0
    c.anchor_right = 1.0
    c.anchor_bottom = 1.0
    c.offset_left = 0.0
    c.offset_top = 0.0
    c.offset_right = 0.0
    c.offset_bottom = 0.0

static func box(bg: Color, radius: int, border: Color = Color(0, 0, 0, 0), bw: int = 0) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.set_corner_radius_all(radius)
    if bw > 0:
        sb.set_border_width_all(bw)
        sb.border_color = border
    return sb

static func label(text: String, fsize: int, col: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var l := Label.new()
    l.text = text
    l.horizontal_alignment = align
    l.add_theme_font_override("font", font())
    l.add_theme_font_size_override("font_size", fsize)
    l.add_theme_color_override("font_color", col)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l

static func outline(l: Label, size: int, col: Color) -> void:
    l.add_theme_constant_override("outline_size", size)
    l.add_theme_color_override("font_outline_color", col)

static func apply_button_colors(b: Button, col: Color) -> void:
    var dark := col.darkened(0.38)
    var n := box(col, 46)
    n.border_width_bottom = 10
    n.border_color = dark
    n.shadow_size = 12
    n.shadow_color = Color(0, 0, 0, 0.35)
    n.shadow_offset = Vector2(0, 6)
    var h: StyleBoxFlat = n.duplicate()
    h.bg_color = col.lightened(0.08)
    var p: StyleBoxFlat = n.duplicate()
    p.bg_color = col.darkened(0.06)
    p.border_width_bottom = 3
    p.shadow_size = 4
    b.add_theme_stylebox_override("normal", n)
    b.add_theme_stylebox_override("hover", h)
    b.add_theme_stylebox_override("pressed", p)
    b.add_theme_stylebox_override("focus", n)
    b.add_theme_stylebox_override("disabled", n)

static func button(text: String, col: Color, min_size: Vector2 = Vector2(600, 130), fsize: int = 46, txt: Color = Color.WHITE) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = min_size
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_override("font", font())
    b.add_theme_font_size_override("font_size", fsize)
    for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        b.add_theme_color_override(k, txt)
    apply_button_colors(b, col)
    b.resized.connect(func(): b.pivot_offset = b.size * 0.5)
    b.button_down.connect(func(): b.create_tween().tween_property(b, "scale", Vector2(0.95, 0.95), 0.06))
    b.button_up.connect(func(): b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
    b.pressed.connect(func():
        AudioManager.play("click")
        AudioManager.haptic(12))
    return b

static func center(parent: Control, node: Control) -> void:
    node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    parent.add_child(node)

static func card(radius: int = 52) -> PanelContainer:
    var pc := PanelContainer.new()
    pc.add_theme_stylebox_override("panel", box(PANEL, radius, Color(1, 1, 1, 0.10), 3))
    return pc

static func background() -> Control:
    var root := Control.new()
    fill(root)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var g := Gradient.new()
    g.set_color(0, NAVY)
    g.set_color(1, PURPLE)
    g.add_point(0.55, Color(0.11, 0.08, 0.33))
    var tex := GradientTexture2D.new()
    tex.gradient = g
    tex.fill_from = Vector2(0.5, 0.0)
    tex.fill_to = Vector2(0.5, 1.0)
    tex.width = 8
    tex.height = 256
    var tr := TextureRect.new()
    tr.texture = tex
    tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tr.stretch_mode = TextureRect.STRETCH_SCALE
    fill(tr)
    tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(tr)
    var decor := [[Vector2(-220, 120), PINK, 620.0], [Vector2(640, 980), CYAN, 700.0], [Vector2(-120, 1500), VIOLET, 560.0]]
    for d in decor:
        var p := Panel.new()
        var col: Color = d[1]
        p.add_theme_stylebox_override("panel", box(Color(col.r, col.g, col.b, 0.07), 400))
        p.position = d[0]
        p.size = Vector2(d[2], d[2])
        p.mouse_filter = Control.MOUSE_FILTER_IGNORE
        root.add_child(p)
    return root

static func logo(tile: int = 108) -> HBoxContainer:
    var hb := HBoxContainer.new()
    hb.add_theme_constant_override("separation", 8)
    hb.alignment = BoxContainer.ALIGNMENT_CENTER
    var letters := "BLOCKPOP"
    for i in letters.length():
        var col: Color = PieceManager.color_of(i % 5 + 1)
        var pc := PanelContainer.new()
        pc.custom_minimum_size = Vector2(tile, tile)
        var sb := box(col, int(tile * 0.26))
        sb.border_width_bottom = int(tile * 0.09)
        sb.border_color = col.darkened(0.42)
        sb.shadow_size = 10
        sb.shadow_color = Color(0, 0, 0, 0.35)
        pc.add_theme_stylebox_override("panel", sb)
        var l := label(letters[i], int(tile * 0.6), Color.WHITE)
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        outline(l, 6, col.darkened(0.5))
        pc.add_child(l)
        pc.pivot_offset = Vector2(tile, tile) * 0.5
        hb.add_child(pc)
    return hb
