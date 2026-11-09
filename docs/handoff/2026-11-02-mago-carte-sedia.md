---
type: handoff
date: 2026-11-02
status: in-corso
seq: 3
prev: docs/handoff/2026-11-01-mago-carte-sedia.md
tags: [prima-persona, mago-nero, carte, braccia-fps, mediapipe]
---

# Handoff: prima persona con le braccia del mago e la presa delle carte

## Obiettivo
Vista in prima persona al tavolo (come Liar's Bar): il giocatore vede le sue mani che tengono 5 carte, grandi e leggibili,
e nessun dito entra nelle carte (0 mm sulla pelle deformata, contatti 0-2 mm). Gli altri maghi si vedono da fuori.

## A che punto siamo
- SCELTA DELL'UTENTE (2/11): in prima persona si usano le braccia del MAGO DI MESHY con la presa del 1/11
  (carte_sedia/presa_ventaglio.json, mago_carte.glb). Le braccia FPS restano salvate per dopo, non si usano ora.
- Foto in prima persona fatte: carte_sedia/foto/fp_guarda.png, fp_prende.png, fp_gioca.png, prima_persona_3.png
  (fotogrammi 201, 322, 333 della sequenza). 0 incroci mani-carte con le mani lisciate.
- Si aspetta il parere dell'utente o "APPROVATO". Nel gioco (GamePC) NULLA, nessun commit.
- Difetti piccoli visti e non corretti: puntino nero vicino al pollice destro (foto guarda); macchia grigia sul palmo
  sinistro dove finisce il guanto (facce della manica originale).

## Cosa abbiamo provato che NON ha funzionato
- Braccia FPS (CGTrader "Game Ready FPS Arms") con presa cercata a numeri: pugno con carte piantate, dorsi verso il
  giocatore, polso impossibile, guanto "plastilina". Bocciata.
- Posa copiata dalle foto dell'utente con MediaPipe (braccia_fps/prova_foto.py): il pollice nella foto vista avversario
  e' nascosto (MediaPipe lo inventa); i punti 3D di MediaPipe non combaciano coi 2D (~100 px); pinza aperta di 17,5 mm
  per proporzioni diverse. Funzionava solo con correzioni e carte libere di girare. Non approvata.
- File Blender per posare a mano (scaricati/braccia_fps/posa_mano.blend): troppo difficile per l'utente.
- 4 forme di mano FPS (rilassata, morbida, pinza, pugno; braccia_fps/forme_mano.py): "nessuna", senza carte non
  sembrano tenere niente.

## Problemi incontrati e come li abbiamo risolti
- Lisciare la mesh di Meshy apre fessure: Meshy sdoppia i punti sulle cuciture UV -> saldarli prima (remove_doubles).
- Mesh Meshy con normali a facce piatte: togliere sharp_edge e normali personalizzate, ombreggiatura morbida.
- Verso "verso il palmo" di una falange: misurarlo a dita DRITTE (riposo); a dito piegato il segno viene sbagliato.
- Blender 5.2: un materiale nuovo puo' non avere il nodo Principled (crearlo); le aree divise si vedono solo dopo il
  ridisegno (impostarle in un timer successivo).

## Decisioni prese
- Scelto: braccia del mago + presa 1/11. Scartati: braccia FPS (per ora), pose a mano in Blender, forme generiche.
- Prima persona: testa e collo del proprio mago nascosti (3.716 punti), mani saldate+lisciate con guanto di cuoio liscio.
  Scartato: riusare la texture con cuciture FPS (legata alla mappa UV di quel modello).
- Licenza braccia FPS (Royalty Free No AI): vendibile se il modello resta chiuso nel gioco, niente IA.

## File toccati
- carte_sedia/foto_fp.py (nuovo): scena di un fotogramma con telecamera agli occhi (occhi() + direzione della testa).
- carte_sedia/prima_persona.py (nuovo): via testa/collo, saldatura, lisciatura e guanto liscio, controllo_fp() incroci.
- carte_sedia/rendi.py: risoluzione da json, aggancio "prima_persona", controllo dopo il rendering, camere da json.
- assets_src/personaggi/braccia_fps/: tutto il lavoro FPS (prova_*.py, prepara_posa.py, layout_posa.py,
  controlla_carte.py, forme_mano.py, leggi_mano.py, camera_foto.py, venv_mp con MediaPipe, mano_foto.json).
- scaricati/braccia_fps/posa_mano.blend + APRI_POSA_MANO.bat (originali arms.* intatti).
- Foto vecchie nel Cestino su richiesta. RIPRENDI_DA_QUI.txt aggiornato. Memoria: presa-carte-incroci.md.

## Dove vogliamo andare
1. Chiedi all'utente il parere sulle 3 foto in prima persona; se vuole, correggi puntino nero e macchia grigia.
2. Con "APPROVATO": nel gioco, prima persona per il proprio mago (telecamera agli occhi, testa/collo nascosti, mani
   lisciate col guanto liscio), carte nella mano sinistra come presa_ventaglio.json; mani ferme col respiro (IK) e
   gioca_carta solo con la destra sul tavolo (extras di mago_carte.glb). Poi build, prova, commit su "grafica".

## Da sapere prima di toccare qualcosa
- Foto prima persona: python foto_fp.py fp_X FOTOGRAMMA; poi blender -b --factory-startup --python rendi.py --
  fp_X.glb fp_X.json <percorso>/foto/fp_X.png foto 0 occhi (cartella carte_sedia, Python di Blender con -X utf8).
- Le modifiche di prima_persona.py valgono SOLO per le foto: il GLB e i controlli usano la mesh originale.
- L'utente vuole foto prima dei video; finestre di prova fuori schermo; italiano semplice; foto vecchie nel Cestino
  solo su richiesta.
