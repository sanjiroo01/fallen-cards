# LE CATENE DELL'ALTARE — regole decise dall'utente (20/10/2026)

Nuova direzione del gioco, decisa dall'utente il 20/10/2026 dopo la discussione con Claude e Codex
(cartella `Desktop\ai team`: POSTA e PROGETTI\altare-design). Sostituisce come proposta il combattimento a
candele-vita (che resta nel codice e in `progetto.md`: niente è stato cancellato). Stato: **da provare nel
simulatore** (`tests/sim_catene.gd`), poi in una versione giocabile contro il computer.

Ispirazione dichiarata dall'utente: "Saw l'enigmista": devi liberarti o muori. Pensato **soprattutto per il
multigiocatore** (4 persone in rete); il computer riempie i posti vuoti e serve alle prove.

**In una frase:** liberati dalle catene prima degli altri, ma uno di voi lavora per l'altare.

## Materiale
- 4 campioni, ciascuno legato all'altare da **5 catene** (anelli = catene: un'unica unità).
- **12 candele** = l'orologio (numeri da tarare col simulatore).
- Mazzo del Custode a 6 carte diverse (proporzioni da tarare). Si vede **quante carte ci sono in gioco in
  totale**, non quante ne ha ciascuno.

## Inizio di ogni manche (3 manche)
- Tutti a 5 catene, candele riaccese.
- Il Custode sceglie **in segreto un sabotatore** (cambia a ogni manche). Solo lui lo sa.

## Un turno
1. **Pesca:** ognuno ancora legato sceglie 1 carta fra 3 coperte (non vede cosa prende). Massimo 3 in mano:
   se ne ha 4, ne brucia una nel fuoco a sua scelta (il totale cala senza effetti visibili: copre anche i
   cambi di testimone).
2. **Scelta segreta:** ognuno decide **se tirare la catena o no** e può **giocare al massimo 1 carta**, su
   chiunque, anche su sé stesso.
3. **Esecuzione nell'ordine dei colpi** (visibile, a rotazione, come nel gioco attuale). Gli effetti delle
   carte sono **anonimi**: si vede cosa succede, non chi l'ha fatto. Si vede invece chi ha tirato e chi no.
4. **L'altare:** se **tutti i legati tirano**, l'altare resta fermo e la candela non si spegne. Chi non tira
   "si fa portare" dagli altri e può attirare sospetti (ma può anche farlo apposta).
5. **Candele:** se ne spegne 1 per turno; **+1 dopo la prima liberazione**; **+1 dopo la scoperta del
   sabotatore** (fino a 3 per turno).

## Le 6 carte (su chiunque, anche su sé stessi)
1. **Togli un anello** (−1 catena) — la più comune.
2. **Aggiungi un anello** (+1 catena) — la più comune.
3. **Aggiungi due anelli** (+2 catene) — rara.
4. **Salta un turno** — il bersaglio perde la sua prossima mossa (non tira e non gioca carte).
5. **Voto** — si vota SOLO quando esce questa carta. Votano tutti e 4 (anche il sabotatore e chi è libero).
   Se la **maggioranza** indovina, il sabotatore è **scoperto**: prende **+2 catene** (da tarare), le sue
   carte "Passa il testimone" bruciano e non può più passare il ruolo; il tempo accelera. Se si sbaglia o
   non c'è maggioranza **non succede nulla** (ma si sa che quella persona non era il sabotatore).
6. **Passa il testimone** — solo il sabotatore può usarla: il ruolo passa a un altro legato, in segreto.
   Per gli altri è una carta inutile, ma nessuno sa chi la tiene. **Punto cardine:** non si sa mai quando il
   ruolo è passato; lo si intuisce solo se il numero di carte cala senza effetti e senza votazioni.

## Il sabotatore
- Non può **mai** essere il **primo** a liberarsi.
- Può continuare a sabotare anche da scoperto (gli altri useranno "Salta un turno" contro di lui).
- Chi passa il testimone torna innocente; i punti da sabotatore vanno a chi ha il ruolo a fine manche.

