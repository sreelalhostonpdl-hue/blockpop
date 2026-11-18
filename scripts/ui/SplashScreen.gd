extends Control
const UI = preload("res://scripts/ui/UITheme.gd")

func _ready() -> void:
    add_child(UI.background())
    var cc := CenterContainer.new()
    UI.fill(cc)
    add_child(cc)
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 30)
    cc.add_child(vb)
    var logo := UI.logo(108)
    vb.add_child(logo)
    var tag := UI.label("BLOCK PUZZLE", 40, UI.CYAN)
    tag.modulate.a = 0.0
    vb.add_child(tag)
    var tiles := logo.get_children()
    for t in tiles:
        t.scale = Vector2.ZERO
    var tw := create_tween()
    for i in tiles.size():
        tw.parallel().tween_property(tiles[i], "scale", Vector2.ONE, 0.45) \
            .set_delay(i * 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(tag, "modulate:a", 1.0, 0.5).set_delay(0.6)
    tw.tween_interval(0.7)
    tw.tween_callback(UIManager.show_home)
