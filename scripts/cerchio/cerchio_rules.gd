class_name CerchioRules
extends RefCounted
## Regole del gioco (docs/progetto.md), senza grafica. Usate dal gioco e dai simulatori.
##
## Un giro:
## 1. il Custode può estrarre un Presagio;
## 2. tutti scelgono in segreto: attacca X, difenditi da X, riaccendi una candela, abilità speciale
##    (una volta a partita); e possono giocare coperta una carta del Custode;
## 3. rivelazione contemporanea: prima le carte, poi il Custode estrae l'ordine dei colpi e i colpi
##    si risolvono in quell'ordine:
##    - attacchi chi non si difende da te: perde una candela;
##    - attacchi chi si difende da te: contrattacco, perdi tu una candela;
##    - chi muore prima del suo turno non colpisce più (niente morti tutti insieme);
##    - ti difendi da chi non aveva scelto di attaccarti: sei stanco (al giro dopo puoi solo attaccare);
##      se aveva scelto di attaccarti ma è morto prima del suo turno, niente contrattacco e niente stanchezza;
## 4. chi resta senza candele muore; l'ultimo vivo vince la manche. Il cerchio non resta mai vuoto.
## Altare: ogni candela spenta porta la sua fiamma all'altare al centro; riaccendere la prende da lì.

enum Cls { CAVALIERE, STREGA, ELFO, DOMATORE }
const CLS_NAMES := ["cavaliere", "strega", "elfo", "domatore"]

enum Move { ATTACK, DEFEND, SPECIAL, HEAL }   # HEAL: riaccendere una candela

enum Omen { NONE, NOTTE_DI_SANGUE, SANGUE_DOPPIO, SCAMBIO, SILENZIO, TRIBUTO, IRA }
const OMEN_NAMES := ["nessuno", "notte di sangue", "sangue doppio", "scambio", "silenzio", "tributo",
	"ira del custode"]

enum Card { SPECCHIO, LAMA, CATENA, PATTO, FIAMMA, RESPIRO, OMBRA, FURTO, MALEDIZIONE, SETE }
const CARD_NAMES := ["specchio", "lama doppia", "catena", "patto di sangue", "fiamma rubata",
	"ultimo respiro", "ombra", "furto", "maledizione", "sete"]
## Carte che vogliono un avversario come bersaglio.
const CARD_TARGETED := [Card.CATENA, Card.PATTO, Card.FIAMMA, Card.FURTO, Card.MALEDIZIONE]

## Patti del Custode (in prova): un dono subito, un prezzo per il resto della manche.
enum Pact { OCCHI, MANO, CUORE, SANGUE, PELLE, NOME }
const PACT_NAMES := ["occhi", "mano", "cuore", "sangue", "pelle", "nome"]

## Orrori dei luoghi (in prova): il luogo colpisce ogni place_every giri, annunciato il giro prima.
const PLACE_NAMES := ["foresta", "cimitero", "cripta", "lago"]


class Player:
	var id := 0
	var cls := 0
	var candles := 4.0
	var alive := true
	var special_left := true
	var tired := false
	var hand: Array[int] = []                # carte del Custode in mano
	var cursed := false                      # Maledizione: niente carte per il resto della manche
	var attacked_me_last: Array[int] = []   # chi mi ha attaccato nel giro precedente
	var history: Array[Dictionary] = []      # le mie scelte rivelate, dalla più vecchia
	var pacts: Array[int] = []               # patti presi in questa manche (al massimo due)
	var revealed: Array[int] = []            # patti che gli altri hanno già scoperto
	var pact_target := -1                    # Nome: l'avversario consegnato al Custode
	var shield := 0                          # Cuore: giri in cui nessuno può colpirti
	var undead := false                      # Pelle: tornato dalla morte, può solo attaccare
	var spent := 0.0                         # cimitero: candele spente agli altri dall'ultimo risveglio


