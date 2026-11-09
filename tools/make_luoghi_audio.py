"""Musiche e suoni d'ambiente per tre luoghi, tutti sintetizzati (niente campioni esterni):
- musica_cimitero.wav: lenta e funebre in re minore (organo scuro, coro grave "ah", campana a morto lontana);
- musica_cripta.wav: rituale sotterraneo (tamburi lenti come un battito, canto gutturale, sfregamenti di metallo,
  eco lunga di sala di pietra);
- musica_lago.wav: gelida (vetro strofinato, campanelli di ghiaccio, poche note di pianoforte lontano);
- cimitero.wav: ambiente in loop (corvi, un cancello di ferro che cigola, fruscio di foglie);
- lago.wav: ambiente in loop (il ghiaccio che geme, scricchiola e vibra lontano);
- crepa_1..3.wav: singoli schiocchi di ghiaccio che si crepa (non in loop).
Tutto e' costruito "ad anello": i toni continui hanno frequenze che chiudono un numero intero di giri nel
loop, i filtri lavorano sulle frequenze (quindi sono circolari) e le code di eco che sforano la fine
ricominciano dall'inizio. Cosi' la giunta del loop non salta.
Serve solo numpy (va bene il Python di Blender).
Uso: python tools/make_luoghi_audio.py  -> scrive i .wav in audio/ e stampa le misure di ogni file
"""
import os
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_foresta_audio import note_freq  # noqa: E402
from make_meteo_audio import OUT, SR, conv, reverb, save, spectral  # noqa: E402

rng = np.random.default_rng(47)


# ------------------------------------------------------------------ attrezzi comuni

def giro(buf, snd, at):
    """Somma snd in buf dal secondo at; quello che sfora la fine ricomincia dall'inizio (loop)."""
    n = len(buf)
    i = int(at * SR) % n
    pos = 0
    while pos < len(snd):
        m = min(len(snd) - pos, n - i)
        buf[i:i + m] += snd[pos:pos + m]
        pos += m
        i = 0


def eco(x, length=3.0, mix=0.4):
    """Riverbero ad anello: la coda che esce dalla fine rientra all'inizio."""
    y = reverb(x, length, mix)
    out = np.zeros(len(x))
    giro(out, y, 0.0)
    return out


def qf(f, sec, passo=1):
    """Arrotonda la frequenza perche' il tono chiuda giri interi nel loop (niente salto alla giunta).
    passo=2 quando serve anche la meta' della frequenza (le sotto-armoniche del canto di gola)."""
    return max(1, round(f * sec / passo)) * passo / sec


def morbido(n, a, r):
    """Inviluppo: sale in a secondi, scende negli ultimi r secondi, curve a coseno (niente clic)."""
    k = np.arange(n) / SR
    dur = n / SR
    up = 0.5 - 0.5 * np.cos(np.pi * np.clip(k / max(a, 1e-4), 0, 1))
    down = 0.5 - 0.5 * np.cos(np.pi * np.clip((dur - k) / max(r, 1e-4), 0, 1))
    return up * down


def pan(snd, p):
    """Destra/sinistra a potenza costante: p=0 tutto a sinistra, p=1 tutto a destra."""
    return snd * np.cos(p * np.pi / 2), snd * np.sin(p * np.pi / 2)


def db(x):
    return 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-12)


def a_livello(x, target):
    """Porta il volume medio di x a target dB."""
    return x * 10 ** ((target - db(x)) / 20)


def a_livello_forte(x, target, win=0.5):
    """Porta a target dB il mezzo secondo piu' forte di x (per suoni brevi o radi)."""
    m = int(SR * win)
    e = np.convolve(x ** 2, np.ones(m) / m, mode="valid") if len(x) > m else np.array([np.mean(x ** 2)])
    return x * 10 ** ((target - 10 * np.log10(e.max() + 1e-12)) / 20)


def sega(f_t):
    """Dente di sega con i bordi ammorbiditi (meno fischi spuri): f_t frequenza istante per istante."""
    dt = f_t / SR
    t = np.cumsum(dt) % 1.0
    y = 2 * t - 1
    a = t < dt
    u = t[a] / dt[a]
    y[a] -= u + u - u * u - 1
    b = t > 1 - dt
    u = (t[b] - 1) / dt[b]
    y[b] -= u * u + u + u + 1
    return y


