extends Node
## Screen navigation with fade transitions, Android back + pause/resume handling.

const SplashScreen = preload("res://scripts/ui/SplashScreen.gd")
const HomeScreen = preload("res://scripts/ui/HomeScreen.gd")
const GameScreen = preload("res://scripts/ui/GameScreen.gd")
const SettingsScreen = preload("res://scripts/ui/SettingsScreen.gd")
const UI = preload("res://scripts/ui/UITheme.gd")

var root: Control
var current: Control = null
var current_name := ""

func setup(r: Control) -> void:
    root = r
    show_splash()

func _swap(scr: Control, scr_name: String) -> void:
    if current != null:
        root.remove_child(current)
        current.queue_free()
    current = scr
    current_name = scr_name
    UI.fill(scr)
    root.add_child(scr)
    scr.modulate.a = 0.0
    scr.create_tween().tween_property(scr, "modulate:a", 1.0, 0.25)

func show_splash() -> void:
    AdManager.hide_banner()
    _swap(SplashScreen.new(), "splash")

func show_home() -> void:
    _swap(HomeScreen.new(), "home")
    AdManager.show_banner()

func show_game() -> void:
    AdManager.hide_banner()
    _swap(GameScreen.new(), "game")

func show_settings() -> void:
    AdManager.hide_banner()
    _swap(SettingsScreen.new(), "settings")

func on_back() -> void:
    match current_name:
        "game":
            current.on_back()
        "settings":
            show_home()
        "home":
            GameManager.save_session()
            get_tree().quit()

func on_app_paused() -> void:
    if current_name == "game" and current != null:
        current.auto_pause()
