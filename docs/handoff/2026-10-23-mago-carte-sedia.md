---
type: handoff
date: 2026-10-23
status: in-corso
seq: 1
prev: nessuno
tags: [mago-nero, animazioni, carte, sedia-pietra, dita, meshy]
---

# Handoff: mago nero seduto con le carte (passo 1)

## Obiettivo
Il personaggio Meshy "mago nero" (sarà TUTTI i campioni) deve sedersi su una sedia di pietra al tavolo, guardare un
ventaglio di 5 carte, giocarle e alzarsi (rabbia se perde). Regola dell'utente: le animazioni che il personaggio ha già
NON devono cambiare di nulla. Passo 1 = solo prova da guardare (foto/video); passo 2 (gioco + commit) SOLO dopo "APPROVATO".

## A che punto siamo
- Fatto e verificato: 5 animazioni nuove (si_siede, guarda_carte, gioca_carta con rilascio al fotogramma 28,
  si_alza, respiro_seduto da sommare), ossa delle dita aggiunte, sedia di pietra, carte che scivolano a ~36 cm dal bordo.
- File finale: assets_src/personaggi/mago_nero/carte_sedia/mago_carte.glb. Animazioni vecchie identiche
  all'originale: ossa 0, pelle 0,0002 mm, anche in Godot (confronto.txt, confronto_pelle.txt, confronto_godot.txt).
- Ultima richiesta: carte alzate nella mano all'altezza "2" della schermata dell'utente
  (Pictures/Screenshots/Screenshot 2026-10-23 005227.png) -> applicato presa_alta_2.json (2 cm), sequenza rifatta,
  controlli ok, foto mostrate (foto/carte_alzate_applicate.png, foto/anteprima_finale.png). In attesa del sì dell'utente.
- NON rifatti ancora con la presa nuova: video_partita.mp4 e video_animazioni_vecchie.mp4 (quelli su disco sono vecchi).

## Cosa abbiamo provato che NON ha funzionato
- Ventaglio con la mano rigida (senza ossa delle dita): carte "appoggiate sul pollice", bocciato dall'utente.
- Presa con pollice davanti e dita dietro senza compenetrazione: impossibile con questo guanto (la radice del pollice
  taglia il piano delle carte). Funziona la presa "nel palmo" (pollice sulle facce, dita attorno al bordo), ~0,7 mm.
- Alzare le carte lungo il loro asse: le sposta DI LATO (utente: "più aumentano i cm più le sposti verso un lato").
  Giusto: dritte in alto nel mondo, nel piano delle carte, la mano ferma (alza_carte.py, su_dir).
- Ricerca automatica delle punte delle dita: sbaglia (dita piegate e fuse). Punte lette sul disegno (disegna_mano.py).
- Zona del pollice per sola distanza: invadeva il palmo (pelle strappata 28 mm). Limitata a un tubo di 2,2 cm.
- Tubo stretto (1,3 cm) anche sulle 4 dita: peggio (parti di dito restavano al palmo). Tolto.
- Bordo del tavolo raggiunto dalla sedia scostata: le braccia sono corte (44 cm spalla-polso); ci si tira con le cosce.
- Carta atterrata col cerchio in su: rotazione di 169° in pochi fotogrammi. Ora atterra a faccia in su.

## Problemi incontrati e come li abbiamo risolti
- Anteprime sfasate: Blender importa le animazioni a 24 fps. Impostare scene.render.fps = 30 PRIMA di importare.
- Meshy duplica i punti lungo le cuciture: per le distanze sulla superficie saldare i punti per posizione (dita.py).
- Controlli "mani" dopo le dita: contare anche le falangi (LeftHand*), non solo l'osso della mano (controlli.py).
- Stiramento: misurarlo in mm di allungamento, non in rapporto (le nocche danno rapporti alti e invisibili).

## Decisioni prese
- Tutti i campioni = mago; sedia SEMPRE in pietra (fatta in Blender, sedia_pietra.py, texture dark_rock CC0); 5 carte
  in mano. Le REGOLE del gioco andranno rifatte in futuro (non ora).