def formanti(x, picchi):
    """Filtro delle vocali: somma di risonanze (frequenza, larghezza, volume in dB) sulle frequenze."""
    f = np.fft.rfftfreq(len(x), 1 / SR)
    g = np.full_like(f, 0.01)
    for fc, bw, gdb in picchi:
        g += 10 ** (gdb / 20) / (1 + ((f - fc) / (bw / 2)) ** 2)
    g /= 1 + (60 / np.maximum(f, 1)) ** 4
    return np.fft.irfft(np.fft.rfft(x) * g, len(x))


def modi(freqs, decays, amps, dur):
    """Risposta di un oggetto che vibra (metallo, ghiaccio): somma di toni che si spengono."""
    n = int(SR * dur)
    k = np.arange(n) / SR
    ir = np.zeros(n)
    for f, d, a in zip(freqs, decays, amps):
        ir += a * np.sin(2 * np.pi * f * k + rng.uniform(0, 6.3)) * np.exp(-k / d)
    return ir * morbido(n, 0.0005, min(0.05, dur / 4))


def limita(x, soglia=0.72, tetto=0.97):
    """Limitatore morbido: sotto la soglia non tocca nulla, sopra piega dolcemente verso il tetto."""
    a = np.abs(x)
    sopra = a > soglia
    y = x.copy()
    y[sopra] = np.sign(x[sopra]) * (soglia + (tetto - soglia) * np.tanh((a[sopra] - soglia) / (tetto - soglia)))
    return y


def finale(name, left, right, target):
    """Volume medio a target dB, picchi rari piegati dal limitatore, poi scrive il file stereo."""
    g = 10 ** ((target - db(np.concatenate([left, right]))) / 20)
    left, right = limita(left * g), limita(right * g)
    save(name, left, np.abs(left).max(), right)    # save divide per il picco sinistro e rimoltiplica: invariato


