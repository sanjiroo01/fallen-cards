---
name: blender-export
description: Esporta e verifica asset Blender per Godot. Usa per GLB, glTF, collisioni, materiali, rig, animazioni e problemi di importazione nel progetto Godot.
---

Il motore del progetto e' Godot. Ricava versione e renderer da project.godot, documentazione del repository e versione dell'eseguibile disponibile; non trattare config_version come versione dell'engine. Se le informazioni non bastano, chiedi la versione prima di usare funzionalita' specifiche. Non migrare il progetto o aprirlo con una major diversa per effettuare una verifica.

Preferisci glTF 2.0 (.glb per una consegna compatta) se il progetto non ha gia' una pipeline definita. Mantieni un workflow .blend diretto o un altro formato se gia' funzionante. L'import diretto .blend richiede Blender nelle installazioni Godot che lo supportano; non configurarlo automaticamente su tutte le macchine.

1. Salva il .blend sorgente e prepara una collezione o copia destinata all'export. Esporta solo gli elementi necessari.
2. Verifica scala fisica, assi, pivot, gerarchie, normali e materiali. Controlla gli effetti delle trasformazioni prima di applicarle, soprattutto con armature, shape key e animazioni.
3. Controlla compatibilita' dei modificatori, delle istanze e dei materiali con l'esportatore effettivamente installato. Mantieni il sorgente editabile se devi convertire la copia.
4. Per animazioni verifica rest pose, clip, durata, root motion e campionamento secondo la pipeline. Per collisioni e LOD usa le convenzioni reali del motore.
5. Esporta e verifica esistenza e dimensione non nulla del file. Reimporta in una scena temporanea separata e confronta dimensioni, orientamento, materiali e animazioni rilevanti.
6. Quando puoi accedere al motore, importa l'asset e osserva il risultato in una scena di prova. La reimportazione in Blender non dimostra da sola compatibilita' completa con il motore.

Riporta percorsi, preset/impostazioni rilevanti, anomalie e verifiche. Usa stati distinti: "esportato", "reimportato in Blender", "verificato nel motore". Non dichiarare l'ultimo stato se quel controllo non e' avvenuto.

## Controlli specifici per Godot

- Controlla Y-up e orientamento nel gioco. La convenzione Godot distingue la direzione della camera (-Z) dal fronte degli asset orientati (+Z); verifica anche le convenzioni del controller esistente. Non aggiungere rotazioni correttive duplicate a quelle dell'esportatore.
- Per collisioni privilegia primitive dove adatte. Una mesh concava puo' servire per geometria statica; per corpi dinamici usa forme adatte, come primitive o convex. I suffissi di importazione non sostituiscono la verifica della gerarchia fisica.
- Se il progetto usa suffissi, verifica supporto e opzioni nella versione installata: -col aggiunge collisione statica dalla mesh, -colonly usa la geometria solo per collisione, -convcol genera una forma convessa. Non rinominare in massa gli oggetti per attivarli.
- Metti logica di gioco, script e aggiunte in una scena .tscn che istanzia il modello o in una scena ereditata, secondo la struttura esistente. Verifica che una reimportazione conservi le personalizzazioni; non modificare a mano i file nella cache .godot.
- Confronta materiali e animazioni nell'illuminazione e nel renderer del gioco. Controlla clip, loop e root motion reali; l'importazione del file non dimostra da sola che il controller funzioni.
- Un import headless con esito positivo verifica solo una parte della pipeline. Per dichiarare riuscita la verifica visiva e fisica occorre osservare la scena in esecuzione e controllare le interazioni pertinenti.

Consulta le pagine equivalenti per la versione installata; queste fonti puntano alla stable corrente:
- https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html
- https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html
- https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html
- https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html
