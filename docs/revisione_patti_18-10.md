# Revisione indipendente dei Patti e degli Orrori (18/10/2026)

Tre IA indipendenti hanno letto solo `SCHEDA_PATTI_PER_REVISIONE.txt` (nella cartella superiore).
Sintesi dei pareri; le decisioni dell'utente vanno in `progetto.md`.

## Su cui sono d'accordo più revisori
- **Segno visibile ma uguale per tutti** (catena nera al polso / candela nera): si sa CHI ha un patto, non QUALE.
  Il segreto deve riguardare quale patto hai, non se lo hai. Base del bluff (come Coup, Liar's Bar).
- **Il dono si vede subito → il segreto dura un giro**: il bluff oggi è quasi nullo (Cieco, Banchetto si vedono).
- **Ultima maledizione** in coppia rompe il gioco (con Ritorno dalla fossa il prezzo sparisce; con Banchetto
  decide la manche). Deve prendersi da sola. Con 2 soli vivi va vietata. Lo spettro che ha maledetto non
  scommette sulla sua vittima. Due revisori: "chi è spacciato fa da arbitro" è frustrante; proposta alternativa:
  prezzo "scendi a 1 candela" invece della morte (l'utente aveva scelto la morte).

## Strategia (revisore 1)
- Oggi i patti sono più FORTI che STRATEGICI ("sempre il migliore" e "mai" vincono quasi uguale).
- Proposta principale: **patti dormienti** (come Coup): il dono non arriva subito, lo attivi tu come mossa segreta
  in un giro a scelta; il prezzo parte all'attivazione. Nasce il bluff e conta il momento.
- Cuore: prezzo troppo duro e conviene solo per chiudere; prezzo per 3 giri invece che fino a fine manche.
- Mano nera: contrattacchi su di lei da 2 (rischio pari al guadagno).
- Banchetto: rubi solo a chi ha più candele di te, massimo 2.
- Cripta: puro caso; meglio che **il nome lo scelgano gli spettri** (a maggioranza; pari = caso).
- Foresta il migliore dei luoghi; cimitero buono ma serve un contatore visibile.

## Cosa rompe il gioco (revisore 2) - chiarimenti tecnici da fissare
- Dimezzamento prima del dono; candele perse sull'altare; Patto cieco non in coppia (4→2→3 costa poco).
- Un colpo spegne al massimo 2 candele: i raddoppi non si sommano (già così nel codice).
- Cuore ferma colpi e contrattacchi contro di lui, non i suoi contrattacchi; maledizione e orrori lo colpiscono.
- Ritorno dalla fossa: torna subito e la manche continua; se muoiono tutti insieme vince chi torna.
- Doni di più giocatori nello stesso giro: tutti insieme, sulle candele di partenza, prima dei colpi.
- Mano nera ha prezzo zero finché non esistono le abilità (o se l'abilità è già usata): costo anche 1 candela.
- Cimitero: conta ogni candela spenta, in qualunque modo.

## Emozione e chiarezza (revisore 3)
- Momenti forti: Maledizione, Ritorno, Banchetto, Cuore; Cripta e Foresta. Deboli: Mano nera, Patto cieco, Cimitero
  ("dall'ultimo risveglio" non si ricorda: meglio "i morti prendono chi ha ucciso per ultimo").
- Due patti = dimezzare è un calcolo: meglio "il secondo patto costa 1 candela che brucia sull'altare".
- Quando un patto si rivela: tutto si ferma 1,5 s, il Custode dice il nome, appare il segno vero sul corpo.
- Spettri: vedono tutti i patti; una volta a manche posano una "mano fredda" su un vivo (verità o bugia).
- Idee "wow": duello finale cerimoniale (ultima catena spezzata, buio, il Custode offre a entrambi un ultimo patto
  pubblico); l'ultima candela (primo piano, battito); il patto spezzato (colpire chi rivela il patto in quel giro
  ruba il prezzo).