def misura(name, loop=True):
    """Rilegge il file e stampa durata, picco, volume per secondo e salto alla giunta."""
    with wave.open(os.path.join(OUT, name), "rb") as w:
        ch = w.getnchannels()
        x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float64) / 32768
    x = x.reshape(-1, ch)
    secs = [db(x[i * SR:(i + 1) * SR]) for i in range(len(x) // SR)]
    print(f"  {name}: {len(x) / SR:.2f} s, {ch} canali, picco {np.abs(x).max():.3f}, "
          f"dB per secondo min {min(secs):.1f} medio {np.mean(secs):.1f} max {max(secs):.1f}")
    print("    ", " ".join(f"{v:.0f}" for v in secs))
    if loop:
        salto = np.abs(x[0] - x[-1]).max()
        passo = np.abs(np.diff(x, axis=0)).mean()
        passo_max = np.abs(np.diff(x, axis=0)).max()
        # i passi subito prima e subito dopo la giunta: se il salto e' simile, il suono prosegue liscio
        vicini = np.abs(np.diff(np.concatenate([x[-4:], x[:4]]), axis=0))
        print(f"    giunta: salto {salto:.4f}, passi vicini {np.round(vicini.max(axis=1), 4)}, "
              f"passo medio {passo:.4f}, passo massimo {passo_max:.4f}")
    else:
        print(f"    primo campione {np.abs(x[0]).max():.4f}, ultimo {np.abs(x[-1]).max():.4f}")


# ------------------------------------------------------------------ musica del cimitero

def organo(f, dur):
    """Nota d'organo scuro: registri di 16', 8', 4', quinta; due canne un filo stonate fra loro."""
    n = int(SR * dur)
    k = np.arange(n) / SR
    x = np.zeros(n)
    for h, a in ((0.5, 0.7), (1, 1.0), (2, 0.45), (3, 0.2), (4, 0.12), (6, 0.04)):
        for det in (-0.12, 0.15):
            x += a * np.sin(2 * np.pi * (f * h + det * h) * k + rng.uniform(0, 6.3))
    return x * morbido(n, 1.2, 2.5)


def coro(f, dur):
    """Voce del coro: dente di sega con vibrato lento, tre cantori un poco stonati fra loro."""
    n = int(SR * dur)
    k = np.arange(n) / SR
    x = np.zeros(n)
    for det in (-0.004, 0.0, 0.005):
        vib = 1 + 0.006 * np.sin(2 * np.pi * rng.uniform(4.6, 5.6) * k + rng.uniform(0, 6.3))
        drift = 1 + 0.002 * spectral(rng.standard_normal(n), 0.3, 3.0) * 30
        x += sega(f * (1 + det) * vib * drift)
    return x * morbido(n, 2.5, 3.0)


def campana(f, dur=9.0):
    """Campana a morto: parziali di campana (bordone, prima, terza minore, quinta, nominale...)."""
    parz = ((0.5, 1.0, 7.0), (1.0, 0.8, 4.5), (1.19, 0.55, 3.0), (1.5, 0.35, 2.5), (2.0, 0.6, 2.2),
            (2.51, 0.25, 1.4), (2.66, 0.2, 1.1), (3.01, 0.15, 0.9), (4.07, 0.08, 0.6))
    x = modi([f * p for p, _, _ in parz], [d for _, _, d in parz], [a for _, a, _ in parz], dur)
    m = int(SR * 0.03)
    x[:m] += spectral(rng.standard_normal(m), 400, 3000) * np.exp(-np.arange(m) / (SR * 0.006)) * 0.3
    return spectral(x, 50, 2200) * morbido(len(x), 0.002, 1.5)


def musica_cimitero(sec=60.0):
    n = int(SR * sec)
    t = np.arange(n) / SR
    # accordi lenti in re minore: Rem, Sib, Solm, La (do diesis: il gelo), Rem, Mib (il buio), Solm, La
    accordi = [("D2", "A2", "D3", "F3"), ("Bb1", "F2", "D3", "F3"), ("G1", "D2", "Bb2", "D3"),
               ("A1", "E2", "C#3", "E3"), ("D2", "A2", "D3", "F3"), ("Eb2", "Bb2", "Eb3", "G3"),
               ("G1", "D2", "Bb2", "D3"), ("A1", "E2", "C#3", "E3")]
    voci = [("A3", "D4", "F4"), ("F3", "Bb3", "D4"), ("G3", "Bb3", "D4"), ("E3", "A3", "C#4"),
            ("F3", "A3", "D4"), ("G3", "Bb3", "Eb4"), ("D3", "G3", "Bb3"), ("E3", "A3", "C#4")]
    passo = sec / len(accordi)
    org = [np.zeros(n), np.zeros(n)]
    ch = [np.zeros(n), np.zeros(n)]
    for i, (acc, vv) in enumerate(zip(accordi, voci)):
        at = i * passo
        for c in range(2):
            for nm in acc:
                giro(org[c], organo(note_freq(nm), passo + 2.5) * (1.0 if nm[-1] in "12" else 0.6), at)
            for j, nm in enumerate(vv):
                # le voci entrano un poco sfalsate, piu' a sinistra o a destra
                lato = (0.35, 0.65, 0.5)[j]
                g = (1 - lato) if c == 0 else lato
                giro(ch[c], coro(note_freq(nm), passo + 3.0) * g, at + 0.2 * j)
    org = [spectral(o, 30, 1500, tilt=-1.5) for o in org]
    # coro: vocale "ah" di voci gravi (formanti attorno a 650, 1080, 2650 Hz)
    ah = ((650, 110, 0), (1080, 130, -6), (2650, 180, -10), (2900, 200, -12), (3300, 250, -24))
    ch = [formanti(c, ah) for c in ch]
    respiro = 0.6 + 0.4 * (0.5 - 0.5 * np.cos(2 * np.pi * t / (2 * passo)))   # il coro si gonfia e si ritira
    ch = [c * respiro for c in ch]
    # pedale grave che non si ferma mai: re basso
    ped = sum(np.sin(2 * np.pi * qf(note_freq("D1") * h, sec) * t) / h for h in (1, 2, 3))
    ped *= 0.75 + 0.25 * np.sin(2 * np.pi * qf(0.05, sec) * t)
    # campana a morto lontana ogni 10 secondi (un rintocco su tre un poco piu' debole)
    bell = np.zeros(n)
    for i in range(6):
        giro(bell, campana(note_freq("D4")) * (1.0 if i % 3 else 0.7), 3.0 + i * 10.0)
    left = (a_livello(org[0], -23) + a_livello(ch[0], -24) + a_livello(ped, -30)
            + a_livello_forte(eco(bell, 4.5, 0.6), -22))
    right = (a_livello(org[1], -23) + a_livello(ch[1], -24) + a_livello(np.roll(ped, 300), -30)
             + a_livello_forte(eco(np.roll(bell, int(SR * 0.015)), 4.5, 0.6), -22))
    left, right = eco(left, 3.5, 0.35), eco(right, 3.5, 0.35)
    finale("musica_cimitero.wav", left, right, -17.5)


# ------------------------------------------------------------------ musica della cripta

def tamburo(forte=1.0):
    """Colpo di tamburo profondo: pelle che scende di tono e un soffio di battente."""
    m = int(SR * 1.4)
    k = np.arange(m) / SR
    f = 42 + 40 * np.exp(-k / 0.06)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-k / 0.45)
    x += 0.3 * np.sin(2 * np.pi * np.cumsum(f * 1.6) / SR) * np.exp(-k / 0.15)
    x += spectral(rng.standard_normal(m), 60, 500) * np.exp(-k / 0.03) * 0.5
    return x * forte * morbido(m, 0.002, 0.4)


def sfregamento(dur=3.2):
    """Metallo strofinato: attrito a strappi che fa vibrare una lastra (toni non armonici)."""
    n = int(SR * dur)
    k = np.arange(n) / SR
    noise = spectral(rng.standard_normal(n), 400, 6000)
    strappi = np.clip(spectral(rng.standard_normal(n), 2, 30) * 6 + 0.3, 0, 1)
    eccita = noise * strappi * np.sin(np.pi * k / dur) ** 1.5
    fr = rng.uniform(300, 3800, 16)
    ir = modi(fr, rng.uniform(0.2, 1.0, 16), rng.uniform(0.3, 1.0, 16), 1.6)
    x = conv(eccita, ir)
    return spectral(x, 200, 6500) * morbido(len(x), 0.05, 0.6)


def gutturale(f0, sec, seme):
    """Canto gutturale: voce grave ricca, con una risonanza stretta che scorre fra le armoniche
    (fischio sopra il bordone) e un mezzo tono sotto che ringhia (voce di gola)."""
    r = np.random.default_rng(seme)
    n = int(SR * sec)
    t = np.arange(n) / SR
    f0 = qf(f0, sec, 2)
    vib = 0.004 * np.sin(2 * np.pi * qf(0.13, sec) * t)
    ph = 2 * np.pi * np.cumsum(f0 * (1 + vib)) / SR
    # la risonanza sale e scende lenta fra la 6a e la 12a armonica
    res = f0 * (9 + 3 * np.sin(2 * np.pi * qf(1 / 15, sec) * t + r.uniform(0, 6.3))
                + 1.2 * np.sin(2 * np.pi * qf(1 / 6, sec) * t))
    x = np.zeros(n)
    for h in range(1, 40):
        fh = f0 * h
        corpo = 1 / h ** 0.8
        corpo *= 0.3 + 1 / (1 + ((fh - 500) / 250) ** 2) + 0.6 / (1 + ((fh - 900) / 300) ** 2)
        fischio = 2.2 / (1 + ((fh - res) / (f0 * 0.35)) ** 2)
        x += (corpo + fischio) * np.sin(h * ph)
        # sotto-armoniche: la gola che vibra a meta' frequenza
        x += 0.25 * corpo * np.sin((h - 0.5) * ph)
    respiro = 0.7 + 0.3 * np.sin(2 * np.pi * qf(1 / 7.5, sec) * t) ** 2
    return spectral(x * respiro, 45, 4000)


def musica_cripta(sec=60.0):
    n = int(SR * sec)
    # battito lento: "tum-tum" ogni 1,5 secondi, ogni otto battiti un colpo piu' forte
    drum = np.zeros(n)
    beat = 1.5
    for i in range(int(sec / beat)):
        at = 0.6 + i * beat           # nessun colpo proprio sulla giunta del loop
        forte = 1.3 if i % 8 == 0 else 1.0
        giro(drum, tamburo(forte), at)
        giro(drum, tamburo(0.6 * forte), at + 0.3)
    # bordone di canto: re basso a sinistra, la stessa voce un filo diversa a destra, e una quinta piu' bassa
    f0 = qf(note_freq("D2"), sec)
    vl = gutturale(f0, sec, 1) + 0.5 * gutturale(qf(note_freq("G1"), sec), sec, 3)
    vr = gutturale(qf(f0 * 1.003, sec), sec, 2) + 0.5 * gutturale(qf(note_freq("G1") * 0.997, sec), sec, 4)
    # sfregamenti metallici rari, uno a sinistra e uno a destra
    met = [np.zeros(n), np.zeros(n)]
    for at, p in ((11.0, 0.2), (33.5, 0.8), (49.0, 0.45)):
        l, r = pan(sfregamento(rng.uniform(2.6, 3.6)), p)
        giro(met[0], l, at)
        giro(met[1], r, at)
    left = (a_livello(eco(drum, 5.0, 0.5), -21) + a_livello(vl, -24)
            + a_livello_forte(eco(met[0], 5.5, 0.6), -24))
    right = (a_livello(eco(drum, 5.0, 0.5), -21) + a_livello(vr, -24)
             + a_livello_forte(eco(met[1], 5.5, 0.6), -24))
    # la sala di pietra: eco lunga su tutto
    left, right = eco(left, 6.0, 0.4), eco(right, 6.0, 0.4)
    finale("musica_cripta.wav", left, right, -17.5)


# ------------------------------------------------------------------ musica del lago

def vetro(f, dur):
    """Bicchiere strofinato: tono puro e acuto che nasce piano, con il tremolio dell'attrito."""
    n = int(SR * dur)
    k = np.arange(n) / SR
    ph = 2 * np.pi * f * k + rng.uniform(0, 6.3)
    x = np.sin(ph) + 0.12 * np.sin(2 * ph) + 0.04 * np.sin(3 * ph)
    x += 0.5 * np.sin(2 * np.pi * (f + 1.3) * k)                     # battimento lento
    attrito = 1 + 0.15 * spectral(rng.standard_normal(n), 2, 9) * 20
    soffio = spectral(rng.standard_normal(n), f * 0.9, f * 1.1) * 0.6
    return (x * attrito + soffio) * morbido(n, dur * 0.35, dur * 0.4)


def campanello(f):
    """Campanellino di ghiaccio: tintinnio con parziali non armoniche, breve."""
    return modi([f, f * 2.76, f * 5.4, f * 8.9], [0.9, 0.35, 0.12, 0.05], [1.0, 0.4, 0.2, 0.08], 1.6)


def pianoforte(f, dur=4.5):
    """Nota di pianoforte: corde un poco stonate fra le armoniche, le acute si spengono prima."""
    n = int(SR * dur)
    k = np.arange(n) / SR
    x = np.zeros(n)
    for h in range(1, 14):
        fh = f * h * np.sqrt(1 + 0.0004 * h * h)
        if fh > 8000:
            break
        for det in (-0.4, 0.4):
            x += (1 / h ** 1.3) * np.sin(2 * np.pi * (fh + det) * k + rng.uniform(0, 6.3)) * np.exp(-k * (0.5 + 0.35 * h))
    m = int(SR * 0.02)
    x[:m] += spectral(rng.standard_normal(m), 500, 4000) * np.exp(-np.arange(m) / (SR * 0.004)) * 0.2
    return x * morbido(n, 0.004, 1.2)


def musica_lago(sec=60.0):
    n = int(SR * sec)
    t = np.arange(n) / SR
    # tappeto freddo: re e la gravi, un mi sopra (quinta su quinta, vuota) e un'aria sottile
    pad = [np.zeros(n), np.zeros(n)]
    for c in range(2):
        for nm, v in (("D3", 1.0), ("A3", 0.7), ("E4", 0.4)):
            f = qf(note_freq(nm) * (1 + 0.002 * (c - 0.5)), sec)
            pad[c] += v * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.3))
        pad[c] *= 0.6 + 0.4 * np.sin(2 * np.pi * qf(1 / 20, sec) * t + c) ** 2
        aria = spectral(rng.standard_normal(n), 2500, 9000, tilt=-2.0)
        aria *= 0.5 + 0.5 * np.clip(spectral(rng.standard_normal(n), 0.05, 0.3) * 4 + 0.5, 0, 1)
        pad[c] = a_livello(pad[c], -27) + a_livello(aria, -36)
    # vetri strofinati: note acute e lente (secondo, nota, durata, destra/sinistra)
    vetri = [(1.0, "A5", 9.0, 0.3), (6.0, "D6", 8.0, 0.7), (13.0, "F5", 10.0, 0.5), (19.0, "C#6", 7.0, 0.25),
             (24.5, "E6", 8.0, 0.75), (31.0, "A5", 10.0, 0.4), (38.0, "F6", 6.5, 0.6), (43.0, "D6", 9.0, 0.35),
             (50.0, "Bb5", 8.0, 0.65), (55.5, "E5", 7.5, 0.5)]
    gl = [np.zeros(n), np.zeros(n)]
    for at, nm, dur, p in vetri:
        l, r = pan(vetro(note_freq(nm), dur), p)
        giro(gl[0], l, at)
        giro(gl[1], r, at)
    # campanelli di ghiaccio: piccoli grappoli radi
    ice = [np.zeros(n), np.zeros(n)]
    for at in (4.5, 16.0, 27.5, 36.0, 47.0, 57.0):
        for j in range(rng.integers(2, 5)):
            nm = rng.choice(["D7", "A6", "F7", "E7", "C#7", "A7"])
            l, r = pan(campanello(note_freq(nm)) * rng.uniform(0.4, 1.0), rng.uniform(0.15, 0.85))
            giro(ice[0], l, at + j * rng.uniform(0.12, 0.35))
            giro(ice[1], r, at + j * rng.uniform(0.12, 0.35))
    # pianoforte lontano: poche note che scendono
    pia = np.zeros(n)
    for at0, frase in ((8.0, ["A4", "F4", "D4", "C#4"]), (28.0, ["F4", "E4", "D4", "A3"]),
                       (44.0, ["D5", "A4", "F4", "E4", "D4"])):
        for j, nm in enumerate(frase):
            giro(pia, pianoforte(note_freq(nm)) * (1.0 - 0.1 * j), at0 + j * 1.6 + rng.uniform(-0.05, 0.08))
    pia = spectral(pia, 80, 2500)
    left = (pad[0] + a_livello(eco(gl[0], 4.0, 0.5), -25) + a_livello_forte(eco(ice[0], 4.0, 0.55), -27)
            + a_livello_forte(eco(pia, 5.0, 0.65), -21))
    right = (pad[1] + a_livello(eco(gl[1], 4.0, 0.5), -25) + a_livello_forte(eco(ice[1], 4.0, 0.55), -27)
             + a_livello_forte(eco(np.roll(pia, int(SR * 0.01)), 5.0, 0.65), -21))
    finale("musica_lago.wav", left, right, -18.5)


