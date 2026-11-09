---
type: handoff
date: 2026-11-01
status: concluso
seq: 2
prev: docs/handoff/2026-10-23-mago-carte-sedia.md
tags: [mago-nero, carte, presa, abbandonato, prima-persona]
---

# Handoff: presa delle carte calcolata sul mago di Meshy (ABBANDONATA)

## Obiettivo
Il mago nero di Meshy seduto al tavolo con 5 carte in mano: perno fra pollice e indice-medio, niente dita nelle
carte. Il 1/11 l'utente ha ABBANDONATO la strada. Motivi: dita fuse, avambraccio che si deforma, dito piegato a meta',
troppi token. In prima persona si useranno braccia FPS separate (come Liar's Bar). Il mago di Meshy resta per come ci
vedono gli altri, con scheletro e animazioni intatti.

## A che punto siamo
- Lavoro concluso e messo da parte: tutto in assets_src/personaggi/mago_nero/carte_sedia/ (STATO_LAVORO.txt, sezione 1/11).
- Numeri finali: 0 incroci mano-carte su 1351 fotogrammi (incroci.txt), polpastrelli 0,3-1,5 mm (contatti.txt), animazioni
  vecchie identiche (confronto.txt: 0 m). L'utente ha detto comunque "non va bene nulla": i numeri non bastano, l'aspetto no.
- mago_carte.glb aggiornato con la presa nuova. Nel gioco (GamePC) NULLA, nessun commit. Video vecchi non rifatti.

## Cosa abbiamo provato che NON ha funzionato
- Presa "nel palmo" (23/10): le carte entravano nel palmo, fino a 12 mm, mentre il controllo vecchio diceva 0.
- Presa col pollice sul mago intero (1/11): numeri perfetti ma aspetto bocciato. Il guanto Meshy ha dita fuse e
  l'avambraccio si deforma: nessuna presa calcolata lo rende credibile da vicino.
- Prese con il polso fuori dal costo: la piega del polso andava oltre 100 gradi.
- Pollice staccato con forza al lancio: la pelle si tirava 13,9 contro un massimo di 5,5 nelle animazioni originali.

## Problemi incontrati e come li abbiamo risolti
- Controllo cieco sulle carte da 2 mm. Rimedio: contare i lati della pelle che tagliano la lastra (incroci.py).
  Vale anche per le braccia FPS.
- Respiro sommato: sposta i polsi e le due mani si muovono fra loro sulla stessa carta. Rimedio: IK che rimette le
  mani a posto (sequenza.ferma_mani).
- Sfumature tra animazioni durante una presa: attraversano le carte. Rimedio: interrompere solo con la mano lontana.

## Decisioni prese
- SCELTO: prima persona con braccia separate pronte (CGTrader "Game Ready FPS Arms", in modelli_scaricati/braccia_fps).
  SCARTATO: presa calcolata sul mago di Meshy (dita fuse, troppi token).
- Il mago di Meshy resta per la vista degli altri, scheletro e animazioni INTATTI.

## File toccati
- carte_sedia/: incroci.py, incroci_clip.py, cerca_presa_pollice.py, rifinisci_polso.py, pieghe_per_numero.py,
  cerca_pinza_dita.py, cerca_pila_bordo.py, valuta_polso.py, tabella_contatti.py, foto_presa.py, foto_finali.py (nuovi).
- carte_sedia/: anima.py, chiavi.py, mano_dita.py (Thumb_gira), sequenza.py (ferma_mani), esporta.py, rendi.py (modificati).
- carte_sedia/: presa_ventaglio.json, pinza_dita.json, pila_bordo.json (nuovi).
  Copie delle vecchie: presa_ventaglio_PALMO_23-10.json, pila_*_23-10.npy, pinze_destra_23-10.npy.
- carte_sedia/foto: restano solo presa_nuova_*.png; 39 file vecchi nel Cestino di Windows su richiesta dell'utente.
- Memoria: presa-carte-incroci.md. RIPRENDI_DA_QUI.txt: nota in cima.

## Dove vogliamo andare
Prova delle braccia FPS (solo da guardare, niente nel gioco): esame del modello, ricolore a guanto di cuoio nero con
bordo della manica, 5 carte tenute come in Liar's Bar davanti a una telecamera in prima persona, controllo incroci,
3 foto dalla vista del giocatore e una ravvicinata.

## Da sapere prima di toccare qualcosa
- Non cancellare niente in carte_sedia: e' il materiale della strada abbandonata, puo' servire (incroci.py si riusa).
- Per il mago intero si puo' tornare indietro con presa_ventaglio_PALMO_23-10.json.
