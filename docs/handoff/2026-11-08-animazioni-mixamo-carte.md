---
type: handoff
date: 2026-11-08
status: in-corso
seq: 1
prev: nessuno
tags: [mixamo, animazioni, carte, dadi, braccia-prima-persona, mago-meshy, codex]
---

# Handoff: animazioni Mixamo delle carte sui nostri scheletri

## Obiettivo
L'utente ha trovato su Mixamo movimenti delle carte che gli piacciono più di quelli fatti a mano. Vuole ricopiarli
sui NOSTRI scheletri come animazioni in più: braccia in prima persona di Codex (v010) e mago Meshy visto dagli altri.
Le ossa e le animazioni esistenti non devono cambiare. Il lavoro lo fa Codex, Claude controlla.

## A che punto siamo
- Le clip Mixamo sono pronte e controllate (65 ossa, cinque dita per mano):
  `Desktop\prova_chatgpt_mani\animazioni_mixamo_da_claude\mixamo_originali\65_ossa\`
  Carte_A_ybot (1-271), Carte_B_ybot (1-274), Dadi_attesa_ybot (1-145), Dadi_agitati_ybot (1-275), 30 fps.
- Pacchetto per Codex pronto nella stessa cartella: COMPITO_CODEX.md, MESSAGGIO_DA_DARE_A_CODEX.txt, `destinazioni\`
  (copie: braccia v010 .blend, mago_meshy_con_dita.glb, mago Meshy originale per confronto, FBX caricato su Mixamo).
- Codex ha letto il compito e risposto con un piano corretto. Claude ha dato all'utente un testo di aggiunta:
  pose di riposo diverse, presa v010 e controlla.py, luce delle candele, e FARE PRIMA SOLO Carte_A sulle braccia
  con video accanto all'originale Mixamo. Non si sa se l'utente l'ha già incollato.
- Codex scriverà in `animazioni_mixamo_da_claude\v001_codex\`. Niente ancora consegnato.

## Cosa abbiamo provato che NON ha funzionato
- Caricare su Mixamo le braccia v010 o il mago Meshy riggato: "impossibile mappare lo scheletro esistente"
  (solo braccia / scheletro non Mixamo).
- Mago senza scheletro con "Standard Skeleton (65)": Mixamo crea 33 ossa con il SOLO indice, perché le dita del guanto
  sono chiuse e unite. Quei file sono in `mixamo_originali\vecchie_33_ossa_non_usare\`.

## Problemi incontrati e come li abbiamo risolti
- Mixamo rifiuta lo scheletro → FBX del mago senza scheletro (da mago_nero_pulito.glb, posa ad A, 1,85 m, texture dentro).
- Dita mancanti → riscaricate le stesse clip sul personaggio Y Bot di Mixamo (65 ossa). Il movimento è lo stesso.

## Decisioni prese
- Lo scheletro Mixamo serve solo come sorgente; non entra nel gioco. Scartato: usare lo scheletro Mixamo per tutto e
  ricopiarci le animazioni Meshy (rifare presa e braccia v010 già approvate costerebbe lavoro per niente).
- Mago visto dagli altri: si usa mago_base_dita.glb (Meshy + 30 ossa delle dita aggiunte il 23/10), non l'originale a 24 ossa.
- Ordine: prima le carte, poi i dadi (le clip dei dadi le ha volute l'utente "perché possono servire"; nel gioco non ci sono dadi).
- Il lavoro va a Codex; Claude controlla e inserisce nel gioco solo dopo "APPROVATO".

## File toccati
- `assets_src\personaggi\mago_nero\per_mixamo\mago_nero_per_mixamo.fbx`: nuovo, mago senza scheletro per Mixamo.
- `Desktop\prova_chatgpt_mani\animazioni_mixamo_da_claude\`: cartella nuova con compito, messaggio, copie e clip.
- `RIPRENDI_DA_QUI.txt`: riga del 7/11 sulle animazioni Mixamo.
- Memoria: `mixamo-dita-ybot.md` + riga in MEMORY.md.
- Nessun file del gioco (GamePC) modificato; originali in `scaricati\` e cartella v010 intatti.

## Dove vogliamo andare
1. Quando l'utente porta il primo video di Codex (Carte_A sulle braccia in prima persona): guardare il video e le foto
   con luce delle candele, controllare i numeri di controlla.py (0 attraversamenti mani/carte, mani sopra il tavolo)
   e il confronto con l'originale Mixamo.
2. Se va bene: Codex fa Carte_B, poi il mago intero (seduto, solo dalla schiena in su), poi i dadi.
3. Dopo "APPROVATO": inserire nel gioco (prima persona) e riesportare build\PROGETTO.exe.

## Da sapere prima di toccare qualcosa
- Python non è nel PATH di Git Bash: per leggere i GLB usare Blender 5.2 (`C:\Program Files\Blender Foundation\Blender 5.2\blender.exe -b --factory-startup`) o PowerShell.
- Controllare SEMPRE l'elenco delle ossa dei file Mixamo (contare le dita), non fidarsi dell'opzione scelta sul sito.
- Il `controlla.py` della v010 funziona solo dalla sua cartella (legge `lavoro\movimenti_v010.json`).
- Schiena: Mixamo Spine/Spine1/Spine2 dal basso; Meshy Spine02/Spine01/Spine: verificare i genitori prima di abbinare.
- I file Y Bot contengono il corpo `Alpha_Surface`/`Alpha_Joints`: solo da guardare, non va esportato.