# ------------------------------------------------------------------ ambiente del cimitero

def cra(r):
    """Un "cra" di corvo: voce ruvida con armoniche, gola che gracchia, tono che cala un poco."""
    dur = r.uniform(0.22, 0.34)
    n = int(SR * dur)
    k = np.arange(n) / SR
    u = k / dur
    f0 = r.uniform(480, 640)
    f = f0 * (1.08 - 0.15 * u) * (1 + 0.03 * r.standard_normal(n).cumsum() / np.sqrt(np.arange(1, n + 1)))
    ph = 2 * np.pi * np.cumsum(f) / SR
    # armoniche con fasi sparse (se partono tutte insieme fanno punte secche che gracchiano male)
    x = sum(np.sin(h * ph + r.uniform(0, 6.3)) / h ** 0.6 for h in range(1, 12))
    gracchio = 1 + 0.7 * np.sin(2 * np.pi * r.uniform(55, 80) * k) * np.clip(0.7 + 0.3 * r.standard_normal(n), 0, 1.3)
    x = x * gracchio + spectral(r.standard_normal(n), 1000, 4000) * 2.0
    x = formanti(x, ((1300, 500, 0), (2200, 600, -3), (3400, 800, -10)))
    # gola tirata: la voce satura un poco (piu' roca, e senza punte che sforano)
    x = np.tanh(2.5 * x / (np.abs(x).max() + 1e-9))
    return x * morbido(n, 0.015, 0.08)


