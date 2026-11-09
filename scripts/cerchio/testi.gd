class_name Testi
extends RefCounted
## Tutti i testi del gioco: classi, Presagi, frasi del Custode e istruzioni.

const CLASSI := [
	{"nome": "Cavaliere", "articolo": "il Cavaliere", "da": "dal Cavaliere", "di": "del Cavaliere", "colore": Color(0.62, 0.7, 0.86),
		"abilita": "Giuramento",
		"desc_abilita": "Per questo giro nessuno può farti male: chi ti attacca viene respinto e diventa stanco. Se nessuno ti attacca, il giuramento è sprecato e sei tu a diventare stanco.",
		"motto": "Una lama, un giuramento."},
	{"nome": "Strega", "articolo": "la Strega", "da": "dalla Strega", "di": "della Strega", "colore": Color(0.66, 0.36, 0.86),
		"abilita": "Occhio della strega",
		"desc_abilita": "Scegli un avversario e guarda la sua mossa segreta prima di decidere la tua. Lui non saprà di essere stato spiato.",
		"motto": "Vedo quello che pensi."},
	{"nome": "Elfo arciere", "articolo": "l'Elfo", "da": "dall'Elfo", "di": "dell'Elfo", "colore": Color(0.42, 0.8, 0.46),
		"abilita": "Freccia doppia",
		"desc_abilita": "Attacchi due avversari nello stesso giro. Ognuno dei due può contrattaccarti, se si stava difendendo da te.",
		"motto": "Due frecce, due bersagli."},
	{"nome": "Domatore di draghi", "articolo": "il Domatore", "da": "dal Domatore", "di": "del Domatore", "colore": Color(0.95, 0.42, 0.18),
		"abilita": "Soffio del drago",
		"desc_abilita": "Il tuo drago sputa fuoco su tutti gli avversari. Chi si stava difendendo da te si salva e ti contrattacca.",
		"motto": "Il fuoco non sceglie."},
	# i campioni in più delle Catene, per le partite da 5 a 8 (22/10): nel vecchio gioco del cerchio non compaiono
	{"nome": "Sacerdotessa", "articolo": "la Sacerdotessa", "da": "dalla Sacerdotessa", "di": "della Sacerdotessa", "colore": Color(0.9, 0.82, 0.55),
		"abilita": "", "desc_abilita": "", "motto": "Ho pregato l'altare sbagliato."},
	{"nome": "Medico della peste", "articolo": "il Medico", "da": "dal Medico", "di": "del Medico", "colore": Color(0.55, 0.62, 0.5),
		"abilita": "", "desc_abilita": "", "motto": "Ho visto morire troppi per avere paura."},
	{"nome": "Becchino", "articolo": "il Becchino", "da": "dal Becchino", "di": "del Becchino", "colore": Color(0.62, 0.5, 0.38),
		"abilita": "", "desc_abilita": "", "motto": "Ho scavato fosse per tutti voi."},
	{"nome": "Gladiatore", "articolo": "il Gladiatore", "da": "dal Gladiatore", "di": "del Gladiatore", "colore": Color(0.85, 0.22, 0.32),
		"abilita": "", "desc_abilita": "", "motto": "Le catene le conosco bene."},
]
const CLASSI_CERCHIO := 4            # il vecchio gioco del cerchio usa solo i primi quattro (hanno l'abilità)

const PRESAGI := [
	{"nome": "", "testo": ""},
	{"nome": "Notte di sangue", "testo": "Nessuno può difendersi né riaccendere: tutti devono attaccare."},
	{"nome": "Sangue doppio", "testo": "Ogni colpo e ogni contrattacco spegne 2 candele."},
	{"nome": "Scambio", "testo": "Chi ha più candele e chi ne ha meno se le scambiano."},
	{"nome": "Silenzio", "testo": "In questo giro niente carte e niente abilità."},
	{"nome": "Tributo", "testo": "Chi ha più candele ne offre una all'altare."},
	{"nome": "Ira del Custode", "testo": "Se in questo giro nessuno perde candele, tutti ne perdono una."},
]

