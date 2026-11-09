"""Suoni della foresta cupa, sintetizzati (niente campioni esterni):
- foresta.wav: notte nel bosco in loop (vento fra i pini, grilli radi, un gufo, tronchi che scricchiolano,
  un rametto che si spezza);
- musica_foresta.wav: musichetta horror in loop (carillon stonato in re minore su un tappeto grave e
  dissonante, colpi lontani di tamburo).
Serve solo numpy (va bene il Python di Blender).
Uso: python tools/make_foresta_audio.py  -> scrive i .wav in audio/
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_meteo_audio import SR, conv, loopify, reverb, save, spectral  # noqa: E402

rng = np.random.default_rng(31)


def place(buf, snd, at):
    i = int(at * SR)
    m = min(len(snd), len(buf) - i)
    if m > 0:
        buf[i:i + m] += snd[:m]


# ------------------------------------------------------------------ ambiente

def owl():
    """Gufo: due "uh" gravi e morbidi, il secondo più lungo."""
    out = []
    for dur, f in ((0.32, 380.0), (0.7, 360.0)):
        n = int(SR * dur)
        k = np.arange(n) / SR
        env = np.sin(np.pi * np.minimum(k / dur, 1.0)) ** 1.5
        f_t = f * (1 + 0.04 * np.sin(np.pi * k / dur))
        ph = 2 * np.pi * np.cumsum(f_t) / SR
        tone = np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.05 * rng.standard_normal(n)
        out.append(tone * env)
        out.append(np.zeros(int(SR * 0.18)))
    return np.concatenate(out)


def cricket(sec):
    """Grillo: treni di cri-cri acuti, con pause."""
    n = int(SR * sec)
    x = np.zeros(n)
    t = rng.uniform(0, 0.5)
    f = rng.uniform(4300, 4900)
    while t < sec - 0.3:
        for p in range(3):
            m = int(SR * 0.018)
            k = np.arange(m) / SR
            place(x, np.sin(2 * np.pi * f * k) * np.sin(np.pi * k / 0.018), t + p * 0.03)
        t += 0.45 if rng.random() < 0.8 else rng.uniform(1.5, 3.5)
    return x


def creak(dur):
    """Tronco che scricchiola: attrito a scatti con un tono che scende."""
    n = int(SR * dur)
    k = np.arange(n) / SR
    rate = 38 + 20 * np.sin(np.pi * k / dur)
    pulses = (np.sin(2 * np.pi * np.cumsum(rate) / SR) > 0.93).astype(float)
    body = conv(pulses, np.sin(2 * np.pi * 210 * np.arange(600) / SR) * np.exp(-np.arange(600) / 120))[:n]
    return spectral(body, 120, 1600) * np.sin(np.pi * k / dur) ** 0.6


def howl(f_lo=360.0, f_hi=640.0, dur=4.2, seed=0):
    """Ululato di lupo: la voce sale, tiene la nota tremando, poi scivola giù e si spegne.
    Tono con armoniche e un filo di fiato; lontano (filtrato), l'eco la mette reverb()."""
    r = np.random.default_rng(seed)
    n = int(SR * dur)
    k = np.arange(n) / SR
    u = k / dur
    # profilo dell'altezza: salita rapida, tenuta, discesa lenta in fondo
    rise = np.clip(u / 0.18, 0, 1) ** 0.6
    fall = np.clip((u - 0.62) / 0.38, 0, 1) ** 1.4
    f = f_lo + (f_hi - f_lo) * rise - (f_hi - f_lo) * 0.55 * fall
    f *= 1 + 0.012 * np.sin(2 * np.pi * 5.2 * k) * np.clip((u - 0.2) / 0.2, 0, 1)    # tremolio della voce
    f *= 1 + 0.004 * spectral(r.standard_normal(n), 0.5, 4.0) * 20
    ph = 2 * np.pi * np.cumsum(f) / SR
    voice = np.sin(ph) + 0.45 * np.sin(2 * ph) + 0.18 * np.sin(3 * ph) + 0.06 * np.sin(4 * ph)
    breath = spectral(r.standard_normal(n), 500, 3000) * 0.12
    env = np.clip(u / 0.08, 0, 1) * np.clip((1 - u) / 0.25, 0, 1) ** 1.3
    return spectral((voice + breath) * env, 150, 2600)


def pack(seed):
    """Branco lontano: tre lupi che attaccano uno dopo l'altro, ognuno con la sua voce."""
    out = np.zeros(int(SR * 7.5))
    for i, (lo, hi, dur, at) in enumerate(((330, 600, 4.6, 0.0), (390, 700, 4.0, 1.1), (300, 520, 4.8, 2.3))):
        place(out, howl(lo, hi, dur, seed + i) * (1.0 if i == 0 else 0.7), at)
    return out


def twig():
    m = int(SR * 0.08)
    return spectral(rng.standard_normal(m), 900, 7000) * np.exp(-np.arange(m) / (SR * 0.012))


