---
name: progetto-ui-craft
description: Cura l'aspetto di HUD, carte, menu e schermate di PROGETTO con tipografia, gerarchia e componenti riconoscibili. Usa per rendere l'interfaccia raffinata e leggibile o rimuovere l'aspetto da modello generico; affianca game-ui-ux per struttura e input. Per un sito richiesto separatamente usa il riferimento web.
---

# Interfacce curate, coerenti con il gioco

Questa skill governa composizione, tipografia e finitura. Per navigazione, adattamento e gestione dello stato usa la skill esistente game-ui-ux quando pertinente; verifica le API sulla versione Godot effettiva, non copiare esempi destinati a versioni successive.

## Disegna attorno a una scelta reale

Per la schermata richiesta identifica: cosa deve decidere il giocatore, quali informazioni sono pubbliche, quale azione viene dopo e quale feedback conferma l'esito. Dai priorità a questi elementi. Non riempire la schermata di riquadri perché manca un contenuto: lascia vedere personaggi e altare dove serve.

Costruisci una gerarchia esplicita tra azione, stato e spiegazione. Definisci in un unico tema o insieme di valori condivisi i ruoli tipografici, spaziature, colori semantici, superfici, bordi e stati. Riusa i componenti esistenti quando funzionano. Uno stesso evento deve usare la stessa grammatica in menu, carte e HUD.

Per testi, scritte e font leggi [references/tipografia-e-testi.md](references/tipografia-e-testi.md). Scegli il carattere dai font realmente disponibili e dalla direzione aggiornata. Se l'autore rifiuta la presentazione attuale, riconsidera anche il font precedente: non conservarlo solo perché approvato in passato. Controlla numeri, accenti italiani e testo lungo. Riserva il carattere più espressivo ai ruoli che lo sostengono; i valori da confrontare devono leggersi rapidamente. Verifica alla dimensione di utilizzo: ingrandire un'anteprima nasconde i problemi.

Non importare automaticamente l'estetica di un sito promozionale: il gioco non richiede una griglia di riquadri, pulsanti a pillola, icone decorative e bagliori ovunque. Una superficie può suggerire ferro, carta o stoffa con una struttura semplice e buona luce, senza texture pesanti dietro ogni frase. La coerenza conta più della quantità di ornamenti.

## Stati e comportamento fanno parte della grafica

Mostra normale, passaggio del mouse, focus tastiera, selezionato, premuto e disabilitato per i controlli realmente presenti. Non affidare stato e identità al solo colore. Il testo deve restare leggibile sul fotogramma più luminoso del fuoco e su quello più scuro; usa un supporto localizzato se necessario. Non esporre dati riservati nei suggerimenti, nelle animazioni o nei messaggi di esito.

Usa transizioni che spieghino causa ed effetto. Evita movimenti continui su elementi che richiedono lettura. Rispetta le opzioni di riduzione del movimento già presenti; non introdurre un sistema nuovo fuori incarico.

In Godot, applica la direzione tramite Theme, risorse e nodi Control adatti al layout esistente. Non rasterizzare testo funzionale dentro un'immagine. Verifica tagli, sovrapposizioni, focus e aree cliccabili alle risoluzioni supportate: almeno finestra di riferimento e una più piccola quando possibile. Non aggiungere supporto mobile o controller se non previsto dal progetto.

## Consegna

Mostra la schermata nel gioco con dati reali, uno stato di interazione pertinente e un confronto prima/dopo alla stessa scala. Riporta le verifiche effettive e le limitazioni. Un'immagine statica non dimostra che i pulsanti funzionino.

Se l'utente chiede anche un sito, leggi [references/web.md](references/web.md). Non convertire il gioco in un sito.