## Carte del Custode, nello stesso ordine di CerchioRules.Card.
const CARTE := [
	{"nome": "Specchio", "testo": "Questo giro ogni colpo contro di te torna a chi l'ha tirato."},
	{"nome": "Lama doppia", "testo": "Questo giro i tuoi colpi spengono 2 candele."},
	{"nome": "Catena", "testo": "Scegli un avversario: questo giro deve attaccare te. Insieme a «difenditi da lui» è un contrattacco sicuro."},
	{"nome": "Patto di sangue", "testo": "Scambi le tue candele con quelle di un avversario. Il Custode ne trattiene una per sé."},
	{"nome": "Fiamma rubata", "testo": "Togli una candela a un avversario e la accendi davanti a te."},
	{"nome": "Ultimo respiro", "testo": "Se questo giro dovresti morire, resti in vita con 1 candela."},
	{"nome": "Ombra", "testo": "Questo giro nessuno può colpirti."},
	{"nome": "Furto", "testo": "Rubi una carta a caso a un avversario."},
	{"nome": "Maledizione", "testo": "Annulla la carta di un avversario e lo lascia senza carte per tutta la manche."},
	{"nome": "Sete", "testo": "Ogni colpo che metti a segno questo giro ti fa riaccendere una candela dall'altare."},
]

const SCENARI := [
	{"nome": "La foresta cupa", "sotto": "Pini neri, nebbia, un falò nel cerchio. Nessuna via d'uscita."},
	{"nome": "Il cimitero dimenticato", "sotto": "Lapidi storte, un mausoleo chiuso, il cancello alle spalle."},
	{"nome": "La cripta sepolta", "sotto": "Volte di pietra, torce, sarcofagi sigillati. Un solo raggio di luna."},
	{"nome": "Il lago ghiacciato", "sotto": "Il cerchio nel ghiaccio, una nave intrappolata, scogliere di neve."},
]

const CUSTODE_INIZIO := [
	"Benvenuti nel mio cerchio. Uno solo vedrà l'alba.",
	"Le candele sono la vostra vita. Guardatele bruciare.",
	"Ancora voi. Il cerchio ha fame.",
]
const CUSTODE_MORTE := [
	"Un'altra fiamma si spegne. Delizioso.",
	"Il cerchio ringrazia.",
	"Benvenuto fra gli spettri.",
	"Così presto?",
]
const CUSTODE_NULLA := [
	"Nessuno sanguina? Che noia.",
	"Paura, eh?",
	"Il cerchio aspetta. Il cerchio non perdona.",
]