def forest(sec=44.0):
    n = int(SR * sec)
    chans = []
    for c in range(2):
        wind = spectral(rng.standard_normal(n), 90, 1400, tilt=-2.0)
        gust = 0.3 + 0.7 * np.clip(spectral(rng.standard_normal(n), 0.04, 0.25) * 3 + 0.5, 0, 1)
        leaves = spectral(rng.standard_normal(n), 1800, 6000) * 0.12 * gust ** 2   # aghi che frusciano
        x = wind * gust * 0.9 + leaves
        x += cricket(sec) * (0.05 if c == 0 else 0.035)
        x += cricket(sec) * (0.03 if c == 1 else 0.02)
        chans.append(x)
    # eventi sparsi (lontani dalla giunta del loop), un po' più a destra o a sinistra
    # (suono, secondo, volume, destra/sinistra, riverbero): i lupi sono lontani, con molta eco del bosco
    events = [(owl(), 4.2, 1.6, 0.7, 0.45), (owl(), 24.0, 1.1, 0.8, 0.45), (creak(1.6), 8.0, 0.09, 0.3, 0.45),
              (creak(2.2), 38.5, 0.07, 0.6, 0.45), (twig(), 11.7, 0.6, 0.2, 0.45),
              (howl(350, 650, 4.4, 7), 14.5, 2.2, 0.25, 0.75), (pack(11), 28.5, 1.6, 0.75, 0.8)]
    for snd, at, vol, pan, wetmix in events:
        wet = reverb(snd, 3.2 if wetmix > 0.6 else 2.2, wetmix)
        place(chans[0], wet * vol * (1 - pan) * 0.5, at)
        place(chans[1], wet * vol * pan * 0.5, at)
    save("foresta.wav", loopify(chans[0]), 0.75, loopify(chans[1]))


# ------------------------------------------------------------------ musica

def note_freq(name):
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "Bb": 10, "B": 11}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + 12 * (octave + 1) - 69) / 12)


def musicbox(f, dur, wow):
    """Nota di carillon: lamella metallica (armoniche non intere) che si spegne, un po' stonata."""
    n = int(SR * dur)
    k = np.arange(n) / SR
    ph = 2 * np.pi * np.cumsum(f * wow[:n]) / SR
    tone = (np.sin(ph) + 0.35 * np.sin(2.76 * ph) * np.exp(-k / 0.25)
            + 0.18 * np.sin(5.4 * ph) * np.exp(-k / 0.08))
    return tone * np.exp(-k / 1.1) * np.minimum(k / 0.003, 1)


def music(bpm=58, bars=16):
    beat = 60.0 / bpm
    sec = bars * 4 * beat
    n = int(SR * sec)
    t = np.arange(n) / SR
    # carillon che si scarica: l'intonazione ondeggia piano e cala un poco
    wow = 1 + 0.006 * np.sin(2 * np.pi * 0.31 * t) + 0.003 * np.sin(2 * np.pi * 1.7 * t)
    # melodia in re minore armonico (il do diesis e il sol diesis danno il gelo); None = pausa
    phrase_a = ["D5", "F5", "A5", "G#5", "A5", "F5", "D5", None,
                "C#5", "E5", "G5", "F5", "E5", "C#5", "A4", None]
    phrase_b = ["Bb4", "D5", "F5", "E5", "F5", "D5", "Bb4", None,
                "A4", "C#5", "E5", "D5", "C#5", "A4", "G#4", None]
    melody = phrase_a + phrase_b + phrase_a + ["Bb4", "D5", "F5", "E5", "D5", "C#5", "D5", None,
                                               "A4", None, "G#4", None, "D4", None, None, None]
    box = np.zeros(n)
    for i, nm in enumerate(melody):
        if nm is None:
            continue
        at = i * beat                               # una nota ogni battito
        jitter = rng.uniform(-0.02, 0.03)           # un carillon vecchio non va a tempo
        start = int((at + jitter) * SR)
        if start < 0 or start >= n:
            continue
        snd = musicbox(note_freq(nm), 3.0, wow[start:])
        # ogni tanto una nota esce più debole, come un dente consumato
        place(box, snd * rng.uniform(0.55, 1.0), (at + jitter))
    box = spectral(box, 250, 9000)
    # tappeto grave: re e la bassi con un mi bemolle che stride, si gonfia e si sgonfia
    pad = np.zeros(n)
    for f, v in ((note_freq("D2"), 1.0), (note_freq("A2"), 0.6), (note_freq("Eb3"), 0.35), (note_freq("D3"), 0.4)):
        for det in (-0.25, 0.0, 0.3):
            ph = 2 * np.pi * (f + det) * t + rng.uniform(0, 6.3)
            saw = 2 * ((ph / (2 * np.pi)) % 1.0) - 1
            pad += saw * v
    swell = 0.45 + 0.55 * (0.5 - 0.5 * np.cos(2 * np.pi * t / (8 * beat)))
    pad = spectral(pad, 40, 700, tilt=-2.0) * swell
    # colpi lontani di tamburo all'inizio di ogni due battute
    drum = np.zeros(n)
    for b in range(0, bars, 2):
        m = int(SR * 1.2)
        k = np.arange(m) / SR
        hit = np.sin(2 * np.pi * 52 * k * (1 - 0.15 * k)) * np.exp(-k / 0.35)
        place(drum, hit, b * 4 * beat)
    left = reverb(box * 0.55, 4.0, 0.55)[:n] + pad * 0.32 + reverb(drum, 3.0, 0.5)[:n] * 0.5
    box_r = np.roll(box, int(SR * 0.012))                     # carillon un filo spostato: suono largo
    right = reverb(box_r * 0.55, 4.0, 0.55)[:n] + np.roll(pad, int(SR * 0.02)) * 0.32 + reverb(drum, 3.0, 0.5)[:n] * 0.5
    save("musica_foresta.wav", loopify(left, 2.0), 0.8, loopify(right, 2.0))


if __name__ == "__main__":
    forest()
    music()
