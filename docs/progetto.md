# PROGETTO (nome provvisorio): documento di progetto

Approvato dall'utente il 15 ottobre 2026. È il riferimento per regole, personaggi, scenari e piano.
Le voci segnate **(da provare)** si decidono con il simulatore; quelle **(da definire)** con l'utente.
Le scelte creative (personaggi, aspetto, scenari, nome) restano dell'utente.

## L'idea
Quattro campioni fantasy vengono trascinati in un luogo maledetto, sempre diverso, e si affrontano attorno
a un cerchio rituale. Ogni giro tutti scelgono in segreto chi attaccare o da chi difendersi, poi si rivela
tutto insieme. L'ultimo rimasto in vita vince.

- **Tono:** cupo e teso: luci di candela, ombre, paura.
- **Modalità:** online con gli amici e anche da soli, contro avversari controllati dal computer.
- **Durata:** 10-15 minuti a partita.
- **Ispirazioni:** la tensione di Buckshot Roulette, le classi con abilità proprie di Hearthstone, l'atmosfera
  dei soulslike. Deve restare diverso da Liar's Bar.

## Personaggi
All'inizio della partita ognuno sceglie il suo personaggio. Ogni classe ha un'abilità speciale usabile
**una sola volta per partita**; un simbolo acceso accanto al personaggio mostra a tutti se è ancora disponibile.

**Al lancio, quattro classi:**

| Classe | Abilità speciale (una volta per partita) |
|---|---|
| Cavaliere | *Giuramento*: in quel giro nessuno può fargli male; chi lo attacca viene respinto e diventa stanco. Se nessuno lo attacca, è sprecata e il cavaliere diventa stanco. |
| Strega | *Occhio della strega*: vede la scelta di un avversario prima di confermare la propria. |
| Elfo arciere | *Freccia doppia*: attacca due avversari nello stesso giro. |
| Domatore di draghi | *Soffio del drago*: il drago esce e sputa fiamme su tutti gli avversari; chi si stava difendendo dal domatore si salva e lo contrattacca, come contro chiunque (scelto il 15/10; punto da rifinire). |

**Dopo, con aggiornamenti:** stregone, negromante, barbaro, assassina dell'ombra, paladino, druido. Le loro
abilità vanno riprogettate con queste regole (da definire).

## Come si gioca un giro
1. Il **Custode** scopre un **Presagio**: una carta che cambia le regole solo per quel giro.
2. Tutti scelgono **in segreto** una mossa:
   - **attaccare** un avversario;
   - **difendersi da** un avversario (si nomina la persona, non un tipo di difesa);
   - usare la propria **abilità speciale**, se non è già stata usata.
   - **riaccendere una candela**, solo con 2 candele o meno: riesce se in quel giro nessuno ti attacca.
3. **Rivelazione contemporanea**, poi si risolve:

| Cosa succede | Risultato |
|---|---|
| Attacchi qualcuno che non si difende da te | lui perde una candela |
| Attacchi qualcuno che si difende proprio da te | contrattacco: perdi tu una candela |
| Due giocatori si attaccano a vicenda | perdono una candela entrambi |
| Ti attaccano in due e ti difendi da uno solo | il secondo ti colpisce |
| Ti difendi da qualcuno che non ti attacca | diventi **stanco** |

**Stanchezza** (opzione B, scelta dall'utente): chi è stanco nel giro successivo non può difendersi e deve
attaccare. Un simbolo sopra il personaggio lo mostra a tutti. L'opzione A (mezza candela) resta solo come
confronto nel simulatore.

**Iniziativa** (provata il 15/10, elimina le manche senza vincitore: dal 20-25% allo 0%): dopo la
rivelazione il Custode estrae a caso l'ordine in cui si risolvono i colpi (proposta dell'utente: l'ordine
**non si conosce mentre si sceglie**, è più crudele). Chi muore prima del suo turno non colpisce più: due
giocatori non possono uccidersi a vicenda e il cerchio non resta mai vuoto. Ira del Custode e Luna nera non
spengono mai l'ultima candela dell'ultimo vivo. Mostrare l'ordine prima o dopo cambia pochissimo i numeri
(durata, equilibrio, strategie fisse).

