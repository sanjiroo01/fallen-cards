class_name CateneBot
extends RefCounted
## Avversario del computer per le "Catene dell'altare". Vede solo ciò che vedrebbe un giocatore: catene, candele,
## chi tira, effetti anonimi delle carte, esiti dei voti, totale delle carte in gioco, la propria mano e il proprio
## ruolo. Tiene un sospetto per ognuno; da sabotatore finge, mente al voto e passa il testimone quando si sente
## osservato.
##
## Stili: "furbo" (normale), "ingenuo" (da sabotatore tira poco e non passa il testimone), e per le prove delle
## strategie "sempre_tira", "mai_tira", "accumula" (tiene le carte di catene per l'ultimo respiro), "aggressivo".

const C := CateneRules.Card

var pid := 0
var style := "furbo"
var rng := RandomNumberGenerator.new()
var sus := [0.0, 0.0, 0.0, 0.0]     # sospetto "pubblico": quello che chiunque può ricavare dagli eventi
var known := -1                      # sabotatore conosciuto con certezza (chi ha passato il testimone lo sa)
var _cards_before := 0


func _init(id: int, st: String, seed_value: int) -> void:
	pid = id
	style = st
	rng.seed = seed_value


func is_sab(r: CateneRules) -> bool:
	return r.is_sab(pid)


## Un sabotatore conosce i complici (con due sabotatori si conoscono): non li colpisce e non li accusa.
func _mate(r: CateneRules, q: int) -> bool:
	return q != pid and is_sab(r) and r.is_sab(q)


## Tutti i sabotatori sono stati scoperti (cosa che chiunque sa: scoperti e numero dei sabotatori sono pubblici).
func _all_found(r: CateneRules) -> bool:
	var found := 0
	for q in r.n:
		if r.is_sab(q) and r.players[q].unmasked:
			found += 1
	return found >= r.n_sabs


## Un sabotatore scoperto e ancora legato da colpire (mai sé stessi né il complice); -1 se non c'è.
func _open_sab(r: CateneRules) -> int:
	for q in r.chained():
		if q != pid and r.is_sab(q) and r.players[q].unmasked and not _mate(r, q):
			return q
	return -1


# ------------------------------------------------------------------ osservazione

## Da chiamare prima della pesca: ricorda il totale delle carte.
func before_turn(r: CateneRules) -> void:
	if sus.size() != r.n:
		sus.resize(r.n)
		sus.fill(0.0)
	_cards_before = r.cards_total()
	if known >= 0 and (is_sab(r) or r.players[known].free):
		known = -1


## Dopo la risoluzione del turno: aggiorna i sospetti con gli eventi pubblici.
func observe(r: CateneRules, drawn: int) -> void:
	var visible := 0
	var skipped := {}
	var freed := false
	for e in r.events:
		match e["t"]:
			"saltato":
				skipped[e["pid"]] = true
			"togli", "aggiungi", "salta", "voto":
				visible += 1
				if e["t"] == "togli" and not r.sab_deck.is_empty():
					sus[e["pid"]] -= 0.4           # chi si toglie anelli sembra uno che vuole scappare, non sabotare
			"togli_nulla":
				visible += 1
				sus[e["pid"]] += 20.0          # a 1 catena e il "togli" non ha effetto: è il sabotatore
			"libero":
				freed = true
		if e["t"] == "voto" and e.get("esito", "") == "innocente":
			sus[e["pid"]] = minf(sus[e["pid"]], -2.0)
	for e in r.events:
		if e["t"] == "tirano":
			# chi poteva tirare e non l'ha fatto (chi era stato fatto saltare è scusato)
			var idle: Array = []
			for q in e["chi"]:
				if not (q in e["pids"]) and not skipped.has(q):
					sus[q] += 1.0 if not r.pull_or_card else 0.3
					idle.append(q)
			if r.pull_or_card:
				# ogni catena aggiunta viene da uno di chi non ha tirato; frenare chi sta per liberarsi è da sabotatore
				var low := 99
				for q in e["chi"]:
					low = mini(low, r.players[q].chains)
				for e2 in r.events:
					if e2["t"] == "aggiungi":
						var cand := idle.filter(func(q: int) -> bool: return q != e2["pid"])
						var w := 2.0 if r.players[e2["pid"]].chains - e2["n"] <= low else 0.6
						for q in cand:
							sus[q] += w / cand.size()
	# carte sparite senza effetti: forse un cambio di testimone (o solo carte bruciate perché la mano era piena)
	var unexplained := _cards_before + drawn - r.cards_total() - visible
	if unexplained > 0 and not freed:
		for q in sus.size():
			sus[q] *= pow(0.8, unexplained)
	elif unexplained < 0:
		# più effetti che carte giocate: qualcuno ha usato la carta nascosta del Guardiano; di solito un "Togli" su
		# sé stesso, quindi chi ha ricevuto un "Togli" in questo turno diventa sospetto
		var tg: Array = []
		for e in r.events:
			if e["t"] == "togli":
				tg.append(e["pid"])
		for q in tg:
			sus[q] += 4.0 / tg.size()


