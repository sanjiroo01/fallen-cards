"""Genera tutti i suoni di PROGETTO (sintesi, niente campioni esterni).
Uso: python3 tools/make_audio.py  -> scrive i .wav in audio/
"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
rng = np.random.default_rng(13)


def t(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.005, d=0.2, curve=4.0):
    x = np.arange(n) / SR
    e = np.minimum(1.0, x / max(a, 1e-4)) * np.exp(-curve * np.maximum(0.0, x - a) / max(d, 1e-4))
    return e


def bp(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, hi], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lp(x, f, order=2):
    sos = signal.butter(order, f, btype="low", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def hp(x, f, order=2):
    sos = signal.butter(order, f, btype="high", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def noise(d):
    return rng.standard_normal(int(SR * d))


def brown(d):
    w = rng.standard_normal(int(SR * d))
    b = np.cumsum(w)
    b = hp(b, 20)
    return b / (np.abs(b).max() + 1e-9)


def reverb(x, length=1.2, mix=0.3, damp=3000):
    n = int(SR * length)
    ir = rng.standard_normal(n) * np.exp(-6.0 * np.arange(n) / n)
    ir = lp(ir, damp)
    ir[0] = 0
    wet = signal.fftconvolve(x, ir)
    total = len(x) + n
    wet = np.pad(wet, (0, max(0, total - len(wet))))[:total]
    wet /= np.abs(wet).max() + 1e-9
    dry = np.concatenate([x, np.zeros(n)])
    dry_n = dry / (np.abs(dry).max() + 1e-9)
    return (1 - mix) * dry_n + mix * wet


def mode(f, d, decay):
    x = t(d)
    return np.sin(2 * np.pi * f * x) * np.exp(-x / decay)


def save(name, x, gain=0.9):
    x = np.asarray(x, dtype=np.float64)
    x = x / (np.abs(x).max() + 1e-9) * gain
    fade = int(0.004 * SR)
    x[-fade:] *= np.linspace(1, 0, fade)
    wavfile.write(os.path.join(OUT, name), SR, (x * 32767).astype(np.int16))
    print("ok", name, round(len(x) / SR, 2), "s")


def loopify(x, xf=2.0):
    n = int(SR * xf)
    head = x[:n].copy()
    tail = x[-n:].copy()
    k = np.linspace(0, 1, n)
    mixed = tail * (1 - k) + head * k
    return np.concatenate([mixed, x[n:-n]])


def amb_cerchio():
    d = 34.0
    room = lp(brown(d), 140) * 0.5
    rain = bp(noise(d), 600, 4500) * 0.05
    rain = lp(rain, 2200) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.05 * t(d)))
    x = room + rain
    # gocce
    for s in rng.uniform(0.5, d - 1.0, 11):
        dd = 0.25
        tt = t(dd)
        f = 1400 - 700 * np.minimum(tt / 0.03, 1.0)
        drip = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt / 0.03) * rng.uniform(0.04, 0.09)
        i = int(s * SR)
        x[i:i + len(drip)] += drip
    # tuono lontano
    th = lp(brown(4.0), 90) * env(int(SR * 4.0), 0.6, 2.0, 1.5) * 0.9
    i = int(18.0 * SR)
    x[i:i + len(th)] += th
    x = reverb(x, 1.6, 0.25, 2000)[: len(x)]
    save("amb_cerchio.wav", loopify(x), 0.5)


def music_drone():
    d = 44.0
    tt = t(d)
    notes = [73.42, 110.0, 87.31, 146.83]
    x = np.zeros_like(tt)
    for i, f in enumerate(notes):
        for det in (-0.25, 0.0, 0.3):
            ph = 2 * np.pi * (f + det) * tt
            saw = signal.sawtooth(ph + rng.uniform(0, 6))
            x += saw * (0.5 if i == 0 else 0.3)
    lfo = 0.5 + 0.5 * np.sin(2 * np.pi * tt / 22.0)
    # filtro che si apre e si chiude lentamente
    out = np.zeros_like(x)
    seg = SR // 2
    for k in range(0, len(x), seg):
        fc = 220 + 380 * lfo[k]
        out[k:k + seg] = lp(x[k:k + seg], fc)
    out *= 0.8 + 0.2 * np.sin(2 * np.pi * tt * 0.13)
    choir = bp(noise(d), 700, 900) * 0.02 * (0.5 + 0.5 * np.sin(2 * np.pi * tt / 15.0))
    out = out + choir
    out = reverb(out, 2.5, 0.35, 1500)[: len(out)]
    save("music_drone.wav", loopify(out, 4.0), 0.45)


def slam():
    d = 0.9
    tt = t(d)
    f = 70 * np.exp(-tt * 8) + 45
    thump = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt / 0.12)
    knock = bp(noise(d), 250, 2200) * np.exp(-tt / 0.03)
    wood = mode(190, d, 0.09) + 0.6 * mode(420, d, 0.07) + 0.4 * mode(770, d, 0.05)
    x = thump * 1.0 + knock * 0.6 + wood * 0.4
    save("slam.wav", reverb(x, 0.9, 0.22, 3000), 0.95)


def chop():
    d = 1.6
    tt = t(d)
    f = 110 * np.exp(-tt * 14) + 50
    thunk = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt / 0.09)
    crunch = lp(noise(d), 1500) * np.exp(-tt / 0.05)
    ring = sum(mode(fr, d, dc) * a for fr, dc, a in [(1830, 0.5, 0.3), (2690, 0.35, 0.22), (4150, 0.2, 0.15), (5980, 0.12, 0.1)])
    x = thunk + crunch * 0.7 + ring * 0.5
    save("chop.wav", reverb(x, 1.4, 0.28, 2500), 0.95)


def blow():
    d = 2.2
    tt = t(d)
    n = noise(d)
    out = np.zeros_like(n)
    seg = SR // 20
    for k in range(0, len(n), seg):
        c = 500 * np.exp(-k / SR * 1.2) + 120
        out[k:k + seg] = bp(n[k:k + seg], c * 0.6, c * 1.8)
    e = np.minimum(1.0, tt / 0.25) * np.exp(-np.maximum(0, tt - 0.25) * 1.6)
    hiss = hp(noise(d), 3500) * np.exp(-tt / 0.3) * 0.25
    x = out * e + hiss
    save("blow.wav", reverb(x, 1.5, 0.3, 2000), 0.8)


def relight():
    d = 1.4
    tt = t(d)
    scratch = bp(noise(d), 2500, 7000) * (np.abs(np.sin(2 * np.pi * 38 * tt)) ** 3) * (tt < 0.22)
    whoosh = lp(noise(d), 900) * np.exp(-np.maximum(0, tt - 0.2) / 0.25) * (tt > 0.2)
    crackle = np.zeros_like(tt)
    for s in rng.uniform(0.25, 1.2, 25):
        i = int(s * SR)
        crackle[i:i + 60] += rng.standard_normal(60) * np.exp(-np.arange(60) / 10) * 0.4
    x = scratch * 0.7 + whoosh * 0.5 + hp(crackle, 1500)
    save("relight.wav", reverb(x, 0.8, 0.2, 4000), 0.7)


def coin_one(d=0.6):
    tt = t(d)
    parts = [(2350, 0.35), (3740, 0.25), (5210, 0.18), (6800, 0.12), (8900, 0.08)]
    x = sum(np.sin(2 * np.pi * f * tt + rng.uniform(0, 6)) * np.exp(-tt / dc) * (1.0 / (i + 1)) for i, (f, dc) in enumerate(parts))
    click = hp(noise(d), 4000) * np.exp(-tt / 0.004)
    return x + click * 0.5


def coins():
    x = np.zeros(int(SR * 1.2))
    for s in (0.0, 0.09, 0.22, 0.31):
        c = coin_one(0.7) * rng.uniform(0.5, 1.0)
        i = int(s * SR)
        x[i:i + len(c)] += c[: len(x) - i]
    save("coins.wav", reverb(x, 0.8, 0.2, 5000), 0.6)
    save("coin.wav", reverb(coin_one(0.7), 0.8, 0.2, 5000), 0.6)


def creak(name, lo, hi, d, rate0, rate1, gain):
    tt = t(d)
    x = np.zeros_like(tt)
    ph = 0.0
    k = 0
    while True:
        prog = k / (d * (rate0 + rate1) / 2)
        r = rate0 + (rate1 - rate0) * min(prog, 1.0)
        ph += 1.0 / r
        i = int(ph * SR)
        if i >= len(x) - 200:
            break
        x[i:i + 120] += rng.standard_normal(120) * np.exp(-np.arange(120) / 25)
        k += 1
    y = bp(x, lo, hi) + 0.6 * bp(x, lo * 2.1, hi * 1.6)
    y *= np.sin(np.pi * tt / d) ** 0.6
    save(name, reverb(y, 0.9, 0.3, 2500), gain)


def drum():
    d = 1.3
    tt = t(d)
    f = 95 * np.exp(-tt * 6) + 55
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt / 0.35)
    skin = bp(noise(d), 150, 1200) * np.exp(-tt / 0.04)
    x = body + skin * 0.5
    save("drum.wav", reverb(x, 1.8, 0.35, 1500), 0.95)


def bell():
    d = 6.0
    tt = t(d)
    f0 = 196.0
    parts = [(0.5, 1.0, 3.5), (1.0, 0.8, 2.5), (1.2, 0.5, 2.0), (1.5, 0.35, 1.6), (2.0, 0.45, 1.3), (2.51, 0.2, 0.9), (3.0, 0.15, 0.7)]
    x = sum(a * np.sin(2 * np.pi * f0 * r * tt) * np.exp(-tt / dc) for r, a, dc in parts)
    x = lp(x, 1400)
    save("bell.wav", reverb(x, 3.0, 0.45, 1200), 0.6)


def heart():
    d = 0.8
    tt = t(d)
    def beat(at, a):
        x = np.zeros_like(tt)
        s = tt - at
        m = s > 0
        x[m] = np.sin(2 * np.pi * 48 * s[m]) * np.exp(-s[m] / 0.07) * a
        return x
    x = beat(0.0, 1.0) + beat(0.2, 0.7)
    save("heart.wav", lp(x, 200), 0.9)


def ghost():
    d = 3.5
    tt = t(d)
    n = noise(d)
    out = np.zeros_like(n)
    seg = SR // 25
    for k in range(0, len(n), seg):
        c = 650 + 300 * np.sin(2 * np.pi * k / SR * 0.9) + 150 * np.sin(2 * np.pi * k / SR * 2.3)
        out[k:k + seg] = bp(n[k:k + seg], c * 0.85, c * 1.15, 1)
    wail = np.sin(2 * np.pi * (330 + 40 * np.sin(2 * np.pi * 0.6 * tt)) * tt) * 0.15
    x = (out * 0.8 + wail) * np.sin(np.pi * tt / d) ** 1.5
    save("ghost.wav", reverb(x, 2.5, 0.5, 2500), 0.55)


def click():
    d = 0.08
    tt = t(d)
    x = bp(noise(d), 800, 3000) * np.exp(-tt / 0.006) + mode(900, d, 0.012) * 0.4
    save("click.wav", x, 0.5)


def swell(name, notes, d, gain):
    tt = t(d)
    x = np.zeros_like(tt)
    for f in notes:
        for det in (-0.4, 0.0, 0.35):
            x += signal.sawtooth(2 * np.pi * (f + det) * tt + rng.uniform(0, 6))
    x = lp(x, 900)
    e = np.minimum(1.0, tt / (d * 0.4)) * np.exp(-np.maximum(0, tt - d * 0.4) / (d * 0.35))
    save(name, reverb(x * e, 2.5, 0.4, 1500), gain)


def whoosh():
    d = 0.9
    tt = t(d)
    n = noise(d)
    out = np.zeros_like(n)
    seg = SR // 30
    for k in range(0, len(n), seg):
        c = 300 + 2200 * (k / len(n)) ** 2
        out[k:k + seg] = bp(n[k:k + seg], c * 0.7, c * 1.4, 1)
    x = out * np.sin(np.pi * tt / d) ** 2
    save("whoosh.wav", x, 0.6)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    amb_cerchio()
    music_drone()
    slam()
    chop()
    blow()
    relight()
    coins()
    creak("creak.wav", 350, 900, 0.9, 22, 70, 0.7)
    creak("chair.wav", 180, 520, 1.3, 12, 35, 0.6)
    drum()
    bell()
    heart()
    ghost()
    click()
    swell("win.wav", [146.83, 220.0, 293.66, 349.23], 4.5, 0.6)
    swell("lose.wav", [73.42, 77.78, 110.0], 4.0, 0.6)
    whoosh()
