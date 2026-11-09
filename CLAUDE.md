# PROGETTO - istruzioni per Claude Code

## Contesto verificato
- Gioco 3D per PC, nome provvisorio PROGETTO: gioco fantasy cupo a scelte segrete e simultanee fra
  quattro campioni attorno a un cerchio rituale.
  **Il riferimento e' `docs/progetto.md`** (regole, classi, scenari, piano): leggilo prima di lavorare sul gioco.
- Il vecchio gioco e' stato spostato in `../dismissed/` (su richiesta dell'utente): non si usa, non si
  cita, non si riporta nel progetto senza una richiesta esplicita.
- Motore dichiarato in project.godot: Godot 4.6, Forward Plus.
- Scena principale: res://scenes/main.tscn (script `scripts/game.gd`).
- Codice: `scripts/cerchio/` (regole, bot, testi e istruzioni), `scripts/world/` (arena, campioni,
  candele, materiali), `scripts/ui/hud.gd` (interfaccia), `scripts/config.gd` (numeri del gioco).
- Prove: `tests/sim_cerchio*.gd` (simulatori); il gioco intero si prova con
  `godot --path . -- --auto --veloce=0.05 --esci` (anche `--clic` per l'interfaccia, `--foto=CARTELLA`).
- Modelli fantasy scaricati: `../Modelli_Fantasy_Condivisi` (cartella condivisa con Codex: leggere il
  suo LEGGIMI.md; le copie di Claude vanno in `Claude`, gli originali non si toccano).
- La cartella ../godot/ contiene gli eseguibili Godot 4.6 per Windows.

## Skill Blender disponibili
Leggi il relativo SKILL.md in .claude/skills/ quando il compito lo richiede:
- blender-game-asset: creazione e modifica dei modelli.
- blender-python: automazione con bpy/bmesh e correzione degli script.
- blender-materials: UV, texture e materiali.
- blender-visual-review: confronto visivo con reference e camera di gioco.
- blender-optimize: analisi e riduzione del costo degli asset.
- blender-export: esportazione e verifica per Godot.

Skill esterne aggiunte il 15/10/2026 su richiesta dell'utente (provenienza in FONTE.md di ognuna):
- nel progetto (MIT): cloth-sim (stoffe simulate, pin, bake), godot-export (GLB per Godot, da
  incrociare con blender-export), reference-to-3d (modello vincolato a tavole di riferimento).
- personali, in ~/.claude/skills (senza licenza, fuori da git): blender-expert (protocollo e strumenti
  comuni bx_audit/bx_review), blender-sculpting, blender-retopology, blender-rigging, blender-hair,
  blender-uv-baking.
- nel progetto (Apache 2.0, scritte per Godot 4.7: verificare su 4.6): godot-animation, game-feel,
  camera-systems, procedural-gen, performance-optimization.
- aggiunte il 15/10/2026 dopo una ricerca online chiesta dall'utente (contenuto controllato, fonte e
  licenza in FONTE.md e LICENSE di ognuna): 3d-essentials, particles-vfx, shader-basics, audio-system
  (GodotPrompter, MIT; note per 4.6), audio-design, game-ui-ux, godot-multiplayer (gamedev-skills,
  Apache 2.0, scritte per 4.7), environment-artist, set-dressing (arjun988, MIT, pensate per BlenderMCP).
- aggiunte il 9/11/2026 su richiesta dell'utente (contenuto controllato, fonte e licenza in FONTE.md e
  LICENSE): blender-clothing (vestiti sui personaggi), blender-animation (trasferire e cuocere movimenti),
  blender-asset-qa (controllo prima del gioco), blender-lighting-lookdev, con la base blender-core
  (EL4CTEO/blender-skills, MIT, Blender 5.2); multiplayer-sync, dedicated-server, player-controller,
  camera-system, state-machine, godot-optimization (GodotPrompter, MIT, Godot 4.3+: verificare su 4.6).
  camera-system (GodotPrompter) e camera-systems (gamedev-skills) sono due skill diverse.
Se due skill dicono cose diverse, valgono queste istruzioni.

## Metodo di lavoro
- Riutilizza il collegamento Blender gia' configurato e la pipeline presente nel progetto.
- Ricava stile e proporzioni dagli asset e dalle reference esistenti; l'ambientazione da sola non definisce lo stile grafico.
- Conserva i sorgenti modificabili e un checkpoint prima di modifiche distruttive.
- Limita le modifiche agli asset richiesti e rispetta eventuali lavori in corso.
- Prima di dichiarare concluso un modello osserva immagini reali del risultato. Se non puoi, segnala il controllo non eseguito.
- Per nuove esportazioni considera glTF 2.0/GLB; conserva i formati esistenti quando gia' funzionanti.
- Verifica dimensioni, orientamento, materiali e collisioni in Godot; per personaggi verifica anche rig e animazioni pertinenti.
- Conserva la logica di gioco in scene che sopravvivano alla reimportazione. Non modificare manualmente la cache .godot/.
- Distingui "script eseguito", "verificato in Blender" e "verificato nel gioco". Non dichiarare verifiche non effettuate.

## Ruoli e autonomia (deciso dall'utente il 15 ottobre 2026)
- L'utente decide cosa realizzare e valuta il risultato. Claude agisce da sviluppatore senior e
  responsabile tecnico: sceglie come realizzarlo.
- Senza chiedere approvazione: scrivere e correggere codice, creare strumenti, eseguire test,
  migliorare l'architettura e risolvere i problemi. Si procede fino al traguardo, aggiornando
  l'utente ai traguardi importanti.
- Si consulta l'utente per la direzione creativa (stile, aspetto, design dei personaggi) e per
  funzionalità non richieste: non introdurle di propria iniziativa.
- Dopo ogni fase importante si mostrano immagini, render o anteprime, e un breve resoconto:
  cosa è fatto, cosa è verificato e come si procede.
- Agenti e skill: si creano quando danno un vantaggio concreto, si documentano e si verificano.
  Niente duplicati, e niente agenti che modificano gli stessi file in contemporanea.
- PROGETTO Live (`tools/blender/live`, skill blender-live) resta disponibile ma non è una priorità.
  Il metodo normale è: script in Blender da riga di comando, poi anteprime.

## Sicurezza del progetto
- Si lavora solo sulle parti pertinenti all'incarico.
- Prima delle modifiche significative si fa un checkpoint git: commit sul ramo di lavoro, oggi `main` (repository GitHub `sanjiroo01/fallen-cards`, dal 9/11/2026).
  Il push su GitHub si fa solo su richiesta.
- Niente cancellazioni definitive: i file vecchi vanno nel Cestino, e solo dopo aver verificato che
  nulla li usa. Niente sovrascritture di originali senza una copia recuperabile.
- Niente spese, acquisti o pubblicazioni senza autorizzazione.
- File di Codex (cartella `Documenti\Codex\...` e cartella `Codex` dei modelli condivisi): non si modificano.
- Un lavoro non è concluso senza le verifiche possibili: immagini osservate davvero, test eseguiti,
  e per gli asset di gioco la prova in Godot.

## Organizzazione
- Diario: `devlog.md`, da aggiornare a fine sessione e ai traguardi.
- Personaggi: si parte dai modelli fantasy gratuiti (CC BY 4.0: citare autore, link, licenza e modifiche).