## Il sospettato principale secondo questo bot (mai sé stesso). I sabotatori già scoperti non contano più: si cerca
## l'altro (con un solo sabotatore, scoperto lui non resta nessuno e si vota di nuovo lui: non succede nulla).
func suspect(r: CateneRules) -> int:
	if _all_found(r):
		for q in r.n:
			if r.is_sab(q) and q != pid:
				return q
	if known >= 0 and known != pid and r.is_sab(known) and not r.players[known].unmasked:
		return known
	var best := -1
	var bv := -INF
	for q in r.n:
		if q == pid or (r.voters_chained and not q in r.chained()):
			continue
		if (r.is_sab(q) and r.players[q].unmasked) or _mate(r, q):
			continue
		var v: float = sus[q] + rng.randf() * 0.3
		if v > bv:
			bv = v
			best = q
	return best


func _confidence(r: CateneRules) -> float:
	var vals: Array[float] = []
	for q in r.n:
		if q != pid and not (r.is_sab(q) and r.players[q].unmasked):
			vals.append(sus[q])
	if vals.size() < 2:
		return 0.0
	vals.sort()
	return vals[-1] - vals[-2]


# ------------------------------------------------------------------ scelte

func choose(r: CateneRules) -> Dictionary:
	var me := r.players[pid]
	var sab := is_sab(r)
	var others := r.chained().filter(func(q: int) -> bool: return q != pid and not _mate(r, q))
	var leader := _leader(r, others)
	# tirare?
	var behind := others.is_empty() or me.chains >= _median(r, others)
	var p_pull := 0.85 if behind else 0.65
	match style:
		"sempre_tira": p_pull = 1.0
		"mai_tira": p_pull = 0.0
		"ingenuo": p_pull = 0.45 if sab else p_pull
	if sab and style == "furbo":
		p_pull = 0.8
	var pull := rng.randf() < p_pull
	# carta: la migliore della mano
	var best := -1
	var best_v := 0.0
	var best_t := pid
	for i in me.hand.size():
		var res := _value(r, me.hand[i], sab, leader)
		if res[0] > best_v:
			best_v = res[0]
			best = i
			best_t = res[1]
	# il "Togli" nascosto del sabotatore: per sembrare uno che vuole scappare quando si sente osservato, o per non
	# restare il più legato (mai per liberarsi per primo)
	if sab and me.secret > 0 and not (not r.anyone_free and me.chains <= 1):
		var top_other := 0
		for q in others:
			top_other = maxi(top_other, r.players[q].chains)
		if _my_risk(r) >= 1.0 or me.chains >= top_other:
			if best_v < 10.5:
				best = CateneRules.SECRET
				best_v = 10.5
				best_t = pid
	if r.pull_or_card and best >= 0:
		# giocare costa il tiro (e si vede): si gioca solo se ne vale la pena
		var need := 6.0 if not sab else 5.0
		if best_v < need and pull:
			best = -1
		elif best_v >= need:
			pull = false
	var burn := _worst(r, sab) if best < 0 else -1
	return {"pull": pull, "card": best, "target": best_t, "target2": _second(r, best_t), "burn": burn}


