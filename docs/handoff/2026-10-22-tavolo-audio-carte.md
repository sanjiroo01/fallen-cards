---
type: handoff
date: 2026-10-22
status: in-corso
seq: 1
prev: nessuno
tags: [catene-altare, giocatori-4-8, tavolo, audio, carte, trono]
---

# Handoff: tavolo da 8, audio, carte cupe

## Obiettivo
"Le catene dell'altare": gioco horror di inganno, con un sabotatore segreto, per 4-8 persone in rete. Si vince con
l'atmosfera (luce e scena), più che con il dettaglio dei personaggi. In questa sessione: un tavolo più grande e
interessante, la scena più realistica, l'audio regolabile anche in partita e le carte più cupe.

## A che punto siamo
- Funziona: da 4 a 8 giocatori (menu "Al tavolo"). Funzionano anche il tavolo di pietra, le catene agganciate al
  tavolo, le carte giocate sul tavolo, il rogo al proprio posto, il pannello Audio (generale, interruttore, tasto M,
  pausa) e le carte nuove. La build è esportata e provata (commit e0ae4e8).
- A metà: fase 2 di ISTRUZIONI_ATMOSFERA.txt. Il trono è nella scena (THRONE_POS z = -5,15), ma il Custode gli
  fluttua davanti senza sedersi. Con la visuale "di tre quarti" (quella salvata dall'utente) il trono resta fuori
  dall'inquadratura.
- Non iniziato: fase 3 (scheletro del Custode, si alza e si siede), fasi 4-5, i morti decorativi da Meshy.
- La sacerdotessa NON va nella scena: ci lavora l'utente.

## Cosa abbiamo provato che NON ha funzionato
- Regole dei 4 senza ritocchi a 5-8 giocatori: il sabotatore prende troppi punti (2,45 contro 1,45 a 8). Scartate.
- Rune a trattini accese sulla cornice delle carte: sembrano lucine moderne. Tolte; al loro posto un solco inciso.
- Colature di cera come cerchi pieni (rosa piatto) e poi come strisce lunghe fino in fondo (era un errore nella forma
  della goccia). Ora sono goccia e colatura brevi.
- Gocce di sangue a (455,735): coprivano la spiegazione della carta. Spostate a (520,575).
- Colature di cera a forma di capsule sul bordo del tavolo e dischi sul piano: sembravano plastica e buchi. Tolte.
- Rogo con il materiale arancione emissivo (_ignite): sembrava una sagoma piatta di plastica. Ora c'è la brace
  (brace.gdshader) più il volume di fuoco largo 1,5 m.
- `_top_bar.reparent(_root)` con le opzioni di base: la barra finiva fuori schermo. Serve `reparent(_root, false)`.

## Problemi incontrati e come li abbiamo risolti
- Audio "non si toglie": i suoni dei luoghi suonano sul canale Amb, che nessun cursore comandava. Ora i volumi vanno
  sui canali (Master, Amb, SFX) in sfx.gd _apply_settings. La regola è nella memoria volumi-sui-canali.
- Le prove sovrascrivevano user://audio.cfg dell'utente. Ora prova_audio.gd salva il file e lo rimette a posto alla
  fine.
- Pulsanti in alto coperti dai messaggi grandi: la barra adesso è l'ultimo figlio di _root.
- I bot da 6 in su giocano poco la carta Voto (0,25 a manche): i sospetti si diluiscono. Non è corretto: è da misurare
  con persone vere.

## Decisioni prese
- 5 giocatori: le regole dei 4, ma il sabotatore salvo prende 2 punti. Scartato il "senza doppio colpo" (1,98 contro
  1,51).
- 6-8 giocatori: 2 sabotatori che si conoscono, bruciano i 2 più legati, 14 candele, candela ferma se tirano tutti
  tranne uno, carte del sabotatore su un solo bersaglio. Scartato "un solo sabotatore" (troppo forte e poco sociale).
- Le catene vanno agli anelli sul basamento del tavolo. Scartato "al trono": servirebbero catene lunghe 6-8 m, sono
  costose da simulare e attraversano il tavolo.
- L'altare è a terra e non si muove. Le funzioni altar_step e altar_fly restano nel codice ma non vengono chiamate.
- Per Ponytail ci sono solo le skill, non il plugin: i suoi automatismi vogliono Node.js, che manca.
- Il dorso delle carte usa il cerchio rituale del pavimento (la firma visiva). Scartato un sigillo disegnato a parte.

## File toccati
- scripts/catene/catene_rules.gd: N campioni, sabs(), is_sab(), for_players(), burn_top, escaped[].
- scripts/catene/catene_bot.gd: complici, sabotatori scoperti, sus di dimensione N.
- scripts/catene/catene_match.gd: N giocatori, testi, complice, rogo al posto, niente volo.
- scripts/world/arena.gd: posti per N, _table(), anelli del tavolo, _off_table, carte sul tavolo, burn_seat.
- scripts/world/figura.gd: 4 campioni nuovi (sagome), slump, burn_in_place.
- scripts/ui/hud.gd: "Al tavolo", Audio con interruttore e generale, tasto M, Audio e Visuale nella pausa, _top_bar.
- scripts/audio/sfx.gd: audio_on, master_vol, volumi sui canali.
- scripts/ui/carta.gd: inchiostri, alone del simbolo, dorso solo da immagine.
- scripts/cerchio/testi.gd: campioni 5-8, regole per 6-8.
- scripts/game.gd: --giocatori=N, --prova-audio.
- tests/sim_catene.gd (giocatori=N), tests/prova_catene.gd (tavolo, rogo, voto), tests/prova_audio.gd (nuovo).
- assets/carte/*.png, ../assets_src/carte/cuoci_carte.py (v2; la v1 è salvata accanto), sorgenti_cc0/.
- docs/catene_altare.md (in fondo: da 4 a 8), CREDITI.txt, assets/scenari/FONTI.txt, ../RIPRENDI_DA_QUI.txt.
- Fuori dal repo: ~/.claude/skills/ponytail*, plugin superpowers, ~/.claude/skills/handoff, Desktop/dorso_carta.png,
  fronte_carta_bianca.png e fronte_carta_vuota.png.

## Dove vogliamo andare
1. Fai sedere il Custode sul trono e porta il trono dentro l'inquadratura con tutte le visuali, compresa "di tre
   quarti". Controlla con le foto dalla telecamera del gioco.
2. Poi la fase 3: scheletro del Custode (Mixamo, chiedi all'utente di caricare l'FBX), animazioni seduto, si alza e
   si risiede. Si alza quando viene scoperto il sabotatore.

## Da sapere prima di toccare qualcosa
- Comandi dalla cartella GamePC, con G=../godot/Godot_v4.6-stable_win64_console.exe. Le finestre di prova vanno sempre
  fuori schermo: `--position -20000,-20000`.
- Prove principali: `$G --path . --resolution 1600x900 --position -20000,-20000 -- --prova-catene=CARTELLA --giocatori=8`;
  `-- --prova-audio=CARTELLA`; `-s res://tests/sim_catene.gd -- 1500 tira_o_carta=1 giocatori=N strategie=0`.
- Nel simulatore, candele, punti del sabotatore e doppio colpo per N >= 5-6 li decide for_players: le opzioni valgono
  solo se scritte a mano.
- Il file audio.cfg dell'utente ha musica spenta e volumi a zero: è una sua scelta, non un errore.
- Al primo avvio dopo un cambio delle immagini serve `$G --headless --path . --import`.
- Dopo ogni modifica: riesporta build/PROGETTO.exe e provalo (`./PROGETTO.exe --headless --audio-driver Dummy -- --auto --veloce=0.02 --esci`).
