---
name: blender-materials
description: Prepara UV, texture e materiali Blender per asset da videogioco. Usa per texturing, baking e correzione dei materiali da esportare.
---

Leggi stile, motore, pipeline shader e risoluzioni concordate. Riutilizza palette e materiali del progetto. Non trasformare uno stile cartoon in fotorealistico senza richiesta.

- Controlla UV con una texture checker, soprattutto nelle zone visibili. Mantieni densita' texel coerente tra asset comparabili. Distingui sovrapposizioni intenzionali da quelle che danneggiano baking o lightmap.
- Scegli numero di materiali e dimensioni texture in relazione a dimensione sullo schermo e piattaforma; evita texture grandi su dettagli minuscoli.
- Verifica quali nodi e proprieta' supportano esportatore e shader di destinazione. Il risultato in Blender non garantisce lo stesso risultato nel gioco. Esegui baking dei procedurali solo quando necessario alla pipeline.
- Per baking di normal map verifica cage, triangolazione, tangenti e convenzione del canale verde del motore. Imposta lo spazio colore secondo il significato della texture; distingue colore da dati come roughness, metallic e normal.
- Per texture impacchettate documenta il contenuto di ciascun canale. Non presumere un ordine universale ORM/RMA.
- Osserva il materiale con illuminazione neutra e, quando disponibile, nella scena di gioco. Controlla cuciture, stretching e riflessi incoerenti.

Consegna texture effettivamente salvate, mappatura dei canali, materiali e controlli eseguiti. Per risorse esterne registra fonte e licenza verificata; non attribuire licenze per supposizione.