def corvo(seme, versi):
    """Un corvo che gracchia versi volte di fila."""
    r = np.random.default_rng(seme)
    out = np.zeros(int(SR * (versi * 0.8 + 0.5)))
    at = 0.0
    for _ in range(versi):
        snd = cra(r)
        i = int(at * SR)
        out[i:i + len(snd)] += snd * r.uniform(0.75, 1.0)
        at += len(snd) / SR + r.uniform(0.25, 0.45)
    return out


def cancello(dur=2.8):
    """Cancello di ferro che cigola: il cardine arrugginito si blocca e scivola (impulsi a scatti
    con un tono che sale e scende) e fa vibrare le sbarre di ferro."""
    n = int(SR * dur)
    k = np.arange(n) / SR
    u = k / dur
    rate = 260 + 260 * np.sin(np.pi * u) ** 1.5 + 60 * np.sin(2 * np.pi * 1.7 * k)
    rate *= 1 + 0.04 * spectral(rng.standard_normal(n), 3, 40) * 20
    fase = np.cumsum(rate) / SR % 1.0
    impulsi = np.exp(-fase * 25) * (0.4 + 0.6 * np.clip(spectral(rng.standard_normal(n), 1, 12) * 5 + 0.6, 0, 1))
    ferro = modi([820, 1460, 2310, 3570, 5100, 640], [0.06, 0.05, 0.04, 0.03, 0.02, 0.12],
                 [1.0, 0.8, 0.6, 0.4, 0.2, 0.5], 0.4)
    x = conv(impulsi * morbido(n, 0.15, 0.5), ferro)
    # alla fine le sbarre battono piano contro il fermo
    colpo = modi([310, 720, 1130, 1890, 2700], [0.5, 0.35, 0.25, 0.15, 0.08], [1.0, 0.7, 0.5, 0.3, 0.2], 1.5)
    giro_fine = np.zeros(len(x) + len(colpo))
    giro_fine[:len(x)] += x / (np.abs(x).max() + 1e-9)
    i = int(SR * (dur - 0.1))
    giro_fine[i:i + len(colpo)] += colpo / (np.abs(colpo).max() + 1e-9) * 0.35
    return spectral(giro_fine, 250, 7000)


