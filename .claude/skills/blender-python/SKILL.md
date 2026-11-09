---
name: blender-python
description: Scrivi, correggi o rendi ripetibili script Python per Blender usando bpy e bmesh. Usa quando automatizzi modifiche alla scena o risolvi errori di scripting.
---

Rileva versione Blender e strumenti disponibili prima di scegliere API o comandi. Esegui bpy nel runtime Blender o attraverso il collegamento esistente, non presumere che il Python ordinario lo includa.

- Preferisci bpy.data e bmesh quando evitano dipendenze inutili dal contesto. Per bpy.ops verifica modalita', oggetto attivo, selezione e contesto necessari; usa override solo quando applicabili all'operatore.
- Parametrizza dimensioni, seed casuale, percorsi e nomi rilevanti. Limita creazioni e aggiornamenti a una collezione identificabile. Ripetere lo script non deve duplicare involontariamente tutti gli oggetti.
- Non cancellare l'intera scena per correggere un singolo asset. Salva un checkpoint prima di trasformazioni irreversibili e conserva il sorgente dei procedimenti di generazione.
- Lavora per passi verificabili; registra errori con traceback e identifica l'operazione fallita. Non sopprimere eccezioni per simulare successo.
- Dopo l'esecuzione controlla gli invarianti utili: presenza degli oggetti, dimensioni, materiali, output salvati. Quando l'effetto e' visivo, osserva anche un'immagine del risultato.
- Su Windows cita correttamente i percorsi con spazi; usa l'operatore PowerShell & per avviare un eseguibile il cui percorso e' tra virgolette. Non assumere un percorso fisso di installazione.

Riporta script salvato, versione usata, verifiche eseguite e limiti. Se manca accesso a Blender, consegna lo script come non eseguito.

Per problemi di contesto consulta la documentazione della versione installata: https://docs.blender.org/api/current/info_gotchas_operators.html
