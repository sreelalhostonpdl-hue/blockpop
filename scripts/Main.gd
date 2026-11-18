extends Control
## Bootstrap + Android lifecycle.

func _ready() -> void:
    get_tree().set_auto_accept_quit(false)
    AdManager.initialize()
    AudioManager.start_music()
    UIManager.setup(self)

func _notification(what: int) -> void:
    match what:
        NOTIFICATION_WM_GO_BACK_REQUEST:
            UIManager.on_back()
        NOTIFICATION_APPLICATION_PAUSED:
            GameManager.save_session()
            UIManager.on_app_paused()
            AudioManager.set_paused(true)
        NOTIFICATION_APPLICATION_RESUMED:
            AudioManager.set_paused(false)
        NOTIFICATION_WM_CLOSE_REQUEST:
            GameManager.save_session()
            get_tree().quit()