def cimitero(sec=40.0):
    n = int(SR * sec)
    chans = []
    for c in range(2):
        foglie = spectral(rng.standard_normal(n), 350, 6000, tilt=-3.0)
        soffio = 0.35 + 0.65 * np.clip(spectral(rng.standard_normal(n), 0.04, 0.25) * 3 + 0.5, 0, 1)
        aria = spectral(rng.standard_normal(n), 60, 400, tilt=-2.0) * 0.6
        chans.append(a_livello(foglie * soffio ** 1.5 + aria * soffio, -21.5))
    # (suono, secondo, volume dB del mezzo secondo piu' forte, destra/sinistra, eco)
    eventi = [(corvo(1, 3), 5.0, -15.0, 0.2, 0.35),        # vicino, a sinistra
              (corvo(2, 2), 13.5, -19.0, 0.85, 0.55),      # lontano, a destra
              (cancello(), 20.0, -15.0, 0.6, 0.45),        # il cancello, una volta sola
              (corvo(3, 4), 28.0, -16.0, 0.7, 0.45),       # medio, a destra
              (corvo(4, 2), 34.0, -20.0, 0.1, 0.6)]        # molto lontano, a sinistra
    for snd, at, vol, p, wet in eventi:
        x = a_livello_forte(reverb(snd, 2.5, wet), vol)
        l, r = pan(x, p)
        giro(chans[0], l * np.sqrt(2), at)
        giro(chans[1], r * np.sqrt(2), at)
    finale("cimitero.wav", chans[0], chans[1], db(np.concatenate(chans)))


