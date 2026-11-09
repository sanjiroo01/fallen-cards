---
name: meshy-model-cleanup
description: Ispeziona e prepara geometria e materiali di personaggi Meshy prima di rigging o esportazione. Usa per fusioni indesiderate, topologia, proporzioni, scala, trasparenze e riduzione del costo; non applica automaticamente pulizie distruttive a un modello già riggato.
---

# Preparazione dei modelli Meshy

Conserva il modello ricevuto e lavora su una copia o collezione di preparazione. Prima di modificare, rileva mesh, armature, modificatori, shape key, UV, materiali, texture, parti separate e animazioni. Una procedura per una mesh statica non è automaticamente valida per un personaggio già associato a un'armatura.

## Diagnosi prima della pulizia

Osserva figura intera e articolazioni: braccia attaccate al busto, dita fuse, vestito saldato alle gambe, cavità o superfici sovrapposte nelle pieghe. Confronta silhouette e proporzioni dalla distanza di partita. Conta geometria e materiali quando serve decidere una riduzione; non inventare un budget universale.

Verifica dimensioni e trasformazioni nella gerarchia. Su una mesh ancora non riggata può essere utile normalizzare la scala prima del binding. Su armature, skin, shape key e oggetti animati, non usare automaticamente Ctrl+A su tutto: controlla il rapporto mesh/scheletro e gli effetti su rest pose e clip. Evita correzioni di scala applicate una volta al modello e una seconda volta durante l'import.

## Interventi mirati

- Correggi fusioni e geometria che impediscono il movimento; non rendere tutte le superfici chiuse per principio. Stoffa, ciocche su piani e aperture intenzionali possono essere valide.
- Usa Merge by Distance solo su una selezione e con una soglia adeguata alla scala. Non saldare dita vicine, strati del vestito o punti separati che servono alla deformazione.
- Controlla normali e orientamento facce prima di ricalcolarle. Le superfici sottili non si risolvono necessariamente con Recalculate Outside; valuta il materiale e il risultato nel motore.
- Rimuovi elementi estranei solo dopo aver verificato che non siano genitori, riferimenti, agganci o parti dello scheletro. Una luce di anteprima può essere superflua; un Empty della gerarchia può essere necessario.
- Unisci mesh solo se semplifica davvero il lavoro e non rompe parti mobili, UV, materiali, skin o shape key. Accessori separati non sono automaticamente un errore.
- Riduci o ricostruisci la geometria dove migliora il costo senza compromettere silhouette, articolazioni e UV. La decimazione non equivale a retopology adatta all'animazione.

Velo, capelli, corona e gonna fanno parte dell'identità del personaggio: non eliminarli come rimedio predefinito. Valuta separazione, pesi, agganci rigidi o una soluzione semplificata coerente con il gioco. Osserva anche trasparenza, compenetrazioni e risposta dei materiali nel motore; la sola anteprima Meshy non basta.

## Preparazione per un auto-rigger

Verifica corpo umanoide distinguibile, posa neutra sufficientemente simmetrica e arti separati. Se il modello è già valido e riggato, conserva il percorso esistente. Non trasformare alla cieca una posa articolata in rest pose: può richiedere re-binding o una procedura dedicata.

La FAQ Adobe descrive limiti per appendici, abiti molto ingombranti e parti scollegate. Un personaggio stilizzato può funzionare se resta umanoide riconoscibile; ali e accessori possono richiedere trattamento separato, non un divieto assoluto di riuso dell'animazione del corpo.

Consegna confronto prima/dopo, parti corrette, eventuali cambiamenti di geometria/materiali misurati e difetti residui. Non dichiarare «pronto per il rig» senza aver controllato le aree di deformazione; non dichiarare il rig riuscito perché la pulizia è terminata.

Fonte sui requisiti Mixamo: [FAQ ufficiale Adobe](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html).