## Secondo bersaglio (sab_double): fra gli altri legati, quello con meno catene dopo il primo bersaglio.
func _second(r: CateneRules, first_t: int) -> int:
	var best := -1
	var bv := 99.0
	for q in r.chained():
		if q == pid or q == first_t or _mate(r, q):
			continue
		var v := r.players[q].chains + rng.randf() * 0.5
		if v < bv:
			bv = v
			best = q
	return best


## [valore, bersaglio] di una carta in questo turno.
func _value(r: CateneRules, card: int, sab: bool, leader: int) -> Array:
	var me := r.players[pid]
	var hoard := style == "accumula" and r.candles > 3
	match card:
		C.TOGLI:
			if hoard:
				return [0.0, pid]
			if sab and not r.anyone_free and me.chains <= 1:
				return [0.0, pid]                    # si scoprirebbe da solo
			return [10.0, pid]
		C.AGGIUNGI2:
			if hoard or leader < 0:
				return [0.0, pid]
			return [9.0, _hit_target(r, leader)]
		C.AGGIUNGI:
			if hoard or leader < 0:
				return [0.0, pid]
			var v := 11.0 if style == "aggressivo" else 6.0
			return [v * (0.6 + rng.randf() * 0.6), _hit_target(r, leader)]
		C.SALTA:
			if _open_sab(r) >= 0:
				return [7.0, _open_sab(r)]
			if leader < 0:
				return [0.0, pid]
			return [3.0 + rng.randf() * 2.0, leader]
		C.VOTO:
			if sab or _all_found(r):
				return [0.0, pid]
			var conf := _confidence(r)
			var top := suspect(r)
			if (known >= 0 and known != pid) or (conf >= 2.0 and sus[top] >= 2.0):
				return [12.0, top]
			if r.candles <= 4 and rng.randf() < 0.3:
				return [5.0, top]
			return [0.0, pid]
		C.TESTIMONE:
			if sab and not me.unmasked and style != "ingenuo":
				var risk := _my_risk(r)
				var tgt := _frame_target(r)
				if tgt >= 0 and risk >= 1.0 and rng.randf() < 0.7:
					return [11.0, tgt]
				return [0.0, pid]
			if not sab and rng.randf() < 0.15:
				return [1.0, _frame_target(r)]       # finto passaggio: confonde chi conta le carte
			return [0.0, pid]
	return [0.0, pid]


## Il rivale da appesantire. Il sabotatore frena chi sta per liberarsi (vuole tutti legati); un innocente
## appesantisce chi può bruciare al posto suo: il più legato degli altri (se sono io il più legato, quello subito
## sotto di me, per superarmi). Il sabotatore scoperto è sempre un buon bersaglio.
func _hit_target(r: CateneRules, leader: int) -> int:
	if _open_sab(r) >= 0 and rng.randf() < 0.5:
		return _open_sab(r)
	if is_sab(r) or style == "aggressivo":
		return leader
	var best := -1
	var bv := -1.0
	for q in r.chained():
		var v := r.players[q].chains + rng.randf() * 0.5     # a pari merito si sceglie a caso
		if q != pid and v > bv:
			bv = v
			best = q
	return best if best >= 0 else leader


func _leader(r: CateneRules, others: Array) -> int:
	var best := -1
	var bv := 99
	for q in others:
		var v: int = r.players[q].chains
		if v < bv or (v == bv and rng.randf() < 0.5):
			bv = v
			best = q
	return best


func _median(r: CateneRules, others: Array) -> float:
	var v: Array[int] = []
	for q in others:
		v.append(r.players[q].chains)
	v.sort()
	return float(v[v.size() / 2])


## Quanto il sabotatore si sente osservato: di quanto il suo sospetto pubblico supera quello degli altri legati.
func _my_risk(r: CateneRules) -> float:
	var mine: float = sus[pid]
	var other_max := -INF
	for q in r.chained():
		if q != pid:
			other_max = maxf(other_max, sus[q])
	return mine - other_max + 1.0


