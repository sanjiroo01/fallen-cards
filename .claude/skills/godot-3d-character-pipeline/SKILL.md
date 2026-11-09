---
name: godot-3d-character-pipeline
description: Coordina il percorso di un personaggio 3D da Meshy o altra sorgente a Blender, rig, animazioni e Godot4. Usa per scegliere o diagnosticare la pipeline completa; per un singolo difetto passa alla skill specifica, senza rifare le fasi già valide.
---

# Personaggi animati per Godot

Obiettivo: un personaggio coerente con il gioco, deformabile e verificato nella scena reale. Una bella immagine Meshy non dimostra la qualità del modello, del rig o delle animazioni.

## Ricava il contesto senza interrogatorio

Leggi le istruzioni del progetto, ispeziona i file pertinenti e gli strumenti disponibili. Ricava versione del motore, formato, natura del personaggio, rig presente e animazioni richieste. In PROGETTO il motore dichiarato è Godot4.6: conferma la versione effettiva quando usi opzioni specifiche; config_version non è la versione del motore. Chiedi solo i dati mancanti che cambiano il lavoro.

Parti dal problema attuale. Un asset già riggato non deve essere rimandato all'auto-rigger per principio. Non acquistare software, attivare servizi o caricare modelli online soltanto perché figurano in questa pipeline. Usa gli strumenti già disponibili; l'invio a un servizio deve rientrare nell'incarico dell'autore.

## Formati secondo il passaggio

Per nuove consegne Blender → Godot preferisci glTF2.0/GLB, come indicato dalla documentazione Godot. Mantieni FBX quando il percorso esistente funziona o quando serve per Mixamo e altri strumenti. Non convertire più volte un file senza necessità. OBJ può servire come geometria statica, ma non trasporta scheletro e animazioni. Conserva il sorgente modificabile e le texture.

## Percorso proporzionato al personaggio

1. **Inventario:** geometria, materiali, gerarchie, dimensioni, eventuali skin, shape key e clip. Osserva il modello dalla camera del gioco.
2. **Preparazione se necessaria:** correggi i difetti che impediscono animazione o lettura. Usa meshy-model-cleanup, se disponibile, senza cancellare il dettaglio utile.
3. **Scheletro:** riusa quello valido oppure scegli un metodo adatto alla forma e agli strumenti. Mixamo è una possibilità per bipedi umanoidi; rig personalizzati e strumenti Blender coprono altri casi. Consulta blender-character-rigging quando serve.
4. **Animazione:** usa il rig sorgente compatibile o effettua un retarget verificato. Per Mixamo consulta mixamo-animation-retarget. Non basta che i nomi delle ossa coincidano.
5. **Consegna al motore:** importa e prova in una scena controllata; consulta godot-animation-import. Le skill tecniche già presenti, come blender-export e blender-rigging, rimangono utili e non vanno duplicate o sostituite automaticamente.

Prepara un solo personaggio e una clip significativa come prova prima di elaborare l'intero gruppo. Documenta l'accordo tecnico scelto: scala e altezza, riferimento di orientamento, posizione di appoggio, scheletro/rest pose, formato, clip e gestione dello spostamento. Non imporre -Y in Godot: Blender ed engine hanno convenzioni diverse, e l'esportatore può già convertirle. Verifica il fronte rispetto al controller esistente.

I campioni attorno all'altare non richiedono automaticamente un controller da gioco d'azione, una camera personale o animazioni walk/run/jump. Scegli le prove coerenti con l'incarico: attesa, movimento delle braccia, trazione o gesto rituale solo se previsti. La logica resta nella scena di gioco, separata dai dati importati.

## Consegna verificabile

Riporta file sorgente ed esportato, impostazioni significative, problemi rimasti ed evidenze osservate. Distingui modello preparato, rig provato, clip provata e personaggio verificato in Godot. Un import senza errori non certifica materiali, pesi, loop, contatti o prestazioni. L'esecuzione di questa skill non autorizza modifiche al gameplay.

Fonti tecniche: [formati Godot4.6](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html), [retarget Godot4.6](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/retargeting_3d_skeletons.html).