## Pagine delle istruzioni: [titolo, testo]. Le apre il pulsante "?" e il menu "Come si gioca".
const REGOLE := [
	["Lo scopo",
	"Quattro campioni sono trascinati nel cerchio del Custode. Ognuno ha davanti 4 candele: sono le sue vite.\n\nQuando perdi tutte le candele muori per il resto della manche.\n\nSi giocano 3 manche. Vince la partita chi fa più punti."],
	["Il giro",
	"1. Vedi l'ordine dei colpi di questo giro (la riga sopra le mosse).\n\n2. Tutti scelgono in segreto una mossa.\n\n3. Si rivelano tutte insieme.\n\n4. I colpi si risolvono uno dopo l'altro, in quell'ordine."],
	["Le mosse",
	"ATTACCA un avversario: se lui non si difende da te, perde una candela.\n\nDIFENDITI DA un avversario: se lui ti attacca, lo contrattacchi e perde lui una candela.\n\nRIACCENDI UNA CANDELA (solo con 2 candele o meno): se nessuno ti attacca, prendi una fiamma dall'altare e riaccendi una candela.\n\nABILITÀ: la mossa speciale del tuo campione. Si usa una sola volta in tutta la partita."],
	["Contrattacco e stanchezza",
	"Se attacchi chi si sta difendendo proprio da te, il colpo torna indietro: perdi tu una candela.\n\nSe ti difendi da qualcuno che non aveva scelto di attaccarti, sei STANCO: nel giro dopo non puoi difenderti né riaccendere, puoi solo attaccare (o usare l'abilità).\n\nSe due giocatori si attaccano a vicenda, perdono una candela entrambi.\nSe ti attaccano in due e ti difendi da uno solo, l'altro ti colpisce."],
	["L'ordine dei colpi",
	"Prima di scegliere vedi l'ordine dei colpi, nella riga sopra le mosse. A ogni giro il primo posto passa al campione vivo successivo (il primo della manche lo estrae il Custode).

Di solito non cambia nulla. Conta quando un colpo uccide: chi muore prima del suo turno non fa partire il suo colpo.

Così c'è sempre un vincitore, e sai chi rischia di più."],
	["Il duello finale",
	"Quando restate in due, nessuna mossa è sicura:\n\n- l'attacco batte chi riaccende;\n- chi riaccende batte chi si difende (e chi si difende resta stanco);\n- la difesa batte l'attacco.\n\nDevi indovinare cosa farà l'altro."],
	["L'altare",
	"Al centro del cerchio c'è l'altare del Custode.\n\nOgni candela che si spegne porta la sua fiamma sull'altare.\n\nPer riaccendere una candela devi prendere una fiamma dall'altare: se l'altare è vuoto, non si può riaccendere."],
	["I campioni", ""],   # riempita dal gioco con le classi
	["Manche e punti",
	"Ogni manche finisce quando resta un solo vivo.\n\nPunti: 3 all'ultimo vivo, 2 al secondo, 1 al terzo, 0 al primo che muore.\n\nLa terza manche vale DOPPIO. A pari punti vince chi si è piazzato meglio nella terza manche.\n\nA ogni manche le candele si riaccendono tutte. Le abilità no: una volta per partita."],
	["Gli spettri",
	"Chi muore diventa uno spettro fino alla fine della manche. Non può toccare il gioco dei vivi.\n\nA ogni giro però può scommettere: indica un vivo che secondo lui perderà una candela.\n\nOgni 2 previsioni giuste guadagna 1 punto (al massimo 1 per manche)."],
]


## Istruzioni delle Catene dell'altare (docs/catene_altare.md, REGOLE DEFINITIVE): il gioco di adesso.
const REGOLE_CATENE := [
	["Lo scopo",
	"Da quattro a otto campioni sono incatenati al tavolo di pietra attorno all'altare. Ognuno inizia con 4 catene.\n\nLiberati prima che si spengano le candele: chi resta legato con più catene prende fuoco, lì dove sta.\n\nUno di voi, in segreto, lavora per l'altare: è il sabotatore. Tre manche: vince chi fa più punti."],
	["Il turno",
	"1. Il Custode ti offre tre carte coperte: ne prendi una (al massimo 3 in mano). Tutti vedono solo quante carte ci sono in gioco in totale.\n\n2. Scegli in segreto: O tiri la catena O giochi una carta (su chiunque, anche su di te). Non tutte e due.\n\n3. Le carte coperte si mescolano sul tavolo e se ne posa una davanti a ogni campione, in ordine casuale: non si sa chi le ha giocate. La carta segreta del Guardiano resta nel fuoco e si gira per ultima. Si vede invece chi ha tirato."],
	["L'altare e le candele",
	"Se tutti i legati tirano, la candela non si spegne (al massimo 2 turni di fila; da sei giocatori in su basta che tirino tutti tranne uno).\n\nBasta uno che non tira e se ne spegne una.\n\nDopo che il primo si è liberato se ne spegne una in più a ogni turno."],
	["Le carte",
	"TOGLI UNA CATENA: una catena in meno. A zero sei libero.\nAGGIUNGI UNA CATENA / DUE CATENE: catene in più a chi scegli.\nSALTA UN TURNO: il bersaglio perde la mossa seguente.\nVOTO: a fine turno si vota il sabotatore.\nPASSA IL TESTIMONE: serve solo al sabotatore. Per gli altri è inutile, ma nessuno sa chi la tiene."],
	["Il sabotatore",
	"Pesca da un mazzo suo: Aggiungi, Salta e Passa il testimone. Le sue carte Aggiungi e Salta colpiscono DUE campioni alla volta. Il Guardiano gli dona un «Togli» nascosto (ogni 3 turni) per fingere di volersi liberare.\n\nPassando il testimone il ruolo va a un altro legato, a caso: chi lo passa non sa a chi.\n\nNon deve liberarsi: se si libera per primo prende 0 punti e il ruolo passa da solo."],
	["Il voto e il Guardiano",
	"Votano solo i legati, a maggioranza: più della metà (3 su 4, 4 su 6, 5 su 8; 2 se restate in 2 o 3). Con la parità non succede nulla.\n\nSe almeno 2 lo chiedono, il Guardiano aggiunge un voto: metà delle volte dice il vero. Una volta per manche.\n\nSabotatore scoperto: +2 catene e non può più passare il testimone. Voto sbagliato: nulla (o, nella modalità a eliminazione, il condannato brucia)."],
	["L'ultimo respiro",
	"All'ultima candela l'altare si agita: 30 secondi in cui tutti giocano subito fino a 3 carte fra Togli, Aggiungi e Salta.\n\nPoi il fuoco diventa blu e chi ha più catene brucia (a parità, tutti i pari). Da sei giocatori in su bruciano i due più legati.\n\nChi si libera o viene eliminato ha finito: non vota e non gioca più."],
	["I punti",
	"Primo a liberarsi 3, altri liberi 2, legato ma salvo 1, bruciato 0.\n\nSabotatore mai scoperto: 3 se si salva (2 se al tavolo siete in cinque o più), 1 se brucia insieme a un innocente, 0 se brucia senza innocenti o si libera per primo.\n\nSabotatore scoperto: come gli altri, ma 0 se brucia."],
	["Da sei a otto giocatori",
	"Al tavolo grande cambiano poche cose:\n\n- I sabotatori sono DUE e si conoscono: aiutatevi senza farvi notare. Passando il testimone il ruolo non va mai al complice, e il complice saprà chi è il nuovo.\n- Le carte del sabotatore colpiscono un solo campione.\n- Le candele sono 14; la candela non si spegne se tirano tutti i legati tranne uno.\n- Alla fine bruciano i DUE più legati (a parità anche chi è pari al secondo).\n- Il voto scopre un sabotatore alla volta: scoperto il primo, si cerca l'altro."],
]

static var catene := true            # quali istruzioni mostrare: false con --cerchio (il vecchio gioco)


static func regole() -> Array:
	return REGOLE_CATENE if catene else REGOLE


static func pagina(i: int) -> Array:
	var p: Array = regole()[i].duplicate()
	if p[0] == "Le carte del Custode":
		var t := "A inizio manche ricevi 3 carte coperte. Puoi giocarne una per giro insieme alla tua mossa: si scopre alla rivelazione. Tutti vedono quante carte hai, non quali.\n\n"
		for c in CARTE:
			t += "%s: %s\n" % [c["nome"].to_upper(), c["testo"]]
		p[1] = t.strip_edges()
	elif p[0] == "I campioni":
		var t := ""
		for c in CLASSI.slice(0, CLASSI_CERCHIO):
			t += "%s — %s\n%s\n\n" % [c["nome"].to_upper(), c["abilita"], c["desc_abilita"]]
		p[1] = t.strip_edges()
	elif p[0] == "I Presagi":
		var t := "A ogni giro il Custode può scoprire un Presagio:\n\n"
		for k in range(1, PRESAGI.size()):
			t += "%s: %s\n\n" % [PRESAGI[k]["nome"].to_upper(), PRESAGI[k]["testo"]]
		p[1] = t.strip_edges()
	return p


static func a_caso(lista: Array) -> String:
	return lista[randi() % lista.size()]
