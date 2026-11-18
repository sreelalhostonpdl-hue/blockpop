# Testing report

**Honest scope:** this was produced in an environment with **no Godot binary and no network**, so the game
was **never launched** and the GDScript was **never compiled or executed** here.

| Check | Result |
|---|---|
| `tools/check_project.py` – every `res://` path exists, autoload files exist, indentation, bracket balance, every `Autoload.method` / `UI.method` call resolves to a defined func | PASS |
| Shape library re-derived independently in Python (17 bases × rotations, deduped) | 45 distinct shapes (≥20 required) |
| Asset generation (`tools/generate_assets.py`): 7 SFX + loopable music + 5 icons | PASS (files produced) |
| `tests/TestRunner.tscn` headless logic suite (shapes, collision, intersecting row+col clear = 19 unique cells, scoring table + combo, generator fairness, game-over detection, session save/restore) | **WRITTEN, NOT RUN** |
| On-device / emulator gameplay, touch, 60 FPS, Android pause/resume, export | **NOT TESTED** |
| AdMob | **NOT INTEGRATED** (adapter only) |

## What you must run first
1. `godot --headless --import` (generates the import cache) then `godot --headless res://tests/TestRunner.tscn` – expect `RESULT: OK`.
2. Open in Godot 4.3+, press Play (desktop window is portrait 1080×1920; resize freely), fix any parse error shown in the Output panel.
3. Export to a device and verify: drag/drop, tap-select + tap-place, pause on home button, resume after kill, music loop, haptics.
