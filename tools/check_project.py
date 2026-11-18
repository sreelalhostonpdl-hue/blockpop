"""Static sanity checks (no Godot needed): res:// refs, autoload files, indentation,
bracket balance, and that every `Autoload.method(` / `UI.method(` call has a matching func.
Run: python3 tools/check_project.py"""
import re, sys, glob, os
os.chdir(os.path.join(os.path.dirname(__file__), ".."))
errors = []
gd = glob.glob("scripts/**/*.gd", recursive=True) + glob.glob("tests/*.gd")
text = {f: open(f).read() for f in gd}

# 1. res:// references
for f in gd + ["project.godot", "export_presets.cfg"] + glob.glob("scenes/*.tscn") + glob.glob("tests/*.tscn"):
    t = open(f).read() if f not in text else text[f]
    for m in re.finditer(r'res://[A-Za-z0-9_/\.\-]+', t):
        path = m.group(0)
        if not os.path.exists(path[6:]):
            errors.append(f"{f}: missing {path}")
# dynamic sfx names
for n in ["place","clear","combo","gameover","click","pickup","invalid","music"]:
    if not os.path.exists(f"assets/audio/{n}.wav"): errors.append(f"missing audio {n}")

# 2. indentation + brackets
for f, t in text.items():
    depth = {"(":0,"[":0,"{":0}
    for i, line in enumerate(t.split("\n"), 1):
        if "\t" in line: errors.append(f"{f}:{i} tab character")
        stripped = line.lstrip(" ")
        if stripped and not stripped.startswith("#") and (len(line)-len(stripped)) % 4:
            if not (depth["("] or depth["["] or depth["{"]) and not line.rstrip().endswith("\\") :
                prev = t.split("\n")[i-2].rstrip() if i>1 else ""
                if not prev.endswith("\\"): errors.append(f"{f}:{i} indent not multiple of 4")
        code = re.sub(r'"(\\.|[^"\\])*"', '""', line.split("#")[0])
        for ch in code:
            if ch in "([{": depth[ch]+=1
            elif ch == ")": depth["("]-=1
            elif ch == "]": depth["["]-=1
            elif ch == "}": depth["{"]-=1
    if any(v for v in depth.values()): errors.append(f"{f}: unbalanced brackets {depth}")

# 3. API call cross-check
funcs = {}
auto = {"SaveManager","BoardManager","PieceManager","ScoreManager","AudioManager","AdManager","GameManager","UIManager"}
for a in auto:
    t = text[f"scripts/{a}.gd"]
    funcs[a] = set(re.findall(r'^func (\w+)', t, re.M)) | set(re.findall(r'^(?:var|const) (\w+)', t, re.M)) | set(re.findall(r'^signal (\w+)', t, re.M))
funcs["UI"] = set(re.findall(r'^static func (\w+)', text["scripts/ui/UITheme.gd"], re.M)) | set(re.findall(r'^const (\w+)', text["scripts/ui/UITheme.gd"], re.M))
for f, t in text.items():
    for m in re.finditer(r'\b(' + "|".join(list(auto)+["UI"]) + r')\.(\w+)', t):
        owner, member = m.groups()
        if member not in funcs[owner] and member not in ("connect","emit"):
            errors.append(f"{f}: {owner}.{member} not defined")
print("\n".join(errors) if errors else "ALL STATIC CHECKS PASSED")
print(f"{len(gd)} scripts checked")
sys.exit(1 if errors else 0)