var players: Array[Player] = []
var omen := Omen.NONE
var forced: Array[int] = []    # chi deve attaccare per forza in questo giro
var order: Array[int] = []     # ordine dei colpi del giro
var round_no := 0
var fatigue := "B"             # "B" stanchezza, "A" mezza candela (solo confronto)
var use_omens := true
var omen_rate := 0.5           # probabilità di un Presagio a ogni giro
var fire_counter := true       # chi si difende dal domatore contrattacca anche il soffio
var initiative := "caso"       # "nessuna" (tutto contemporaneo), "caso", "deboli"
var elf_first := false         # (prova scartata) l'elfo agisce sempre per primo
var fire_last := false         # (prova scartata) il soffio del drago si risolve per ultimo
var order_hidden := true       # l'ordine si estrae solo dopo la rivelazione
var order_rotate := false      # ordine visibile prima delle scelte: ogni giro il primo posto passa al vivo successivo
var _first := -1               # chi colpisce per primo in questo giro (ordine a rotazione)
var heal := true               # "Riaccendi una candela"
var max_candles := 4.0
var heal_cap := 3.0            # si riaccende solo con 2 candele o meno
var use_altar := true          # le fiamme spente vanno all'altare; riaccendere le prende da lì
var altar := 0.0
var altar_take_all := false   # chi riaccende prende tutte le fiamme dell'altare (fino a heal_take_cap)
var heal_take_cap := 3.0      # fin dove si può risalire riaccendendo
var patto_cost := 1.0         # candele che il Custode trattiene a chi gioca il Patto di sangue
var use_cards := true          # carte del Custode
var cards_per_manche := 3
var begin_deaths: Array[int] = []           # morti per un patto all'inizio del giro (Nome)
var begin_events: Array[Dictionary] = []   # cosa è successo all'inizio del giro (Scambio, Tributo)
var use_pacts := false
var pact_rate := 0.5           # probabilità che il Custode offra un patto a ogni giro (dal secondo)
var pact_max := 6.0            # Sangue: fin dove si può salire rubando
var offers := {}               # patti mostrati in questo giro: pid -> [patto, patto]
var pacts_shown := false       # a metà manche il Custode mostra i patti una volta sola
var pact_when := "morte"       # "morte": il giro dopo la prima morte; "giro": al giro pact_round
var pact_round := 3
var place := -1                # luogo (indice di PLACE_NAMES), -1 nessun orrore
var place_every := 3
var marked := -1               # cripta: chi è stato chiamato dal cancello
var rng := RandomNumberGenerator.new()


func setup(classes: Array, candles: float, seed_value: int, fatigue_mode := "B", omens := true) -> void:
	rng.seed = seed_value
	fatigue = fatigue_mode
	use_omens = omens
	players.clear()
	round_no = 0
	altar = 0.0
	max_candles = candles
	for i in classes.size():
		var p := Player.new()
		p.id = i
		p.cls = classes[i]
		p.candles = candles
		players.append(p)
	if use_cards:
		deal_cards()


## Ognuno riceve le sue carte coperte da un mazzo con due copie di ogni carta.
func deal_cards() -> void:
	var deck: Array = []
	for k in Card.size():
		deck.append(k)
		deck.append(k)
	_shuffle(deck)
	for p in players:
		p.hand.clear()
		p.cursed = false
		for k in cards_per_manche:
			p.hand.append(deck.pop_back())


func alive_ids() -> Array[int]:
	var out: Array[int] = []
	for p in players:
		if p.alive:
			out.append(p.id)
	return out


func is_over() -> bool:
	return alive_ids().size() <= 1


func winner() -> int:
	var a := alive_ids()
	return a[0] if a.size() == 1 else -1


