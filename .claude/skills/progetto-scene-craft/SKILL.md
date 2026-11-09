---
name: progetto-scene-craft
description: Rifinisce la resa complessiva della scena 3D in Godot, collegando camera, luce, materiali e VFX alla leggibilità della partita. Usa quando la scena appare piatta, artificiale, confusa o incoerente anche se i modelli singoli sono buoni; non sostituisce le skill di modellazione, rig o ottimizzazione.
---

# Rifinitura della scena dalla camera di gioco

Il risultato è il fotogramma giocabile, non il render isolato del modello. Leggi la direzione artistica esistente e osserva la scena attuale. Per tecniche di modellazione, materiali, effetti e ottimizzazione consulta soltanto le skill pertinenti già installate. Non rifare un asset se il difetto dipende dalla luce o dalla camera.

## Diagnosi per impatto

Parti da silhouette, sovrapposizioni e valori: tutti i partecipanti devono distinguersi nelle fasi che richiedono una decisione. Prova l'inquadratura reale con altare basso e alto se questi stati esistono già, con gli effetti massimi pertinenti. Non cambiare regole o inventare stati per completare una prova grafica.

Controlla ciò che copre il campione più lontano, mani e catene quando si muovono e spazio per l'interfaccia. Se la vista è scomoda, correggi prima posizione, lente, punto di mira e ostacoli; aggiungere un'altra visuale non è una soluzione automatica. Mantieni stabile la camera durante lettura e scelta; eventuali dettagli di regia devono restituire rapidamente il controllo visivo.

## Luce e materiali con una logica

Separa la luce che racconta il luogo dalla luce necessaria a capire il gioco. Il fuoco può dominare l'atmosfera senza bruciare visivamente volti e testi. Cerca sorgenti motivate e separazione leggibile dal fondo, evitando contorni luminosi gratuiti su ogni oggetto. Non schiarire tutto uniformemente per correggere un solo personaggio nascosto.

Confronta ferro, pelle, stoffa, osso, pietra e cera sotto la stessa luce. Differenzia la risposta dei materiali con scala, rugosità e dettagli appropriati, non solo cambiando colore. Usura e sporco devono seguire contatto, umidità e costruzione, non una macchia casuale ripetuta dappertutto. Risolvi prima effetto plastica, scala e grandi superfici, poi microtexture.

Non usare nebbia, glow, vignettatura o contrasto estremo per nascondere problemi di composizione. Valuta gli effetti in movimento: un fermo immagine non rivela tremolii, interferenze tra superfici trasparenti, scie o tessuti che attraversano il corpo. Velo, capelli e fuoco richiedono una verifica del materiale nel motore, non solo nel visualizzatore del generatore 3D.

## Costo e coerenza

Investi dettaglio dove resta visibile alla distanza di partita. Un export più pesante o una texture più grande non garantisce un'immagine migliore. Confronta costo e resa delle modifiche significative sulla stessa scena e macchina; annota impostazioni e misure disponibili. Se non puoi misurare, non dichiarare un miglioramento delle prestazioni. Non imporre un numero universale di poligoni, luci o FPS senza un obiettivo del progetto.

Verifica anche che effetti e camera non rivelino l'autore di una carta anonima o un ruolo segreto. Le differenze tra scenari devono convivere con una scala di personaggi e una grammatica visiva comune.

Consegna viste prima/dopo confrontabili e gli stati osservati. Distingui risultato Blender, anteprima del modello e risultato Godot: l'uno non certifica l'altro. Se il lavoro richiesto è una correzione, applica prima il cambiamento con maggiore effetto e ricontrolla, senza allargare il compito a tutti gli scenari.
