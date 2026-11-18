extends Node
## Persistent storage (JSON in user://). Holds best score, settings, per-mode sessions, daily status.

const PATH := "user://blockpop_save.json"
const TMP_PATH := "user://blockpop_save.tmp"

var data: Dictionary = {}

func _ready() -> void:
    load_data()

func _defaults() -> Dictionary:
    return {
        "best": 0,
        "settings": {"sound": true, "music": true, "haptic": true},
        "sessions": {},
        "daily_done": "",
        "games_played": 0,
    }

func load_data() -> void:
    data = _defaults()
    if not FileAccess.file_exists(PATH):
        return
    var f := FileAccess.open(PATH, FileAccess.READ)
    if f == null:
        return
    var parsed = JSON.parse_string(f.get_as_text())
    if parsed is Dictionary:
        for k in parsed:
            data[k] = parsed[k]
        var st: Dictionary = _defaults()["settings"]
        if data["settings"] is Dictionary:
            for k in data["settings"]:
                st[k] = data["settings"][k]
        data["settings"] = st
        if not (data["sessions"] is Dictionary):
            data["sessions"] = {}

func save_data() -> void:
    # write to temp file then rename so a crash can't corrupt the save
    var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
    if f == null:
        return
    f.store_string(JSON.stringify(data))
    f.close()
    var dir := DirAccess.open("user://")
    if dir != null:
        if dir.file_exists(PATH.get_file()):
            dir.remove(PATH.get_file())
        dir.rename(TMP_PATH.get_file(), PATH.get_file())

func get_best() -> int:
    return int(data.get("best", 0))

func set_best(v: int) -> void:
    data["best"] = v

func get_setting(key: String) -> bool:
    return bool(data["settings"].get(key, true))

func set_setting(key: String, value: bool) -> void:
    data["settings"][key] = value
    save_data()

func get_session(mode: String) -> Dictionary:
    var s = data["sessions"].get(mode, {})
    return s if s is Dictionary else {}

func set_session(mode: String, s: Dictionary) -> void:
    data["sessions"][mode] = s

func clear_session(mode: String) -> void:
    data["sessions"].erase(mode)

func has_session(mode: String) -> bool:
    return not get_session(mode).is_empty()