## Inizio giro: il Custode può estrarre un Presagio; alcuni agiscono subito.
func begin_round() -> void:
	round_no += 1
	forced.clear()
	begin_events.clear()
	begin_deaths.clear()
	omen = Omen.NONE
	if use_omens and rng.randf() < omen_rate:
		omen = 1 + rng.randi() % (OMEN_NAMES.size() - 1)
	var ids := alive_ids()
	_shuffle(ids)
	match omen:
		Omen.NOTTE_DI_SANGUE:
			forced = ids.duplicate()
		Omen.SCAMBIO:
			ids.sort_custom(func(a, b): return players[a].candles > players[b].candles)
			var hi: int = ids[0]
			var lo: int = ids[ids.size() - 1]
			if players[hi].candles > players[lo].candles:
				var t := players[hi].candles
				players[hi].candles = players[lo].candles
				players[lo].candles = t
				begin_events.append({"t": "scambio", "a": hi, "b": lo})
		Omen.TRIBUTO:
			ids.sort_custom(func(a, b): return players[a].candles > players[b].candles)
			var hi: int = ids[0]
			if players[hi].candles > 1.0:
				players[hi].candles -= 1.0
				if use_altar:
					altar += 1.0
				begin_events.append({"t": "tributo", "pid": hi})
	# a metà manche il Custode mostra a ognuno, in segreto, due patti estratti a caso
	offers = {}
	if use_pacts and not pacts_shown:
		var due := round_no == pact_round if pact_when == "giro" else alive_ids().size() < players.size()
		if due:
			pacts_shown = true
			for pid in alive_ids():
				var all: Array = range(Pact.size())
				_shuffle(all)
				offers[pid] = [all[0], all[1]]
	order = alive_ids()
	_shuffle(order)
	if order_rotate:
		# a rotazione: il primo della manche è estratto a caso, poi il primo posto passa al vivo successivo
		order_hidden = false
		var rot_ids := alive_ids()
		var k := rng.randi() % rot_ids.size()
		if _first >= 0:
			k = 0
			while k < rot_ids.size() and rot_ids[k] <= _first:
				k += 1
			k = k % rot_ids.size()
		_first = rot_ids[k]
		order = []
		for q in rot_ids.size():
			order.append(rot_ids[(k + q) % rot_ids.size()])
	if initiative == "deboli":
		order.sort_custom(func(a, b): return players[a].candles < players[b].candles)
	if elf_first:
		for pid in order.duplicate():
			if players[pid].cls == Cls.ELFO:
				order.erase(pid)
				order.push_front(pid)


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


## Prende i patti scelti fra quelli mostrati (nessuno, uno o due). Con due patti le candele si dimezzano
## (per difetto; servono almeno 2 candele). Il dono arriva subito, il prezzo dura fino a fine manche.
## target serve all'Ultima maledizione (l'avversario maledetto).
func take_pacts(pid: int, picks: Array, target := -1) -> void:
	var p := players[pid]
	if picks.is_empty() or not p.alive or not offers.has(pid):
		return
	if picks.size() >= 2:
		if p.candles < 2.0:
			return
		var half := floorf(p.candles / 2.0)
		if use_altar:
			altar += p.candles - half
		p.candles = half
	for k in picks:
		if not offers[pid].has(k) or p.pacts.has(k) or not p.alive:
			continue
		p.pacts.append(k)
		begin_events.append({"t": "patto_accettato", "pid": pid, "pact": k})
		_apply_pact(pid, k, target)


func _apply_pact(pid: int, k: int, target: int) -> void:
	var p := players[pid]
	match k:
		Pact.OCCHI:
			if _gain(pid, minf(2.0, heal_cap - p.candles)) > 0.0:
				p.revealed.append(k)                 # le candele che si riaccendono da sole si vedono
		Pact.CUORE:
			p.shield = 2
		Pact.SANGUE:
			p.revealed.append(k)                     # tutti vedono le candele rubate
			for t in attack_targets(pid):
				if players[t].candles > 1.0 and p.candles < pact_max:
					players[t].candles -= 1.0
					p.candles += 1.0
		Pact.NOME:
			# chi pronuncia il nome muore; il maledetto perde subito 2 candele e sanguina doppio fino a fine manche
			p.revealed.append(k)
			p.pact_target = target
			if use_altar:
				altar += p.candles
			p.candles = 0.0
			p.alive = false
			begin_deaths.append(pid)
			if target >= 0 and players[target].alive:
				var t := players[target]
				var loss := minf(2.0, t.candles)
				if alive_ids().size() <= 1:
					loss = minf(loss, t.candles - 1.0)     # il cerchio non resta mai vuoto
				t.candles -= loss
				if use_altar:
					altar += loss
				if t.candles <= 0.0:
					t.alive = false
					begin_deaths.append(target)


## Patto che gli altri conoscono già (si scopre quando il suo effetto si vede).
func known_pact(pid: int, k: int) -> bool:
	return players[pid].revealed.has(k)


func _reveal(pid: int, k: int) -> void:
	if not players[pid].revealed.has(k):
		players[pid].revealed.append(k)


## Colpi e contrattacchi contro pid spengono 2 candele (Sangue, Nome, chiamato dal cancello della cripta).
func fragile(pid: int) -> bool:
	if players[pid].pacts.has(Pact.SANGUE):
		return true
	if place == 2 and marked == pid and place_strikes_now():
		return true
	for q in players:
		if q.pacts.has(Pact.NOME) and q.pact_target == pid:
			return true
	return false


