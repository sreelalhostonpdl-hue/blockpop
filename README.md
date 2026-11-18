# BLOCKPOP – casual 10×10 block puzzle (Godot 4.3+, GDScript, Android first)

Original visuals (generated in code), original audio and icons (`tools/generate_assets.py`), no third-party assets.

## Run
1. Install **Godot 4.3+** (standard build). Open `project.godot` (first open imports assets).
2. Press **F5**. Portrait 1080×1920, stretch `canvas_items`/`expand`, GL Compatibility renderer.
3. Optional tests: `godot --headless --import && godot --headless res://tests/TestRunner.tscn`.

## Controls
Drag a piece onto the board (it floats above your finger; a preview and line-completion glow show where it will land),
**or** tap a piece to select it and tap the board. No timer.

## Architecture (autoloads in `scripts/`)
| Module | Role |
|---|---|
| `GameManager` | flow: new/resume, placement, clear, game over, fair revive, daily challenge |
| `BoardManager` | 10×10 matrix, collision/placement, full-line detection **before** clearing, simultaneous row+column clearing |
| `PieceManager` | 45 shapes, balanced generator (≥1 piece fits, limits big-piece clusters when crowded) |
| `ScoreManager` | 10/block; 100/250/450/700 per 1–4 lines; +50×(combo−1) |
| `SaveManager` | atomic JSON save: best, settings, per-mode sessions, daily status |
| `AudioManager` | pooled SFX, looping music, haptics |
| `AdManager` | AdMob adapter (see below) |
| `UIManager` + `scripts/ui/*` | splash, home, game (+pause/game-over), settings |

Unfinished games (board, pieces, score, RNG state) are saved after every move and on Android pause; **Continue** resumes them.
Daily challenge: same seeded piece sequence for everyone each day; reach 2000 points.

## Ads – read this
AdMob is **not integrated**: the policy layer and call sites are done, the native bridge is not (cannot be built here).
No fake ads are shown; the rewarded-continue button stays hidden until a real rewarded ad is ready.
Steps and where to put production IDs: `docs/ADMOB_INTEGRATION.md` (`PROD_IDS` in `scripts/AdManager.gd`).

## Release
`docs/PLAY_STORE.md` (build, signing, listing, Data safety), `docs/PRIVACY_POLICY_TEMPLATE.md`, `docs/TESTING_REPORT.md`.
Placeholders to replace: application ID `com.yourcompany.blockpop`, `PRIVACY_POLICY_URL`, production AdMob IDs.

## Known limitations
- Fonts use the system font stack (Poppins/Montserrat/Nunito → Roboto fallback); drop an OFL TTF into the project for fully custom typography.
- Not yet run in Godot (see testing report); expect to fix small parse/runtime issues on first launch.
