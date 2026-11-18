extends Node
## Google AdMob ADAPTER.
##
## STATUS: the adapter, frequency capping, test/production ID switch and all call sites are
## implemented. The NATIVE AdMob SDK bridge is NOT bundled in this repository, so
## `backend_ready` stays false and NO ads are shown (nothing is faked). To go live, follow
## docs/ADMOB_INTEGRATION.md and fill in the six `_backend_*` functions below.
## Never shown during active gameplay: banner = home only, interstitial = on leaving the
## game-over screen, rewarded = user-initiated button on the game-over screen.

# ------------------------------- ADMOB CONFIGURATION -------------------------------
const USE_TEST_ADS := true   # <-- set to false ONLY for the release build

# Google's official sample IDs (safe for development):
const TEST_IDS := {
    "app": "ca-app-pub-3940256099942544~3347511713",
    "banner": "ca-app-pub-3940256099942544/6300978111",
    "interstitial": "ca-app-pub-3940256099942544/1033173712",
    "rewarded": "ca-app-pub-3940256099942544/5224354917",
}
# <-- ENTER YOUR PRODUCTION AD UNIT IDS HERE (from admob.google.com). The app ID must also
#     go into the Android export / plugin config (see docs/ADMOB_INTEGRATION.md).
const PROD_IDS := {
    "app": "ca-app-pub-REPLACE_ME~REPLACE_ME",
    "banner": "ca-app-pub-REPLACE_ME/REPLACE_ME",
    "interstitial": "ca-app-pub-REPLACE_ME/REPLACE_ME",
    "rewarded": "ca-app-pub-REPLACE_ME/REPLACE_ME",
}
const MIN_SESSIONS_BETWEEN_INTERSTITIALS := 3
const MIN_SECONDS_BETWEEN_INTERSTITIALS := 120
# -----------------------------------------------------------------------------------

var backend_ready := false          # becomes true once a native bridge is wired in
var privacy_options_required := false
var _sessions_since_interstitial := 0
var _last_interstitial_msec := -1000000
var _banner_visible := false

func ids() -> Dictionary:
    return TEST_IDS if USE_TEST_ADS else PROD_IDS

func _ready() -> void:
    _backend_initialize()

func is_available() -> bool:
    return backend_ready

## Called at startup: consent (UMP) must complete before ads are requested.
func initialize() -> void:
    _backend_request_consent_then_init()

func show_privacy_options() -> void:
    _backend_show_privacy_options()

func show_banner() -> void:
    if backend_ready and not _banner_visible:
        _banner_visible = true
        _backend_show_banner()

func hide_banner() -> void:
    if _banner_visible:
        _banner_visible = false
        _backend_hide_banner()

func register_session_end() -> void:
    _sessions_since_interstitial += 1

func is_rewarded_ready() -> bool:
    return backend_ready and _backend_rewarded_ready()

## `done` is always called exactly once (also when no ad is shown).
func maybe_show_interstitial(done: Callable) -> void:
    var elapsed := (Time.get_ticks_msec() - _last_interstitial_msec) / 1000.0
    if backend_ready and _sessions_since_interstitial >= MIN_SESSIONS_BETWEEN_INTERSTITIALS \
            and elapsed >= MIN_SECONDS_BETWEEN_INTERSTITIALS and _backend_interstitial_ready():
        _sessions_since_interstitial = 0
        _last_interstitial_msec = Time.get_ticks_msec()
        _backend_show_interstitial(done)
    else:
        done.call()

## `done(rewarded: bool)` is called once. Reward is granted only after a completed view.
func show_rewarded(done: Callable) -> void:
    if is_rewarded_ready():
        _backend_show_rewarded(done)
    else:
        done.call(false)

# ----------------------------- NATIVE BRIDGE (TO IMPLEMENT) -----------------------------
# Each function below is the single place where the AdMob plugin API must be called.
func _backend_initialize() -> void:
    # TODO(native): detect the installed AdMob plugin and set backend_ready = true after
    # MobileAds initialisation succeeds. Until then ads stay disabled.
    backend_ready = false

func _backend_request_consent_then_init() -> void:
    # TODO(native): UMP consent request (required for EEA/UK). Set privacy_options_required
    # from the UMP status, then initialise the SDK and preload interstitial + rewarded ads.
    pass

func _backend_show_privacy_options() -> void:
    pass  # TODO(native): UMP privacy options form

func _backend_show_banner() -> void:
    pass  # TODO(native): load/show anchored adaptive banner at screen bottom using ids().banner

func _backend_hide_banner() -> void:
    pass  # TODO(native): hide/destroy banner

func _backend_interstitial_ready() -> bool:
    return false  # TODO(native)

func _backend_show_interstitial(done: Callable) -> void:
    done.call()  # TODO(native): show ad, call done on dismissed/failed, then preload next

func _backend_rewarded_ready() -> bool:
    return false  # TODO(native)

func _backend_show_rewarded(done: Callable) -> void:
    done.call(false)  # TODO(native): done.call(true) only from the user-earned-reward callback