## Candele spente da un colpo di who su tgt (mai più di 2).
func hit_amount(who: int, tgt: int) -> float:
	var base := 2.0 if omen == Omen.SANGUE_DOPPIO else 1.0
	if players[who].pacts.has(Pact.MANO) or fragile(tgt):
		base *= 2.0
	return minf(base, 2.0)


## Candele perse da who quando il bersaglio lo contrattacca.
func counter_amount(who: int) -> float:
	var base := 2.0 if omen == Omen.SANGUE_DOPPIO else 1.0
	if fragile(who):
		base *= 2.0
	return minf(base, 2.0)


## Viewer vede la mossa di pid prima di scegliere (Cuore: tutti; Nome: la vittima vede chi l'ha venduta).
func sees(viewer: int, pid: int) -> bool:
	var p := players[pid]
	if viewer == pid or not p.alive:
		return false
	if p.pacts.has(Pact.CUORE) and p.shield <= 0:
		return true
	return p.pacts.has(Pact.NOME) and p.pact_target == viewer


## Il luogo colpisce alla fine di questo giro.
func place_strikes_now() -> bool:
	return place >= 0 and round_no % place_every == 0


## Il luogo colpirà al prossimo giro (l'annuncio: ululato, campana, voce, scricchiolio).
func place_warns_now() -> bool:
	return place >= 0 and round_no % place_every == place_every - 1


## Posizione nell'ordine dei colpi (0 = primo).
func rank(pid: int) -> int:
	return order.find(pid)


func must_attack(pid: int) -> bool:
	return players[pid].tired or players[pid].undead or forced.has(pid)


func attack_targets(pid: int) -> Array[int]:
	var all: Array[int] = []
	for t in alive_ids():
		if t != pid:
			all.append(t)
	return all


func defend_targets(pid: int) -> Array[int]:
	return attack_targets(pid)


func can_heal(pid: int) -> bool:
	var p := players[pid]
	return heal and p.candles < minf(max_candles, heal_cap) and (not use_altar or altar >= 1.0)


func can_play_card(pid: int) -> bool:
	var p := players[pid]
	return use_cards and p.alive and not p.cursed and omen != Omen.SILENZIO and not p.hand.is_empty()


func abilities_allowed() -> bool:
	return omen != Omen.SILENZIO


## Scelte legali di pid (senza carta). Ogni scelta: {"move", "target" | "targets", "peek"}.
## La carta si aggiunge alla scelta con "card" (e "card_target" se serve).
func legal_choices(pid: int) -> Array[Dictionary]:
	var p := players[pid]
	var out: Array[Dictionary] = []
	for t in attack_targets(pid):
		out.append({"move": Move.ATTACK, "target": t})
	if not must_attack(pid):
		if not p.pacts.has(Pact.OCCHI):       # senza occhi non vedi chi arriva: niente difesa
			for t in defend_targets(pid):
				out.append({"move": Move.DEFEND, "target": t})
		if can_heal(pid):
			out.append({"move": Move.HEAL})
	if p.special_left and abilities_allowed() and not p.pacts.has(Pact.MANO):
		match p.cls:
			Cls.CAVALIERE:
				if not must_attack(pid):
					out.append({"move": Move.SPECIAL})
			Cls.ELFO:
				var ts := attack_targets(pid)
				for i in ts.size():
					for j in range(i + 1, ts.size()):
						out.append({"move": Move.SPECIAL, "targets": [ts[i], ts[j]]})
			Cls.DOMATORE:
				out.append({"move": Move.SPECIAL})
	return out


## Toglie candele; con guard non spegne l'ultima candela dell'ultimo vivo.
## L'Ultimo respiro (carta) tiene in vita con una candela.
func _hurt(pid: int, amount: float, rep: Dictionary, guard := false) -> void:
	var p := players[pid]
	if not p.alive or amount <= 0.0:
		return
	if guard and p.candles - amount <= 0.0 and alive_ids().size() <= 1:
		amount = maxf(p.candles - 0.5, 0.0)
	if p.candles - amount <= 0.0 and p.pacts.has(Pact.PELLE) and not p.undead:
		# patto della Pelle: torna dalla morte con 2 candele, ma da ora può solo attaccare
		if use_altar:
			altar += p.candles
		p.candles = 1.0
		p.undead = true
		_reveal(pid, Pact.PELLE)
		rep["events"].append({"t": "risorge", "pid": pid})
		return
	if p.candles - amount <= 0.0 and rep.get("_respiro", {}).has(pid) and not rep["_respiro"][pid]:
		rep["_respiro"][pid] = true
		amount = p.candles - 1.0
		rep["events"].append({"t": "respiro", "pid": pid})
		if amount <= 0.0:
			return
	p.candles -= amount
	rep["damage"] += amount
	if use_altar:
		altar += amount
	rep["events"].append({"t": "perde", "pid": pid, "n": amount, "perche": rep.get("_cause", "")})
	if p.candles <= 0.0:
		p.alive = false
		rep["deaths"].append(pid)
		rep["events"].append({"t": "muore", "pid": pid})


