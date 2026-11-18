extends Node
## Block library (45 shapes generated from 17 base shapes + rotations) and balanced generator.

const COLORS := [
    Color(0.133, 0.827, 0.933),  # cyan
    Color(1.0, 0.31, 0.64),      # pink
    Color(1.0, 0.62, 0.11),      # orange
    Color(1.0, 0.85, 0.24),      # yellow
    Color(0.61, 0.36, 1.0),      # violet
]

var shapes: Array = []

func _ready() -> void:
    _build()

func color_of(c: int) -> Color:
    return COLORS[(maxi(c, 1) - 1) % COLORS.size()]

func cells_of(id: int) -> Array:
    return shapes[id].cells

func _build() -> void:
    shapes.clear()
    _add("single", [Vector2i(0, 0)], 0.6)
    _add("line2", [Vector2i(0, 0), Vector2i(1, 0)], 1.0)
    _add("line3", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], 1.0)
    _add("line4", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], 0.8)
    _add("line5", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)], 0.5)
    _add("square2", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], 1.0)
    _add("square3", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)], 0.35)
    _add("rect2x3", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], 0.5)
    _add("corner3", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], 1.0)
    _add("corner5", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(0, 2)], 0.5)
    _add("L", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)], 0.9)
    _add("J", [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)], 0.9)
    _add("T", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)], 0.8)
    _add("S", [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)], 0.7)
    _add("Z", [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)], 0.7)
    _add("Llong", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(1, 3)], 0.35)
    _add("Jlong", [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(0, 3)], 0.35)

func _add(nm: String, pts: Array, weight: float) -> void:
    var seen := {}
    var cur: Array = pts
    for r in 4:
        cur = _normalize(_rot(cur))
        var key := _key(cur)
        if seen.has(key):
            continue
        seen[key] = true
        var w := 0
        var h := 0
        for c in cur:
            w = maxi(w, c.x + 1)
            h = maxi(h, c.y + 1)
        shapes.append({"name": nm, "cells": cur, "w": w, "h": h, "n": cur.size(), "weight": weight})

func _rot(cells: Array) -> Array:
    var out: Array = []
    for c in cells:
        out.append(Vector2i(-c.y, c.x))
    return out

func _normalize(cells: Array) -> Array:
    var mx := 9999
    var my := 9999
    for c in cells:
        mx = mini(mx, c.x)
        my = mini(my, c.y)
    var out: Array = []
    for c in cells:
        out.append(Vector2i(c.x - mx, c.y - my))
    out.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
    return out

func _key(cells: Array) -> String:
    var parts: PackedStringArray = []
    for c in cells:
        parts.append("%d,%d" % [c.x, c.y])
    return ";".join(parts)

func _pick(rng: RandomNumberGenerator, fill: float) -> int:
    var ws: Array = []
    var total := 0.0
    for s in shapes:
        var w: float = s.weight
        if fill > 0.5:
            if s.n <= 3:
                w *= 1.6
            elif s.n >= 6:
                w *= 0.5
        elif fill < 0.2 and s.n == 1:
            w *= 0.4
        ws.append(w)
        total += w
    var roll := rng.randf() * total
    for i in ws.size():
        roll -= ws[i]
        if roll <= 0.0:
            return i
    return ws.size() - 1

## Balanced generation: at least one piece must fit the current board, and when the
## board is crowded we avoid giving several large pieces at once.
func generate_three(rng: RandomNumberGenerator) -> Array:
    var fill := BoardManager.filled_count() / 100.0
    var last_key := ""
    for attempt in 40:
        var set: Array = []
        for i in 3:
            set.append({"id": _pick(rng, fill), "color": 1 + rng.randi() % COLORS.size()})
        var any_fits := false
        var big := 0
        for p in set:
            if BoardManager.can_fit_anywhere(shapes[p.id].cells):
                any_fits = true
            if shapes[p.id].n >= 5:
                big += 1
        if not any_fits:
            continue
        if big >= 2 and fill > 0.4:
            continue
        if big >= 3:
            continue
        return set
    return _fallback(rng)

func _fallback(rng: RandomNumberGenerator) -> Array:
    var fitting: Array = []
    for i in shapes.size():
        if shapes[i].n <= 4 and BoardManager.can_fit_anywhere(shapes[i].cells):
            fitting.append(i)
    var set: Array = []
    for i in 3:
        var id := 0  # single block
        if not fitting.is_empty():
            id = fitting[rng.randi() % fitting.size()]
        set.append({"id": id, "color": 1 + rng.randi() % COLORS.size()})
    return set