# ------------------------------------------------------------------ ambiente del lago e crepe

def piu(r, dur=2.0):
    """Il "piu-u" del ghiaccio che vibra lontano: un fischio che scende veloce, ripetuto dagli echi
    sotto la lastra (le acute arrivano prima delle gravi)."""
    n = int(SR * dur)
    k = np.arange(n) / SR
    f_a, f_b, tau = r.uniform(2500, 4000), r.uniform(150, 260), r.uniform(0.08, 0.16)
    out = np.zeros(n)
    for j, (rit, vol) in enumerate(((0.0, 1.0), (r.uniform(0.08, 0.14), 0.5), (r.uniform(0.2, 0.32), 0.25))):
        kk = np.clip(k - rit, 0, None)
        f = f_b + (f_a - f_b) * np.exp(-kk / tau)
        ph = 2 * np.pi * np.cumsum(f) / SR
        x = (np.sin(ph) + 0.3 * np.sin(2 * ph)) * np.exp(-kk / 0.35) * (k >= rit)
        x *= np.clip((k - rit) / 0.003, 0, 1)
        out += x * vol
    return spectral(out, 120, 6000) * morbido(n, 0.002, 0.5)


def schiocco(r, forte=1.0):
    """Crepa secca: scatto brevissimo, la lastra che tintinna e un tonfo sordo sotto."""
    n = int(SR * 0.9)
    k = np.arange(n) / SR
    scatto = spectral(r.standard_normal(n), 1200, 8000) * np.exp(-k / 0.004) * np.clip(k / 0.0015, 0, 1)
    lastra = modi(r.uniform(700, 3500, 6), r.uniform(0.03, 0.12, 6), r.uniform(0.3, 1.0, 6), 0.9)
    tonfo = spectral(r.standard_normal(n), 40, 220) * np.exp(-k / 0.18)
    x = scatto * 1.3 / (np.abs(scatto).max() + 1e-9) + lastra / (np.abs(lastra).max() + 1e-9) * 0.6
    x += tonfo / (np.abs(tonfo).max() + 1e-9) * 0.8
    return x * forte * morbido(n, 0.0008, 0.3)


def gemito(r, dur=4.5):
    """Il ghiaccio che geme: rombo grave che si gonfia, con un tono basso e ruvido che cala."""
    n = int(SR * dur)
    k = np.arange(n) / SR
    u = k / dur
    rombo = spectral(r.standard_normal(n), 25, 160, tilt=-2.0)
    f = r.uniform(70, 95) * (1 - 0.3 * u)
    ph = 2 * np.pi * np.cumsum(f) / SR
    tono = (np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.25 * np.sin(3 * ph)) * (0.6 + 0.4 * np.abs(spectral(r.standard_normal(n), 8, 30)) * 10)
    x = rombo / (np.abs(rombo).max() + 1e-9) + 0.5 * tono / (np.abs(tono).max() + 1e-9)
    return spectral(x, 25, 600) * np.sin(np.pi * u) ** 2


