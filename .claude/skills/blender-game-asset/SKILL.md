---
name: blender-game-asset
description: Crea o modifica modelli Blender destinati a un videogioco, dalla reference al modello utilizzabile. Usa per props, edifici, ambienti modulari e blockout.
---

Leggi il CLAUDE.md del progetto e le reference disponibili. Ricava motore/versione, stile, camera di gioco, dimensioni, piattaforma e budget dalle informazioni esistenti. Chiedi solo i dati che cambiano concretamente il lavoro; se mancano budget, dichiara le ipotesi senza inventare limiti ufficiali.

1. Ispeziona il file e gli oggetti prima di modificarli. Riutilizza il collegamento Blender disponibile. Salva una copia recuperabile prima di operazioni distruttive e limita le modifiche alla collezione dell'asset.
2. Costruisci prima silhouette e proporzioni. Confronta il blockout con le reference dalla camera di gioco e con un riferimento di scala. Procedi autonomamente alle rifiniture salvo richiesta di approvazione intermedia.
3. Aggiungi dettagli solo quando migliorano la lettura alla distanza prevista. Usa istanze o Geometry Nodes per elementi ripetuti quando compatibili con l'esportazione; conserva il sorgente modificabile.
4. Imposta pivot e punti di aggancio coerenti con uso, animazione e griglia del progetto. Non applicare indiscriminatamente trasformazioni a rig o gerarchie animate.
5. Controlla shading, normali, intersezioni indesiderate e triangolazione risultante. Una superficie aperta intenzionale non e' automaticamente un errore per un asset da gioco.
6. Produci e osserva una vista dalla camera di gioco e viste complementari. Correggi i difetti osservati prima di consegnare.

Consegna percorso del .blend, anteprime effettivamente prodotte, dimensioni e statistiche misurate. Distingui modello pronto in Blender da asset verificato nel motore. Se non puoi osservare immagini o aprire il motore, indica il controllo rimasto da svolgere.