func _gain(pid: int, amount: float) -> float:
	var p := players[pid]
	var g := minf(amount, max_candles - p.candles)
	p.candles += maxf(g, 0.0)
	return maxf(g, 0.0)


## Prima delle mosse si scoprono le carte. Restituisce pid -> carta che ha effetto in questo giro.
func _play_cards(choices: Dictionary, rep: Dictionary) -> Dictionary:
	var played := {}
	for pid in choices:
		var c: Dictionary = choices[pid]
		if not c.has("card") or not can_play_card(pid):
			continue
		var k: int = c["card"]
		var p := players[pid]
		if not p.hand.has(k):
			continue
		p.hand.erase(k)
		played[pid] = k
		rep["events"].append({"t": "carta", "pid": pid, "card": k, "target": c.get("card_target", -1)})
		rep["cards"] = rep.get("cards", 0) + 1
	# Maledizione: annulla la carta del bersaglio e lo lascia senza carte per la manche
	var cancel := {}
	for pid in played:
		if played[pid] == Card.MALEDIZIONE:
			var t: int = choices[pid].get("card_target", -1)
			if t >= 0 and players[t].alive:
				players[t].cursed = true
				cancel[t] = true
				rep["events"].append({"t": "maledetto", "da": pid, "a": t})
	for t in cancel:
		if played.has(t):
			rep["events"].append({"t": "carta_annullata", "pid": t, "card": played[t]})
			played.erase(t)
	for pid in played:
		var t: int = choices[pid].get("card_target", -1)
		match played[pid]:
			Card.FURTO:
				if t >= 0 and not players[t].hand.is_empty():
					var k: int = players[t].hand.pop_at(rng.randi() % players[t].hand.size())
					players[pid].hand.append(k)
					rep["events"].append({"t": "furto", "da": pid, "a": t})
			Card.CATENA:
				# il bersaglio deve attaccare chi l'ha incatenato (le abilità non si fermano)
				if t >= 0 and players[t].alive and choices.has(t) and choices[t]["move"] != Move.SPECIAL:
					var keep: Dictionary = choices[t].duplicate()
					keep["move"] = Move.ATTACK
					keep["target"] = pid
					choices[t] = keep
					rep["events"].append({"t": "catena", "da": pid, "a": t})
			Card.PATTO:
				if t >= 0 and players[t].alive:
					var x := players[t].candles
					players[t].candles = players[pid].candles
					players[pid].candles = maxf(1.0, x - patto_cost)   # il Custode trattiene il suo prezzo
					rep["events"].append({"t": "patto", "da": pid, "a": t})
	for pid in played:
		if played[pid] == Card.FIAMMA:
			var t: int = choices[pid].get("card_target", -1)
			if t >= 0 and players[t].alive and players[pid].alive:
				rep["events"].append({"t": "fiamma", "da": pid, "a": t})
				rep["_cause"] = "fiamma"
				var was_altar := altar
				_hurt(t, 1.0, rep, true)
				altar = was_altar          # la fiamma non va all'altare: va a chi la ruba
				_gain(pid, 1.0)
	return played


