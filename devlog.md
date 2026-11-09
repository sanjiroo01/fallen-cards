# Diario di PROGETTO

Il diario del lavoro precedente è archiviato in `../dismissed/GamePC/devlog.md`.

## 1. Il gioco nuovo (15/10/2026)
- Idea scelta con l'utente: quattro campioni fantasy (Cavaliere, Strega, Elfo arciere, Domatore di
  draghi) attorno al cerchio del Custode, scelte segrete e simultanee, tono cupo e teso.
  Riferimento: `docs/progetto.md`.
- Simulatori (`tests/sim_cerchio.gd`, `tests/sim_cerchio_manche.gd`), circa 50.000 partite fra bot:
  - iniziativa: l'ordine dei colpi elimina le manche senza vincitore (dal 20-25% allo 0%);
  - tre manche a punti (3/2/1/0, la terza doppia): 11-13 minuti, mai decise prima della terza;
  - scommessa dello spettro: tenuta; lo spettro non tocca il gioco dei vivi.
- Ordine dei colpi estratto solo dopo le scelte (proposta dell'utente): stessi numeri, più crudele.
- Problema trovato: nel duello a due difendersi era sempre meglio (difesa-difesa 80-86% dei giri).
  Soluzione approvata: "Riaccendi una candela" (con 2 o meno, riesce se nessuno ti attacca), che crea
  un cerchio attacco > riaccendi > difesa > attacco. 4 candele: 12,9 minuti, classi 24-27%.
  I bot ora leggono le ultime mosse libere dell'avversario nel duello.

## 2. Pulizia e prototipo giocabile (15/10/2026)
- Tutto il vecchio gioco è in `../dismissed/` (codice, modelli, carte, maschere, eseguibile, diario,
  strumenti Blender dei vecchi personaggi, skill personaggio). Tenuti: candele, luci, materiali,
  geometria, shader, suoni generati, caratteri, PROGETTO Live (esempi resi generici).
- Prototipo: menu con scelta del campione, 10 pagine di regole nel gioco, pulsante "? Regole" sempre
  presente, Presagi, Patto, Occhio della strega, Freccia doppia, Giuramento, Soffio del drago,
  rivelazione con mosse sopra le teste, ordine dei colpi, racconto, candele che si spengono e si
  riaccendono, spettri e scommesse, classifica e verdetto. Scenari: foresta cupa e castello maledetto.
- Le regole ora restituiscono anche la lista degli eventi del giro (`rep["events"]`) per animarli.
- Verifiche: partite automatiche complete senza errori (`--auto`); 5 partite premendo pulsanti a caso
  (`--clic`) senza errori; immagini osservate di menu, regole, scelta, rivelazione, classifiche e
  verdetto. Corretti dopo le immagini: scritte 3D troppo grandi e sovrapposte, telecamera troppo bassa,
  suggerimento scritto in verticale, frasi del racconto ("dalla Strega", "1 punto").
- Da fare: online, effetti degli scenari, audio dedicato, modelli veri e animazioni, nome del gioco.

### Shadowkin, prima revisione Codex completata - 15 ottobre 2026
- Richiesta dell'utente: modificare un primo modello a scelta e mostrare prima/dopo. Scelto Shadowkin.
- File finale: `../Modelli_Fantasy_Condivisi/Codex/01_Shadowkin_v001/Shadowkin_Codex_v001.blend`; checkpoint PRIMA e sorgenti conservati, texture incorporate.
- Materiali stoffa/cuoio/metalli rivisti, maschera separata, aggiunti grimorio, sigillo da petto e focus magico. Render prima/dopo osservati da tre quarti, in dettaglio e da dietro, con posa/camera/luci identiche.
- Blender 5.2.2: file finale riaperto e controllato; 151 ossa, tre azioni originali e 8.292 vertici originali conservati. 21.274 triangoli valutati, accessori inclusi e studio escluso. Focus segue la mano nella prova di rotazione. Archivio originale invariato.
- Non ancora esportato o verificato in Godot; nessuna nuova animazione di combattimento creata. Limiti e istruzioni riproducibili in CONSEGNA.md della revisione. Nessun file di Claude o codice del gioco modificato.

### Shadowkin v002, variante stregone Codex - 15 ottobre 2026
- Richiesta: mantello stracciato, maschera cupa e vestiario nuovo, mantenendo la v001 approvata. Salvato `../Modelli_Fantasy_Condivisi/Codex/01_Shadowkin_v002/Shadowkin_Codex_v002.blend`.
- Mantello lungo con strappi geometrici, maschera autonoma di ferro annerito con fessure reali, veste lunga aperta, stola ricamata, corda in vita e polsi fasciati. Grimorio e focus mantenuti; elementi precedenti in archivio nascosto. Originali e v001 intatti.
- Verificato in Blender 5.2.2 con riapertura del file: 151 ossa, tre azioni originali, texture incorporate, pesi dei nuovi tessuti normalizzati; piccole rotazioni di testa/Cloak4/coscia e focus alla mano superate. 49.153 triangoli visibili valutati. ZIP originale con hash invariato.
- Render veri prima/dopo da tre quarti, dettaglio e retro con identiche camere/posa/luci. Tre cicli di revisione visiva; spalle e attacchi della stola ancora rifinibili. Nessuna nuova animazione, simulazione cloth, export o verifica in Godot. UV/baking e test di animazione ancora necessari. Consegna riproducibile e istruzioni Claude nella cartella v002. Aspetto v002 ancora da approvare dall'utente; nessun file Claude o codice di gioco modificato.

### Shadowkin v003, tunica e libro in mano - 15 ottobre 2026
- Richiesta dell'utente: usare le skill Blender, correggere tunica davanti, libro in mano e ciondolo sospeso. Letti blender-expert/rigging/motion-state-inspection e visual-review; bx_audit/bx_review eseguiti. Nessuna installazione duplicata.
- File `../Modelli_Fantasy_Condivisi/Codex/01_Shadowkin_v003/Shadowkin_Codex_v003.blend`: inserto cucito e allacciatura, falde raccordate e fascia aderente; ciondolo/stola/fibbie senza cinghie archiviati. Libro nella mano sinistra, posa statica dedicata e correttivo reversibile di contatto. Originali, v001/v002, file Claude e codice Godot intatti.
- Verificato in Blender 5.2.2: riapertura, 151 ossa, texture incorporate, quattro azioni (tre originali e una posa), libro segue rotazione mano di 10 gradi, posa stabile fra frame 1/20/1. Test vertici nelle pagine/copertine zero interni; contatto minimo palmo/copertina circa 1,4 mm; 49.417 triangoli visibili valutati. Render e tavola tecnica osservati.
- Audit: nuovo inserto/fascia e due falde senza auto-intersezioni rilevate o bordi non manifold. Corpo ancora problematico: 1.296 coppie intersecanti, 24 bordi non manifold; baseline v002 1.251/24. Non certificato pronto per le animazioni. Limiti in CONSEGNA.md. Nessun export/test Godot o simulazione cloth. Aspetto v003 ancora da valutare dall'utente.

### Shadowkin v004, veste dettagliata e bastone - 15 ottobre 2026
- Richiesta dell'utente: maggior cura/dettagli al vestito, bastone da stregone e identita' del personaggio. Variante dello Shadowkin Mage, nome provvisorio Stregone del Velo.
- Salvato `../Modelli_Fantasy_Condivisi/Codex/01_Shadowkin_v004/Shadowkin_Codex_v004.blend`: bordi ricamati, cuciture, toppe, sfilacciature, tessitura/UV e pieghe piu' varie; bastone con legno, fasciatura, bronzo e ametista nella destra, libro nella sinistra. Focus precedente archiviato; revisioni precedenti intatte.
- Blender 5.2.2: riapertura, 151 ossa, cinque azioni statiche, texture incorporate, prese seguono le mani in rotazioni di 8 gradi e posa stabile cambiando frame. Zero vertici nei volumi semplificati di pagine/asta. 60.293 triangoli visibili valutati. Render e tavola tecnica osservati, bx_audit eseguito.
- Asta/amestista/toppe/bordi senza problemi geometrici principali rilevati. Corpo ancora da pulire: 1.599 coppie intersecanti/24 bordi non manifold contro 1.296/24 in v003; la presa modifica il risultato. Correttivi specifici, non un rig certificato. Nessun attacco animato, simulazione cloth, export o test Godot. Baking/ottimizzazione e pulizia prima del gioco. Consegna e continuita' Claude nella cartella v004; nessun file Claude o codice di gioco modificato.

## 3. Carte del Custode, altare, Presagi nuovi (15/10/2026)
- Richiesta dell'utente: il gioco annoiava, mancavano strategia e brivido. Scelte: 3 carte a manche che
  cambino lo sviluppo, Presagi che diano fastidio, qualcosa al centro con cui interagire, senza copiare
  Buckshot Roulette.
- Regole: carte giocate coperte con la mossa, altare al centro, sei Presagi nuovi. Bot che usano le carte.
  Simulatore (`sim_cerchio_manche.gd carte`): numeri in docs/progetto.md.
- Nel gioco: le tue carte in basso (scegli carta ed eventuale bersaglio, poi la mossa), carte giocate
  sopra le teste e nel racconto, carta del Presagio estratta dal mazzo nel cerchio, fiamme che volano
  all'altare e tornano a chi riaccende, punti spiegati a fine manche, scritte più lente.
- Verifiche: partite --auto e --clic (che preme anche le carte) senza errori; immagini osservate.
  Corretti: riga delle carte e classifica scritte in verticale, carta giocata da te davanti alla telecamera.

### Shadowkin v005, cappuccio e palette cupa - 15 ottobre 2026
- Richiesta: copricapo come cappuccio di stoffa e tunica piu' cupa. File `../Modelli_Fantasy_Condivisi/Codex/01_Shadowkin_v005/Shadowkin_Codex_v005.blend`.
- Vecchio copricapo archiviato (814 facce); cappuccio nuovo con pieghe, apertura sotto il mento e orlo cucito. Maschera intercambiabile conservata, opaca e in ombra. Palette tunica/mantello/dettagli scurita. Libro, bastone, prese e versioni precedenti conservati; nessun file Claude/codice di gioco modificato.
- Verificato in Blender 5.2.2 con riapertura: 151 ossa/cinque azioni, texture incorporate, cappuccio segue testa in rotazione di 8 gradi, posa stabile, test prese senza vertici interni ai volumi semplificati. Audit cappuccio/orlo/cuciture senza problemi geometrici principali rilevati; render e tavola tecnica osservati.
- 85.607 triangoli visibili valutati; Subdivision del cappuccio da ridurre per il gioco. Problemi della base gia' documentati in v004 restano aperti. Nessun cloth sim, attacco animato, export o test Godot. Consegna e istruzioni Claude nella cartella v005; aspetto ancora da valutare dall'utente.

### Shadowkin v006, prova occhi visibili - 15 ottobre 2026
- Richiesta: rendere visibili gli occhi sotto il cappuccio. Variante ../Modelli_Fantasy_Condivisi/Codex/01_Shadowkin_v006/Shadowkin_Codex_v006.blend; v005 conservata.
- Maschera con aperture a mandorla, occhi ambrati (emissione tenue 0,18), pupille nere e palpebre; dieci oggetti oculari, pesi Head=1. Confronto render prima/dopo con stessa camera. Tre cicli visivi, tavola tecnica osservata.
- Verifica su file riaperto Blender 5.2.2: 151 ossa/cinque azioni, texture incorporate, occhi/maschera seguono testa 8 gradi con errore sotto 1 micrometro; frame 1/20/1 stabile. bx_audit parti oculari e maschera senza problemi geometrici principali rilevati. 89.895 triangoli visibili valutati.
- Occhi non riggati per sguardo indipendente/battito; altre maschere non testate. Problemi corpo, ottimizzazione e baking precedenti restano aperti. Nessun attacco animato, export o test Godot. Consegna e continuita' Claude nella cartella v006; proposta visiva da valutare dall'utente. Nessun file Claude o codice di gioco modificato.

## 4. Grafica, effetti e scontri in primo piano (15/10/2026)
- Spunti: luce unica dall'alto e buio attorno (Buckshot Roulette, Inscryption), primo piano su ogni
  scontro (Darkest Dungeon), fermo immagine e scintille sui colpi (Hades), "SEI CADUTO" (soulslike).
  Skill usate: game-feel (scossone a "trauma", fermo immagine a tempo reale), camera-systems.
- Arena: fascio di luce dall'alto con raggi nella nebbia, foschia a terra, braci dall'altare, cenere
  nell'aria, pellicola (vignettatura, grana), contorni dei campioni illuminati.
- Scontri: la telecamera va su ogni colpo dal lato libero, pausa, poi il colpo; rallentatore sui colpi che
  uccidono e sui contrattacchi; scintille, numeri del danno, lampo rosso quando colpiscono te; battito
  del cuore e schermo più scuro quando ti resta una candela; scritta grande per contrattacchi e morti.
- Carte visibili su ogni campione (ventaglio di carte coperte con il numero). Scudo della difesa ad anello.
- Regola corretta dopo le immagini: un colpo non spegne mai più di 2 candele (Lama doppia + Sangue doppio
  arrivava a 4, uccisione istantanea).
- Verifiche: partite --auto e --clic senza errori; immagini di scelta, rivelazione e scontri osservate.

### Shadowkin v007, reference blu notte/oro - 15 ottobre 2026
- Richiesta dell'utente: provare lo stregone come l'illustrazione inviata. File ../Modelli_Fantasy_Condivisi/Codex/01_Shadowkin_v007/Shadowkin_Codex_v007.blend. V006 e originali conservati.
- Nuova veste lunga e mantello blu notte, ricami/glifi dorati, spalle a strati, cappuccio con volto nascosto, maniche e bastone con corona/energia viola statica. Libro in mano, occhi/maschera precedenti conservati nascosti. Tre revisioni visive; render prima/dopo neutri e tavola tecnica osservati, vista con luci cupe separata.
- Blender 5.2.2: riapertura, 151 ossa/cinque azioni, texture/reference incorporate; pesi nuovi max due influenze, zero non pesati. Piccole rotazioni testa/clavicole/mani/bacino verificate nei campioni, frame 1/20/1 stabile. Audit 16 parti: maniche ancora 207/229 coppie intersecanti, cappuccio 110 vertici isolati valutati; altre parti campionate senza auto-intersezioni riportate. Non pronto per animazioni.
- 219.645 triangoli visibili, supera budget di prova 180.000; baking ricami e ottimizzazione necessari. Gonna al bacino e mantello Cloak1..6 da provare su attacchi/camminata. Nessuna simulazione cloth, nuova animazione, export o prova Godot. Consegna/continuita' Claude nella cartella v007; nessun codice di gioco o file Claude modificato. Proposta artistica in attesa del giudizio dell'utente.

## 5. Scenari generati e skill nuove (15/10/2026)
- Richiesta: mentre Codex lavora ai personaggi, io curo scenari e il resto; cercare skill nuove online
  senza doppioni e ricordarle tutte (memoria `catalogo-skill`).
- Skill installate dopo una ricerca fatta da un agente (contenuto controllato, LICENSE e FONTE.md in ogni
  cartella): 3d-essentials, particles-vfx, shader-basics, audio-system, audio-design, game-ui-ux,
  godot-multiplayer, environment-artist, set-dressing. Non installato il plugin GodotPrompter (aggiunge un
  hook e modifica le istruzioni).
- `scripts/world/scenari.gd`: luoghi costruiti da un seme (skill procedural-gen), diversi a ogni partita.
  Foresta: terreno con rilievi fuori dal cerchio (shader `terra`: terra, muschio, foglie, pozzanghere),
  alberi contorti a rami ricorsivi, fila lontana nella nebbia, pietre ritte con rune, funghi luminosi,
  fuochi fatui. Castello: colonne gotiche (alcune crollate con macerie), archi, muro con finestre e raggi
  di luna, trono del Custode, stendardi, torce, ossa. Ogni albero/gruppo è una sola mesh.
- Luce: luna in controluce dietro il Custode (le sagome si staccano dalla nebbia, 3d-essentials: in 4.6 la
  nebbia volumetrica è più chiara, densità abbassata).
- Misure (performance-optimization, prima misurare): foresta 170 FPS di mediana (10% peggiore 163),
  castello 159 (145) a 1600x900. Prove `--scenario=N`, FPS stampati a fine partita con `--foto`.

## 6. Scelta del luogo, audio, scenari con materiali e oggetti veri (16/10/2026)
- Menu: scelta del luogo (A caso, La foresta cupa, Il castello maledetto). Pulsante "Audio" sempre visibile
  (menu e partita): musica, ambiente, effetti, musica accesa/spenta, scossoni e lampi disattivabili
  (accessibilità), salvati in user://opzioni.cfg.
- Asset Poly Haven (CC0, elenco in assets/scenari/FONTI.txt; originali in ../assets_src/polyhaven):
  7 materiali fotografici 2k (foglie del sottobosco, corteccia di pino, roccia muschiosa, mattoni e
  pavimento del castello), 18 oggetti scansionati, cielo notturno HDR (sfondo, luce diffusa, riflessi).
- `tools/blender/scenari_props.py` (skill blender-optimize): import, misura, Decimate solo sopra il budget,
  export GLB. Esempi: radici 225.261 -> 13.999 triangoli, candeliere 212.992 -> 4.259, forziere 103.330 ->
  13.996. Scartati pini e abeti interi (8-17 milioni di poligoni).
- Scenari: materiali proiettati sul mondo (triplanari, niente UV da preparare); foresta con tronchi
  caduti, ceppi, radici, rocce, felci, rami secchi e i resti di un campione che ha perso; castello con
  statue gotiche ai lati del trono, candelieri accesi, forziere, cancello e portone, lampadario, teste di
  leone, mobile gotico.
- Misure: foresta 168 FPS di mediana (10% peggiore 156), castello 166 (143). Immagini osservate.
- Ancora da migliorare: alberi costruiti a mano (ancora semplici), finestre del castello.

### Shadowkin v008, prese e braccia libere - 16 ottobre 2026
- Richieste: correggere mano del bastone, abbassare mano sinistra/libro, evitare braccia che attraversano il mantello. File ../Modelli_Fantasy_Condivisi/Codex/01_Shadowkin_v008/Shadowkin_Codex_v008.blend; v007 conservata.
- Nuova presa destra e libro verticale al fianco; corretta mano sinistra specchiata, nuova posa statica (151 ossa/sei azioni). Maniche ricostruite, vecchie fasciature/fibbie archiviate; mantello aperto dietro le braccia con margine costruttivo 25 mm, correttivo locale delle prese.
- Tre revisioni visive, render reali e tavola tecnica osservati. Riapertura Blender 5.2.2: nuovi pesi max due influenze/normalizzati, zero non pesati; zero attraversamenti maniche/mantello nella posa e +/-6 gradi avambracci, zero vertici nei collider semplificati libro/asta. Agganci e frame stabili.
- Maniche senza auto-intersezioni rilevate; mantello ancora 188 coppie (25 senza Solidify), da pulire. 224.949 triangoli visibili: ottimizzazione/baking necessari. Nessun attacco, camminata, cloth sim, export o test Godot. Consegna e continuita' Claude nella cartella v008. Nessun codice di gioco o file Claude modificato.

### Shadowkin v009 — ritorno a v007 e sole mani, 16 ottobre 2026
- Su richiesta utente scartata la direzione v008: nuova copia Codex/01_Shadowkin_v009/Shadowkin_Codex_v009.blend derivata da v007. V007/v008 conservate.
- Entrambe le mani orientate verso il basso, libro verticale; asta verticale. Polsi/dita e correttivo locale; nessuna modifica a tunica, mantello o maniche (superfici confrontate: 0 m).
- File riaperto, frame 1/20/1 stabile, render osservati. Rimangono compenetrazioni nelle dita (audit: R 800, L 196 coppie), soprattutto presa del bastone: non dichiarata completamente rifinita. Tre revisioni visive, arresto senza ulteriori interventi. Nessuna esportazione/prova Godot.


### Shadowkin v010 — presa sul bastone, 16 ottobre 2026
- Richiesta: correggere solo la mano sul bastone. Base v009, file Codex/01_Shadowkin_v010/Shadowkin_Codex_v010.blend. Dita curve attorno all'asta, pollice opposto verso basso, raccordo del polso e superficie locale ripulita; vecchia mano archiviata nascosta. Abito e mano del libro conservati.
- File riaperto e render osservati. Nuova mano: zero auto-intersezioni/non manifold/vertici isolati/facce nulle; zero vertici nel cilindro di contatto (27,9 mm). Frame 1/20/1 stabile; mano e bastone seguono il polso a 6 gradi (errore < 0,000001 m). 8.256 triangoli mano, 225.355 totali visibili.
- Limite esplicito: nuova presa chiusa rigida all'osso Hand; le dita non si aprono singolarmente. Rig originale/pezzo precedente conservati. Nessun export/test Godot, altri problemi v009 non affrontati. Consegna, attribuzione, script e report nella cartella v010.

## 7. Esplora i luoghi, foresta vera, falò (16/10/2026)
- Richiesta: concentrarsi sugli scenari, senza personaggi. Menu: "Esplora i luoghi" (solo scenario, cerchio
  e falò; trascina per girare, rotella per la distanza, gira da sola; "Altro luogo", "Nuova disposizione").
  Prove: `--esplora=N --foto=CARTELLA` (6 inquadrature, poi esce). Il menu non mostra più i campioni.
- Foresta: vegetazione di dasy444 (Sketchfab, CC BY; l'utente ha scaricato il pacchetto FBX, sorgenti in
  ../assets_src/sketchfab/foresta_notte). `tools/blender/foresta_vegetazione.py` estrae i 9 modelli campione
  (pini, albero a foglie, cespugli, arbusti, erba) a grandezza reale. Nel gioco: 206 alberi e ~280 piante di
  sottobosco con MultiMesh, foglie "a forbice", dissolvenza vicino alla telecamera (niente cespugli davanti
  all'obiettivo). Tolti i tronchi finti, le pietre ritte e i funghi; massi veri attorno al cerchio.
  Oggetti appoggiati al punto più basso del terreno sotto di loro (niente più pietre sospese).
  Dubbio di licenza annotato in assets/scenari/FONTI.txt (texture forse prese da internet).
- Altare: basamento a gradini nella pietra del luogo, braciere di pietra scansionato (Poly Haven), fuoco a
  lingue di fiamma (sprite a goccia disegnato nel codice), scintille e fumo.
- `tools/blender/ispeziona_scenario.py`: elenco pezzi, triangoli, materiali e anteprime di un modello.
- Castello: ancora aperto dietro le colonne (pavimento fino all'orizzonte): da chiudere.

### Shadowkin v011 — correzione del verso della mano, 16 ottobre 2026
- L'utente ha respinto la presa v010: dita rivolte a sinistra in modo innaturale; richiesta esplicita di presa rivolta verso destra. Corretti orientamento del palmo e curvatura delle dita, indice/pollice alti e mignolo basso. Asta traslata di 74 mm verso il corpo per il contatto corretto mantenendo la sede del polso. Abito e mano del libro conservati.
- File Codex/01_Shadowkin_v011/Shadowkin_Codex_v011.blend. Verificato riaprendo: mano senza auto-intersezioni/non manifold/facce nulle; zero vertici nel cilindro di contatto. Frame seek stabile, polso 6 gradi con mano/asta/cristallo solidali. Render osservati; 8.050 triangoli mano, 225.149 intero personaggio.
- Presa ancora chiusa rigida al polso, apertura indipendente delle dita non implementata. Nessun export/Godot. Consegna e script nella cartella v011; versioni precedenti conservate.

## 8. Via il castello e il Custode provvisorio; cimitero dimenticato (16/10/2026)
- L'utente: il castello non piaceva, la statua del Custode era fatta male. Tolti entrambi (il codice del
  castello resta nella storia di git). Il Custode tornerà con un modello all'altezza.
- Lapidi realistiche gratuite con licenza commerciale non trovate (le scansioni belle sono "non
  commerciali"), quindi `Scenari._cemetery` costruisce il cimitero: lapidi, croci, obelischi, lastre e croci
  celtiche in pietra muschiosa fotografica a file irregolari e inclinate, mausoleo con il cancello di ferro
  scansionato, recinzione di ferro, pini veri, erba, tronchi, candele accese sulle tombe, fuochi fatui.
- Personaggi proposti dall'utente (Sketchfab): analizzati e passati a Codex; nessuno ha lo scheletro, quattro
  (Pigcraft) hanno ~500.000 vertici esatti (probabile IA), il drago demoniaco non indica la licenza.

## Pulizia delle versioni — 16 ottobre 2026
Su richiesta esplicita dell'utente, le cartelle Codex/01_Shadowkin_v001 fino a Codex/01_Shadowkin_v010 sono state spostate nel Cestino di Windows. Conservata v011 approvata, verificata con SHA256 invariato. Originali scaricati e cartella Claude non toccati.
Il file v011.blend contiene il modello corrente ed e' indipendente dalle vecchie cartelle per apertura e modifica. revisiona_v011.py e' uno script storico di ricostruzione che richiede la base v009: per rieseguirlo occorre ripristinare v009 dal Cestino. verifica_finale.py controlla invece direttamente il modello v011 conservato. Elenco dei percorsi rimossi in VERSIONI_RIMOSSE.json.

## 9. Palude, lago ghiacciato, pioggia e fulmini (16/10/2026)
- L'utente ha scelto palude e lago ghiacciato come altri luoghi, e pioggia con fulmini nel cimitero.
- Poly Haven (CC0): neve, assi consumate, fango con foglie, legno muschioso; lanterna di legno, fianco di
  montagna (153.472 -> 24.000 triangoli), parete di roccia, tronco morto.
- Shader nuovi: `acqua` (nera, liscia, increspature lente, chiazze galleggianti, bordi chiari a radenza) e
  `ghiaccio` (spessori, crepe storte solo in alcune zone, neve portata dal vento). Riflessi dello schermo
  (SSR) accesi su cimitero, palude e lago.
- Palude: isola di fango allo stesso livello del cerchio, acqua attorno, isolotti, alberi morti, tronchi,
  canne, pontile marcio con assi mancanti e tre lanterne accese, nebbia verdastra fitta, fuochi fatui.
- Lago: cerchio sul ghiaccio, rive di neve, montagne innevate, pareti di roccia, pini, tronchi spogli, massi
  con un velo di neve sulle facce in alto, neve che cade.
- Cimitero: pioggia (5.000 gocce), terreno bagnato e lucido, fulmini a una o due scariche con il tuono che
  arriva in ritardo secondo la distanza.
- Corretti dopo le immagini: crepe del ghiaccio a esagoni, acqua invisibile, alberi della palude troppo
  chiari, isola che copriva il cerchio.

## 10. Tempo atmosferico e palude piena (16/10/2026)
- Richiesta: pioggia e tuoni del cimitero più belli, palude meno vuota, un tempo diverso per luogo.
- `tools/make_meteo_audio.py` (solo numpy): pioggia in loop stereo (fruscio, gocce vicine, rombo d'acqua),
  tre tuoni (vicino con schiocco, medio, lontano solo brontolio, con riverbero), vento in loop.
- Pioggia rifatta: 9.000 gocce sottili sfumate di lunghezze diverse, cerchi d'acqua sul terreno, rumore in
  loop; il tuono scelto secondo la distanza del fulmine (ritardo e volume).
- Lago: nevicata più fitta con folate che cambiano direzione, vento in sottofondo.
- Palude: altri 16 alberi morti vicini e piegati, ceppi e tronchi che affiorano, radici, rami, felci,
  cespugli sulle rive, ninfee a gruppi, banchi di nebbia che scivolano e cambiano densità.
- Provato e tolto: muschio pendente dai rami (strisce scollegate dai rami, sembravano rettangoli neri).
- Non verificato: l'ascolto dei suoni (non posso sentirli); controllati solo durata e generazione.

### Nuovi modelli e Crimson Strega del sangue v001 — 16 ottobre 2026
- Scaricati dal formato originale Sketchfab, estratti e verificati cinque modelli CC BY 4.0: 09_Creeping_Shadow_Creature, 10_Dark_Nature_Hybrid_Warrior, 11_Cosmic_Phantom, 12_Faceless_Shadow_Assassin, 13_Crimson_Silk_Empress. Originali con attribuzioni/hash nella cartella condivisa Originali, catalogo aggiornato. Drago Giant Evil Demon non scaricato: nessun download gratuito/licenza libera sulla scheda attuale.
- Crimson trasformata in prima proposta statica Strega del sangue: Codex/13_Crimson_v001/Crimson_Strega_del_Sangue_Codex_v001.blend. Tessuti cremisi, base scura, aureola rituale, sigilli e magia rossa statica. Vincolo utente rispettato: scollatura e seno originali; intera geometria originale identica (0 m di spostamento).
- File riaperto, texture incorporate, render prima/dopo e matcap/wire osservati. Originale unico mesh con basamento, senza scheletro o azioni; 734.158 triangoli modificato. Audit originale auto-intersezioni saltato per densita'; quattro ornamenti campionati senza problemi rilevati. Non ancora pronto per animazioni d'attacco: separazione/retopologia/rig e baking necessari. Nessun export/prova Godot, nessun codice di gioco/file Claude modificato.
- Consegna, limiti, attribuzione, script e continuita' Claude nella cartella v001. Texture dei drappi ancora con riflessi chiari dipinti originali; aureola/ornamenti da ricontrollare al cambio posa. Tre revisioni visive, proposta in attesa del giudizio dell'utente.

## 11. Orizzonti chiusi, fuoco nuovo, schermata iniziale (16/10/2026)
- Orizzonte: colline lontane (`Scenari._hills`, oltre i 20 m il terreno sale fino a ~11 m) coperte da 420
  pini senza ombre (`_far_forest`), terreni da 150 m, foschia di profondità del colore della notte (22-75 m,
  anche sul cielo): non si vede più dove finisce il mondo (foresta, cimitero, palude; il lago era già chiuso).
- Fuoco: shader `fuoco` (piani rivolti alla telecamera, rumore che sale, forma a goccia deformata, lingue,
  dal giallo al rosso) al posto delle macchie di particelle.
- Menu rifatto: titolo grande che tremola, schede dei campioni a sinistra (striscia del colore, abilità,
  descrizione) e dei luoghi a destra, scheda scelta con bordo d'oro, GIOCA grande che respira, braci che
  salgono, bordi sfumati, entrata animata, telecamera dentro la radura che gira attorno al falò.
- Prove: `--solo-menu` (foto del menu senza partite). L'utente non vuole vedere partite mentre valuta gli
  scenari.

## 12. Falò vero, altare alto, cerchio rituale, sfondo del menu (16/10/2026)
- Falò: sei ceppi carbonizzati incrociati e letto di braci (shader `brace`: crepe sottili che pulsano),
  14 fiammelle (shader `fuoco` rifatto: giallo solo alla base, arancio, punte rosse che svaniscono).
- Altare (`Arena._altar`, piano a `ALTAR_TOP` = 1,06 m): tre gradini con bordo, zoccolo, colonna a otto
  facce con colonnine agli spigoli, riquadri incassati con rune che brillano, cornice, braciere sopra.
  Spostati di conseguenza: punto delle fiamme raccolte (`altar_pos`), fiammelle e scritta dell'altare.
- Cerchio (shader `cerchio` su un piano): doppio anello, 36 rune diverse, anello interno, stella a otto
  punte con borchie, solchi consumati, luce che scorre; quattro luci rosse basse senza riflessi lucidi.
- Menu: cliccare un luogo cambia lo sfondo con una dissolvenza (velo `Hud.fade` sotto l'interfaccia);
  "A caso" ne mostra uno diverso dal precedente. Pulsante rinominato "Audio e schermo".

## 13. Cripta al posto della palude, lago rifinito (16/10/2026)
- Decisione dell'utente: tenere il lago con oggetti dedicati, sostituire la palude con un luogo al chiuso.
- `tools/scarica_polyhaven.py`: scarica modelli e texture CC0 da Poly Haven in assets_src e aggiorna FONTI.
  Nuovi: dutch_ship_medium, rock_face_02, coastal_cliff_04, antique_ceramic_vase_01, marble_bust_01,
  brass_goblets, kite_shield; texture monastery_stone_floor, old_stone_wall, rock_wall_08, dark_rock.
  Scartati: fir_tree_01 (7 milioni di triangoli), stone_01 e rock_09 (sassolini di pochi cm),
  decorative_book_set_01 (nessun glTF).
- Cripta (`Scenari._crypt`, luogo 2): sala a 16 lati (raggio 8,6 m), volta di rotazione aperta al centro
  (raggio di luna), 8 colonne con costoloni e torce (fiamma "fuoco" + luce che trema, ombre a una su due),
  campate: portone con scudi e testa di leone, cancello sul buio con barlume rosso, due sarcofagi
  costruiti con candelabri e forziere, due statue su piedistallo, due pareti di loculi; macerie, colonna
  rotta, radici dalla volta, foschia, suono "cripta" (gocce e brusio). Niente luna diretta, poca luce
  dal cielo; la telecamera libera resta dentro i muri (`Arena.orbit_max` = 7,4).
- Lago: nave olandese inclinata nel ghiaccio vicino alla riva (scala 0,62), scogliere innevate, rocce,
  alberi morti innevati, creste di lastre di ghiaccio con neve; montagne più chiare e foschia più lontana.
- Prove: `--vista=gradi,distanza,inclinazione` (una foto da un punto preciso, con `--esplora=N`), FPS
  stampati a ogni veduta. Cripta 73-174 FPS, lago 64-134 (1920x1080).
- Errori trovati guardando le foto: nave girata verso il cerchio (il modello è lungo sull'asse X), poi
  sepolta oltre la riva; creste come lastre di vetro; cancello invisibile (ferro nero su fondo nero).


### Crimson v002 — personaggio in piedi (17 ottobre 2026, Codex)
- Richiesta dell'utente: trasformare Crimson in personaggio in piedi per il gioco, conservando scollatura e proporzioni del seno. Sorgente seduta e v001 conservate.
- Consegna: Modelli_Fantasy_Condivisi/Codex/13_Crimson_v002. Blender modificabile con texture incorporate; GLB con rig di 56 ossa e Idle/Cast/Hit; confronto prima/dopo, GIF reale, attribuzione e continuita' Claude.
- Ricostruiti tronco, arti, mani con dita e costume; 62.543 triangoli, altezza 1,778 m. Riduzione del busto per decimazione/baking, non retopologia manuale completa. Pesi normalizzati, max quattro influenze, nessun vertice esportato privo di pesi. Provate le tre clip e il movimento indipendente di un dito.
- Audit campionato delle parti nuove senza auto-intersezioni rilevate; cucitura del corsetto saldata. Restano cinque coppie rilevate nel corpo derivato dalla sorgente, raccordi artistici del costume e capelli da rifinire. Niente rig facciale, camminata/corsa, LOD o cloth simulato. Nessuna certificazione globale dei contatti fra parti.
- Prova separata Godot 4.6: import/materiali/orientamento verificati anche con cattura reale del renderer Compatibility; 56 ossa, tre clip, appoggio/collisione, un solo rilascio magia e ritorno a Idle verificati. Mano Cast 22,4 cm, piede fermo. La preview contiene sfera dimostrativa, non danno/regole del gioco. Nessuna integrazione nella partita GamePC, nessuna modifica a codice o copie Claude.
- Per provare: Avvia_Prova_Crimson.cmd oppure Prova_Godot/project.godot; Spazio magia, H colpo, I attesa. Il passaggio di consegne non avvia Claude automaticamente.


### Crimson v003 — gambe snelle, abito nero/cremisi e tacchi (17 ottobre 2026, Codex)
- Su richiesta dell'utente: sezioni visibili delle gambe ridotte del 22% in larghezza/18% in profondita', vecchi stivali gonfi sostituiti con gambali aderenti e calzature granato col tacco di circa 8 cm. Modellati punta, avampiede, collo, arco, suola e tallone; caviglia del rig adattata. Palette nera con pannelli cremisi coordinati al reggiseno. Non sono piedi nudi o dita scoperte.
- Consegna in Codex/13_Crimson_v003: .blend, GLB, anteprime e confronto con v002, GIF, attribuzione, rapporto e continuita' Claude. V002 conservata. Geometria di testa/busto/seno/scollatura identica a v002, hash delle coordinate confrontato.
- Blender riaperto: 65.103 triangoli, 56 ossa, pesi normalizzati, Idle/Cast/Hit e movimento dita/piede verificati. Audit dei campioni delle nuove calzature senza auto-intersezioni rilevate; restano cinque nella parte originale del corpo, non modificata. Raccordi e limiti del prototipo documentati; niente camminata sui tacchi verificata, facciale, LOD o cloth.
- Godot 4.6 in progetto separato: import, materiali/orientamento osservati con cattura reale, capsule/appoggio, tre clip, unico rilascio magia e ritorno a Idle passati. Nessuna modifica al codice GamePC o alle copie di Claude. Per provare usare Avvia_Prova_Crimson.cmd nella nuova cartella.


## 14. Licenze, vegetazione CC0, cripta, suono della foresta, altare (17/10/2026)
- Richiesta: tutto deve poter essere venduto, con i nomi degli autori dove serve. Controllo di ogni cosa
  che entra nel gioco: Poly Haven CC0 (licenza riletta: uso commerciale libero, citazione non obbligatoria);
  caratteri Cinzel, Cinzel Decorative, IM FELL (OFL 1.1, mancava il testo per Cinzel Decorative: aggiunto);
  suoni e musica generati da noi; funzioni di rumore negli shader di David Hoskins e Inigo Quilez (MIT);
  Godot (MIT, con le librerie che usa).
- Vegetazione di dasy444 tolta dal gioco: la corteccia è una foto con nome da download e alcune foglie
  vengono da un sito di ritagli; l'autore non poteva dare in licenza quello che non era suo. Rifatta solo
  da Poly Haven: `tools/blender/vegetazione_carte.py` fotografa l'abete giovane fir_sapling dall'alto e di
  fianco (immagini con trasparenza), `tools/blender/vegetazione_alberi.py` costruisce pino alto, medio,
  basso (tronco con la corteccia di pine_sapling_small, palchi di aghi spioventi, monconi secchi; 740-1.090
  triangoli) e il pino lontano (tre piani incrociati), più cespugli shrub_02/03, ortiche e due erbe (la
  trasparenza delle foglie, che Poly Haven dà a parte, viene messa dentro l'immagine). Cartella
  `assets/scenari/vegetazione_cc0`; quella vecchia è esclusa dall'esportazione (va nel Cestino col sì).
- Riconoscimenti: `CREDITI.txt` (dentro il gioco) e pulsante "Riconoscimenti" nel menu; `tools/licenze.gd`
  scrive accanto al gioco esportato la cartella LICENZE (crediti, licenza di Godot e delle sue librerie,
  caratteri, shader). Prova: `--solo-menu --crediti`.
- Cripta: lo schermo nero veniva dalla telecamera libera che, alzata, usciva dall'apertura della volta, e in
  basso entrava nei sarcofagi. `Arena._crypt_reach` la tiene sempre sotto la volta e lontana dai muri;
  32 vedute di prova, nessuna più nera (al massimo 3,5% di punti scuri). Aggiunto il raggio di luna
  dall'apertura (luce fredda e cono di pulviscolo; la foschia sul cono era raddoppiata: `fog_disabled`).
- Foresta: suono proprio (`audio/foresta.wav`: vento fra i pini, grilli, gufo, tronchi che scricchiolano) e
  musica horror (`audio/musica_foresta.wav`: carillon stonato in re minore su un tappeto grave e
  dissonante, tamburo lontano), da `tools/make_foresta_audio.py`. `Sfx.place_music` cambia la musica
  secondo il luogo. Livelli misurati (fondo -18 dB, eventi 2-3 dB sopra); l'ascolto vero resta all'utente.
- Altare (rune tenute): gradini dal bordo arrotondato, zoccolo modanato, colonnine tortili, capitello con
  dentelli, catene di ferro fra le colonnine, colature di cera; le rune pulsano e rischiarano di rosso la
  pietra attorno. `Arena._oct_lathe`: tornio a otto facce piane e profilo morbido.
- Verifiche: partite --auto nei quattro luoghi dal gioco esportato senza errori; foto di tutti i luoghi;
  FPS 1920x1080: foresta 70-137, cimitero 67-124, cripta 88-167, lago 41 alla prima veduta poi 63-127.
  Nel pacchetto esportato non ci sono immagini o modelli di dasy444 (restano solo i nomi nell'elenco interno
  dei file finché la cartella vecchia è nel progetto).


### Crimson v004 — corsetto, rete e sandali aperti (17 ottobre 2026, Codex)
- Su richiesta dell'utente, osservati Dark elf priestess e Dark Elf Spellblade in Obsidian Armor come riferimenti di silhouette/costume; nessun loro asset scaricato/incorporato. Preservati viso, seno e scollatura: geometria del corpo conservato identica a v003, hash confrontato.
- Sandali aperti senza stivali, piedi naturali con cinque dita e unghie per lato; rete geometrica su gambe complete, bustino costruito sul tronco con distanza media 2,66 mm/max 4,27 mm, braccia ridotte radialmente del 28%, guanti assottigliati. Tre drappi aperti, nero/cremisi. Rimossi Focus_magico e vecchia sfera dimostrativa della preview. Rimossa superficie interna del bacino che attraversava il costume.
- File in Codex/13_Crimson_v004: .blend, GLB, confronto, dettagli piedi/vita, GIF, attribuzione, verifiche e continuita' Claude. Versioni precedenti conservate.
- Blender: 118.117 triangoli, 56 ossa, pesi e Idle/Cast/Hit verificati, dita/piede campionati, GLB reimportato, render e matcap/wire osservati. Residui documentati: cinque coppie di auto-intersezioni nel corpo sorgente, sedici rilevate nel piede destro; raccordi spalle/schiena. Piede sinistro senza audit completo separato. Non e' una rifinitura artistica definitiva; niente locomozione/cloth/LOD e rete piu' pesante da ottimizzare.
- Godot 4.6 in progetto separato Compatibility: import/materiali/orientamento osservati in cattura reale, collisione/appoggio, tre clip, singolo segnale magia e ritorno a Idle passati. Nessuna misura prestazioni della partita con quattro copie, nessuna modifica a codice GamePC o copie Claude.


## 15. Pulizie, lupi, altare sospeso, qualità grafica (17/10/2026)
- Pulizie (sì dell'utente): nel Cestino la vecchia vegetazione dasy444 e il suo originale, 5 texture e 3
  modelli mai usati, 2 scaricamenti di prova. Gioco esportato da 487 a 390 MB, nessuna traccia di dasy444.
- Foresta: ululati di lupo sintetizzati (`howl`, `pack` in `tools/make_foresta_audio.py`: voce che sale,
  trema e scende, con fiato; un lupo solo e un branco di tre, lontani con molta eco). Suono lungo 42 s;
  gli ululati 5 dB sopra il fondo del bosco.
- Altare sospeso (richiesta dell'utente): `Arena._altar_root` (altare, fuoco, fiamme raccolte, scritta)
  galleggia a `ALTAR_LIFT` = 0,5 m e ondeggia appena (`_altar_float`); sotto, un blocco di roccia strappato
  dal suolo con radici; quattro catene grosse (MultiMesh, ricalcolate a ogni fotogramma, più tese quando
  l'altare sale) dagli spigoli alti a pali di ferro piantati a terra fra i posti dei campioni; bagliore
  rosso sotto. Tolte le catenelle decorative sulle facce.
- Qualità grafica: `scripts/ui/grafica.gd`, scelta Media/Alta/Ultra nel pannello "Audio e schermo"
  (salvata in user://grafica.cfg, partenza Alta). Alta: luce che rimbalza (SSIL), ombre morbide che
  sfumano con la distanza, filtro delle texture 16x, MSAA 4x, più dettaglio lontano, nebbia più fine,
  bagliore più morbido. Prova: `--grafica=0/1/2`. FPS a 1920x1080 (misure a ogni veduta): Media 51-177,
  Alta 32-125 (di solito 55-90), Ultra 29-89. La differenza Media/Alta è visibile ma leggera.
- Verifiche: export, quattro partite --auto e una --clic dal gioco esportato senza errori; foto osservate.


### Crimson v005 — anatomia continua e viste del retro (17 ottobre 2026, Codex)
- Dopo il rifiuto della v004, sostituiti arti per sezioni e piedi procedurali con una base anatomica adulta MakeHuman CC0 gia' presente nel progetto (dati MPFB2 e licenza inclusi). Tronco, bacino, gambe, piedi, braccia e mani nella stessa superficie: 9.260 vertici, una sola componente connessa, regioni del rig verificate.
- Rest pose e pesi adattati; corsetto/guanti/fasce ricavati dal corpo, rete aderente, sandali aperti intorno al piede anatomico, spallacci angolari piccoli e drappi cremisi. Volto e seno preservati: 8.466 coordinate nella regione protetta identiche a v004. Rimosse vecchie superfici posteriori sovrapposte e alcuni lembi inferiori dei capelli; non dichiarare capelli/schiena immutati.
- Consegnati in Codex/13_Crimson_v005 .blend, GLB, render di fronte/retro dritto/retro tre quarti/piedi/dettagli, confronto con v004, GIF Cast, tavola matcap/wire, dati CC0, attribuzione, rapporti e continuita' Claude. Originali e checkpoint precedenti conservati.
- Blender 5.2.2: 88.979 triangoli valutati, 56 ossa, pesi normalizzati <=4, Idle/Cast/Hit con piedi fermi e ritorno alla posa, movimento indipendente dito mano e avampiede, GLB reimportato. Raccordo collo non definitivo; audit con residui corpo 22, sorgente 1, guanto destro 29 e fasce sandalo 30 per lato. Niente dichiarazione globale di topologia pulita.
- Godot 4.6 Compatibility, prova separata: import, cattura reale del renderer, scheletro/clip, appoggio, mano Cast circa 29,6 cm, piedi fermi, unico segnale magia e ritorno Idle passati. Nell'ambiente ristretto il renderer avvisa che non puo' scrivere la cache shader; cattura e verifiche completate. Niente camminata/corsa, facciale, cloth, LOD o benchmark con quattro copie. Nessuna integrazione nel gioco e nessuna modifica alle copie Claude. Il checkpoint non avvia Claude automaticamente.


### Crimson v006 — pancia scoperta e costume cremisi (17 ottobre 2026, Codex)
- Alessandro conferma le forme della v005 e chiede pancia scoperta, costume anziche' pantaloncino e abiti coordinati. Tolti corsetto/lacci e materiale shorts; slip sgambato cremisi ricavato dal corpo, cuciture scure, cintura bassa con fibbia, drappo anteriore piu' corto/stretto, bordi guanti e calze coordinati. Fasce calze ricostruite dalla superficie delle rispettive cosce, eliminando lembi che attraversavano la pelle.
- Tutte le coordinate di corpo anatomico e parte originale testa/seno identiche a v005 (hash confrontati); rig e rest pose invariati. Corpo 9.260 vertici, componente unica. Slip a distanza media 2,13 mm/max 2,20 mm dalla pelle in riposo. Pancia scoperta verificata da tre raggi frontali.
- In Codex/13_Crimson_v006: blend, GLB, fronte/retro/costume/Cast, confronto v005, GIF, matcap/wire, rapporti, licenza e checkpoint Claude. V005 e originali preservati. 85.043 triangoli, altezza 1,78 m, 56 ossa, pesi <=4 normalizzati; Idle/Cast/Hit, dita e avampiede, GLB reimportati e verificati.
- Audit residui: corpo 22, sorgente 1, slip 4, guanto destro 29, fasce sandalo 30 per lato. Cintura, entrambe fasce calze, suole/tacchi e spallaccio campionati senza auto-intersezioni rilevate. Restano raccordo collo, materiali uniformi e rifiniture; niente topologia globalmente certificata, facciale, camminata/corsa, cloth, LOD o benchmark.
- Prova separata Godot 4.6 Compatibility: import/materiali osservati in cattura reale, scheletro/clip, appoggio, mano Cast circa 29,6 cm, piedi fermi, segnale magia unico e ritorno Idle passati. Avviso cache shader non scrivibile nell'ambiente ristretto, cattura completata. Nessuna integrazione nel gioco o modifica delle copie Claude. Il checkpoint non avvia Claude automaticamente.


### Crimson v007 — foto originali, gambe nude e dettagli (17 ottobre 2026, Codex)
- Su richiesta di Alessandro e dalle sue due foto del modello originale: cosce alte piu' piene, parte bassa delle gambe affusolata, glutei arrotondati; proporzioni interpretate in piedi da viste sedute, non misurazione esatta. L'utente sceglie esplicitamente gambe nude: tolte rete e fasce larghe.
- Ombelico scolpito nell'addome (incavo misurato 5,715 mm), slip triangolare con collegamenti sottili (tessuto da 0,097638 a 0,027212 m2, -72,13%), fascia cremisi del reggiseno sul dorso, fascia oro antico sottile e decorata sulla coscia destra. Tolti cintura/fibbia e drappo davanti. Drappi posteriori raccordati ai fianchi. Testa/viso/seno: tutte le coordinate della parte sorgente identiche alla v006; anatomia inferiore modificata.
- Consegnati in Codex/13_Crimson_v007 blend, GLB, fronte/profilo/retro, dettagli ombelico-costume-dorso, confronto v006, GIF, matcap/wire, foto di riferimento, rapporti, licenze e continuita' Claude. V006 e precedenti conservate. 64.543 triangoli, altezza 1,78 m, corpo unico da 9.720 vertici, 56 ossa, pesi <=4 normalizzati, Idle/Cast/Hit e dita/avampiede verificati, GLB reimportato.
- Corrette le nuove compenetrazioni interne delle cosce emerse durante la revisione. Audit finale corpo 22 (14 arti inferiori, 8 torso superiore; nessuna coppia rilevata in bacino/cosce/ombelico), sorgente 1, slip 3, guanto destro 29, fasce sandalo 30 per lato. Fascia dorso e base fascia coscia senza auto-intersezioni rilevate. Niente dichiarazione globale di topologia perfetta; raccordo collo, pelle e bordi da rifinire. Niente facciale, camminata/corsa, cloth, LOD o benchmark.
- Godot 4.6 Compatibility separato: import/materiali osservati in cattura reale, scheletro/clip, appoggio, movimento mano Cast circa 29,6 cm, piedi fermi, unico segnale magia e ritorno Idle passati. Avviso cache shader non scrivibile nell'ambiente ristretto, prova e cattura completate. Nessuna integrazione nel gioco o modifica alle copie Claude. Checkpoint non avvia Claude automaticamente.


## 16. Fuoco in volume, cerchio di brace, Custode (17/10/2026)
- L'utente: corvi finti, grafica "da gioco economico", fuoco rimasto indietro, foglie sospese.
- Fuoco: `shaders/fuoco_volume.gdshader` (si percorre il raggio di vista dentro una scatola e si somma la
  luce di una fiamma di rumore che sale; colore dalla temperatura; si ferma sugli oggetti davanti), faville
  che salgono, aria che trema (`shaders/calore.gdshader`). Le vecchie fiammelle piatte sono tolte.
- Cerchio: brace rosso cupo con punti caldi che scorrono, terra bruciata attorno ai solchi, crepe; un primo
  tentativo era troppo dorato, scurito.
- Foglie: cadevano meno del freno dell'aria (gravità 0,35 contro freno 0,4-0,8): ora cadono; spariscono
  vicino alla telecamera. Corvi visibili tolti (forme semplici, sembravano finti); restano i versi.
- Mattoni dell'altare: verificato con una telecamera che segue l'altare (--segui-altare): con la pietra
  attaccata all'altare la differenza fra foto è uguale all'altare fermo (0,09-0,17 contro 0,35-0,45).
- Custode: modello in Blender di un aiutante (assets_src/custode, 29.257 triangoli, stoffe CC0 caban e
  hessian_230), dietro il cerchio, fluttua; gli occhi sono il materiale che si accende quando parla.
- Musiche e suoni di cimitero, cripta e lago (tools/make_luoghi_audio.py, di un aiutante), collegati.


### Crimson v008 — copertura del costume, forme e fascia sottile (17 ottobre 2026, Codex)
- V007 rifiutata dall utente per forme insufficienti, esposizione della zona intima e fascia dorso troppo larga. Nuovo pannello opaco continuo davanti-sotto-dietro e collegamenti sottili ai fianchi. Zona anatomica nascosta levigata (131 vertici) e 24 facce eliminate solo dove la copertura include centri e vertici, preservando pelle delle cosce/glutei. Non ripristinare il costume v007.
- Fianchi campionati da 38,26 a 46,23 cm (circa +21%); estensione posteriore Y da 8,03 a 13,74 cm (+5,72 cm). Fascia reggiseno da 2,83 a 0,98 cm (circa -65%). Testa/viso/seno: coordinate della parte sorgente identiche a v007, hash confrontato; anatomia inferiore modificata. Gambe nude, ombelico, fascia coscia e sandali mantenuti.
- In Codex/13_Crimson_v008: blend, GLB, fonte/attribuzione/licenze, fronte/lato/retro/dettagli, viste basse vestite, GIF, confronto con v007, matcap/wire, rapporti e checkpoint Claude. Originali e versioni precedenti conservati. 89.423 triangoli, altezza 1,78 m, corpo connesso da 9.707 vertici, 56 ossa, pesi <=4 normalizzati, Idle/Cast/Hit e dita/avampiede verificati; GLB reimportato.
- Copertura: 120 campioni per 11 pose (1.320 raggi), zero mancanti; materiale nel GLB confermato OPAQUE, alpha 1 e doubleSided. Controllate immagini basse davanti/dietro. Verifica limitata alle clip campionate, non a qualsiasi animazione futura o costume rimosso. Aperture intenzionali nel corpo sotto il costume documentate.
- Audit residui: corpo 22, sorgente 1, guanto destro 29, fasce sandalo 30 per lato. Nuovo pannello slip, fascia dorso e fascia coscia base senza auto-intersezioni rilevate. Raccordo collo, drappi e materiali da rifinire; niente facciale, camminata/corsa, cloth, LOD o benchmark quattro copie. Il pannello e piu denso e richiede ottimizzazione per produzione.
- Godot 4.6 Compatibility separato: import/materiali osservati in cattura reale, scheletro/clip, appoggio, mano Cast circa 29,6 cm, piedi fermi, unico segnale magia e ritorno Idle passati. Avviso cache shader non scrivibile nell ambiente ristretto, cattura completata. Nessuna integrazione nel gioco o modifica alle copie Claude. Il checkpoint non avvia Claude automaticamente.



### Crimson v009 - nuova base Gus scelta dall utente (17 ottobre 2026, Codex)
- V008 e precedenti rifiutate artisticamente. Su scelta esplicita di Alessandro scaricato Female body base mesh di gus_thewise, OBJ originale, CC BY 4.0. Originale, SHA-256 e attribuzione conservati; nuova copia Codex/13_Crimson_v009, nessun originale o file Claude sovrascritto.
- Corpo Gus realmente usato (15.229 vertici connessi), raccordo superiore adattato, coordinate preesistenti testa/viso/seno Crimson conservate. Costume opaco aderente, gambe nude, ombelico Gus, fascia coscia, fascia reggiseno sottile, sandali aperti, guanti aderenti e drappi. 66.708 triangoli, rig preliminare 56 ossa, <=4 pesi normalizzati, nessun vertice senza pesi. Escluso il vecchio corpo dal GLB, reimport Blender e import statico Godot 4.6 separato verificati; cattura reale osservata, avviso cache shader non scrivibile ma render completato.
- Proposta per valutazione delle forme, non definitiva: raccordo laterale busto e retro collo/choker, attacchi drappi, materiali e pesi da rifinire. Nessuna clip esportata/certificata, nessuna prova del controller o integrazione nel gioco principale. I test animati e di copertura v008 NON si applicano alla nuova base. Anteprime fronte/profilo/retro osservate; checkpoint Claude aggiornato, non avvio automatico.



### Crimson Gus v010 - corpo originale intatto e file editabile (17 ottobre 2026, Codex)
- Nuova direzione esplicita: rinuncia al vecchio seno Crimson, corpo Gus originale con sola testa Crimson e solo reggiseno/slip. Corpo Gus identico all OBJ per tutte le coordinate float32 e indici facce (15229 vertici, 15208 poligoni), nessun morph, solo trasformazione oggetto scala/assi/posizione. Seno e schiena appartengono alla stessa mesh originale. Testa adattata al corpo, collo ritagliato e ancora editabile.
- Pelle satinata/lucida, costume aderente con fasce alte e retro stretto; nessun guanto, scarpa, drappo, collare o fascia coscia. File .blend pulito con texture incorporate, oggetti separati e modificatori abiti non applicati; APRI_IN_BLENDER.md spiega apertura, import OBJ/GLB e copia di lavoro dell utente. Anteprime fronte/lato/retro e dettaglio osservati; 93 sonde statiche centrali, 0 mancanti.
- GLB statico esportato e reimportato in Blender; import Godot 4.6 Compatibility e cattura reale osservati, 11 mesh senza scheletro (avviso cache shader non scrivibile, render completato). Nessun rig, clip, controller, collisioni o integrazione nel gioco principale; copertura futura in movimento non certificata. Raccordo collo e bordi abiti rifinibili manualmente. Originali e versioni precedenti conservati; copia condivisa Codex/13_Crimson_v010 con fonte Gus e RYStudio CC BY 4.0, istruzioni Claude senza avvio automatico.



## Codex — 18 ottobre 2026: libreria Blender e alternative personaggio

- Rimossi dal catalogo e spostati nel Cestino esclusivamente Dark Knight CC BY-NC e la sua copia nella nuova libreria, su richiesta esplicita dell'utente.
- Creato Desktop/gioco claude/Personaggi_Blender: 14 originali convertiti, 16 versioni disponibili, 9 file originali di animazione Orc; cartelle Originale/Versioni per modello, texture incorporate, attribuzioni e indice. 39 .blend riaperti senza dipendenze mancanti; copia verificata SHA-256.
- Crimson Gus v011: forma superiore seno reversibile tramite shape key (~5,6 mm), coppe abbassate fino a 16 mm, nuova giunzione collo/testa chiusa e testa rialzata 45 mm. Viso preservato sopra la linea della mandibola. 93 sonde statiche centrali dello slip, zero mancate coperture. Base priva di rig/animazioni.
- Nuova alternativa Japan v001 proposta dall'utente: scaricato originale YØD CC BY 4.0; busto e viso originali, intimo rosso, gambe/piedi Gus e sandali aperti con tacco circa 8 cm. Giunzioni cosce chiuse; colore pelle raccordato. Ancora prototipo statico ad alta densita, retopologia e rig non eseguiti. Originali e licenze conservati.
- Report Blender e reimport GLB inclusi; anteprime reali fronte/lato/retro e confronto prima/dopo. Prove Godot separate dove presenti. Nessuna integrazione o modifica del gioco principale.
- Per continuare leggere CONTINUA_CLAUDE.md del checkpoint scelto; non sovrascrivere le versioni Codex. Claude non viene avviato automaticamente.


## Codex — 18 ottobre 2026: Japan v002, scarpe e raccordo gambe

Nuova versione Codex/15_Japan_v002/Japan_Intimo_Rosso_Tacchi_Codex_v002.blend e copia in Personaggi_Blender/15_Japan_Young_Woman/Versioni. v001 e originali conservati.
Fascette regolari da 17 mm, suole ricostruite e tacchi terminati contro la superficie inferiore della suola con 0,25 mm di sovrapposizione interna; ricostruzione locale cosce 0,58–0,78 m e texture pelle incorporate. Giunzione molto attenuata; lieve sfaccettatura ancora visibile in dettaglio. Viso, busto, mani e piedi invariati: 680956 vertici controllati, deviazione massima 0. Nessun bordo aperto nella fascia delle giunzioni.
Riapertura Blender 5.2, reimport GLB e prova visiva separata Godot 4.6 Compatibility. UV delle gambe sul primo canale. La prova Godot Compatibility mostra ancora artefatti di shading sui polpacci e una sottile linea alta coscia: non approvato per integrazione nel motore. Nessuna integrazione nel gioco principale. Modello ancora statico e denso, privo di rig e animazioni.
Anteprime reali fronte/retro, cosce, scarpe e confronto v001/v002. Attribuzioni YOD e gus_thewise incluse. CONTINUA_CLAUDE.md aggiornato, non avvia automaticamente Claude.


## Codex — 18 ottobre 2026: Japan v003, SOLO fasce avampiede

Su richiesta esplicita dell'utente, modificate esclusivamente Fascetta_avampiede_R e Fascetta_avampiede_L: fasce da 14 mm con profilo regolare e attacchi laterali alla suola, arretrate 7 mm. Nessuna modifica a corpo, piedi, suole, tacchi, caviglie, vestiti, materiali o texture. Hash di tutte le altre mesh verificati invariati prima/dopo e dopo riapertura del .blend. GLB reimportato in Blender; foto reale completa e dettagli osservati. Nessuna nuova verifica Godot: restano le limitazioni runtime della v002.
Salvato Codex/15_Japan_v003/Japan_Fascette_Codex_v003.blend e copia in Personaggi_Blender/15_Japan_Young_Woman/Versioni/Codex_Japan_Fascette_Codex_v003.blend. Versioni precedenti e originali conservati. Attribuzioni e checkpoint Claude inclusi; nessun avvio automatico.


## Codex — 18 ottobre 2026: Japan v004, fasce aderenti al piede

Su richiesta dell'utente, abbassate e ricostruite esclusivamente le due fasce avampiede sulla superficie del piede. Eliminato l'arco sollevato della v003; spessore 1 mm verso esterno e attacchi alla suola preservati. Corpo, piedi, suole, tacchi, cinturini caviglia, abiti, materiali e texture invariati. Hash delle altre mesh verificati anche dopo riapertura del file; GLB reimportato in Blender; foto reali completa/dettaglio/lato osservate. Nessuna nuova verifica Godot o modifica dei problemi ereditati dalla v002.
Rilascio: Codex/15_Japan_v004/Japan_Fascette_Aderenti_Codex_v004.blend e copia in Personaggi_Blender/15_Japan_Young_Woman/Versioni/Codex_Japan_Fascette_Aderenti_Codex_v004.blend. Originali e versioni precedenti conservati, attribuzioni YOD e gus_thewise incluse. Checkpoint per Claude senza avvio automatico.


## Codex — 18 ottobre 2026: Japan v005, fasce corrette e accessori dark fantasy

Richiesta utente: correggere la fascia che attraversava il piede vicino alle dita e aggiungere vestiario minimo da gioco mantenendo l'aspetto aperto del costume. Le due fasce ora seguono l'inviluppo convesso esterno del piede, arretrate 6 mm rispetto alla v004, larghezza 12 mm. Verificati i modificatori applicati: 0 coppie di triangoli intersecanti con i piedi, 0 campioni penetranti su 10706 per lato. Distanza minima campionata circa 0,40 mm.
Aggiunti bracciali scuri, collare, cintura sottile con pietra rossa e piccoli lembi laterali nella collezione ABITI_DARK_FANTASY_v005. Corpo, intimo originale, piedi, suole, tacchi, cinturini caviglia e altre mesh preesistenti invariati (hash confrontati dopo riapertura). Texture incluse.
Render reali davanti, dietro, tre quarti e scarpe osservati. GLB reimportato in Blender e importato in Godot 4.6: 35 mesh, 0 ossa, 0 animazioni. Prova runtime separata: persistono gli artefatti delle gambe già presenti nella v002; è un prototipo statico denso, non un personaggio pronto al gameplay. Nessuna modifica al gioco.
Rilascio: Codex/15_Japan_v005/Japan_Dark_Fantasy_Codex_v005.blend e Personaggi_Blender/15_Japan_Young_Woman/Versioni/Codex_Japan_Dark_Fantasy_Codex_v005.blend. Originali e versioni precedenti conservati; attribuzioni YOD e gus_thewise incluse. Handoff in CONTINUA_CLAUDE.md senza avvio automatico di Claude.

## 17. Claude — 18 ottobre 2026: regole riviste, avversari Adattivi, partita più chiara

- Patti del Custode e orrori dei luoghi progettati e provati SOLO nel simulatore (`tests/sim_patti.gd`); tre revisioni
  indipendenti, Codex e ChatGPT: prima va verificato il combattimento base. Report sul Desktop dell'utente.
- Combattimento base: con avversari "furbi" il duello delle regole attuali funziona (4,3 giri, mosse 34/31/35%);
  l'ordine casuale cambia il vincitore nell'1% delle manche. Scartate penalità nel duello e riaccensione a 3.
- Nel gioco: stanchezza giusta (`tests/prova_stanchezza.gd`); avversari Normali/Adattivi (menu > Avversari);
  ordine dei colpi visibile prima di scegliere, a rotazione (`tests/prova_ordine.gd`); carte a parità con bersaglio
  a caso; poi, su richiesta, carte del Custode e Presagi SPENTI (codice conservato), interfaccia all'80% con
  riquadri e pulsanti tondi, niente scheda sopra i campioni, anteprima curata, Visuale a scelta (5 inquadrature,
  tasto V). Confronto difficoltà: `tests/sim_difficolta.gd`.

## 18. Claude — 20 ottobre 2026: scritte rifatte; il duello finale è prevedibile
- L'utente trovava le scritte "primitive e orribili". Causa principale: Cinzel e IM Fell hanno numeri antichi
  (l'1 sembra una I: "−I", "Manche I"). Ora: EB Garamond (OFL, numeri moderni) per testo, intestazioni e numeri;
  Cinzel Decorative solo nei titoli senza cifre ("Fine della prima manche"). Caratteri in un solo posto
  (`Stile.font_*`), prova a vista `tests/prova_caratteri.gd`.
- Ordine dei colpi: targhette colorate in fila (la tua in oro), tolto dal racconto dove era doppio. Racconto
  con righe che sbiadiscono e intestazioni in oro. Nomi e mosse sopra i campioni con alone scuro, mosse colorate
  (rosso attacco, azzurro difesa) e in minuscolo. "−1" netto. "Altare vuoto" non si scrive più sopra il fuoco.
  Tabella in colonne vere. Corretto "ti difendi da il" → "dal".
- Prova dell'utente: nel 1 contro 1 entrambi si difendono, poi sono stanchi e devono attaccare: prevedibile.
  Vuole l'incertezza di Buckshot Roulette. Proposte: ChatGPT (sigilli dichiarati con bluff e accuse, alla Coup /
  Liar's Bar) e Claude ("l'altare carico": sigilli con esito noto in quantità ma non in ordine). Decide l'utente.


## Codex — 20 ottobre 2026: Japan v006, correzione colori e labbra

Richiesta utente: correggere i colori applicati male e aggiungere colore alle labbra. Ricostruite le maschere del costume da quattro viste calibrate con controllo della visibilità delle superfici. Eliminato il vecchio materiale cremisi assegnato a zone di pelle. Colore del tessuto incorporato nell'albedo originale e labbra rosate con sfumatura morbida.
Individuato e corretto un secondo errore ereditato: facce basse del costume assegnate al materiale pelle delle gambe con UV sostituite. Ripristinate UV e materiale della fonte Japan, scegliendo la faccia originale dal centro del triangolo per conservare le cuciture UV. Tutte le mesh e le posizioni sono identiche alla v005; scarpe e accessori conservati.
File riaperto in Blender, texture incorporate, GLB reimportato: 35 mesh senza scheletro/animazioni. Render reali davanti, retro, lati e viso controllati. Prova Godot separata; permane il problema preesistente di ombreggiatura delle gambe nel motore. Nessuna modifica al gioco principale. Il personaggio rimane statico e molto denso.
Rilascio: Codex/15_Japan_v006/Japan_Colori_Corretti_Codex_v006.blend e Personaggi_Blender/15_Japan_Young_Woman/Versioni/Codex_Japan_Colori_Corretti_Codex_v006.blend. Versioni precedenti conservate, indici e attribuzioni aggiornati. CONTINUA_CLAUDE.md documenta il lavoro senza avvio automatico di Claude.

## 19. Claude — 20 ottobre 2026 (sera): Le catene dell'altare, regole e simulatore
- L'utente ha ridisegnato il gioco "alla Saw": 5 catene, candele che accelerano, sabotatore segreto con passaggio
  di testimone, voto solo con la carta Voto, ultimo respiro di 30 secondi, chi ha più catene brucia. Regole in
  `docs/catene_altare.md` (vecchio sistema conservato). Discussione con Codex in `Desktop\ai team` (lettere 1-6).
- Nuovo codice di sole regole: `scripts/catene/catene_rules.gd` (manche, carte anonime, voto, testimone, ultimo
  respiro, punti) e `scripts/catene/catene_bot.gd` (sospetti da eventi pubblici, bugie al voto, passaggi).
  Simulatore `tests/sim_catene.gd` con manopole da riga di comando.
- Errori trovati e corretti nel simulatore: gli innocenti appesantivano chi stava per liberarsi (è il lavoro del
  sabotatore: nessuno si liberava); a parità i bot sceglievano sempre il posto 0 (falsava le strategie).
- Esiti in fondo a `docs/catene_altare.md`. Proposta all'utente: 4 catene, "Togli" ~45% / "Aggiungi" ~13%, voto
  a maggioranza semplice (almeno 2, senza pari), sabotatore 2 punti se si salva (con 3 è troppo forte).

## 20. Claude — 21 ottobre 2026: Le catene dell'altare, regole definitive
- Con l'utente, Codex (chiamato in sola lettura con il suo programma, lettere 8-10 in `Desktop\ai team\POSTA`) e il
  simulatore si sono fissate le regole: mazzo proprio del sabotatore, dono del Guardiano (Togli nascosto ogni 3
  turni), voto a maggioranza dei soli legati, Guardiano a richiesta di 2, carte mescolate, testimone a destinatario
  ignoto, punti 3/2/1/0 e sabotatore 3/1/0, seconda modalità "a eliminazione". Testo in `docs/catene_altare.md`
  (sezione "REGOLE DEFINITIVE"); valori predefiniti in `scripts/catene/catene_rules.gd`.
- Errori del simulatore corretti strada facendo (molti segnalati da Codex): chi passava il testimone sapeva a chi;
  liberazioni controllate solo a fine turno; carte nell'ordine dei posti; il sabotatore già scoperto poteva essere
  "eliminato"; il tavolo che parla sapeva chi era innocente; opzioni mangiate da un errore nei comandi di prova.
- Risultato: sabotatore 1,73 punti a manche, innocente 1,67; ~5 minuti a manche. Prossimo: versione giocabile.
- Versione giocabile (21/10/2026, notte): `scripts/catene/catene_match.gd` gioca la partita nella scena esistente
  (catene dai campioni all'altare, tre carte coperte, tirare sì/no, carta e bersaglio, carte mescolate, voto con
  Guardiano, ultimo respiro di 30 secondi in tempo reale, rogo e classifica). Il vecchio gioco del cerchio resta con
  `--cerchio`. Pagine "Come si gioca" nuove (`Testi.REGOLE_CATENE`). Provato con `--auto` (partite intere) e con
  `--clic` (pulsanti premuti a caso); build riesportata e provata.

## 21. Claude — 21 ottobre 2026 (notte): primo personaggio vero, la sacerdotessa del culto

- L'utente ha preso Meshy Pro. Personaggi pensati per le Catene: condannati del Custode, realistici e cupi, mani libere,
  sagome riconoscibili (guida e descrizioni in `../documenti/GUIDA_PERSONAGGI_MESHY.txt`). Lezioni su Meshy: GPT Image 2.5 Flare
  (Nano Banana fa disegni), 9:16, parole sobrie per il filtro, niente simboli religiosi veri (culto inventato).
- Sacerdotessa: originale Meshy 2,25 milioni di triangoli → 50.000 (viso e mani protetti, colori/lucentezza/rilievi
  ricalcolati dall'originale sulla mappa ridotta: niente stiramenti; la mappa "nuova" spezzettava le stoffe).
  Il remesh di Meshy era inservibile.
- Scheletro a 22 ossa con nomi tipo Mixamo; articolazioni misurate col righello (la ricerca a fette sbaglia per gonna,
  velo e capelli); pesi da copia piena (voxel), max 4 ossa per punto. Prove di posa ok; prova in Godot ok.
- 12 animazioni Mixamo trasferite (rotazione di ogni osso rispetto al riposo; appoggio a terra del punto più basso,
  perché le gambe sono più lunghe del manichino). File: `assets/personaggi/sacerdotessa/sacerdotessa.glb`.
  Programmi in `../assets_src/personaggi/sacerdotessa/`; prove `tests/prova_personaggio.gd`, `tests/prova_animazioni.gd`.
- Prossimo (utente): tutti i movimenti del gioco prima di metterla nell'arena; poi il Cavaliere esiliato.

## 22. Claude — 21 ottobre 2026: presentazione grafica (skill di Codex progetto-*)

- L'utente non era soddisfatto di testi, scritte e presentazione. Skill usate: progetto-visual-review (diagnosi su foto
  vere, prima/dopo alle stesse condizioni), progetto-ui-craft con tipografia-e-testi, progetto-art-direction,
  progetto-scene-craft (solo il rogo). Foto di prova: `--clic --foto=...` ora fotografa anche la schermata di scelta.
- Tre problemi principali trovati: (1) Cinzel Decorative per annunci e carte unisce le lettere ("LE", "MANCHE") e in
  maiuscolo non si legge; (2) sei riquadri con lo stesso peso e le stesse informazioni ripetute (candele e carte in
  tre posti), scelta del turno piccola e poco chiara ("Tiri la catena: SÌ"); (3) finestre grandi a misura fissa e
  mezze vuote, classifica come testo centrato, frasi sbagliate ("Tu non era il sabotatore", "si parte da il",
  "Il sabotatore era tu", "La Strega si libera per primo").
- Fatto: due famiglie di caratteri (IM Fell per titoli, annunci, carte e Custode, in minuscolo; EB Garamond per tutto
  il resto; prova in `tests/prova_caratteri.gd`); riquadri e pulsanti con un solo filo e angoli appena smussati;
  contorno visibile per la tastiera; riga in alto senza riquadro; riquadro personale solo con catene e ruolo;
  annunci e voce del Custode su un'ombra morbida; scelta del turno in due righe (Carta / Catena: Tira, Non tirare) e
  Conferma separata col tempo accanto alla frase; finestre grandi che seguono il contenuto, classifica in tabella;
  menu delle Catene senza le abilità delle classi vecchie, descrizione intera del luogo scelto; frasi con il soggetto
  giusto (`_say`) e verbi al posto di aggettivi maschili; carte 3D più alte e leggibili; il campione che brucia si
  annerisce invece di diventare una sagoma arancione piatta.
- Corretto anche un errore vecchio: nell'ultimo respiro un doppio clic veloce sul bersaglio fermava la partita.
- Provato: partite `--auto` e `--clic` intere, vecchio gioco `--cerchio`, build riesportata e avviata (caratteri inclusi).
- Non verificato: movimento e tempi degli annunci (solo fermi immagine), uso reale con mouse e tastiera, schermi
  diversi da 1600x900. Rimasto: scritte sopra i campioni lontani ancora piccole; "libero/eliminato" restano al maschile
  nella tabella; il nome PROGETTO è provvisorio.

## 23. Claude — 2 novembre 2026: tavolo da 5 a 8 con le sedie, Custode seduto sul trono
- Richiesta: tavolo adatto da 5 a 8 giocatori, sedie, Custode seduto sul trono. Scelte dell'utente: un solo tavolo
  per tutti, la sedia di pietra del 22/10, menu ancora da 4 a 8.
- Tavolo: lo stesso anello di pietra attorno all'altare, abbassato a 75 cm (da stare seduti; seduta a 42 cm).
- Sedie: `sedia_pietra.glb` (da assets_src/personaggi/mago_nero/carte_sedia) una per posto, rivolta all'altare
  (`arena.gd _chair`); si rifanno quando cambia il numero di posti.
- Campioni seduti (sagome provvisorie, `figura.gd`): il corpo "in piedi" scende di 33 cm dentro l'actor, che ora ha
  il perno all'anca; gambe sedute ferme (`_legs`). Strattoni: scivola al massimo 12 cm sulla sedia e si piega in
  avanti; bruciato si accascia sul tavolo; scritte, scudo e petto abbassati.
- Custode: `assets_src/custode/custode_seduto.py` piega il modello (senza scheletro) alle anche e alle ginocchia,
  stringe lo spessore delle gambe, la tunica scende dalle ginocchia al gradino; nessun punto dentro il trono;
  `custode_seduto.glb` gia' nelle coordinate del trono. Non fluttua piu', respira appena.
- Provato: partite `--auto` a 5 e 8, `tests/prova_catene.gd --giocatori=5/8` (0 punti di catena nella pietra) con
  foto nuove (11 Custode sul trono, 12-13 seduto di fianco/dietro, 14 dall'alto).
- Rimasto: le gambe sedute sono blocchi provvisori (arriveranno i personaggi veri); il Custode per alzarsi alla
  rivelazione del sabotatore avra' bisogno dello scheletro (fase 3).