**Il duello finale (problema trovato il 15/10).** Quando restano in due, difendersi è sempre meglio che
attaccare: se l'altro attacca lo contrattacchi, se si difende anche lui non succede niente. Nei giri liberi
del duello i bot si difendono entrambi l'80-86% delle volte, poi sono stanchi e devono attaccarsi per forza:
il duello diventa un'altalena meccanica (difesa-difesa, attacco-attacco) decisa dalle candele rimaste.

**"Riaccendi una candela"** (approvata dall'utente il 15/10, solo con 2 candele o meno): una quarta mossa. Se in quel giro nessuno ti
attacca, riaccendi una candela; si può fare solo con 2 candele o meno. Nel duello nasce un cerchio come
carta-forbice-sasso: l'attacco batte chi riaccende, chi riaccende batte chi si difende (che resta anche
stanco), la difesa batte l'attacco. Con 4 candele: 12,9 minuti, classi fra 24% e 27% (le più equilibrate
finora), nel duello nessuna coppia di mosse supera il 27%, attacca sempre 1,9%, difendi sempre 1,1%,
principiante 23,6%; tempo da morti 35% (era 31%). Varianti scartate: riaccendere senza limite (16 minuti),
fino a 3 con 5 candele (14,6 minuti), fino a 2 con 5 candele (il duello torna a difesa-difesa al 54%).

## Partita: tre manche a punti (provato il 15/10)
- Una partita = **3 manche**, come in Buckshot Roulette. Ogni manche si gioca in quattro con **4 candele**
  ciascuno, finché ne resta uno: c'è sempre un vincitore della manche.
- **Punti per piazzamento**: ultimo vivo 3, secondo 2, terzo 1, primo a morire 0. **La terza manche vale
  doppio.** Vince la partita chi ha più punti; a pari punti, chi si è piazzato meglio nella terza manche.
- Le abilità speciali restano **una volta per partita** (non per manche): scegliere in quale manche usarle è
  parte della strategia.
- Risultati (2.000 partite fra bot per variante): durata 11-13 minuti; classi fra 21% e 29% di vittorie;
  nessuna partita già decisa prima della terza manche; nel 64-68% vince chi non ha vinto la prima manche.
  Alternative scartate: eliminazione a ogni manche (chi esce guarda per il 44% del tempo, elfo al 39%),
  "chi vince 2 manche" (in 37 partite su 100 tre vincitori diversi e serve uno spareggio).

