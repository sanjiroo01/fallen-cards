---
name: mixamo-animation-retarget
description: Prepara clip Mixamo e trasferisce animazioni tra scheletri compatibili o diversi verso Godot4. Usa per scambio With Skin/Without Skin, retarget, rest pose, proporzioni, contatti e root motion; non rigga automaticamente creature non umanoidi né sostituisce un rig valido.
---

# Mixamo e trasferimento delle animazioni

Prima di caricare o convertire file identifica il rig sorgente e quello di destinazione. Mantieni il servizio e il formato già funzionanti. Non acquistare strumenti o inviare asset online fuori dall'incarico. Mixamo è rivolto ai bipedi umanoidi: per altre anatomie usa un rig e animazioni adatti, senza assumere che basti rinominare le ossa.

## Distingui due percorsi

**Stesso personaggio e stesso rig Mixamo:** può non servire un retarget in Blender. Conserva un modello di riferimento con skin e scheletro; per le clip successive valuta il download senza skin, quando disponibile, evitando di importare una nuova copia del corpo per ogni animazione. La dicitura e le opzioni del pannello vanno controllate nella versione effettiva.

**Rig di destinazione diverso:** il cambio formato non effettua il retarget. Confronta gerarchia, rest pose, orientamento delle ossa, radice e proporzioni. Scegli un solo percorso principale, Blender oppure importer Godot, e documentalo per evitare correzioni duplicate. Non comprare o presumere disponibile un add-on di retarget.

## Lavora prima su una clip

Scegli una clip che eserciti le parti importanti del campione. Mantieni il movimento leggibile dalla distanza di partita; non scaricare pacchetti di camminata o combattimento non richiesti. Verifica durata, posa iniziale/finale, loop e contatti. Usa una frequenza di campionamento adatta alla sorgente e al movimento, non 30fps come obbligo universale.

In Blender, mantieni separati il rig sorgente e il destinatario durante la verifica. Correggi le differenze di posa e gli eventuali vincoli, poi campiona il movimento sullo scheletro esportabile se necessario. Conserva l'originale; prima di rimuovere vincoli sulla copia verifica che le chiavi campionate riproducano il movimento. Un rig con gli stessi nomi può avere rest pose diversa.

In Godot, quando devi condividere animazioni tra umanoidi diversi, configura e verifica BoneMap/SkeletonProfileHumanoid sui dati sorgente e destinatario pertinenti nelle impostazioni avanzate. Controlla mapping mancante o errato, rest pose e tracce importate. Non applicare il profilo umanoide a una creatura che non lo rappresenta; non rimuovere tracce di accessori o facciali solo perché non sono nella mappa standard.

## Spostamento e diagnosi

Decidi esplicitamente tra clip sul posto e clip con spostamento. Il controller e l'animazione non devono applicare due volte la stessa traslazione o rotazione. Per campioni che restano attorno all'altare, non aggiungere movimento del corpo fisico soltanto perché il clip sorgente lo contiene.

I piedi che scivolano possono dipendere da velocità del controller, retarget, scala, contatti della clip o blending: non attribuire ogni caso alla root motion. Se le proporzioni cambiano durante la clip, controlla anche tracce di posizione/scala e rest pose; BoneMap non è un correttore universale di scala.

Consegna file e clip usati, rig sorgente/destinatario, scelta di campionamento, trattamento dello spostamento e prove osservate. L'anteprima Mixamo, l'animazione in Blender e quella nel gioco sono verifiche distinte.

Fonti: [workflow Mixamo Adobe](https://helpx.adobe.com/creative-cloud/help/animate-characters-mixamo.html), [retarget Godot4.6](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/retargeting_3d_skeletons.html).