## A chi passare il testimone (o su chi far convergere i voti): il legato più sospettato dopo di me.
func _frame_target(r: CateneRules) -> int:
	var best := -1
	var bv := -INF
	for q in r.chained():
		if q == pid or _mate(r, q):
			continue
		var v: float = sus[q] + rng.randf() * 0.3
		if v > bv:
			bv = v
			best = q
	return best


## Indice della carta da bruciare se la mano è piena.
func _worst(r: CateneRules, sab: bool) -> int:
	var me := r.players[pid]
	if me.hand.size() <= r.hand_max:
		return -1
	var order_sab := [C.VOTO, C.SALTA, C.AGGIUNGI, C.TESTIMONE, C.AGGIUNGI2, C.TOGLI]
	var order_inn := [C.TESTIMONE, C.SALTA, C.VOTO, C.AGGIUNGI, C.AGGIUNGI2, C.TOGLI]
	for c in (order_sab if sab else order_inn):
		var i := me.hand.find(c)
		if i >= 0:
			return i
	return 0


## Voto segreto. Il sabotatore mente: vota l'innocente più sospettato per dividere i voti.
func vote(r: CateneRules) -> int:
	if is_sab(r) and not r.players[pid].unmasked:
		var t := _frame_target(r)
		if t < 0:
			t = suspect(r)
		return t
	return suspect(r)


## Chiede il Guardiano? L'innocente quando non è sicuro; il sabotatore a volte, per non distinguersi.
func wants_guardian(r: CateneRules) -> bool:
	if r.guardian_used or _all_found(r):
		return false
	if is_sab(r):
		return rng.randf() < 0.3
	if known >= 0 and known != pid:
		return false
	return _confidence(r) < 2.0 or rng.randf() < 0.3


## Voti già visti e ne manca uno: l'innocente chiama il Guardiano se il quasi condannato è il suo sospettato;
## il sabotatore accetta se il quasi condannato non è lui (un innocente accusato a torto non gli costa nulla).
func asks_guardian_after(r: CateneRules, tally: Dictionary) -> bool:
	var top := -1
	var total := 0
	for q in tally:
		total += tally[q]
	var need := total / 2 + 1 if r.voters_chained else r.majority
	for q in tally:
		if tally[q] == need - 1:
			top = q
	if top < 0:
		return false
	if is_sab(r):
		return top != pid
	return top == suspect(r) or (known >= 0 and top == known)


## Ultimo respiro: gioca subito una carta di catene utile, oppure si ferma ({}).
func burst(r: CateneRules) -> Dictionary:
	var me := r.players[pid]
	var sab := is_sab(r)
	var others := r.chained().filter(func(q: int) -> bool: return q != pid and not _mate(r, q))
	var target := -1
	var tv := -1.0
	for q in others:
		var v := r.players[q].chains + rng.randf() * 0.5
		if v > tv:
			tv = v
			target = q
	if sab and me.secret > 0 and not (not r.anyone_free and me.chains <= 1):
		return {"card": CateneRules.SECRET, "target": pid}
	for i in me.hand.size():
		var c: int = me.hand[i]
		if c == C.TOGLI and not (sab and not r.anyone_free and me.chains <= 1):
			return {"card": i, "target": pid}
	for i in me.hand.size():
		var c: int = me.hand[i]
		if (c == C.AGGIUNGI or c == C.AGGIUNGI2) and target >= 0:
			# se sono il più legato, appesantisco il secondo per superarmi; altrimenti tengo giù il primo
			return {"card": i, "target": target, "target2": _second(r, target)}
	if r.burst_salta:
		# "Salta" ferma chi può ancora togliersi anelli: il rivale con le catene più vicine alle mie
		var rival := -1
		var rd := 99.0
		for q in others:
			var d: float = absf(r.players[q].chains - me.chains) + rng.randf() * 0.5
			if d < rd:
				rd = d
				rival = q
		var si := me.hand.find(C.SALTA)
		if si >= 0 and rival >= 0:
			return {"card": si, "target": rival, "target2": _second(r, rival)}
	return {}


## Chi ha appena passato il testimone sa chi è il nuovo sabotatore.
func learn_pass(new_sab: int) -> void:
	known = new_sab