## Morte e spettri
- Chi perde tutte le candele muore per il resto della manche e diventa **spettro**.
- Lo spettro **non influenza il gioco dei vivi** (scelta dell'utente il 15/10, come in Buckshot Roulette):
  guarda e torna in gioco alla manche successiva.
- **Scommessa dello spettro** (provata, tenuta dall'utente): a ogni giro lo spettro indica un vivo che
  secondo lui perderà una candela; ogni due previsioni giuste guadagna 1 punto (al massimo 1 per manche).
  Chi è morto ha sempre una scelta da fare e una possibilità di rimonta (chi muore primo nella prima manche
  vince il 19% invece del 14%).
- Idee scartate: spettro che spegne o protegge una candela, spettro che spia una scelta. Tempo passato da
  morti: circa un terzo della partita, da rivalutare con persone vere.

## Il Custode e i Presagi
Il **Custode del Cerchio** è il padrone di casa: commenta, deride. Il caso decide le regole del giro, le
scelte restano dei giocatori. Il Presagio esce a metà dei giri: le carte cadono nel cerchio e il Custode ne
estrae una. Presagi "che danno fastidio" (richiesta dell'utente, 15/10):
- **Notte di sangue:** nessuno può difendersi né riaccendere, tutti attaccano.
- **Sangue doppio:** ogni colpo e ogni contrattacco spegne 2 candele.
- **Scambio:** chi ha più candele e chi ne ha meno se le scambiano.
- **Silenzio:** niente carte né abilità in questo giro.
- **Tributo:** chi ha più candele ne offre una all'altare.
- **Ira del Custode:** se nessuno sanguina in questo giro, tutti perdono una candela.
Scartati: Luna nera, Patto del Custode, Tregua (poco decisivi).

## Le carte del Custode (approvate come idea il 15/10, in prova)
A inizio manche ognuno riceve **3 carte coperte** (mazzo con due copie di ogni carta). Se ne gioca al massimo
una per giro, **coperta, insieme alla mossa**: si scopre alla rivelazione, prima dei colpi. Tutti vedono
quante carte hai, non quali (differenza voluta con gli oggetti a viso aperto di Buckshot Roulette).
Specchio, Lama doppia, Catena, Patto di sangue (il Custode trattiene 1 candela), Fiamma rubata, Ultimo
respiro, Ombra, Furto, Maledizione, Sete: testi in `scripts/cerchio/testi.gd`.

**Altare:** al centro del cerchio. Ogni candela spenta porta la sua fiamma sull'altare; riaccendere prende
una fiamma da lì (altare vuoto = non si riaccende).

Prova (2.000 partite, 4 candele): 13,8 minuti; classi 24-26%; chi ha in mano una carta vince la manche fra il
23% e il 29% (nessuna carta dominante; il Patto senza prezzo arrivava al 32-34%); il principiante scende dal
21% al 15% (saper giocare conta di più); strategie fisse sotto il 2%. L'altare con una fiamma per volta
quasi non cambia i numeri (raramente resta vuoto); "chi riaccende prende tutte le fiamme" scartato: partite
da 17-25 minuti.

## Combattimento base: verifiche del 18/10/2026 (report sul Desktop dell'utente)
Su consiglio di Codex e ChatGPT si sono fermate le novità e verificato il combattimento base (attacco, difesa
nominativa, riaccensione). Con avversari del computer "furbi" (ricordano le mosse e non si fanno leggere) il
duello delle regole attuali funziona: 4,3 giri, mosse 34/31/35%, scelte obbligate 13%; l'ordine casuale cambia
il vincitore nell'1% delle manche. Scartate: penalità per la difesa a vuoto nel duello (rompe la difesa con
giocatori bravi), riaccendere con 3 candele nel duello (duelli più lunghi). Ordine visibile che ruota: stessi
numeri, scelta di sensazione (non decisa).
Applicato nel gioco (via libera dell'utente): **stanchezza giusta** (chi si difende da chi aveva scelto di
attaccarlo non è stanco, anche se l'attaccante muore prima; `tests/prova_stanchezza.gd`) e **avversari
Adattivi** come difficoltà selezionabile (Audio e schermo > Avversari, oppure `--difficolta=1`); i Normali
restano. Confronto con le regole di oggi: `tests/sim_difficolta.gd` (senza carte: un Adattivo contro tre Normali
vince il 31%, un Normale contro tre Adattivi il 19%).
Poi (decisione dell'utente, 18/10): **ordine dei colpi visibile prima delle scelte, a rotazione** (il primo della
manche è estratto, poi il primo posto passa al vivo successivo; riga "Ordine dei colpi" sopra la frase di aiuto;
`tests/prova_ordine.gd`). Gli Adattivi ne tengono conto (con 1 candela a testa attaccano l'80% se colpiscono per
primi, quasi mai se per secondi). **Carte: a parità il bersaglio si estrae a caso** (prima era sempre il posto del
giocatore umano, che vinceva il 21%; ora 25,6%). Con le regole del gioco di oggi: Adattivo contro tre Normali 27,9%,
Normale contro tre Adattivi 22,8%. Interfaccia: pulsanti tondi, anteprima delle carte curata, niente scheda sopra i
campioni, scelta "Avversari" nel menu.

## Regole nuove: Patti e orrori dei luoghi (proposta del 17/10/2026, provata nel simulatore)
Decisione dell'utente: troppe regole. Si tolgono le **carte del Custode** e i **Presagi**; restano mosse,
stanchezza, ordine a caso, altare, tre manche a punti, spettri. Le classi attuali non si considerano (saranno
sostituite). Prova: `tests/sim_patti.gd` (1.000 partite per variante, nessuna abilità di classe).

**Patti del Custode** (decisi dall'utente il 17-18/10). Il giro dopo la prima morte di ogni manche il
Custode mostra a **ognuno, in segreto, 2 patti estratti a caso** (non in base a chi sta peggio). Se ne
prende uno, nessuno o **tutti e due**: con due le candele si **dimezzano** (per difetto; servono almeno 2
candele). Il dono arriva subito, il prezzo dura fino a fine manche. **Gli altri non sanno quali patti hai
preso** finché l'effetto non si vede (candele che si riaccendono o rubate, un colpo che ti attraversa, un
colpo da 2, il ritorno dalla morte, la morte per maledizione): si può bluffare.

| Patto | Dono | Prezzo |
|---|---|---|
| Il patto cieco | torni fino a 3 candele (+2 al massimo) | non puoi più difenderti |
| La mano nera | ogni tuo colpo spegne 2 candele | non puoi più usare l'abilità (mostrato solo a chi ce l'ha ancora) |
| Cuore di cenere | per 2 giri nessuno può colpirti | poi la tua mossa si vede prima che gli altri scelgano |
| Il banchetto | rubi 1 candela a ogni avversario (che ne abbia più di 1) | ogni colpo su di te spegne 2 candele |
| Ritorno dalla fossa | quando muori torni in vita con 1 candela | da non morto puoi solo attaccare |
| L'ultima maledizione | maledici un avversario: perde subito 2 candele e i colpi su di lui spengono 2 fino a fine manche | muori tu, subito |

Prova (`tests/sim_patti.gd`, 1.000 partite per variante, accettazione a caso per confrontare sì e no nella
stessa situazione): prendere un patto rende fra +0,06 e +0,14 punti a manche per cinque patti (il patto
cieco era +0,31 finché i bot non vedevano le candele riaccese: corretto); l'ultima maledizione è la vendetta
di chi è spacciato; prendere **due patti** rende -0,15 (azzardo, non conviene sempre). Strategie fisse:
"prendi sempre il migliore" 22-23%, "mai patti" 18-24%, "sempre due" 15-22%: nessuna scelta fissa conviene.
Mostrati al 3° giro invece che dopo la prima morte: più patti (12 a partita invece di 9), partite di 13 minuti.
Scartati: Anima (punti doppi o zero: i punti non interessano all'utente), patto offerto a chi sta peggio.

**Orrori dei luoghi.** Ogni 3 giri il luogo colpisce, annunciato il giro prima (ululato, campana, voce,
scricchiolio); toglie 1 candela, mai l'ultima dell'ultimo vivo:
- **Foresta, la bestia:** prende chi si è nascosto (difesa o candela) invece di combattere.
- **Cimitero, i morti:** si alzano contro chi ha spento più candele dall'ultimo risveglio.
- **Cripta, il cancello:** chiama un nome; al giro dopo ogni colpo su di lui spegne 2 candele.
- **Lago, il ghiaccio:** cede sotto chi ha più candele (non sotto chi ne ha una sola).

Risultati (con patti): durata 12-13 minuti con un luogo (16 senza nulla), duello finale da 14 a 8-11 giri,
principiante 15-21%, "attacca sempre" e "difendi sempre" sotto il 7,5%, "accetta sempre" 22-24%, "rifiuta
sempre" 16-21%, rimonte 62-68%, tempo da morti 34-36%.

**Idea dell'utente (17/10), da fare nel gioco:** l'altare reagisce: a ogni candela spenta strattona le catene
come per liberarsi; a ogni morte una catena si spezza (quattro catene, quattro campioni).

## Scenari
Ogni partita in un luogo diverso; ogni luogo ha un suo effetto sulle regole (**da definire**).
Luoghi scelti dall'utente (16/10/2026), tutti di notte, con altare a gradini, falò e cerchio di rune al centro:
- **La foresta cupa** (approvata): pini neri, sottobosco, colline boscose tutto attorno, braci e fuochi fatui.
- **Il cimitero dimenticato** (approvato): lapidi, mausoleo, cancello, pioggia con fulmini e tuoni.
- **La cripta sepolta** (16/10, al posto della palude): sala rotonda a volta con un'apertura da cui scende
  la luna, otto colonne con torce, portone, cancello sul buio, sarcofagi, statue, loculi con vasi e busti.
- **Il lago ghiacciato** (rifinito il 16/10): ghiaccio con crepe, creste di lastre, nave intrappolata,
  scogliere e montagne di neve, alberi morti innevati, nevicata con folate di vento.
Scartati dall'utente: castello (brutto), palude (sostituita), qualsiasi stile cartone animato.

## Presentazione e animazioni
- Personaggi **in piedi in posizioni fisse** attorno al cerchio: si gioca con la testa come seduti.
- **I personaggi si muovono a ogni mossa, non solo con le abilità speciali** (richiesta dell'utente): ogni
  attacco ha la sua animazione (spada, maledizione, freccia, comando al drago), e così difesa, colpo subito,
  contrattacco, stanchezza, morte e diventare spettro. Animazioni minime per classe: attesa, attacco, difesa,
  colpo subito, contrattacco, stanco, morte, abilità speciale.
- La **rivelazione** è il momento clou: rallentatore e fermo immagine quando un contrattacco riesce (skill
  game-feel); inquadrature d'azione (skill camera-systems).

## Modelli di partenza (da valutare, non ancora scaricati)
Catalogo di Codex: `Documenti\Codex\2026-10-14\h\outputs\CATALOGO-FANTASY-GRATUITO.md`. Tutti CC BY 4.0
(citare autore, link, licenza e modifiche). Lo scaricamento da Sketchfab richiede l'account dell'utente.
- Drago europeo (Regina Cachoa): animazioni dichiarate, per il domatore di draghi.
- Elfa guerriera (Los Bionicos): per l'elfo arciere; controllare componenti di terzi.
- Mago oscuro Shadowkin (Ferocious Industries): stregone/strega.
- Orco low-poly (Riltariki): 9 animazioni dichiarate; barbaro futuro.
- Necromante Voidbound (ItsKrish7): 1,7 milioni di triangoli, solo riferimento visivo.
Regola: una prova con un solo modello prima di tutti gli altri; originali conservati, si lavora su copie.

## Prototipo (simulatori)
- Regole: `scripts/cerchio/cerchio_rules.gd`; bot: `scripts/cerchio/cerchio_bot.gd`.
- `tests/sim_cerchio.gd`: una manche, varianti di candele, stanchezza, Presagi, strategie dominanti.
- `tests/sim_cerchio_manche.gd`: formati a tre manche, iniziativa (argomenti `rifinitura`, `spettri`).
- Strategie fisse perdono sempre (attacca sempre 3-4%, difendi sempre 5-7%). **Da tenere d'occhio:** un bot
  "principiante" (scelte molto più casuali) vince ancora il 23% delle partite a punti: l'abilità conta
  nella singola manche (11% per il principiante) ma su tre manche il caso pesa molto. Va bene per giocare
  con gli amici; da rivalutare con persone vere. Elfo primo nell'iniziativa e soffio del drago per ultimo
  non hanno cambiato l'equilibrio del formato a punti: non adottati.

## Piano
1. ~~Prototipo nel simulatore~~ (fatto il 15/10): durata, equilibrio, pareggi, formato a manche, spettri.
2. ~~Prototipo giocabile con forme semplici~~ (fatto il 15/10, vedi sotto).
3. Personaggi e animazioni dai modelli gratuiti, con le skill Blender e Godot.
4. Online con gli amici (da riscrivere per queste regole).
5. Prima uscita piccola (4 classi, 2 scenari), prezzo basso e demo gratuita; poi classi e scenari nuovi con
   aggiornamenti.

## Prototipo giocabile (15/10)
- Tu contro tre avversari del computer, 3 manche, nel luogo scelto nel menu (o a caso) fra i quattro sopra.
- Campioni fatti di forme semplici, ognuno con il suo colore e il suo oggetto (spada e scudo, cappello e
  bastone, arco, drago sulla spalla). Si muovono a ogni mossa: scatto d'attacco, freccia o maledizione che
  vola, scudo verso chi si teme, contrattacco, colpo subito, aura del giuramento, soffio del drago, morte e
  spettro.
- Istruzioni nel gioco: "Come si gioca" nel menu e il pulsante "? Regole" sempre presente (10 pagine);
  suggerimento a ogni scelta e racconto dei colpi a destra.
- File: `scripts/game.gd` (svolgimento), `scripts/world/arena.gd`, `scripts/world/figura.gd`,
  `scripts/ui/hud.gd`, `scripts/cerchio/testi.gd` (tutti i testi), `scripts/config.gd` (numeri).
- Prove automatiche: `-- --auto` (il computer gioca anche per te), `-- --clic` (preme pulsanti a caso come
  un giocatore), `--veloce=0.05`, `--foto=CARTELLA`, `--esci`.
- Mancano: audio dedicato (per ora i suoni generati già presenti), online, effetti degli scenari, nome.

## Cosa si è tenuto dal lavoro precedente
Candele e luci (`candle.gd`, `flicker_light.gd`), fabbrica di materiali e geometria (`mats.gd`, `geo.gd`),
shader, suoni generati (`tools/make_audio.py`, `audio/`), caratteri, PROGETTO Live per Blender. Il resto è
archiviato in `../dismissed/`.

## Mercato (ricerca del 15/10/2026)
Buckshot Roulette oltre 8 milioni di copie; Liar's Bar 2-5 milioni (stime) e 113.000 giocatori contemporanei.
Rischi: complessità (deve capirsi in 30 secondi e in diretta), quantità di animazioni, concorrenza dei giochi
"da tavolo con amici", bilanciamento delle classi. Nessun gioco noto con la stessa meccanica centrale
(verifica da approfondire prima dell'annuncio).

## Licenze (regola dell'utente, 17/10/2026)
Il gioco sarà venduto: ogni cosa presa online (modelli, texture, suoni, caratteri, codice) deve avere una
licenza che permette la vendita (CC0, CC BY citando l'autore, OFL, MIT), e una provenienza sicura (niente
pacchetti con immagini prese chissà dove). Prima di usarla: riga in `assets/scenari/FONTI.txt` e in
`CREDITI.txt` (pulsante "Riconoscimenti" nel menu); le licenze complete vanno in `build/LICENZE`
(`tools/licenze.gd`). Vale anche per i personaggi in arrivo da Codex (Sketchfab CC BY: autore, link, modifiche).

## Nuova direzione: Le catene dell'altare (decisa dall'utente il 20/10/2026)
Regole complete in `docs/catene_altare.md` (questo documento resta com'era: il combattimento a candele-vita
non è cancellato). In breve: 5 catene a testa, candele come orologio che accelera, carte del Custode anonime,
un sabotatore segreto che cambia a ogni manche e può passare il testimone, voto solo con la carta Voto,
"ultimo respiro" di 30 secondi, chi ha più catene prende fuoco e vola via. Pensato soprattutto per il
multigiocatore. Prima prova: `tests/sim_catene.gd`.
