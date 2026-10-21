"""Synthesizes the short UI sound effects (original, royalty-free)."""
import numpy as np, wave, os
SR = 44100
def save(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.85
    d = (x * 32767).astype(np.int16)
    with wave.open(f"assets/audio/sfx/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes())
def t(sec): return np.linspace(0, sec, int(SR * sec), endpoint=False)
def env(n, a=0.005, r=0.1):
    tt = np.arange(n) / SR
    return np.minimum(tt / a, 1) * np.exp(-tt / r)
# pops: pitch drop bubble
for i, (f0, f1) in enumerate([(900, 300), (1050, 350), (780, 260)], 1):
    tt = t(0.16); f = f1 + (f0 - f1) * np.exp(-tt * 40)
    ph = 2 * np.pi * np.cumsum(f) / SR
    save(f"pop{i}", np.sin(ph) * env(len(tt), 0.002, 0.04))
# sparkle: high chime cluster
tt = t(0.6); x = np.zeros_like(tt)
for k, (fr, dl) in enumerate([(2093, 0), (2637, 0.05), (3136, 0.1), (4186, 0.15)]):
    s = int(dl * SR); n = len(tt) - s
    x[s:] += np.sin(2*np.pi*fr*np.arange(n)/SR) * env(n, 0.002, 0.12) * (0.8 ** k)
save("sparkle", x)
# tada: major arpeggio + chord
tt = t(1.4); x = np.zeros_like(tt)
for k, fr in enumerate([523.25, 659.25, 783.99, 1046.5]):
    s = int(k * 0.09 * SR); n = len(tt) - s; a = np.arange(n) / SR
    tone = np.sin(2*np.pi*fr*a) + 0.4*np.sin(4*np.pi*fr*a) + 0.15*np.sin(6*np.pi*fr*a)
    x[s:] += tone * env(n, 0.005, 0.45)
save("tada", x)
# click: soft wooden tick
tt = t(0.06); save("click", np.sin(2*np.pi*1400*tt) * env(len(tt), 0.001, 0.012))
# undo: reverse-ish whoosh (filtered noise sweep)
tt = t(0.25); rng = np.random.default_rng(1); n = rng.standard_normal(len(tt))
from scipy.signal import butter, lfilter
b, a = butter(2, [400/(SR/2), 2500/(SR/2)], btype="band"); n = lfilter(b, a, n)
save("undo", n * np.sin(np.pi * tt / 0.25) ** 2)
# brush start: tiny soft swish
tt = t(0.12); n2 = lfilter(*butter(2, [1500/(SR/2), 6000/(SR/2)], btype="band"), rng.standard_normal(len(tt)))
save("swish", n2 * np.sin(np.pi * tt / 0.12) ** 2 * 0.6)

# ---------------------------------------------------------------- v0.2 additions
def tone(fr, sec, a=0.005, r=0.2, harm=(1, 0.3, 0.1)):
    tt = t(sec); x = sum(h*np.sin(2*np.pi*fr*(k+1)*tt) for k, h in enumerate(harm))
    return x * env(len(tt), a, r)
def seq(notes, gap, sec=0.5, r=0.2):
    total = gap*len(notes) + sec; x = np.zeros(int(SR*total))
    for i, f in enumerate(notes):
        s = int(i*gap*SR); y = tone(f, sec, r=r); x[s:s+len(y)] += y
    return x
def sweep(f0, f1, sec, kind="sin", r=0.3):
    tt = t(sec); f = f0 * (f1/f0) ** (tt/sec); ph = 2*np.pi*np.cumsum(f)/SR
    w = np.sin(ph) if kind == "sin" else np.sign(np.sin(ph))*0.4
    return w * env(len(tt), 0.01, r)
def noise_band(sec, lo, hi, shape=None):
    n = lfilter(*butter(2, [lo/(SR/2), hi/(SR/2)], btype="band"), rng.standard_normal(int(SR*sec)))
    tt = t(sec); return n * (shape(tt) if shape else np.sin(np.pi*tt/sec))
save("wrong", sweep(420, 260, 0.35, r=0.15))
save("magic", seq([1046, 1318, 1568, 2093, 2637, 3136], 0.05, 0.4, 0.15))
save("unlock", seq([523, 659, 784, 1046, 1318], 0.08, 0.6, 0.25))
_g = seq([784, 988, 1175, 1568], 0.1, 0.8, 0.35); _n = noise_band(0.3, 2000, 8000); _g[:len(_n)] += 0.3*_n
save("gift", _g)
save("star", seq([1568, 2093], 0.07, 0.4, 0.15))
save("life", seq([392, 523, 659, 784, 1046, 1318, 1568, 2093], 0.07, 0.7, 0.3))
save("achievement", seq([659, 784, 1046, 784, 1046, 1318], 0.11, 0.7, 0.3))
# per-drawing voices (cute, non-scary)
tt = t(0.8); f = 180 + 60*np.sin(np.pi*tt/0.8); g = np.sign(np.sin(2*np.pi*np.cumsum(f)/SR))*0.5
save("roar", lfilter(*butter(2, 900/(SR/2)), g + 0.4*noise_band(0.8, 100, 1200)) * np.sin(np.pi*tt/0.8)**0.6)
tt = t(0.6); f = 500 + 350*np.sin(np.pi*tt/0.6); w = np.sin(2*np.pi*np.cumsum(f)/SR)
save("meow", (w + 0.3*np.sin(4*np.pi*np.cumsum(f)/SR)) * np.sin(np.pi*tt/0.6))
save("chirp", np.concatenate([sweep(2200, 3800, 0.09, r=0.06), np.zeros(1500), sweep(2400, 4200, 0.09, r=0.06), np.zeros(1500), sweep(2000, 3600, 0.12, r=0.08)]))
save("beep", np.concatenate([tone(880, 0.15, r=0.08), np.zeros(2500), tone(1175, 0.2, r=0.1)]))
save("whoosh", noise_band(0.7, 300, 3000))
save("toot", np.concatenate([tone(587, 0.3, 0.02, 0.4, (1, .5, .3, .2)), tone(740, 0.5, 0.02, 0.5, (1, .5, .3, .2))]))
save("twinkle", seq([2093, 2637, 3136, 2637, 3136, 4186], 0.08, 0.5, 0.2))
save("bubble", np.concatenate([sweep(300, 1200, 0.08, r=0.05) for _ in range(4)]))
save("splash", noise_band(0.6, 500, 6000, lambda x: np.exp(-x*6)) + 0.4*sweep(800, 200, 0.6))
save("launch", noise_band(1.2, 80, 900, lambda x: np.minimum(x*3, 1)*np.exp(-x*1.5)) + 0.5*sweep(200, 900, 1.2))
save("chime", seq([1318, 1760, 2093], 0.12, 0.8, 0.4))
save("ding", np.concatenate([tone(1318, 0.5, r=0.3), tone(1046, 0.7, r=0.4)]))
save("squeak", sweep(900, 1800, 0.18, r=0.1))
save("boing", (np.sin(2*np.pi*np.cumsum(200 + 300*np.exp(-t(0.6)*5)*np.cos(2*np.pi*12*t(0.6)))/SR)) * env(int(SR*0.6), 0.005, 0.25))
save("giggle", np.concatenate([sweep(700, 1100, 0.07, r=0.05) for _ in range(5)]))
save("hello", np.concatenate([sweep(500, 900, 0.15, r=0.1), np.zeros(1200), sweep(700, 1200, 0.2, r=0.15)]))

# ---------------------------------------------------------------- music loops
def music(name, notes, bpm, bass):
    beat = 60 / bpm; total = beat * len(notes); x = np.zeros(int(SR*total))
    for i, f in enumerate(notes):
        if f:
            y = tone(f, beat*1.8, 0.01, beat*0.9, (1, 0.25, 0.05)) * 0.35
            s = int(i*beat*SR); e = min(len(x), s + len(y)); x[s:e] += y[:e - s]
    for i, f in enumerate(bass):
        y = tone(f, beat*4, 0.05, beat*2.5, (1, 0.1)) * 0.25
        s = int(i*4*beat*SR); e = min(len(x), s + len(y)); x[s:e] += y[:e - s]
    # wrap the tails so the loop is seamless
    save(name, x)
C, D, E, G, A = 523.25, 587.33, 659.25, 783.99, 880.0
music("music_meadow", [E, G, A, G, E, D, C, None, D, E, G, E, D, C, D, None, E, G, A, C*2, A, G, E, None, D, E, D, C, D, C, None, None], 104,
      [130.8, 98.0, 110.0, 98.0, 130.8, 98.0, 110.0, 98.0])
music("music_dream", [A, None, E, G, None, E, D, None, C, None, D, E, None, G, E, None, A, None, C*2, A, None, G, E, None, D, None, E, C, None, None, None, None], 84,
      [110.0, 87.3, 130.8, 98.0, 110.0, 87.3, 130.8, 98.0])