## Rivela e risolve. choices: pid -> scelta. Restituisce un resoconto (eventi per le animazioni).
func resolve(choices: Dictionary) -> Dictionary:
	var rep := {"damage": 0.0, "counters": 0, "hits": 0, "tired_new": 0, "oath_saves": 0, "fire": 0,
		"deaths": [], "ira": false, "first_strike": 0, "events": [], "order": [], "_respiro": {}}
	choices = choices.duplicate()
	var was_forced := {}
	for pid in choices:
		was_forced[pid] = must_attack(pid)
	var start_alive := alive_ids()
	var played := _play_cards(choices, rep)
	var has_card := func(pid: int, k: int) -> bool: return played.get(pid, -1) == k
	for pid in played:
		if played[pid] == Card.RESPIRO:
			rep["_respiro"][pid] = false
	var tired_next := {}
	var attacks := {}             # attaccante -> [[bersaglio, fuoco], ...]
	var defends := {}
	var oath := {}
	var heals := {}
	for pid in choices:
		var c: Dictionary = choices[pid]
		var p := players[pid]
		attacks[pid] = []
		if not p.alive:
			continue
		if c.has("peek"):
			p.special_left = false
		match c["move"]:
			Move.ATTACK:
				attacks[pid].append([c["target"], false])
			Move.DEFEND:
				defends[pid] = c["target"]
			Move.HEAL:
				heals[pid] = true
			Move.SPECIAL:
				p.special_left = false
				match p.cls:
					Cls.CAVALIERE:
						oath[pid] = true
					Cls.ELFO:
						for t in c["targets"]:
							attacks[pid].append([t, false])
					Cls.DOMATORE:
						rep["fire"] += 1
						for t in start_alive:
							if t != pid:
								attacks[pid].append([t, true])
	if order_hidden:
		_shuffle(order)   # estratto adesso, dopo le scelte
	var seq: Array[int] = order.duplicate() if initiative != "nessuna" else start_alive
	rep["order"] = seq.duplicate()
	var simultaneous := initiative == "nessuna"
	var pending := {}
	var attackers_of := {}
	var base := 2.0 if omen == Omen.SANGUE_DOPPIO else 1.0
	for phase in (2 if fire_last else 1):
		for who in seq:
			if not players[who].alive:
				if phase == 0 and start_alive.has(who) and not attacks.get(who, []).is_empty():
					rep["first_strike"] += 1   # morto prima del suo turno: il suo colpo non parte
					rep["events"].append({"t": "fermato", "pid": who})
				continue
			for a in attacks.get(who, []):
				var tgt: int = a[0]
				var fire: bool = a[1]
				if fire_last and fire != (phase == 1):
					continue
				if not players[tgt].alive or not players[who].alive:
					continue
				var dmg: float = hit_amount(who, tgt)
				if has_card.call(who, Card.LAMA):
					dmg = 2.0                      # mai più di 2 candele a colpo
				var ev := {"t": "colpo", "da": who, "a": tgt, "fuoco": fire, "esito": "colpito", "n": dmg}
				rep["events"].append(ev)
				rep["_cause"] = "colpo"
				if players[tgt].shield > 0:
					ev["esito"] = "cuore"          # Cuore di cenere: il colpo lo attraversa (e tutti lo scoprono)
					_reveal(tgt, Pact.CUORE)
					continue
				if has_card.call(tgt, Card.OMBRA):
					ev["esito"] = "ombra"          # nessuno può colpirlo: il colpo va a vuoto
					continue
				attackers_of[tgt] = attackers_of.get(tgt, []) + [who]
				if oath.has(tgt):
					tired_next[who] = true     # respinto dal Giuramento
					rep["oath_saves"] += 1
					ev["esito"] = "giuramento"
				elif has_card.call(tgt, Card.SPECCHIO):
					ev["esito"] = "specchio"
					_hurt(who, dmg, rep)
				elif defends.get(tgt, -1) == who and (not fire or fire_counter):
					ev["esito"] = "contrattacco"
					rep["counters"] += 1
					var back := counter_amount(who)
					players[tgt].spent += minf(back, players[who].candles)
					if simultaneous:
						pending[who] = pending.get(who, 0.0) + back
					else:
						_hurt(who, back, rep)
				elif defends.get(tgt, -1) == who:
					ev["esito"] = "parato"
				else:
					rep["hits"] += 1
					if players[who].pacts.has(Pact.MANO):
						_reveal(who, Pact.MANO)      # due candele in un colpo: la Mano nera si è vista
					players[who].spent += minf(dmg, players[tgt].candles)
					if simultaneous:
						pending[tgt] = pending.get(tgt, 0.0) + dmg
					else:
						_hurt(tgt, dmg, rep)
					if has_card.call(who, Card.SETE) and players[who].alive and (not use_altar or altar >= 1.0):
						if _gain(who, 1.0) > 0.0:
							if use_altar:
								altar -= 1.0
							rep["events"].append({"t": "sete", "pid": who})
	for pid in pending:
		_hurt(pid, pending[pid], rep)
	rep["_cause"] = "stanchezza"
	for pid in defends:
		var x: int = defends[pid]
		# hai letto bene se x aveva SCELTO di attaccarti, anche se è morto prima del suo turno:
		# niente contrattacco (il colpo non è partito), ma nemmeno stanchezza
		var chose_me := false
		for a in attacks.get(x, []):
			if a[0] == pid:
				chose_me = true
		if not attackers_of.get(pid, []).has(x) and not chose_me:
			if players[pid].alive:
				rep["events"].append({"t": "a_vuoto", "pid": pid, "da": x})
			if fatigue == "B":
				tired_next[pid] = true
			else:
				_hurt(pid, 0.5, rep, true)
	for pid in heals:
		var ok: bool = players[pid].alive and attackers_of.get(pid, []).is_empty() and (not use_altar or altar >= 1.0)
		var want := 1.0
		if use_altar and altar_take_all:
			want = minf(altar, heal_take_cap - players[pid].candles)
		var got := _gain(pid, minf(want, minf(max_candles, heal_take_cap) - players[pid].candles)) if ok else 0.0
		if got > 0.0:
			if use_altar:
				altar -= got
			rep["events"].append({"t": "riaccende", "pid": pid, "n": got})
			rep["heals"] = rep.get("heals", 0) + 1
		elif players[pid].alive:
			rep["events"].append({"t": "riaccende_fallito", "pid": pid})
	for pid in oath:
		if attackers_of.get(pid, []).is_empty():
			tired_next[pid] = true     # Giuramento sprecato
	if omen == Omen.IRA and rep["damage"] == 0.0:
		rep["ira"] = true
		rep["_cause"] = "ira"
		rep["events"].append({"t": "ira"})
		for pid in seq:
			_hurt(pid, 1.0, rep, true)
	if place_strikes_now():
		_place_strike(choices, rep)
	elif place_warns_now() and place == 2:
		var ids := alive_ids()
		marked = ids[rng.randi() % ids.size()]   # il cancello chiama un nome: al prossimo giro sanguina doppio
		rep["events"].append({"t": "chiamato", "pid": marked})
	for p in players:
		if p.shield > 0:
			p.shield -= 1
	for p in players:
		if not start_alive.has(p.id):
			continue
		var was_tired := p.tired
		p.tired = tired_next.has(p.id) and p.alive
		if p.tired and not was_tired:
			rep["tired_new"] += 1
		if p.tired:
			rep["events"].append({"t": "stanco", "pid": p.id})
		var by: Array[int] = []
		for w in attackers_of.get(p.id, []):
			by.append(w)
		p.attacked_me_last = by
		if choices.has(p.id):
			var h: Dictionary = choices[p.id].duplicate()
			h["forced"] = was_forced[p.id]
			p.history.append(h)
	rep["played"] = played
	return rep


