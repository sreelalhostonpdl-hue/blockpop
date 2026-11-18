"""Generates all original BLOCKPOP audio + icon assets. Requires numpy + Pillow.
Run:  python3 tools/generate_assets.py   (from project root)"""
import wave, os
import numpy as np
from PIL import Image, ImageDraw

SR = 22050
OUT_A = "assets/audio"
OUT_I = "assets/icons"

def save(name, buf):
    buf = np.clip(buf, -1, 1)
    with wave.open(f"{OUT_A}/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((buf * 32767).astype("<i2").tobytes())

def note(f, d, k=8.0, vol=0.5, harm=0.25, sweep=0.0):
    t = np.linspace(0, d, int(SR * d), False)
    ph = 2 * np.pi * (f * t + sweep * t * t / (2 * d))
    w = np.sin(ph) + harm * np.sin(2 * ph) + harm * 0.4 * np.sin(3 * ph)
    env = np.minimum(1, t / 0.004) * np.exp(-t * k)
    return w * env * vol

def mix(parts, length):
    buf = np.zeros(int(SR * length))
    for start, sig in parts:
        s = int(start * SR); e = min(len(buf), s + len(sig))
        buf[s:e] += sig[: e - s]
    return buf

def hz(n):  # n semitones from A4
    return 440.0 * 2 ** (n / 12)

C5, E5, G5, B5, C6, D6, E6, G6, B6 = hz(3), hz(7), hz(10), hz(14), hz(15), hz(17), hz(19), hz(22), hz(26)

os.makedirs(OUT_A, exist_ok=True); os.makedirs(OUT_I, exist_ok=True)
save("place", mix([(0, note(160, 0.14, 22, 0.7, 0.1, sweep=-90)), (0.0, note(520, 0.09, 35, 0.35))], 0.18))
save("clear", mix([(i * 0.055, note(f, 0.35, 7, 0.4)) for i, f in enumerate([C5, E5, G5, C6, E6])], 0.65))
save("combo", mix([(i * 0.05, note(f, 0.45, 6, 0.4)) for i, f in enumerate([G5, B5, D6, G6, B6, D6 * 2])], 0.8))
save("gameover", mix([(i * 0.22, note(f, 0.7, 4, 0.45)) for i, f in enumerate([hz(7), hz(3), hz(0), hz(-4)])], 1.6))
save("click", note(900, 0.06, 55, 0.5))
save("pickup", note(660, 0.07, 40, 0.4))
save("invalid", note(110, 0.18, 14, 0.6, 0.6))

# --- music: 8 bars @ 92 BPM, loop-safe (circular mixing) ---
bpm = 92; beat = 60 / bpm; bar = beat * 4; total = bar * 8
N = int(SR * total); buf = np.zeros(N)
def add(start, sig):
    idx = (int(start * SR) + np.arange(len(sig))) % N
    np.add.at(buf, idx, sig)
chords = [(-24, [-12, -9, -5]), (-28, [-16, -12, -9]), (-21, [-9, -5, -2]), (-26, [-14, -10, -7])]  # Am F C G
for ci, (b, tones) in enumerate(chords):
    start = ci * 2 * bar; dur = 2 * bar
    t = np.linspace(0, dur, int(SR * dur), False)
    win = np.sin(np.pi * t / dur) ** 1.5
    pad = sum(np.sin(2 * np.pi * hz(n) * t) + 0.5 * np.sin(2 * np.pi * hz(n + 12) * t) for n in tones)
    add(start, pad * win * 0.07)
    for k in range(8):
        add(start + k * beat, note(hz(b), beat * 0.9, 3.5, 0.28, 0.2))
    pat = [0, 1, 2, 1, 2, 1, 0, 2, 1, 2, 1, 0, 2, 1, 2, 1]
    for k, p in enumerate(pat):
        add(start + k * beat / 2, note(hz(tones[p] + 24), beat * 0.8, 6, 0.16, 0.3))
buf /= np.max(np.abs(buf)) * 1.25
save("music", buf)

# --- icons ---
COLS = [(34, 211, 238), (255, 79, 163), (255, 159, 28), (155, 92, 255)]
def gradient(size):
    ys, xs = np.mgrid[0:size, 0:size] / (size - 1)
    t = 0.6 * ys + 0.4 * xs
    a = np.array([11, 16, 48]); b = np.array([62, 20, 120])
    arr = (a[None, None, :] + (b - a)[None, None, :] * t[..., None]).astype("uint8")
    return Image.fromarray(arr, "RGB")
def blocks(size, span):
    S = 2; big = size * S
    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0)); d = ImageDraw.Draw(layer)
    cell = span * S / 2; gap = cell * 0.08; x0 = (big - span * S) / 2
    for i, c in enumerate(COLS):
        cx = x0 + (i % 2) * cell; cy = x0 + (i // 2) * cell
        box = (cx + gap, cy + gap, cx + cell - gap, cy + cell - gap)
        dark = tuple(int(v * 0.55) for v in c)
        d.rounded_rectangle((box[0], box[1] + cell * 0.05, box[2], box[3] + cell * 0.05), cell * 0.22, fill=dark + (255,))
        d.rounded_rectangle(box, cell * 0.22, fill=c + (255,))
        d.rounded_rectangle((box[0] + cell * 0.12, box[1] + cell * 0.08, box[2] - cell * 0.12, box[1] + cell * 0.38), cell * 0.16, fill=(255, 255, 255, 70))
    return layer.resize((size, size), Image.LANCZOS)
def compose(size, span):
    base = gradient(size).convert("RGBA"); base.alpha_composite(blocks(size, span)); return base
compose(512, 330).save(f"{OUT_I}/icon_512.png")
compose(192, 124).save(f"{OUT_I}/icon_192.png")
gradient(432).save(f"{OUT_I}/adaptive_bg_432.png")
blocks(432, 250).save(f"{OUT_I}/adaptive_fg_432.png")
blocks(512, 420).save(f"{OUT_I}/splash.png")
print("assets generated")
