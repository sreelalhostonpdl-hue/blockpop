extends Node
## 10x10 board matrix. grid[y][x] = 0 (empty) or colour id 1..5.

const SIZE := 10

var grid: Array = []

func _ready() -> void:
    reset()

func reset() -> void:
    grid = []
    for y in SIZE:
        var row: Array = []
        row.resize(SIZE)
        row.fill(0)
        grid.append(row)

func can_place(cells: Array, ox: int, oy: int) -> bool:
    for c in cells:
        var x: int = ox + c.x
        var y: int = oy + c.y
        if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
            return false
        if grid[y][x] != 0:
            return false
    return true

func place(cells: Array, ox: int, oy: int, color: int) -> void:
    for c in cells:
        grid[oy + c.y][ox + c.x] = color

func can_fit_anywhere(cells: Array) -> bool:
    for y in SIZE:
        for x in SIZE:
            if can_place(cells, x, y):
                return true
    return false

func filled_count() -> int:
    var n := 0
    for y in SIZE:
        for x in SIZE:
            if grid[y][x] != 0:
                n += 1
    return n

## Detects ALL complete rows and columns on the current grid (nothing is cleared here).
func find_full_lines() -> Dictionary:
    var rows: Array = []
    var cols: Array = []
    for y in SIZE:
        var full := true
        for x in SIZE:
            if grid[y][x] == 0:
                full = false
                break
        if full:
            rows.append(y)
    for x in SIZE:
        var full := true
        for y in SIZE:
            if grid[y][x] == 0:
                full = false
                break
        if full:
            cols.append(x)
    return {"rows": rows, "cols": cols}

## Clears the given rows+columns simultaneously. Cells at intersections are counted once.
## Returns [{cell: Vector2i, color: int}] of every cleared cell.
func clear_lines(rows: Array, cols: Array) -> Array:
    var seen := {}
    var out: Array = []
    for y in rows:
        for x in SIZE:
            _collect(Vector2i(x, y), seen, out)
    for x in cols:
        for y in SIZE:
            _collect(Vector2i(x, y), seen, out)
    for e in out:
        grid[e.cell.y][e.cell.x] = 0
    return out

func _collect(c: Vector2i, seen: Dictionary, out: Array) -> void:
    if seen.has(c):
        return
    seen[c] = true
    out.append({"cell": c, "color": grid[c.y][c.x]})

func to_array() -> Array:
    var out: Array = []
    for row in grid:
        out.append(row.duplicate())
    return out

func from_array(a: Array) -> bool:
    if a.size() != SIZE:
        return false
    var g: Array = []
    for row in a:
        if not (row is Array) or row.size() != SIZE:
            return false
        var r: Array = []
        for v in row:
            r.append(clampi(int(v), 0, 9))
        g.append(r)
    grid = g
    return true