- Niente "si siede/si alza" nel file Meshy (verificato a 15 campioni/s): fatti da Claude. L'utente può riscaricare da
  Meshy quella per alzarsi: va confrontata con la nostra.
- Respiro esistente (Idle_11) stona da seduto -> respiro_seduto (stessa forma, 4 s, ampiezza 0,8, testa e mani compensate).
- Sedia che scivola piano e poco (opzione 2 dell'utente): spinta 0,29 m quando si alza (minimo per i gesti di rabbia).
- Ossa delle dita AGGIUNTE (non cambiano le ossa esistenti): scelta per poter muovere le dita.

## File toccati
Tutto in assets_src/personaggi/mago_nero/carte_sedia/ (STATO_LAVORO.txt ha l'elenco): rig.py, pose.py, chiavi.py,
carte.py, anima.py (clip), respiro.py, sequenza.py, controlli.py, esporta.py, confronta*.py, rendi.py, rendi_vecchie.py,
dita.py, mano_dita.py, cerca_presa_palmo.py, alza_carte.py, sedia_pietra.py; presa_ventaglio.json (= presa_alta_2).
Fuori: RIPRENDI_DA_QUI.txt (nota in cima), memoria (blender-fps-import-gltf, dita-meshy, maghi-sedia-pietra-carte).
Nel gioco (GamePC) NULLA, nessun commit.

## Dove vogliamo andare
1. Chiedi all'utente se l'altezza delle carte (2 cm) va bene; se no, rifai presa_alta con il valore detto e mostra SOLO foto.
2. Con il sì: rifai i due video (comandi sotto) e mostrali.
3. Con "APPROVATO": passo 2 nel gioco (tutti maghi, sedie di pietra, tavolo abbassato ~72 cm, 5 carte,
   AnimationTree con respiro sommato, sedia mossa dal gioco con extras sedia_z, carte come anima.carte_da_stato),
   foto/video dal gioco, build, commit su "grafica".

## Da sapere prima di toccare qualcosa
- Python di Blender: "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -X utf8 (cartella carte_sedia).
- Rifare tutto: salti.py ... ; sequenza.py ; esporta.py ; confronta.py ORIG mago_carte.glb ; confronta_pelle.py ORIG mago_carte.glb ;
  controlli.py 2 (veloce) o 1 (tutti i fotogrammi, ~10 min).
- Video (in sottofondo, ~25 min): blender -b --factory-startup --python rendi.py -- sequenza.glb sequenza.json
  <percorso>/video_partita.mp4 video - davanti,gioco,gioco_fronte ; poi rendi_vecchie.py ORIG mago_carte.glb <percorso>.mp4
- "mani_nel_corpo 25 mm" in si_alza è la mano sulla tunica (stoffa sottile): verificato a occhio, non è un errore.
- Fermare un render: TaskStop + controllare con tasklist che blender.exe sia chiuso.
- L'utente vuole vedere FOTO prima di ogni video; finestre di prova fuori schermo; parlare in italiano semplice.

## NOVITÀ 1/11 (aggiunta su richiesta dell'utente)
- DECISO: al tavolo si gioca in PRIMA PERSONA, come Liar's Bar. La telecamera è agli occhi del proprio mago; si
  vedono le proprie mani vicine (anche un modello di sole braccia), con le carte grandi e leggibili tenute A PINZA dal
  bordo in basso: pollice davanti vicino all'angolo, indice e medio dietro.
- Questo risolve il limite visto sopra: "pollice davanti e dita dietro impossibile con questo guanto". Le mani della
  prima persona saranno un modello fatto apposta per quella presa. Il mago visto da fuori (gli ALTRI giocatori)
  può tenere la presa "nel palmo", che da lontano non si nota, purché le carte non attraversino le dita.
- Ordine: 1) finire la presa del mago visto da fuori; 2) proporre all'utente la prima persona con un'immagine di
  prova, che va APPROVATA prima di procedere.
- Regole del gioco nuove (bozza da 6 a 8 giocatori, SOLO persone, niente computer): REGOLE_6-8_GIOCATORI.md nella
  radice. Solo da leggere, non si programma finché l'utente non lo chiede.
