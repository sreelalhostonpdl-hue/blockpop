extends Control
const UI = preload("res://scripts/ui/UITheme.gd")

func _ready() -> void:
    add_child(UI.background())
    var margin := MarginContainer.new()
    UI.fill(margin)
    margin.add_theme_constant_override("margin_left", 50)
    margin.add_theme_constant_override("margin_right", 50)
    margin.add_theme_constant_override("margin_top", 120)
    margin.add_theme_constant_override("margin_bottom", 190)  # room for the banner ad
    add_child(margin)
    var vb := VBoxContainer.new()
    vb.alignment = BoxContainer.ALIGNMENT_CENTER
    vb.add_theme_constant_override("separation", 30)
    margin.add_child(vb)

    var logo := UI.logo(108)
    vb.add_child(logo)
    vb.add_child(UI.label("BLOCK PUZZLE", 38, UI.CYAN))
    var gap := Control.new()
    gap.custom_minimum_size = Vector2(0, 20)
    vb.add_child(gap)

    # stats card
    var card := UI.card()
    card.custom_minimum_size = Vector2(760, 0)
    UI.center(vb, card)
    var cm := MarginContainer.new()
    for s in ["left", "right"]:
        cm.add_theme_constant_override("margin_" + s, 50)
    for s in ["top", "bottom"]:
        cm.add_theme_constant_override("margin_" + s, 30)
    card.add_child(cm)
    var hb := HBoxContainer.new()
    hb.add_theme_constant_override("separation", 40)
    cm.add_child(hb)
    hb.add_child(_stat("BEST SCORE", str(SaveManager.get_best()), UI.GOLD))
    var sep := ColorRect.new()
    sep.color = Color(1, 1, 1, 0.12)
    sep.custom_minimum_size = Vector2(3, 90)
    hb.add_child(sep)
    hb.add_child(_stat("LEVEL", str(GameManager.saved_level("classic")), UI.CYAN))

    var has_session := GameManager.has_session("classic")
    var play := UI.button("CONTINUE" if has_session else "PLAY", UI.PINK, Vector2(640, 160), 64)
    UI.center(vb, play)
    play.pressed.connect(func():
        if has_session and GameManager.resume_session("classic"):
            pass
        else:
            GameManager.new_game("classic")
        UIManager.show_game())
    if has_session:
        var ng := UI.button("NEW GAME", UI.VIOLET, Vector2(640, 110), 38)
        UI.center(vb, ng)
        ng.pressed.connect(func():
            GameManager.new_game("classic")
            UIManager.show_game())

    var done := GameManager.daily_done()
    var daily := UI.button("DAILY CHALLENGE\n" + ("COMPLETED TODAY" if done else "Reach %d points" % GameManager.DAILY_TARGET),
        UI.GREEN if done else UI.ORANGE, Vector2(640, 150), 36)
    UI.center(vb, daily)
    daily.pressed.connect(func():
        if not (GameManager.has_session("daily") and GameManager.resume_session("daily")):
            GameManager.new_game("daily")
        UIManager.show_game())

    var settings := UI.button("SETTINGS", Color(0.25, 0.25, 0.55), Vector2(640, 110), 38)
    UI.center(vb, settings)
    settings.pressed.connect(UIManager.show_settings)

func _stat(title: String, value: String, col: Color) -> VBoxContainer:
    var v := VBoxContainer.new()
    v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    v.add_child(UI.label(title, 28, Color(1, 1, 1, 0.65)))
    v.add_child(UI.label(value, 72, col))
    return v
