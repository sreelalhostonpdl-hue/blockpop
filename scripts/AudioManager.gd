extends Node
## Sound effects (pooled players), looping music, haptics.

const SFX_NAMES := ["place", "clear", "combo", "gameover", "click", "pickup", "invalid"]
const POOL_SIZE := 6

var _sfx: Dictionary = {}
var _pool: Array = []
var _music: AudioStreamPlayer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for n in SFX_NAMES:
        var path := "res://assets/audio/%s.wav" % n
        if ResourceLoader.exists(path):
            _sfx[n] = load(path)
    for i in POOL_SIZE:
        var p := AudioStreamPlayer.new()
        p.volume_db = -4.0
        add_child(p)
        _pool.append(p)
    _music = AudioStreamPlayer.new()
    _music.volume_db = -9.0
    add_child(_music)
    var mpath := "res://assets/audio/music.wav"
    if ResourceLoader.exists(mpath):
        var st = load(mpath)
        if st is AudioStreamWAV:
            st.loop_mode = AudioStreamWAV.LOOP_FORWARD
            st.loop_begin = 0
            st.loop_end = int(st.get_length() * st.mix_rate)
        _music.stream = st

func play(sfx_name: String, pitch: float = 1.0) -> void:
    if not SaveManager.get_setting("sound") or not _sfx.has(sfx_name):
        return
    for p in _pool:
        if not p.playing:
            p.stream = _sfx[sfx_name]
            p.pitch_scale = pitch
            p.play()
            return
    var first: AudioStreamPlayer = _pool[0]  # all busy: steal the oldest
    first.stream = _sfx[sfx_name]
    first.pitch_scale = pitch
    first.play()

func start_music() -> void:
    refresh_music()

func refresh_music() -> void:
    if _music == null or _music.stream == null:
        return
    if SaveManager.get_setting("music"):
        if not _music.playing:
            _music.play()
    else:
        _music.stop()

func set_paused(paused: bool) -> void:
    if _music != null:
        _music.stream_paused = paused

func haptic(ms: int = 20) -> void:
    if SaveManager.get_setting("haptic"):
        Input.vibrate_handheld(ms)
