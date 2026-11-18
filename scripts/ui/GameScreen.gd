extends Control
## Gameplay screen: HUD (pause, level, best, animated score) + board view + pause / game-over overlays.
const UI = preload("res://scripts/ui/UITheme.gd")
const GameplayView = preload("res://scripts/ui/GameplayView.gd")

var view: Control
var score_label: Label
var best_label: Label
var level_label: Label
var overlay: Control = null
var overlay_kind := ""
var _shown_score := 0.0
var _score_tween: Tween

func _ready() -> void:
    add_child(UI.background())
    view = GameplayView.new()
    UI.fill(view)
    add_child(view)
    _build_hud()
    GameManager.score_changed.connect(_on_score)
    GameManager.game_over.connect(_on_game_over)
    GameManager.daily_completed.connect(_on_daily_completed)
    _shown_score = ScoreManager.score
    _refresh_labels(ScoreManager.score)
    if not GameManager.playing:
        _on_game_over(ScoreManager.score, false)

func _build_hud() -> void:
    var top := MarginContainer.new()
    top.anchor_right = 1.0
    top.offset_bottom = 400.0
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for s in ["left", "right"]:
        top.add_theme_constant_override("margin_" + s, 40)
    top.add_theme_constant_override("margin_top", 70)
    add_child(top)
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 16)
    vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top.add_child(vb)

    var hb := HBoxContainer.new()
    hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vb.add_child(hb)

    var left := Control.new()
    left.custom_minimum_size = Vector2(250, 120)
    left.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var pause := UI.button("II", Color(0.25, 0.25, 0.55), Vector2(120, 120), 52)
    left.add_child(pause)
    pause.pressed.connect(_show_pause)
    hb.add_child(left)

    var mid := CenterContainer.new()
    mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var pill := PanelContainer.new()
    pill.add_theme_stylebox_override("panel", UI.box(Color(1, 1, 1, 0.1), 40, Color(1, 1, 1, 0.12), 3))
    var pm := MarginContainer.new()
    for s in ["left", "right"]:
        pm.add_theme_constant_override("margin_" + s, 36)
    for s in ["top", "bottom"]:
        pm.add_theme_constant_override("margin_" + s, 14)
    pill.add_child(pm)
    level_label = UI.label("LEVEL 1", 40, UI.CYAN)
    pm.add_child(level_label)
    mid.add_child(pill)
    hb.add_child(mid)

    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(250, 120)
    right.mouse_filter = Control.MOUSE_FILTER_IGNORE
    right.add_child(UI.label("BEST", 28, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_RIGHT))
    best_label = UI.label("0", 58, UI.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
    right.add_child(best_label)
    hb.add_child(right)

    score_label = UI.label("0", 150, Color.WHITE)
    UI.outline(score_label, 12, Color(0.25, 0.1, 0.55))
    score_label.resized.connect(func(): score_label.pivot_offset = score_label.size * 0.5)
    vb.add_child(score_label)

func _refresh_labels(score: int) -> void:
    score_label.text = str(int(_shown_score))
    best_label.text = str(maxi(SaveManager.get_best(), score))
    if GameManager.mode == "daily":
        level_label.text = "DAILY  %d / %d" % [mini(score, GameManager.DAILY_TARGET), GameManager.DAILY_TARGET]
    else:
        level_label.text = "LEVEL %d" % GameManager.level()

func _on_score(score: int, delta: int) -> void:
    if _score_tween != null:
        _score_tween.kill()
    var from := _shown_score
    _score_tween = create_tween()
    _score_tween.tween_method(_set_shown, from, float(score), 0.45 if delta > 0 else 0.01) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    if delta > 0:
        var pop := create_tween()
        pop.tween_property(score_label, "scale", Vector2(1.14, 1.14), 0.08)
        pop.tween_property(score_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    best_label.text = str(maxi(SaveManager.get_best(), score))
    if GameManager.mode == "daily":
        level_label.text = "DAILY  %d / %d" % [mini(score, GameManager.DAILY_TARGET), GameManager.DAILY_TARGET]
    else:
        level_label.text = "LEVEL %d" % GameManager.level()

func _set_shown(v: float) -> void:
    _shown_score = v
    score_label.text = str(int(v))

func _on_daily_completed() -> void:
    var l := UI.label("DAILY CHALLENGE COMPLETE!", 54, UI.GOLD)
    UI.outline(l, 12, Color(0.1, 0.05, 0.25))
    l.anchor_right = 1.0
    l.offset_top = 420.0
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(l)
    AudioManager.play("combo")
    var tw := l.create_tween()
    tw.tween_interval(1.8)
    tw.tween_property(l, "modulate:a", 0.0, 0.5)
    tw.tween_callback(l.queue_free)

# ------------------------------------------------------------------ overlays
func _make_overlay(kind: String) -> VBoxContainer:
    _close_overlay()
    overlay_kind = kind
    overlay = Control.new()
    UI.fill(overlay)
    var dim := ColorRect.new()
    dim.color = Color(0.02, 0.01, 0.1, 0.72)
    UI.fill(dim)
    overlay.add_child(dim)
    var cc := CenterContainer.new()
    UI.fill(cc)
    overlay.add_child(cc)
    var panel := UI.card(64)
    panel.custom_minimum_size = Vector2(800, 0)
    cc.add_child(panel)
    var m := MarginContainer.new()
    for s in ["left", "right"]:
        m.add_theme_constant_override("margin_" + s, 60)
    for s in ["top", "bottom"]:
        m.add_theme_constant_override("margin_" + s, 60)
    panel.add_child(m)
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 26)
    m.add_child(vb)
    add_child(overlay)
    overlay.modulate.a = 0.0
    overlay.create_tween().tween_property(overlay, "modulate:a", 1.0, 0.2)
    panel.pivot_offset = Vector2(400, 300)
    panel.scale = Vector2(0.88, 0.88)
    panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    return vb

func _close_overlay() -> void:
    if overlay != null:
        overlay.queue_free()
        overlay = null
    overlay_kind = ""

func _show_pause() -> void:
    if overlay != null or not GameManager.playing:
        return
    GameManager.save_session()
    var vb := _make_overlay("pause")
    vb.add_child(UI.label("PAUSED", 90, Color.WHITE))
    var resume := UI.button("RESUME", UI.PINK, Vector2(640, 130), 48)
    UI.center(vb, resume)
    resume.pressed.connect(_close_overlay)
    var restart := UI.button("RESTART", UI.ORANGE, Vector2(640, 120), 42)
    UI.center(vb, restart)
    restart.pressed.connect(func():
        GameManager.new_game(GameManager.mode)
        UIManager.show_game())
    var home := UI.button("HOME", Color(0.25, 0.25, 0.55), Vector2(640, 120), 42)
    UI.center(vb, home)
    home.pressed.connect(func():
        GameManager.save_session()
        UIManager.show_home())

func auto_pause() -> void:
    _show_pause()

func on_back() -> void:
    match overlay_kind:
        "pause":
            _close_overlay()
        "over":
            UIManager.show_home()
        _:
            _show_pause()

func _on_game_over(final_score: int, new_best: bool) -> void:
    AudioManager.play("gameover")
    AudioManager.haptic(60)
    await get_tree().create_timer(0.8).timeout
    if not is_inside_tree():
        return
    var vb := _make_overlay("over")
    vb.add_child(UI.label("GAME OVER", 86, UI.PINK))
    vb.add_child(UI.label("SCORE", 32, Color(1, 1, 1, 0.6)))
    vb.add_child(UI.label(str(final_score), 120, Color.WHITE))
    if new_best:
        vb.add_child(UI.label("NEW BEST!", 56, UI.GOLD))
    else:
        vb.add_child(UI.label("BEST  %d" % SaveManager.get_best(), 48, UI.GOLD))
    # Optional rewarded revive: only offered when a real rewarded ad is loaded.
    if GameManager.can_revive() and AdManager.is_rewarded_ready():
        var rev := UI.button("WATCH AD TO CONTINUE", UI.GREEN, Vector2(640, 120), 36)
        UI.center(vb, rev)
        rev.pressed.connect(func():
            AdManager.show_rewarded(func(ok: bool):
                if ok:
                    _close_overlay()
                    GameManager.revive()))
    var restart := UI.button("PLAY AGAIN", UI.PINK, Vector2(640, 130), 48)
    UI.center(vb, restart)
    restart.pressed.connect(func():
        AdManager.maybe_show_interstitial(func():
            GameManager.new_game(GameManager.mode)
            UIManager.show_game()))
    var home := UI.button("HOME", Color(0.25, 0.25, 0.55), Vector2(640, 110), 40)
    UI.center(vb, home)
    home.pressed.connect(func():
        AdManager.maybe_show_interstitial(UIManager.show_home))
