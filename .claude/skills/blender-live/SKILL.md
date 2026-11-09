---
name: blender-live
description: Lavora dal vivo nella finestra di Blender aperta dall'utente tramite l'add-on PROGETTO Live, su una copia del personaggio, mostrando passi e anteprime. Usa quando l'utente vuole vedere le modifiche in Blender mentre lavori o chiede di collegarti a Blender.
---

PROGETTO Live collega questa sessione alla finestra di Blender dell'utente. Codice in
`tools/blender/live/`:
- `progetto_live.py`: l'add-on;
- `client.py`: il client;
- `azioni/`: le modifiche ammesse.

L'add-on installato è una copia in
`%APPDATA%\Blender Foundation\Blender\5.2\scripts\addons\progetto_live.py`.
Dopo ogni modifica dell'add-on ricopialo lì e chiedi all'utente di riavviare Blender, oppure di
disattivarlo e riattivarlo. Le azioni invece si ricaricano da sole a ogni esecuzione.

## Regole (concordate con l'utente)
- **Solo locale.** L'add-on ascolta su 127.0.0.1 con una chiave in
  `%LOCALAPPDATA%\PROGETTO_live\connessione.json`. Non esporlo in rete, non disattivare la chiave.
- **Niente comandi arbitrari.** I comandi ammessi sono: `stato`, `messaggio`, `apri_copia`, `azione`,
  `anteprima`, `inquadra`, `annulla`, `salva`. Non aggiungere un comando che esegua codice ricevuto
  dalla rete. Le modifiche vanno scritte come file in `azioni/<nome>.py`, con `def run(live, **args)`,
  e richiamate per nome. Gli argomenti possono essere solo testi, numeri, vero/falso e liste.
  Committa le azioni su git: devono restare rileggibili.
- **Solo copie.** Gli originali (i file `.blend` in `Documenti\BLENDER gioco claude\`)
  non si modificano. `apri_copia` crea `lavoro\<nome>_live.blend`, e azioni,
  `salva` e `annulla` funzionano solo lì. Prima di ogni azione l'add-on salva un punto di ripristino
  in `lavoro\ripristino\` (tiene gli ultimi 10) e un passo di Ctrl+Z. Si sostituisce un originale solo
  su richiesta esplicita dell'utente, e mai attraverso PROGETTO Live.
- **Mostra il lavoro.** Usa `messaggio` per dire cosa stai per fare. Dentro le azioni chiama
  `live.passo("...")` a ogni fase, `live.inquadra([...])` sulla zona toccata e `live.anteprima("nome")`
  dopo ogni modifica importante. Usa `tipo="render"` con una camera per un render vero.
  Le immagini vanno in `anteprime\live\`. Guarda davvero le immagini prima di giudicare.
- Non chiudere né riavviare il Blender dell'utente. Per i test usa un Blender separato con
  `--factory-startup` e una cartella di riferimenti di prova.

## Uso
Il Python incluso in Blender basta, non serve installare nulla:
```
PY="C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe"
C="GamePC/tools/blender/live/client.py"
"$PY" "$C" stato                                   # collegato? quale file? quali azioni?
"$PY" "$C" messaggio '{"testo":"Sistemo l orlo del mantello"}'
"$PY" "$C" apri_copia '{"originale":"<nome del file>"}'      # {"nuova":true} per ripartire dall'originale
"$PY" "$C" azione '{"nome":"prova_live","args":{"colore":"verde"}}'
"$PY" "$C" inquadra '{"oggetti":["Mantello"]}'
"$PY" "$C" anteprima '{"nome":"giubbone","tipo":"vista"}'
"$PY" "$C" annulla        # torna all'ultimo punto di ripristino
"$PY" "$C" salva          # salva la copia di lavoro
```
Se il client risponde "non è collegato", chiedi all'utente di aprire Blender, premere N, aprire
la scheda PROGETTO e premere "Collega Claude".

## Scrivere un'azione
```python
"""Cosa fa, su quali oggetti."""
import bpy

def run(live, oggetto="Mantellina", quanto=0.01):
    live.passo("Allungo " + oggetto)
    live.inquadra([oggetto])
    ...                                  # bpy / bmesh, come negli script di tools/blender
    live.ridisegna()
    return {"anteprima": live.anteprima("dopo_" + oggetto)}
```
Un'azione può riusare le funzioni di `tools/blender` aggiungendo quella cartella a `sys.path`. Non deve
salvare file da sola e non deve aprire o scrivere file fuori dalla copia di lavoro.

Le correzioni stabili vanno poi riportate negli script di costruzione (gli script in `tools/blender`), così
il personaggio resta riproducibile. Riporta sempre cosa è stato verificato dal vivo, cosa solo nello
script e cosa nel gioco.
