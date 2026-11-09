---
type: handoff
date: 2026-11-03
status: in-corso
seq: 4
prev: docs/handoff/2026-11-02-mago-carte-sedia.md
tags: [prima-persona, braccia, vestito-mago, tavolo, sedie, custode-seduto, skill, godot-4.7]
---

# Handoff: braccia vestite da mago (a Codex), tavolo da seduti, Custode sul trono

## Obiettivo
"Le Catene dell'Altare" giocato in prima persona come Liar's Bar: il giocatore vede le sue braccia di mago che tengono
le carte, di qualita' alta e uguali al vestito del mago visto dagli altri. Intanto la scena del tavolo deve reggere da
4 a 8 persone sedute, col Custode seduto sul trono.

## A che punto siamo
- NEL GIOCO (ramo "grafica", ultimo commit dopo f2b8e51, build riesportata 3/11 01:57): tavolo a 75 cm, una sedia di
  pietra per posto, campioni seduti (gambe provvisorie a blocchi), Custode seduto sul trono. Prove a 5 e 8 ok
  (0 punti di catena nella pietra). Fluidita' a 8, foresta: 45 fotogrammi/s (prima 50; senza sedie 47).
- BRACCIA IN PRIMA PERSONA: NON nel gioco. Mani e animazione di Codex (presa approvata, da non toccare). Vestito del
  mago fatto da Claude in 5 versioni (assets_src/personaggi/braccia_fps/vestiti_mago); l'utente ancora "sembra un
  manichino". ORA CI LAVORA CODEX nel pacchetto Desktop\prova_chatgpt_mani\vestiario_mago_v005_da_claude
  (COMPITO_CODEX.md; lui scrive in v008_codex\). Non toccare finche' l'utente non dice che ha finito.
- 4 skill nuove nel progetto: card-game, godot-gdscript-headless-testing, steam-publish, localization.
- RIPRENDI_DA_QUI.txt accorciato a ~100 righe; storia completa in documenti/STORIA_DEL_PROGETTO.txt.
- Cartelle riordinate (2/11): scaricati\, riferimenti\, documenti\; file inutili nel Cestino col si' dell'utente.

## Cosa abbiamo provato che NON ha funzionato
- Manica = pelle dell'avambraccio spinta fuori con l'aspetto del mago ricalcato: "manichino".
- Pezzo VERO del modello Meshy del mago attaccato alle ossa di Codex: forme giuste, ma da vicino sgranato e grossolano.
- Pieghe della manica LUNGO il braccio: effetto tubo ondulato. Vanno ATTORNO al braccio (rotoli storti e interrotti).
- Simulazione della stoffa di Blender (tubo spinto verso il gomito): esplode due volte (punte di 60 cm).
- Grinze di guanto e bracciale fatte a numeri e cotte (v5): meglio, ma l'utente non e' contento -> passato a Codex.
- Ornamenti (rune, medaglione, toppa a scudo, ricamo) graditi come idea, purche' solo argento/cuoio/filo.
- Sedie con ombre proiettate: -5 fotogrammi/s a 8 giocatori.

## Problemi incontrati e come li abbiamo risolti
- Colore cotto nero dal mago: il materiale Meshy ha Metallic 1 -> cuocere come EMIT. Stessi Metallic/Roughness del mago
  per sembrare un tutt'uno.
- Pezzo spostato di 6-8 cm: allungare lungo un asse ruotato va fatto sui punti (mesh.transform), non con matrix_world.
- Cottura del bracciale cancellata: pareti interna/esterna sovrapposte nella UV -> separarle prima di cuocere.
- Braccia FPS: sinistra e destra sovrapposte nella UV -> una mappa per mano (UVGuanto 4096x2048).
- Nodo Mix di Blender 5.2: usare gli identificatori (A_Color, B_Color, Result_Color), non gli indici.
- Luminosita' di un'immagine sRGB nei nodi: misurarla in lineare.
- Pacchetti per Codex: impacchettare le immagini nel .blend; il file di Codex ha un'immagine rotta del venditore (ignorarla).
- API GitHub senza accesso: 60 richieste l'ora; gli indirizzi presi da Windows hanno "\r" in fondo (tr -d '\r').

