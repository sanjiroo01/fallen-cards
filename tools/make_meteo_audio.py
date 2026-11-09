"""Suoni del tempo atmosferico, sintetizzati (niente campioni esterni): pioggia in loop, tre tuoni, vento, cripta.
Serve solo numpy (va bene il Python di Blender).
Uso: python tools/make_meteo_audio.py  -> scrive pioggia.wav, tuono_1..3.wav, vento.wav in audio/
"""
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")
rng = np.random.default_rng(16)


def spectral(x, lo, hi, tilt=0.0):
    """Filtro passa-banda nel dominio delle frequenze (lo/hi in Hz), con pendenza in dB per ottava."""
    f = np.fft.rfftfreq(len(x), 1 / SR)
    X = np.fft.rfft(x)
    g = np.ones_like(f)
    g *= 1 / (1 + (lo / np.maximum(f, 1)) ** 4)
    g *= 1 / (1 + (f / hi) ** 4)
    if tilt:
        g *= (np.maximum(f, 20) / 1000) ** (tilt / 6.02)
    return np.fft.irfft(X * g, len(x))


def conv(x, ir):
    n = len(x) + len(ir) - 1
    m = 1 << (n - 1).bit_length()
    return np.fft.irfft(np.fft.rfft(x, m) * np.fft.rfft(ir, m), m)[:n]


def reverb(x, length=2.5, mix=0.35):
    n = int(SR * length)
    ir = rng.standard_normal(n) * np.exp(-5.0 * np.arange(n) / n)
    ir = spectral(ir, 80, 4000)
    ir[0] = 0
    wet = conv(x, ir)
    wet /= np.abs(wet).max() + 1e-9
    dry = np.pad(x, (0, len(wet) - len(x)))
    return dry * (1 - mix) + wet * mix * np.abs(x).max()


def loopify(x, xf=1.5):
    n = int(SR * xf)
    k = np.linspace(0, 1, n)
    return np.concatenate([x[-n:] * (1 - k) + x[:n] * k, x[n:-n]])


def save(name, x, gain=0.9, stereo=None):
    x = np.asarray(x, dtype=np.float64)
    peak = np.abs(x).max() + 1e-9
    x = x / peak * gain
    if stereo is not None:
        y = np.asarray(stereo, dtype=np.float64) / peak * gain
        data = np.stack([x, y], axis=1)
        ch = 2
    else:
        data = x
        ch = 1
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(ch)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(data, -1, 1) * 32767).astype(np.int16).tobytes())
    print("ok", name, round(len(x) / SR, 2), "s")


def rain(sec=14.0):
    """Pioggia: fruscio largo (gocce lontane) + migliaia di piccoli tic (gocce vicine) + gocciolio grave."""
    n = int(SR * sec)
    chans = []
    for c in range(2):
        hiss = spectral(rng.standard_normal(n), 400, 9000, tilt=-2.0) * 0.5
        hiss *= 1 + 0.25 * spectral(rng.standard_normal(n), 0.1, 0.8)      # lente ondate
        drops = np.zeros(n)
        idx = rng.integers(0, n - 400, int(sec * 1400))
        amp = rng.uniform(0.2, 1.0, len(idx)) ** 3
        drops[idx] = amp * rng.choice([-1, 1], len(idx))
        click = np.exp(-np.arange(200) / 18.0) * np.sin(np.arange(200) * rng.uniform(0.6, 1.2))
        drops = conv(drops, click)[:n]
        drops = spectral(drops, 1500, 12000) * 1.4
        low = spectral(rng.standard_normal(n), 60, 400) * 0.25            # acqua che scorre, rombo sotto
        chans.append(loopify(hiss + drops + low))
    save("pioggia.wav", chans[0], 0.8, chans[1])


def thunder(name, sec, crack, seed):
    """Tuono: schiocco secco (se vicino), poi brontolio grave a ondate che si spegne."""
    r = np.random.default_rng(seed)
    n = int(SR * sec)
    t = np.arange(n) / SR
    rumble = spectral(r.standard_normal(n), 25, 260, tilt=-3.0)
    # ondate: il brontolio rotola, si allontana e ritorna
    env = np.exp(-t / (sec * 0.35)) * (1 - np.exp(-t / 0.15))
    rolls = 0.55 + 0.45 * np.abs(spectral(r.standard_normal(n), 0.4, 3.0))
    rolls /= rolls.max()
    x = rumble * env * rolls
    if crack > 0:
        m = int(SR * 0.35)
        snap = spectral(r.standard_normal(m), 300, 7000) * np.exp(-np.arange(m) / (SR * 0.06)) * crack * 3
        x[:m] += snap
    x = reverb(x, 3.0, 0.45)
    save(name, x, 0.95)


def wind(sec=16.0):
    """Vento sul lago: soffio con fischi lenti che salgono e scendono."""
    n = int(SR * sec)
    chans = []
    for c in range(2):
        base = spectral(rng.standard_normal(n), 120, 1800, tilt=-1.5)
        gust = 0.35 + 0.65 * np.clip(spectral(rng.standard_normal(n), 0.05, 0.35) * 3 + 0.5, 0, 1)
        whistle = spectral(rng.standard_normal(n), 500, 900) * 0.6 * gust ** 2
        chans.append(loopify(base * gust + whistle))
    save("vento.wav", chans[0], 0.7, chans[1])


def crypt(sec=18.0):
    """Cripta: gocce rade che cadono in pozze e rimbombano sotto la volta, brusio grave e lontano."""
    n = int(SR * sec)
    chans = []
    for c in range(2):
        drone = spectral(rng.standard_normal(n), 35, 160, tilt=-2.0) * 0.5
        drone *= 0.7 + 0.3 * np.clip(spectral(rng.standard_normal(n), 0.03, 0.2) * 3 + 0.5, 0, 1)
        air = spectral(rng.standard_normal(n), 200, 1200, tilt=-3.0) * 0.12
        drips = np.zeros(n)
        t = 0.3
        while t < sec - 0.5:
            i = int(t * SR)
            m = int(SR * 0.09)
            f0 = rng.uniform(900, 1900)
            k = np.arange(m) / SR
            # goccia: un tonfo breve con il tono che sale (acqua che si chiude)
            drips[i:i + m] += np.sin(2 * np.pi * f0 * k * (1 + 4 * k)) * np.exp(-k / 0.018) * rng.uniform(0.3, 1.0)
            t += rng.uniform(0.6, 2.6)
        drips = reverb(drips, 3.5, 0.6)[:n]
        chans.append(loopify(drone + air + drips * 0.8))
    save("cripta.wav", chans[0], 0.75, chans[1])


if __name__ == "__main__":
    rain()
    thunder("tuono_1.wav", 7.0, 1.0, 1)      # vicino: schiocco forte
    thunder("tuono_2.wav", 8.0, 0.35, 2)     # medio
    thunder("tuono_3.wav", 9.0, 0.0, 3)      # lontano: solo brontolio
    wind()
    crypt()
