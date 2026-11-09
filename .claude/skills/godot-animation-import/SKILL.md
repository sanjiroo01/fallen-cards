---
name: godot-animation-import
description: Importa e diagnostica personaggi, scheletri e clip in Godot4, con AnimationPlayer, AnimationLibrary, retarget e AnimationTree quando servono. Usa per import riusciti solo in anteprima, tracce errate, orientamento, materiali e animazioni che non partono nella scena reale.
---

# Importazione e prova delle animazioni in Godot

Rileva versione effettiva, file sorgente e struttura delle scene. In PROGETTO usa il percorso Godot4.6 già configurato, senza aggiornare il motore per seguire una skill. Un asset GLB/glTF è preferito per nuove esportazioni compatibili; FBX rimane utilizzabile e non richiede una conversione se il percorso già funziona. OBJ non trasporta le animazioni del personaggio.

## Configura l'import senza perdere la scena di gioco

Importa modello e texture necessarie; osserva lo scheletro, il binding e le clip nell'anteprima avanzata. Per una risorsa destinata a condividere soltanto animazioni valuta la modalità Animation Library invece di creare copie complete del personaggio. Per uno scheletro compatibile già usato non inventare un passaggio di retarget obbligatorio.

Quando il retarget è necessario, controlla BoneMap e profilo appropriato sui relativi scheletri. Il profilo umanoide è adatto agli umanoidi. Non usare Rename Bones o rimozione delle tracce come correzioni universali: possono influire su agganci, accessori, materiali animati e clip esistenti. Dopo ogni cambiamento rilevante prova il caso che lo richiedeva.

Mantieni logica e personalizzazioni in una scena .tscn che istanzia o eredita il modello, secondo le convenzioni reali del progetto. Non modificare manualmente la cache .godot. Non salvare la logica solo dentro una scena importata destinata a essere rigenerata.

## Usa la struttura minima necessaria

Per un campione fermo nell'arena può bastare una radice Node3D con il modello istanziato. CharacterBody3D e collisioni servono quando il personaggio ha quel comportamento fisico, non per poter riprodurre una clip. Non aggiungere Camera3D, locomozione, salto o nuove collisioni fuori incarico.

Riusa l'AnimationPlayer importato o configura consapevolmente un player e i percorsi delle tracce. Non creare un secondo AnimationPlayer vuoto aspettandosi che riceva da solo le clip del modello. Controlla il percorso root, il bersaglio Skeleton3D e i nomi reali delle animazioni, inclusi eventuali prefissi di libreria.

AnimationTree serve per transizioni o combinazioni che lo richiedono e usa le animazioni di un AnimationPlayer: collegalo al player corretto. Per una sequenza semplice può bastare AnimationPlayer con transizioni adeguate. Evita che player e albero tentino contemporaneamente di controllare lo stesso scheletro attraverso percorsi indipendenti.

## Diagnosi in ordine

1. **La clip è presente?** Verifica impostazioni di import e libreria assegnata.
2. **Viene riprodotta?** Controlla nome completo, player attivo, nodo di riferimento e logica che avvia/interrompe il movimento.
3. **Le tracce trovano i bersagli?** Controlla percorsi dopo eventuali cambi di gerarchia e il riferimento della skin allo scheletro.
4. **La deformazione è corretta?** Confronta pesi, rest pose, mapping e tracce di trasformazione, non solo i nomi.
5. **Il corpo è orientato e posato bene?** Verifica scala e conversione degli assi attraverso l'intera catena; evita rotazioni correttive applicate due volte.
6. **Il movimento è adatto al gioco?** Controlla loop, transizioni, contatti, velocità e trattamento della root motion secondo il controller esistente.

La prova conclusiva avviene nella scena reale o in una scena di test equivalente, con illuminazione e materiali del motore. Un comando headless può rilevare errori di import, ma non certifica la resa del velo, il contatto dei piedi o i pesi delle spalle. Riporta distintamente file importato, anteprima osservata e comportamento in esecuzione. Non dichiarare queste prove se non sono state fatte.

Fonti: [importazione Godot4.6](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html), [AnimationTree](https://docs.godotengine.org/en/4.6/tutorials/animation/animation_tree.html).
