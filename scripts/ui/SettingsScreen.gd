extends Control
const UI = preload("res://scripts/ui/UITheme.gd")

# <-- Replace with your hosted privacy policy URL before release (required by Google Play).
const PRIVACY_POLICY_URL := "https://example.com/blockpop/privacy"

func _ready() -> void:
    add_child(UI.background())
    var margin := MarginContainer.new()
    UI.fill(margin)
    for s in ["left", "right"]:
        margin.add_theme_constant_override("margin_" + s, 60)
    margin.add_theme_constant_override("margin_top", 140)
    margin.add_theme_constant_override("margin_bottom", 100)
    add_child(margin)
    var vb := VBoxContainer.new()
    vb.alignment = BoxContainer.ALIGNMENT_CENTER
    vb.add_theme_constant_override("separation", 34)
    margin.add_child(vb)
    vb.add_child(UI.label("SETTINGS", 96, Color.WHITE))
    var gap := Control.new()
    gap.custom_minimum_size = Vector2(0, 30)
    vb.add_child(gap)

    _toggle(vb, "SOUND", "sound")
    _toggle(vb, "MUSIC", "music")
    _toggle(vb, "HAPTICS", "haptic")

    var pp := UI.button("PRIVACY POLICY", Color(0.25, 0.25, 0.55), Vector2(720, 120), 38)
    UI.center(vb, pp)
    pp.pressed.connect(func(): OS.shell_open(PRIVACY_POLICY_URL))

    if AdManager.privacy_options_required:
        var ap := UI.button("AD PRIVACY OPTIONS", Color(0.25, 0.25, 0.55), Vector2(720, 120), 38)
        UI.center(vb, ap)
        ap.pressed.connect(AdManager.show_privacy_options)

    var back := UI.button("BACK", UI.PINK, Vector2(720, 140), 50)
    UI.center(vb, back)
    back.pressed.connect(UIManager.show_home)

    var ver := UI.label("v" + str(ProjectSettings.get_setting("application/config/version", "1.0.0")), 28, Color(1, 1, 1, 0.4))
    vb.add_child(ver)

func _toggle(parent: VBoxContainer, title: String, key: String) -> void:
    var card := UI.card(46)
    card.custom_minimum_size = Vector2(840, 0)
    UI.center(parent, card)
    var m := MarginContainer.new()
    for s in ["left", "right"]:
        m.add_theme_constant_override("margin_" + s, 40)
    for s in ["top", "bottom"]:
        m.add_theme_constant_override("margin_" + s, 20)
    card.add_child(m)
    var hb := HBoxContainer.new()
    m.add_child(hb)
    var l := UI.label(title, 48, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    hb.add_child(l)
    var on := SaveManager.get_setting(key)
    var b := UI.button("ON" if on else "OFF", UI.GREEN if on else Color(0.4, 0.4, 0.5), Vector2(220, 100), 42)
    hb.add_child(b)
    b.pressed.connect(func():
        var v := not SaveManager.get_setting(key)
        SaveManager.set_setting(key, v)
        b.text = "ON" if v else "OFF"
        UI.apply_button_colors(b, UI.GREEN if v else Color(0.4, 0.4, 0.5))
        if key == "music":
            AudioManager.refresh_music())