## L'orrore del luogo colpisce (alla fine del giro, dopo i colpi). Non spegne mai l'ultima candela dell'ultimo vivo.
## - foresta: la bestia prende chi si è nascosto (difesa o candela) invece di combattere;
## - cimitero: i morti si alzano contro chi ha spento più candele dall'ultimo risveglio;
## - cripta: chi era stato chiamato dal cancello ha sanguinato doppio in questo giro (vedi fragile);
## - lago: il ghiaccio cede sotto chi ha più candele (pesa di più), ma non sotto chi ne ha una sola.
func _place_strike(choices: Dictionary, rep: Dictionary) -> void:
	var victims: Array[int] = []
	var alive := alive_ids()
	match place:
		0:
			for pid in alive:
				var m: int = choices.get(pid, {}).get("move", Move.ATTACK)
				if m == Move.DEFEND or m == Move.HEAL:
					victims.append(pid)
		1:
			var top := 0.0
			for pid in alive:
				top = maxf(top, players[pid].spent)
			if top > 0.0:
				for pid in alive:
					if players[pid].spent >= top:
						victims.append(pid)
			for p in players:
				p.spent = 0.0
		2:
			marked = -1
		3:
			var top := 0.0
			for pid in alive:
				top = maxf(top, players[pid].candles)
			for pid in alive:
				if players[pid].candles >= top and top > 1.0:
					victims.append(pid)
	rep["events"].append({"t": "luogo", "luogo": place, "vittime": victims})
	rep["_cause"] = "luogo"
	for pid in victims:
		_hurt(pid, 1.0, rep, true)
	rep["place_hits"] = victims.size()
