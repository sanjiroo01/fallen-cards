---
name: blender-character-rigging
description: Sceglie, prepara e verifica scheletro e skinning di un personaggio per Godot. Usa per rig nuovi, pesi e deformazioni o preparazione di un rig di esportazione; riusa rig e animazioni già validi, affiancando blender-rigging se disponibile.
---

# Rig e deformazione dei personaggi

Controlla il rig esistente prima di scegliere uno strumento. La scelta dipende da anatomia, movimenti richiesti, strumenti disponibili e necessità di modifiche, non dalla sola distinzione «personaggio principale/NPC». Un rig Mixamo può essere sufficiente anche per un personaggio definitivo se soddisfa i requisiti verificati. Non aggiungere AccuRIG, Rigify o altri programmi solo per completare una lista.

## Costruzione e skinning

1. Rileva proporzioni, scala, simmetria, rest pose ed eventuali skin. Se il personaggio è già animato, salva una versione recuperabile prima di cambiare gerarchie, assi, nomi o posizione delle ossa in Edit Mode.
2. Per una mesh non riggata scegli un percorso adatto. Con un auto-rigger verifica le articolazioni identificate e il risultato, non solo il messaggio di successo. Con Rigify adatta il metarig, genera il rig e verifica il binding; i controlli non garantiscono da soli che la mesh sia pesata correttamente.
3. Correggi i pesi sulla mesh, in Weight Paint o attraverso i gruppi di vertici. Pose Mode serve a muovere le ossa e osservare il comportamento, non sostituisce la modifica dei pesi. Evita vertici senza influenze valide e influenze su ossa sbagliate. Normalizza e limita le influenze secondo i requisiti verificati dell'esportatore e del motore, non con un numero imposto a priori.
4. Distingui parti deformabili e rigide: pelle/stoffa richiedono un comportamento diverso da corona, arma o pendente. Valuta agganci o pesi appropriati; non unire tutto per comodità dell'auto-rigger.

Non spostare automaticamente l'origine e non applicare tutte le trasformazioni al rig già associato alla mesh. Un nodo di posizionamento nella scena o una copia di esportazione può risolvere una necessità di allineamento senza alterare il binding originale.

## Prove adatte all'uso

Osserva spalle, ascelle, gomiti, polsi, bacino, ginocchia e le parti richieste dal gioco, su entrambi i lati. Prova pose intermedie ed estreme plausibili, torsioni e transizioni, con il costume completo. Una mesh che funziona nella posa neutra può collassare quando tira una catena. Camminata, corsa e salto sono prove utili se richieste, non requisiti universali per campioni fermi nell'arena.

Valuta perdita di volume, stiramenti, intersezioni visibili e contatti dalla camera di gioco oltre che in dettaglio. «Nessuna deformazione» non è un obiettivo corretto: una mesh animata deve deformarsi; il punto è evitare artefatti incompatibili con l'aspetto e i movimenti previsti.

## Rig di lavoro e rig esportato

Conserva nel .blend controlli, vincoli e sorgenti necessari al lavoro. Un rig di controllo non va trasferito automaticamente nel motore come se tutti i suoi meccanismi fossero supportati. Quando serve, prepara una copia/gerarchia di esportazione e campiona le animazioni sullo scheletro previsto, mantenendo root, ossa deformanti e ossa di aggancio necessarie. Non esportare il metarig al posto del rig animato.

Non eliminare tutte le ossa non deformanti per nome senza verificare gerarchie, agganci e tracce. Prova l'export di una clip prima di elaborarle tutte. Consegna il rig sorgente e gli eventuali dati esportati separatamente; distingui pose verificate in Blender da prove realmente osservate in Godot.

Riferimenti tecnici da consultare nella versione installata: [Rigify](https://docs.blender.org/manual/en/latest/addons/rigify/index.html), [skinning Blender](https://docs.blender.org/manual/en/latest/animation/armatures/skinning/parenting.html). Non assumere che l'estensione sia già abilitata.