def crepitio(r, dur, quanti):
    """Piccoli scricchiolii sparsi che seguono una crepa."""
    out = np.zeros(int(SR * dur))
    for _ in range(quanti):
        m = int(SR * 0.04)
        s = spectral(r.standard_normal(m), 1500, 9000) * np.exp(-np.arange(m) / (SR * 0.006))
        i = int(r.uniform(0.1, dur - 0.2) * SR)
        out[i:i + m] += s * r.uniform(0.1, 0.4) * morbido(m, 0.0005, 0.01)
    return out


def crepa(name, seme, dur):
    """Un solo schiocco di ghiaccio (mono, non in loop): scatto, vibrazione che scende, scricchiolii."""
    r = np.random.default_rng(seme)
    n = int(SR * dur)
    x = np.zeros(n)
    s = schiocco(r)
    x[:len(s)] += s
    p = piu(r, min(dur, 2.0))
    x[int(SR * 0.02):int(SR * 0.02) + len(p)] += p[:n - int(SR * 0.02)] * 0.5
    x += crepitio(r, dur, r.integers(4, 9))
    x = reverb(x, 1.8, 0.35)[:n] * morbido(n, 0.0008, 0.4)
    save(name, x, 0.9)


def lago(sec=40.0):
    n = int(SR * sec)
    chans = []
    for c in range(2):
        grave = spectral(rng.standard_normal(n), 25, 140, tilt=-2.0)
        grave *= 0.6 + 0.4 * np.clip(spectral(rng.standard_normal(n), 0.03, 0.2) * 3 + 0.5, 0, 1)
        freddo = spectral(rng.standard_normal(n), 2500, 9000, tilt=-2.0) * 0.08
        chans.append(a_livello(grave + a_livello(freddo, db(grave) - 14), -21.5))
    # gemiti che scorrono da un lato all'altro
    for at, p0, p1, vol, seme in ((3.0, 0.15, 0.85, -15.0, 5), (24.0, 0.9, 0.2, -16.0, 6)):
        r = np.random.default_rng(seme)
        g = a_livello_forte(eco(np.pad(gemito(r), (0, int(SR * 3))), 3.0, 0.4), vol)
        lato = np.linspace(p0, p1, len(g))
        giro(chans[0], g * np.cos(lato * np.pi / 2) * np.sqrt(2), at)
        giro(chans[1], g * np.sin(lato * np.pi / 2) * np.sqrt(2), at)
    # schiocchi e "piu-u" lontani (secondo, suono, volume, destra/sinistra)
    eventi = []
    for at, seme, vol, p in ((9.5, 11, -15.5, 0.7), (31.0, 12, -17.0, 0.3)):
        r = np.random.default_rng(seme)
        eventi.append((at, piu(r, 2.0), vol, p, 0.6))
    for at, seme, vol, p in ((15.5, 21, -13.5, 0.35), (19.0, 22, -18.0, 0.8), (35.0, 23, -15.0, 0.55)):
        r = np.random.default_rng(seme)
        s = np.zeros(int(SR * 2.0))
        s[:int(SR * 0.9)] += schiocco(r)
        s += crepitio(r, 2.0, 5)
        eventi.append((at, s, vol, p, 0.45))
    for at, snd, vol, p, wet in eventi:
        x = a_livello_forte(reverb(snd, 3.5, wet), vol)
        l, r_ = pan(x, p)
        giro(chans[0], l * np.sqrt(2), at)
        giro(chans[1], r_ * np.sqrt(2), at)
    finale("lago.wav", chans[0], chans[1], db(np.concatenate(chans)))


if __name__ == "__main__":
    # si puo' rifare solo una parte, per esempio: python tools/make_luoghi_audio.py musica_cripta
    lavori = {"musica_cimitero": musica_cimitero, "musica_cripta": musica_cripta, "musica_lago": musica_lago,
              "cimitero": cimitero, "lago": lago,
              "crepe": lambda: [crepa("crepa_1.wav", 101, 2.2), crepa("crepa_2.wav", 102, 1.6),
                                crepa("crepa_3.wav", 103, 2.8)]}
    for nome, fai in lavori.items():
        if not sys.argv[1:] or nome in sys.argv[1:]:
            fai()
    print("misure:")
    for nome in ("musica_cimitero.wav", "musica_cripta.wav", "musica_lago.wav", "cimitero.wav", "lago.wav"):
        misura(nome)
    for nome in ("crepa_1.wav", "crepa_2.wav", "crepa_3.wav"):
        misura(nome, loop=False)