## Decisioni prese
- Braccia in prima persona = modello a parte, di qualita' alta (come nei giochi veri); il mago visto dagli altri
  resta identico. Scartato: riusare il modello Meshy da vicino.
- Mani e presa: di Codex, ferme. Il vestito si aggancia alle sue ossa e segue da solo.
- Tavolo: uno solo per 4-8, abbassato a 75 cm (scartati: tavolo che si adatta, tavolo senza altare). Sedie: quella di
  pietra del 22/10 (scartate: nuove gotiche o povere). Menu resta da 4 a 8.
- Custode: modello piegato alle anche/ginocchia (custode_seduto.py), senza scheletro; per alzarsi servira' la fase 3.
- Sedie senza ombre proiettate (a vista non cambia).
- Skill: installate 4, scartata balance-check (dipende dalla sua raccolta e lancia comandi al caricamento).
- Godot 4.7.2: conviene, ma DOPO aver messo nel gioco le braccia di Codex (non cambiare motore a meta').

## File toccati
- GamePC/scripts/world/arena.gd: TABLE_TOP 0.75, _chair (sedie, senza ombre), Custode seduto (custode_seduto.glb).
- GamePC/scripts/world/figura.gd: campioni seduti (actor con perno all'anca, _corpo, _gambe, _legs).
- GamePC/tests/prova_catene.gd: foto 11-14 (Custode sul trono, seduto di fianco/dietro, dall'alto).
- GamePC/assets/scenari/modelli/sedia_pietra.glb, custode_seduto.glb (+ immagini importate).
- assets_src/custode/custode_seduto.py (nuovo).
- assets_src/personaggi/braccia_fps/vestiti_mago/: fp_geometria.py, fp_materiali.py, fp_rughe.py, fp_bracciale.py,
  fp_manica_pieghe.py, fp_foto.py, controlla.py, esporta.py, impacchetta.py; consegna_v002..v005.
- GamePC/.claude/skills/: card-game, godot-gdscript-headless-testing, steam-publish, localization.
- RIPRENDI_DA_QUI.txt (corto), documenti/STORIA_DEL_PROGETTO.txt (nuovo), GamePC/devlog.md sezione 23,
  GamePC/assets/scenari/FONTI.txt (texture Poly Haven, braccia CGTrader).

## Dove vogliamo andare
1. Quando l'utente dice che Codex ha finito: aprire la sua versione (v006 o v008), lanciare controlla.py (0 incroci con
   carte/tavolo/vestito), foto con fp_foto.py "candela" e "studio", mostrarle.
2. Con "APPROVATO": prima persona nel gioco (telecamera agli occhi, braccia vestite alleggerite, carte in mano),
   build, prova, commit.
3. Poi aggiornare Godot a 4.7.2 (cartella nuova accanto alla 4.6, reimport, tutte le prove, git per tornare indietro).
4. Piano a fasi (documenti/ISTRUZIONI_ATMOSFERA.txt): fase 3 scheletro del Custode, fase 4 effetti dai cerchi.

## Da sapere prima di toccare qualcosa
- Non toccare Desktop\prova_chatgpt_mani: ci lavora Codex.
- Gli script di vestiti_mago vanno lanciati dalla loro cartella (percorsi relativi verso la scena di Codex e il mago).
- Le misure di fluidita' oscillano di +-3: ripeterle almeno due volte prima di decidere.
- Alla chiusura di Godot compaiono a volte "resources still in use" / "ObjectDB leaked": c'erano anche prima, non bloccano.
- Le skill nuove sono scritte per Godot 4.7: verificare i comandi sulla 4.6.
