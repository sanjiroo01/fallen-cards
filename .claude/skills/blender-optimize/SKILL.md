---
name: blender-optimize
description: Analizza e ottimizza il costo di asset Blender per giochi, preservandone la resa visiva. Usa per riduzione geometria, LOD, materiali e collisioni.
---

Ricava piattaforma, camera e budget dal progetto. Se non esistono, misura lo stato iniziale e presenta obiettivi provvisori motivati: non imporre una soglia universale di triangoli.

1. Misura triangoli sulla geometria valutata con modificatori, materiali, texture, oggetti e istanze. Distingui statistiche della scena da costo effettivo nel motore; non equiparare slot materiali e draw call misurate.
2. Identifica il problema probabile: geometria, materiali, trasparenze, texture, collisioni o frequenza di ripetizione. Se il motore e' accessibile, usa il profiler per confermarlo.
3. Intervieni su una copia: riduci dettagli invisibili e densita' nelle zone poco importanti; conserva silhouette, UV, normali e parti mobili. Non applicare Decimate indistintamente a tutto.
4. Crea LOD o collisioni semplificate quando la pipeline li richiede. Su mesh deformabili verifica le pose, i pesi e la qualita' delle articolazioni dopo la riduzione. Non assumere naming o supporto LOD universali.
5. Confronta prima/dopo alle distanze previste, includendo transizioni LOD quando verificabili nel motore.

Consegna tabella prima/dopo delle misure reali e compromessi osservati. Non promettere guadagni FPS senza misurazione nel gioco. Se l'utente chiede solo un'analisi, restituisci il rapporto prima di fare modifiche.