## L'ultimo respiro (fine del tempo)
Quando resta l'ultima candela l'altare si agita sempre più forte, suono insopportabile, **conto alla
rovescia di 30 secondi**: niente più turni, ognuno può giocare subito tutte le carte che ha, il più in fretta
possibile. A zero il fuoco diventa blu. (Ogni turno normale ha anche un tempo per scegliere, es. 20 s.)

## Fine della manche
- Finisce allo scadere del tempo, oppure appena **resta un solo legato**.
- **Chi ha più catene prende fuoco e vola via mentre brucia** (a parità bruciano tutti i pari). Scena:
  l'altare tira verso il cielo, i legati si aggrappano al suolo, le catene saltano una a una.

## Punti
| | si salva | brucia |
|---|---|---|
| innocente | 2 se libero, 1 se ancora legato | 0 |
| sabotatore mai scoperto | **3** | **1** (sempre, anche se brucia insieme ad altri) |
| sabotatore scoperto | come un innocente | 0 |

Dopo 3 manche vince chi ha più punti.

## Ancora da decidere / tarare (simulatore)
Numero di candele e catene, proporzioni del mazzo, catene al sabotatore scoperto, frequenza del Voto,
maggioranza necessaria, cosa succede se il sabotatore a 1 catena riceve "Togli un anello" prima che qualcuno
sia libero (l'effetto si perde: è un indizio involontario). Campioni diversi solo nell'aspetto delle carte.

## Risultati del simulatore (20/10/2026, sera) — `tests/sim_catene.gd`
Bot che sospettano (chi non tira, "togli" senza effetto, carte sparite senza effetti), mentono al voto, passano il
testimone quando si sentono osservati, fingono passaggi da innocenti. 1.000-2.000 manche per prova.
- **Con i numeri iniziali** (5 catene, togli e aggiungi quasi pari): nessuno si libera quasi mai (0,01 liberati a
  manche), sabotatore 1,57 punti contro 0,72 di un innocente. Da correggere.
- **Correzioni provate e utili:** 4 catene; mazzo con "Togli" molto più comune di "Aggiungi" (circa 45% / 13%);
  voto vinto da chi ha più voti con almeno 2 e senza pari (con 3 su 4 il sabotatore non veniva quasi mai preso).
  Risultato: 1,7 liberati a manche, prima liberazione al turno ~8,5, ~12 turni e ~5 minuti a manche (~16 a
  partita), 80% delle manche finisce con l'ultimo respiro, sabotatore scoperto 34%.
- **Punti del sabotatore:** con 3 punti se si salva prende 1,82 a manche contro 1,21 di un innocente (troppo);
  con **2 punti** prende 1,36 contro 1,21 (equilibrato, poco sopra perché il ruolo è più difficile). Decide l'utente.
- **Strategie:** nessuna domina. "Tira sempre" va un po' meglio della media (1,39 contro 1,27), "non tirare mai"
  peggio (0,96), accumulare carte per l'ultimo respiro è un errore (0,46), sabotatore ingenuo 0,82.
- **Provata e scartata (per ora):** "o tiri o giochi una carta": voti più precisi ma l'altare non resta quasi mai
  fermo e i voti calano. Meglio la regola dell'utente (peschi sempre, tiri o no, e puoi giocare una carta).
- Limiti: i bot non parlano; con persone vere la scoperta del sabotatore sarà diversa. Le durate sono stime
  (25 secondi a turno + 30 dell'ultimo respiro).

## Decisioni dell'utente e prove del 20/10/2026 (tarda sera)
- **Punti del sabotatore mai scoperto:** 2 se si salva (non più 3), 1 se brucia. Approvato dall'utente.
- **Voto:** resta **3 voti su 4**. Motivo dell'utente: con persone vere che parlano fra loro (chat vocale) o il
  tavolo si coalizza o il sabotatore vince; un 2 contro 1 contro 1 non deve bastare.
- **"Includi il Guardiano"** (idea dell'utente): una volta per manche, quando a un voto manca un solo voto per
  arrivare a 3, si può chiamare il Guardiano: aggiunge un voto che al 50% indica il vero sabotatore e al 50% un
  innocente a caso. Da decidere chi preme il tasto (proposta di Claude: chiunque, in modo anonimo).
- Simulatore (2.000 manche, 4 catene, mazzo tarato, 2 punti al sabotatore; nuove manopole `guardiano=1` e
  `parlano=1`, quest'ultima imita un tavolo che si mette d'accordo sul più sospettato):

  | voto | sabotatore scoperto | punti sabotatore / innocente |
  |---|---|---|
  | più votato con almeno 2 | 34% | 1,36 / 1,21 |
  | 3 su 4 | 25% | 1,44 / 1,22 |
  | 3 su 4 + Guardiano | 32-34% (Guardiano usato nel 22-35% delle manche) | 1,37 / 1,21 |

  Il Guardiano riporta la scoperta allo stesso livello della regola dei 2 voti, senza il difetto del 2-1-1.
  Il "tavolo che parla" dei bot cambia poco perché i loro sospetti nascono già dalle stesse informazioni pubbliche:
  il vero effetto della chiacchiera fra persone resta da misurare con il multigiocatore.

## Decisioni dell'utente del 21/10/2026 (notte) e prove
- **"Salta un turno" non si somma:** se ne arrivano più nello stesso turno vale solo il primo (già così).
- **Chi si è liberato guarda** (e vota): va bene così per ora.
- **Testimone:** chi lo passa non sa a chi va (destinatario a caso fra gli altri legati).
- **Ordine delle carte:** scritta "Le carte si mescolano e partiranno in ordine casuale", scena delle carte
  mescolate, il Guardiano sceglie un campione da cui si parte; poi una carta per volta nell'ordine dei posti
  (es. cavaliere, strega, elfo, drago), ma la carta che esce su ognuno **non è quella che ha giocato**.
- **Guardiano a maggioranza:** non lo decide uno solo; almeno 2 giocatori devono chiederlo. Una volta a manche.
- Da rivedere: i punti di tutti, e un motivo forte per cercare il sabotatore.

Prove (2.000 manche, 4 catene, mazzo tarato, 3 voti su 4, bot che "parlano"):
- Guardiano chiesto alla cieca insieme al voto: chiamato nel 75% delle manche ma scoperta invariata (25%): si spreca.
  Guardiano chiesto **dopo aver visto i voti, solo se ne manca uno** (almeno 2 sì): chiamato nel 26%, scoperta 28%,
  come il Guardiano automatico. Proposta: si vota, si mostrano i voti, e se ne manca uno si decide sul Guardiano.
- Proposta punti: primo a liberarsi 3, altri liberi 2, legati salvi 1, bruciati 0; sabotatore mai scoperto 2 se si
  salva (3 = 1,93 contro 1,59: troppo con i bot), 1 se brucia; scoperto come un innocente ma 0 se brucia.
  Esito: sabotatore 1,42, innocente 1,59.
- Premio per la scoperta (proposta): ogni innocente legato che ha votato giusto perde subito 1 catena; al posto della
  candela in più a turno (che punisce soprattutto gli innocenti legati; nei punti cambia poco: 1,56 contro 1,59).
- Regola proposta "l'ultima catena te la togli da solo": un "Togli" giocato da altri su chi ha 1 catena non ha
  effetto, per tutti. Così il sabotatore a 1 catena non si tradisce quando un altro gli toglie l'ultima.
- Limite noto: i bot indovinano solo il 16% dei voti; persone che parlano lo troveranno più spesso.

## Decisioni dell'utente del 21/10/2026 (seconda parte) e prove
- **Il sabotatore sabota, non scappa.** Pesca da un **mazzo suo** con sole carte per aggiungere anelli, fermare le
  persone e passare il testimone. **Può liberarsi per primo** (raro), ma allora il ruolo passa da solo a un altro
  legato e lui è **penalizzato nei punti**. Guadagna punti solo se fa bene il suo ruolo.
- **Scoprirlo non accelera il tempo:** lo blocca (niente più testimone) e gli dà +2 catene; poi gli altri devono
  farlo bruciare e pensare alla fuga.
- **Guardiano:** entra se almeno 2 persone lo chiedono (la richiesta "alla cieca" era un difetto dei bot).
- **Altare fermo** solo se tirano tutti i legati (già così).
- Punti: ancora da decidere.

Prove (2.000 manche; opzioni `mazzo_sab`, `sab_primo`, `punti_fuga`, `accelera=0`, `guardiano=3`):
- Mazzo del sabotatore con Aggiungi due e mazzo degli altri invariato: si liberano solo 0,5 a manche. Troppo forte.
- **Tarato:** sabotatore {Aggiungi 35, Salta 35, Testimone 30}; altri {Togli 50, Aggiungi 8, Aggiungi due 3,
  Salta 12, Voto 16, Testimone 12}. 1,57 liberati a manche, primo al turno 9, ~12 turni (~5,4 min), scoperta 30%,
  testimone passato 1,6 volte a manche, sabotatore brucia nel 57% e scappa per primo nel 4%.
- **Punti** primo libero 3, altri liberi 2, legati salvi 1, bruciati 0; sabotatore mai scoperto 3 se si salva, 1 se
  brucia, 0 se scappa per primo: sabotatore 1,53, innocente 1,58 (pari). Con 2 al sabotatore: 1,14.
- Strategie: nessuna domina (tira sempre 1,30; normale 1,26; aggressivo 1,21; non tira mai 1,19; accumula 0,83).
- Indizio nuovo da valutare: senza "Togli" nel suo mazzo, il sabotatore è quello a cui non si tolgono mai anelli.
- Risposta di Codex: `Desktop\ai team\POSTA\2026-10-21-0035-d9e1f401-codex.md`. Corretto nel simulatore: con il
  passaggio a caso chi cede il testimone non sa più a chi va. Effetto: scoperta 30% → **16%**, sabotatore più forte
  (con 3 punti: 1,83 contro 1,52).
- Punti del sabotatore proposti da Codex (opzione `sab_solo_zero=1`): mai scoperto 3 se si salva, 1 se brucia
  insieme a un innocente, **0 se brucia da solo**. Esito: **sabotatore 1,53, innocente 1,52** (pari). Con 2 punti:
  1,05. Rispetta l'idea dell'utente: guadagna solo se fa bene il suo ruolo.
- Dubbi aperti per l'utente: carte tenute al cambio di ruolo; due liberati nello stesso turno (chi prende 3);
  carte usabili nell'ultimo respiro; altare tenuto fermo all'infinito se tirano sempre tutti; l'indizio
  "a lui non si tolgono mai anelli" (per Codex è un sospetto, non una prova: si tiene e si osserva).

## Decisioni dell'utente del 21/10/2026 (terza parte) e prove
- **Sabotatore che si libera per primo:** 0 punti e il testimone passa da solo, **anche se era stato scoperto** (il
  nuovo sabotatore torna nascosto).
- **Carta nascosta:** il Guardiano aiuta il sabotatore con un **quarto "Togli un anello" nascosto**, fuori dal
  conteggio delle carte, per fingere di volersi liberare. Nel simulatore (`segreta=1`): uno per manche, passa con il
  ruolo se non usato (da confermare).
- **Due liberati nello stesso turno:** 3 punti a chi si libera prima nell'ordine delle carte. Accettato.
- **Altare fermo al massimo 2 turni di fila** (`fermo_max=2`). Accettato.
- **Seconda modalità "a eliminazione"** (idea dell'utente, `modalita=elimina`): chi viene condannato a maggioranza e
  non è il sabotatore è eliminato (brucia, 0 punti); il sabotatore resta nascosto.

| 2.000 manche | scoperta | innocenti eliminati | punti sabotatore / innocente |
|---|---|---|---|
| normale, senza carta nascosta | 16% | — | 1,53 / 1,52 |
| normale, con carta nascosta | 11% | — | 1,52 / 1,52 |
| a eliminazione, con carta nascosta | 8% | 0,41 a manche | 1,58 / 1,36 |
| a eliminazione, senza carta nascosta | 12% | 0,44 a manche | 1,57 / 1,33 |

Lettera 10 a Codex in POSTA (21/10 01:15).
- Risposta di Codex: `POSTA\2026-10-21-0120-e4a7b211-codex.md` (carta nascosta: una per manche, senza ricarica;
  eliminati che conservano il voto; errori del simulatore). Corretti nel simulatore: liberazione subito dopo ogni
  carta; carte del turno mescolate (`mescola=1`); il sabotatore già scoperto non può essere "eliminato" da un nuovo
  voto; il "tavolo che parla" non sa più chi è innocente; opzione `voto_morti` (eliminati che votano).

| 2.000 manche, dopo le correzioni (carta nascosta) | scoperta | eliminati | sabotatore / innocente |
|---|---|---|---|
| normale | 11% | — | 1,41 / 1,61 |
| a eliminazione, gli eliminati votano | 9% | 0,44 a manche | 1,42 / 1,43 |
| a eliminazione, gli eliminati non votano | 8% | 0,39 a manche | 1,47 / 1,44 |

## Decisioni dell'utente del 21/10/2026 (quarta parte) e prove
- **Chi si libera o viene eliminato ha finito:** non vota e non fa altro. **Votano solo i legati, a maggioranza**
  (4 legati → 3 voti, 3 → 2, 2 → 2); con la parità non succede nulla. Il Guardiano lo chiedono i legati.
- **Al passaggio del testimone il nuovo sabotatore NON tiene le sue carte.** Interpretazione di Claude da confermare:
  le carte si scambiano fra vecchio e nuovo sabotatore (`scambia_mani=1`), così il totale non cambia.
- **Ultimo respiro:** si giocano Togli, Aggiungi e anche **Salta** (il bersaglio non gioca più carte).
- **Carta nascosta:** "una sola per manche è poca e può far capire chi è?". Prove (2.000 manche, bot che notano
  quando compare un "Togli" in più rispetto alle carte giocate):
  - una per manche, senza accorgimenti: scoperta dal 18% al **27%** (il conteggio lo tradisce);
  - **quando la usa brucia anche una sua carta** (`brucia_con_segreta=1`): il conteggio cala come sempre, scoperta 12%;
  - una per manche: sabotatore 1,35 / innocente 1,62; due: 1,27 / 1,67;
  - **ricaricata ogni 4 turni** (se usata): **1,55 / 1,67**; a eliminazione **1,55 / 1,52**;
  - ricaricata ogni 3 turni: 1,73 / 1,67; a eliminazione 1,73 / 1,53 (troppo).

---------------------------------------------------------------------------------------------------------------------

# REGOLE DEFINITIVE (decise dall'utente il 21/10/2026)
Valgono queste; le sezioni sopra sono la storia delle prove. Sono i valori predefiniti di
`scripts/catene/catene_rules.gd` e del simulatore `tests/sim_catene.gd` (senza argomenti).

**Scopo:** sei legato all'altare. Liberati prima che si spengano le candele: chi resta legato con più catene prende
fuoco e vola via con l'altare. Uno di voi, in segreto, lavora per l'altare. 4 campioni, 3 manche.

1. **Inizio manche:** 4 catene a testa, 12 candele. Il Custode sceglie in segreto il sabotatore (cambia ogni manche).
2. **Ogni turno**, chi è legato pesca 1 carta fra 3 coperte (massimo 3 in mano; se sono 4 ne brucia una). A tutti si
   mostra solo il **totale** delle carte in gioco. Poi sceglie in segreto **se tirare la catena** e se giocare
   **una carta** su chiunque, anche su sé stesso.
3. **Le carte si mescolano:** scritta "Le carte si mescolano e partiranno in ordine casuale", il Guardiano sceglie da
   quale campione si parte e su ognuno esce una carta, che **non corrisponde a chi l'ha giocata**. Si vede chi ha
   tirato. Chi arriva a zero catene si libera subito.
4. **L'altare:** se **tutti i legati tirano** resta fermo e la candela non si spegne (al massimo **2 turni di fila**);
   basta uno che non tira e se ne spegne una. Dopo la prima liberazione se ne spegne **una in più** a ogni turno.
5. **Mazzo degli innocenti:** Togli un anello 50%, Voto 16%, Salta un turno 12%, Passa il testimone 12% (per loro
   inutile: copre il sabotatore), Aggiungi un anello 8%, Aggiungi due anelli 3%.
6. **Mazzo del sabotatore:** Aggiungi un anello 35%, Salta un turno 35%, Passa il testimone 30%. In più il **dono del
   Guardiano**: un "Togli un anello" **nascosto**, fuori dal conteggio; quando lo usa brucia anche una sua carta (il
   totale cala come sempre). Se l'ha usato, il Guardiano gliene ridà uno **ogni 3 turni**.
7. **Salta un turno:** il bersaglio perde la mossa seguente; più "Salta" nello stesso turno non si sommano.
8. **Voto** (solo quando esce la carta): votano **solo i legati**, a maggioranza (4 legati: 3 voti; 3 o 2 legati: 2
   voti); con la parità non succede nulla. **Guardiano:** se almeno 2 legati lo chiedono entra e aggiunge un voto,
   50% vero e 50% su un innocente a caso; una volta per manche.
   - Indovinato: il sabotatore è **scoperto**, prende **+2 catene**, le sue carte "Passa il testimone" bruciano e non
     può più passare il ruolo. Il tempo **non** accelera: da lì gli altri devono farlo bruciare e pensare alla fuga.
   - Sbagliato: non succede nulla (modalità normale) oppure l'innocente condannato è **eliminato** (modalità "a
     eliminazione", a scelta) e il sabotatore resta nascosto.
9. **Passa il testimone:** solo il sabotatore. Il ruolo va a un legato **a caso** (chi lo passa non sa a chi); le carte
   in mano si **scambiano** fra i due (il totale non cambia) e il dono del Guardiano passa con il ruolo.
10. **Il sabotatore non deve liberarsi:** se si libera per primo (anche da scoperto) prende 0 punti e il ruolo passa
    da solo a un altro legato, che torna nascosto.
11. **Chi si libera o viene eliminato ha finito:** non vota e non gioca più.
12. **Ultimo respiro:** all'ultima candela l'altare si agita, 30 secondi: si giocano subito fino a 3 carte fra Togli,
    Aggiungi e Salta (Salta ferma il bersaglio fino alla fine). A zero il fuoco diventa blu.
13. **Fine manche:** allo scadere o quando resta un solo legato. Fra i legati brucia chi ha più catene (a parità
    tutti i pari).

**Punti** (dopo 3 manche vince chi ne ha di più):

| | punti |
|---|---|
| primo a liberarsi (a parità nello stesso turno: chi si libera prima nell'ordine delle carte) | 3 |
| altri liberi | 2 |
| legato ma salvo | 1 |
| bruciato o eliminato | 0 |
| sabotatore mai scoperto che si salva | 3 |
| sabotatore mai scoperto che brucia insieme a un innocente | 1 |
| sabotatore che brucia da solo, o che si libera per primo | 0 |
| sabotatore scoperto | come un innocente (0 se brucia) |

**Simulatore** (2.000 manche, regole definitive): ~11 turni e ~5 minuti a manche (~15 a partita); 2,1 liberati a
manche, il primo verso il turno 8; 70% delle manche finisce con l'ultimo respiro; testimone passato 1,2 volte a
manche; sabotatore scoperto 8% (i bot non parlano davvero: con persone sarà di più). Punti: **sabotatore 1,73,
innocente 1,67**; a eliminazione 1,73 / 1,53. Strategie: tirare sempre 1,77, normale 1,67, aggressivo 1,60, non
tirare mai 1,43, accumulare carte per l'ultimo respiro 0,50. Il Guardiano fra i bot non serve quasi mai (votano tutti
uguale): andrà misurato con le persone.

## Modifiche del 21/10/2026 (pomeriggio, richiesta dell'utente: "così non mi sbrigo mai")
- **O tiri la catena O giochi una carta**, non tutte e due (`pull_or_card`).
- **Le carte del sabotatore Aggiungi e Salta colpiscono due campioni** (`sab_double`; nel turno si scelgono due
  bersagli, nel racconto il secondo colpo è segnato come "la stessa carta").
- **La carta segreta del Guardiano** si risolve per ultima: resta al centro del fuoco mentre le altre volano sui campioni.
- Simulatore (2.000 manche per variante, `tests/sim_catene.gd tira_o_carta=1 sab_doppio=1`): 9,4 turni a manche
  (erano 11,2); sabotatore 1,69 punti, innocente 1,40; sabotatore scoperto 16% (era 7%: il doppio colpo si nota);
  liberati 1,3 a manche. Solo "o tiri o giochi": 9,1 turni, 1,66 / 1,55. Solo il doppio colpo: 12,4 turni.
- **Nomi**: "Togli una catena", "Aggiungi una catena", "Aggiungi due catene" (prima "anello").
- **L'altare in partita** parte appoggiato a terra, senza catene al suolo, e sale a ogni candela spenta (fino a ~1,9 m
  all'ultima): le catene di ogni campione (una per catena) si tendono e lo trascinano verso il centro; a fine manche
  l'altare vola via con chi brucia e alla manche dopo riparte da terra.

## Da 4 a 8 giocatori e il tavolo di pietra (22/10/2026, richiesta dell'utente)
L'utente: "opzioni di gioco da 4 a 8 giocatori... fino a 4 lasciamo queste regole, poi un piano di gioco da 6 in su;
intorno all'altare un tavolo rotondo di pietra dove si giocano le carte; niente più altare che vola, le catene restano".
Si sceglie nel menu (Nuova partita > Al tavolo). Codice: `CateneRules.for_players(n)`; simulatore `giocatori=N`.

- **4 giocatori:** le regole definitive, invariate.
- **5 giocatori:** le stesse, ma il sabotatore mai scoperto che si salva prende **2** punti (con 3 vinceva troppo:
  1,99 contro 1,40).
- **Da 6 a 8 giocatori, "il piano dei due sabotatori":**
  - i sabotatori sono **due e si conoscono** (il complice è scritto nel riquadro e all'inizio della manche);
  - passando il testimone il ruolo non va mai al complice; il complice saprà chi è il nuovo;
  - le carte del sabotatore colpiscono **un solo** campione (col doppio colpo, in due, il tavolo non si liberava);
  - **14 candele**; la candela non si spegne se tirano tutti i legati **tranne uno**;
  - alla fine bruciano i **due più legati** (a parità anche chi è pari al secondo; con due soli legati ne brucia uno);
  - il voto scopre un sabotatore alla volta; sabotatore che si salva: **2** punti.
- **Simulatore** (1.500 manche, o tiri o giochi; da 4 a 5 col doppio colpo del sabotatore):

| al tavolo | turni | liberati | bruciati | sabotatore | innocente |
|---|---|---|---|---|---|
| 4 | 9,5 | 1,3 | 1,2 | 1,61 | 1,41 |
| 5 | 9,0 | 1,7 | 1,2 | 1,37 | 1,40 |
| 6 | 10,7 | 2,6 | 2,1 | 1,49 | 1,42 |
| 7 | 10,1 | 3,0 | 2,3 | 1,52 | 1,42 |
| 8 | 9,7 | 3,5 | 2,4 | 1,54 | 1,41 |

  Una partita di 3 manche dura ~13-15 minuti a ogni numero. Con le regole dei 4 senza ritocchi il sabotatore a 8
  prendeva 2,45 punti contro 1,45. Nota: da 6 in su i bot giocano poco la carta Voto (0,25 a manche: con più campioni
  i sospetti si diluiscono); con le persone che parlano sarà diverso, da misurare.
- **Scena:** l'altare sta a terra e non si muove più; attorno un tavolo ad anello di pietra (lastra di lastre
  consumate, basamento a blocchi, alto 86 cm). Le catene vanno dalla cintura agli **anelli bullonati al basamento**,
  davanti a ogni posto; pendono e toccano terra e non entrano mai nella pietra (prova: tests/prova_catene.gd).
  Le carte si mescolano scivolando sul piano e se ne posa una davanti a ogni campione. Chi brucia prende fuoco al suo
  posto, diventa carbone e resta accasciato contro il tavolo, in catene, fino alla manche dopo.
