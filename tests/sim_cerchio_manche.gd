extends SceneTree
## Prototipo: partite a tre manche. Confronta modi di giocare le manche e l'iniziativa che evita i pareggi.
## Uso: godot --headless --path . -s res://tests/sim_cerchio_manche.gd
## Minuti stimati: SEC_PER_ROUND a giro più SEC_BREAK fra una manche e l'altra.

const SEC_PER_ROUND := 30.0
const SEC_BREAK := 30.0
const N := 2000

# impostazioni correnti della prova
var candles := 4.0
var initiative := "caso"
var elf_first := false
var special_scope := "partita"   # "partita" (una volta per tutta la partita) o "manche"
var fire_last := false
var ghost_bets := false        # scommessa dello spettro: i morti indovinano chi sanguinerà
var order_hidden := false      # ordine di iniziativa svelato solo dopo le scelte
var heal := false              # mossa "riaccendi una candela"
var heal_cap := 99.0
var cards := false             # carte del Custode
var altar_on := false          # altare al centro (riaccendere prende le fiamme spente)
var take_all := false
var take_cap := 3.0
var patto_cost := 0.0
var card_stats := {}           # carta -> {giocate, tenute, vinte}
var duel := {}                 # giri a due: quante volte e con quali mosse


func _init() -> void:
	if OS.get_cmdline_user_args().has("spettri"):
		_spettri()
		quit()
		return
	if OS.get_cmdline_user_args().has("carte"):
		_carte()
		quit()
		return
	if OS.get_cmdline_user_args().has("ordine"):
		_ordine()
		quit()
		return
	if OS.get_cmdline_user_args().has("rifinitura"):
		_rifinitura()
		quit()
		return
	print("== INIZIATIVA (una manche a 4, 4 candele, 3000 partite): pareggi ed equilibrio")
	for v in [["nessuna", false], ["caso", false], ["caso", true], ["deboli", false], ["deboli", true]]:
		initiative = v[0]
		elf_first = v[1]
		var s := _single(3000)
		print("  %-8s elfo primo %-5s  pareggi %4.1f%%  colpi annullati dall'iniziativa %.2f a manche  vittorie: %s" % [
			v[0], str(v[1]), 100.0 * s["draws"] / 3000, float(s["first_strike"]) / 3000, s["wins"]])
	initiative = "caso"
	elf_first = true
	for fmt in ["eliminazione", "punti", "primo2"]:
		for sc in ["partita", "manche"]:
			for c in [4.0, 5.0]:
				candles = c
				special_scope = sc
				print("\n== %s, abilità una volta per %s, %d candele" % [fmt.to_upper(), sc, c])
				_report(_match_run(fmt, ""), fmt)
	print("\n== ABILITÀ CONTA? (eliminazione, 5 candele, abilità per manche): un giocatore diverso contro 3 bot")
	candles = 5.0
	special_scope = "manche"
	for pol in ["principiante", "attacca", "difende"]:
		var s := _match_run("eliminazione", pol)
		print("  %-12s vince il %4.1f%% delle partite (equilibrio 25%%)" % [pol, 100.0 * s["p0_wins"] / N])
	quit()


func _new_rules(classes: Array, seed_value: int) -> CerchioRules:
	var r := CerchioRules.new()
	r.use_cards = cards
	r.use_altar = altar_on
	r.altar_take_all = take_all
	r.heal_take_cap = take_cap
	r.patto_cost = patto_cost
	r.setup(classes, candles, seed_value)
	r.initiative = initiative
	r.elf_first = elf_first
	r.fire_last = fire_last
	r.order_hidden = order_hidden
	r.heal = heal
	r.heal_cap = heal_cap
	return r


## Gioca una manche. pols: politica per partecipante ("" bot normale). special: chi ha ancora l'abilità.
## Restituisce vincitore (indice), ordine di morte, giri e giri passati da morto per partecipante.
func _manche(classes: Array, pols: Array, special: Array, seed_value: int, rng: RandomNumberGenerator) -> Dictionary:
	var r := _new_rules(classes, seed_value)
	for i in classes.size():
		r.players[i].special_left = special[i]
	var start_hands := []
	for i in classes.size():
		start_hands.append(r.players[i].hand.duplicate())
	var died: Array[int] = []
	var dead_rounds := []
	dead_rounds.resize(classes.size())
	dead_rounds.fill(0)
	var first_strike := 0
	var ghost_ok := []
	ghost_ok.resize(classes.size())
	ghost_ok.fill(0)
	var guard := 0
	while not r.is_over() and guard < 300:
		guard += 1
		r.begin_round()
		var choices := {}
		var witches: Array[int] = []
		for pid in r.alive_ids():
			var pol: String = pols[pid]
			if pol == "principiante":
				choices[pid] = CerchioBot.choose(r, pid, rng, 1.2)
			elif pol != "":
				choices[pid] = _exploit(r, pid, pol, rng)
			elif r.players[pid].cls == CerchioRules.Cls.STREGA and r.players[pid].special_left:
				witches.append(pid)
			else:
				choices[pid] = CerchioBot.choose(r, pid, rng)
		for w in witches:
			var peek := CerchioBot.witch_peek(r, w, rng)
			var known := {}
			if peek >= 0 and choices.has(peek):
				known[peek] = choices[peek]
			var c := CerchioBot.choose(r, w, rng, 0.3, known)
			if not known.is_empty():
				c["peek"] = peek
			choices[w] = c
		if cards:
			for pid in choices:
				if pols[pid] == "" or pols[pid] == "principiante":
					choices[pid] = CerchioBot.pick_card(r, pid, choices[pid], rng)
		if choices.size() == 2:
			_count_duel(r, choices)
		var bets := {}
		var before := {}
		if ghost_bets:
			for i in classes.size():
				if not r.players[i].alive:
					bets[i] = _ghost_pick(r, rng)
			for pid in r.alive_ids():
				before[pid] = r.players[pid].candles
		var rep := r.resolve(choices)
		first_strike += rep["first_strike"]
		for pid in rep.get("played", {}):
			var k: String = CerchioRules.CARD_NAMES[rep["played"][pid]]
			if not card_stats.has(k):
				card_stats[k] = {"giocate": 0, "tenute": 0, "vinte": 0}
			card_stats[k]["giocate"] += 1
		for i in bets:
			var t: int = bets[i]
			if r.players[t].candles < before[t]:
				ghost_ok[i] += 1
		for d in rep["deaths"]:
			died.append(d)
		for i in classes.size():
			if not r.players[i].alive:
				dead_rounds[i] += 1
	var left := []
	for i in classes.size():
		left.append(r.players[i].special_left)
	for i in classes.size():
		var seen := {}
		for kk in start_hands[i]:
			if seen.has(kk):
				continue
			seen[kk] = true
			var k: String = CerchioRules.CARD_NAMES[kk]
			if not card_stats.has(k):
				card_stats[k] = {"giocate": 0, "tenute": 0, "vinte": 0}
			card_stats[k]["tenute"] += 1
			if r.winner() == i:
				card_stats[k]["vinte"] += 1
	return {"winner": r.winner(), "died": died, "rounds": r.round_no, "dead_rounds": dead_rounds,
		"special_left": left, "first_strike": first_strike, "ghost_ok": ghost_ok}


func _shuffled_classes(rng: RandomNumberGenerator) -> Array:
	var classes := [CerchioRules.Cls.CAVALIERE, CerchioRules.Cls.STREGA, CerchioRules.Cls.ELFO, CerchioRules.Cls.DOMATORE]
	for i in range(3, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = classes[i]
		classes[i] = classes[j]
		classes[j] = t
	return classes


func _single(n: int) -> Dictionary:
	var s := {"draws": 0, "first_strike": 0, "wins": {}}
	var rng := RandomNumberGenerator.new()
	for g in n:
		rng.seed = g * 7919 + 13
		var classes := _shuffled_classes(rng)
		var m := _manche(classes, ["", "", "", ""], [true, true, true, true], g, rng)
		s["first_strike"] += m["first_strike"]
		if m["winner"] < 0:
			s["draws"] += 1
		else:
			var k: String = CerchioRules.CLS_NAMES[classes[m["winner"]]]
			s["wins"][k] = s["wins"].get(k, 0) + 1
	var out := {}
	for k in s["wins"]:
		out[k] = "%.0f%%" % (100.0 * s["wins"][k] / n)
	s["wins"] = out
	return s


## Una partita intera nel formato dato. p0: politica del giocatore 0 ("" = tutti bot normali).
func _match_run(fmt: String, p0: String) -> Dictionary:
	var s := {"first_dead_wins": 0, "minutes": [], "manches": 0, "draws": 0, "wins": {}, "waiting": 0.0, "early": 0, "p0_wins": 0,
		"comeback": 0, "giudizio": 0}
	var rng := RandomNumberGenerator.new()
	for g in N:
		rng.seed = g * 104729 + 7
		var classes := _shuffled_classes(rng)
		var pols := [p0, "", "", ""]
		var special := [true, true, true, true]
		var in_match := [0, 1, 2, 3]
		var points := [0, 0, 0, 0]
		var manche_wins := [0, 0, 0, 0]
		var last_place := [0, 0, 0, 0]
		var total_rounds := 0
		var spectate := [0, 0, 0, 0]   # giri passati senza giocare (morto o eliminato)
		var manche_no := 0
		var winner := -1
		var leader_after_1 := -1
		var first_dead_m1 := -1
		while winner < 0 and manche_no < 6:
			manche_no += 1
			var cls_now := []
			var pol_now := []
			var sp_now := []
			for pid in in_match:
				cls_now.append(classes[pid])
				pol_now.append(pols[pid])
				sp_now.append(special[pid] if special_scope == "partita" else true)
			var m := _manche(cls_now, pol_now, sp_now, g * 10 + manche_no, rng)
			if m["winner"] < 0:
				s["draws"] += 1
			total_rounds += m["rounds"]
			for pid in 4:
				var k := in_match.find(pid)
				spectate[pid] += m["rounds"] if k < 0 else m["dead_rounds"][k]
			if special_scope == "partita":
				for k in in_match.size():
					special[in_match[k]] = m["special_left"][k]
			var mw: int = in_match[m["winner"]] if m["winner"] >= 0 else -1
			var order := []                # dal primo morto al vincitore
			for d in m["died"]:
				order.append(in_match[d])
			if mw >= 0:
				order.append(mw)
			match fmt:
				"eliminazione":
					if in_match.size() > 2:
						in_match.erase(order[0])
					else:
						winner = mw
				"punti":
					var mult := 2 if manche_no == 3 else 1
					if ghost_bets:
						for k in in_match.size():
							points[in_match[k]] += mini(1, m["ghost_ok"][k] / 2)
					for place in order.size():
						points[order[place]] += place * mult
						if manche_no == 3:
							last_place[order[place]] = place
					if manche_no == 2:
						# deciso prima dell'ultima manche: il primo non può più essere raggiunto (max 6 punti in palio)
						var sorted := points.duplicate()
						sorted.sort()
						if sorted[3] - sorted[2] > 6:
							s["early"] += 1
					if manche_no == 3:
						var best := 0
						for pid in 4:
							if points[pid] > points[best] or (points[pid] == points[best] and last_place[pid] > last_place[best]):
								best = pid
						winner = best
				"primo2":
					if mw >= 0:
						manche_wins[mw] += 1
						if manche_wins[mw] >= 2:
							winner = mw
					if winner < 0 and manche_no == 3:
						# tre vincitori diversi: il Giudizio, una manche fra loro
						s["giudizio"] += 1
						in_match = []
						for pid in 4:
							if manche_wins[pid] > 0:
								in_match.append(pid)
			if manche_no == 1 and not order.is_empty():
				first_dead_m1 = order[0]
			if manche_no == 1:
				leader_after_1 = mw
		if winner < 0:
			winner = 0
		if leader_after_1 >= 0 and leader_after_1 != winner:
			s["comeback"] += 1
		s["manches"] += manche_no
		s["minutes"].append((total_rounds * SEC_PER_ROUND + (manche_no - 1) * SEC_BREAK) / 60.0)
		var share := 0.0
		for pid in 4:
			share += float(spectate[pid]) / total_rounds
		s["waiting"] += share / 4.0
		var k: String = CerchioRules.CLS_NAMES[classes[winner]]
		s["wins"][k] = s["wins"].get(k, 0) + 1
		if winner == first_dead_m1:
			s["first_dead_wins"] += 1
		if winner == 0:
			s["p0_wins"] += 1
	return s


func _exploit(r: CerchioRules, me: int, pol: String, rng: RandomNumberGenerator) -> Dictionary:
	var weakest := -1
	for t in r.attack_targets(me):
		if weakest < 0 or r.players[t].candles < r.players[weakest].candles:
			weakest = t
	if pol == "difende" and not r.must_attack(me):
		var last: Array[int] = r.players[me].attacked_me_last
		var opts := r.defend_targets(me)
		return {"move": CerchioRules.Move.DEFEND, "target": last[0] if not last.is_empty() else opts[rng.randi() % opts.size()]}
	return {"move": CerchioRules.Move.ATTACK, "target": weakest}


func _report(s: Dictionary, fmt: String) -> void:
	var mins: Array = s["minutes"]
	mins.sort()
	var avg := 0.0
	for x in mins:
		avg += x
	avg /= mins.size()
	print("  durata: media %.1f min (10%% %.1f, metà %.1f, 90%% %.1f)   manche in media %.2f" % [avg, mins[int(0.1 * (N - 1))],
		mins[int(0.5 * (N - 1))], mins[int(0.9 * (N - 1))], float(s["manches"]) / N])
	var wins := []
	for k in CerchioRules.CLS_NAMES:
		wins.append("%s %.0f%%" % [k, 100.0 * s["wins"].get(k, 0) / N])
	print("  manche senza vincitore: %d   vittorie: %s" % [s["draws"], ", ".join(wins)])
	print("  tempo passato a guardare (morti o eliminati): %.0f%%   rimonte (vince chi non ha vinto la 1a manche): %.0f%%" % [
		100.0 * s["waiting"] / N, 100.0 * s["comeback"] / N])
	if fmt == "punti":
		print("  già decise prima dell'ultima manche: %.1f%%" % (100.0 * s["early"] / N))
	if fmt == "primo2":
		print("  serve il Giudizio (tre vincitori diversi): %.0f%%" % (100.0 * s["giudizio"] / N))


## Formato a punti: correzioni al domatore (drago per ultimo) e all'iniziativa.
func _rifinitura() -> void:
	special_scope = "partita"
	for v in [["caso", false, false], ["caso", false, true], ["caso", true, true], ["deboli", false, true]]:
		for c in [4.0, 5.0]:
			initiative = v[0]
			elf_first = v[1]
			fire_last = v[2]
			candles = c
			print("\n== PUNTI %d candele: iniziativa %s, elfo primo %s, drago per ultimo %s" % [c, v[0], str(v[1]), str(v[2])])
			_report(_match_run("punti", ""), "punti")
	initiative = "caso"
	elf_first = false
	fire_last = true
	candles = 5.0
	print("\n== ABILITÀ CONTA? (punti, 5 candele, caso, drago per ultimo)")
	for pol in ["principiante", "attacca", "difende"]:
		var s := _match_run("punti", pol)
		print("  %-12s vince il %4.1f%% delle partite (equilibrio 25%%)" % [pol, 100.0 * s["p0_wins"] / N])


## Ordine di iniziativa mostrato prima delle scelte o svelato dopo; mossa "riaccendi una candela".
## Misura soprattutto il duello finale (giri a due).
func _ordine() -> void:
	special_scope = "partita"
	initiative = "caso"
	fire_last = false
	ghost_bets = true
	for v in [[true, true, 5.0, "ordine DOPO + riaccendi fino a 3", 3.0], [true, true, 5.0, "ordine DOPO + riaccendi fino a 2", 2.0],
			[true, true, 4.0, "ordine DOPO + riaccendi fino a 3, 4 candele", 3.0]]:
		order_hidden = v[0]
		heal = v[1]
		candles = v[2]
		heal_cap = v[4]
		duel = {}
		print("\n== PUNTI %d candele, %s" % [v[2], v[3]])
		var s := _match_run("punti", "")
		_report(s, "punti")
		var d: float = maxf(duel.get("giri", 0), 1)
		var lib: float = maxf(duel.get("liberi", 0), 1)
		print("  duello finale: %.1f giri a partita, %.0f%% con qualcuno obbligato ad attaccare" % [
			duel.get("giri", 0) / float(N), 100.0 * duel.get("obbligati", 0) / d])
		var combos := []
		for k in duel:
			if k.begins_with("+"):
				combos.append([duel[k], k.substr(1)])
		combos.sort()
		combos.reverse()
		var txt := []
		for c in combos:
			txt.append("%s %.0f%%" % [c[1], 100.0 * c[0] / lib])
		print("  giri liberi del duello: ", ", ".join(txt))
		for pol in ["principiante", "attacca", "difende"]:
			var e := _match_run("punti", pol)
			print("  %-12s vince il %4.1f%%" % [pol, 100.0 * e["p0_wins"] / N])


## Carte del Custode, altare e Presagi nuovi: confronto e peso di ogni carta.
func _carte() -> void:
	special_scope = "partita"
	initiative = "caso"
	order_hidden = true
	heal = true
	heal_cap = 3.0
	ghost_bets = true
	for v in [[false, false, 4.0, "senza carte, senza altare", false, 3.0, 0.0],
			[true, true, 4.0, "carte + altare (una fiamma), il Patto costa 1 candela", false, 3.0, 1.0],
			[true, true, 4.0, "carte + altare (prendi tutto, fino a 3: scartata, troppo lunga)", true, 3.0, 1.0]]:
		take_all = v[4]
		take_cap = v[5]
		patto_cost = v[6]
		cards = v[0]
		altar_on = v[1]
		candles = v[2]
		card_stats = {}
		duel = {}
		print("\n== PUNTI %d candele, Presagi nuovi, %s" % [v[2], v[3]])
		var s := _match_run("punti", "")
		_report(s, "punti")
		print("  duello finale: %.1f giri a partita" % (duel.get("giri", 0) / float(N)))
		if cards:
			var rows := []
			for k in card_stats:
				var cs: Dictionary = card_stats[k]
				rows.append("%s: giocata %.2f a partita, chi l'ha in mano vince la manche il %.0f%%" % [k,
					cs["giocate"] / float(N), 100.0 * cs["vinte"] / maxf(cs["tenute"], 1)])
			rows.sort()
			for row in rows:
				print("    " + row)
		for pol in ["principiante", "attacca", "difende"]:
			var e := _match_run("punti", pol)
			print("  %-12s vince il %4.1f%%" % [pol, 100.0 * e["p0_wins"] / N])


## Conta le scelte nei giri a due: quanti obbligati e, nei giri liberi, quali coppie di mosse.
func _count_duel(r: CerchioRules, choices: Dictionary) -> void:
	var names := ["attacco", "difesa", "speciale", "candela"]
	var forced := false
	var moves := []
	for pid in choices:
		forced = forced or r.must_attack(pid)
		moves.append(names[choices[pid]["move"]])
	moves.sort()
	duel["giri"] = duel.get("giri", 0) + 1
	if forced:
		duel["obbligati"] = duel.get("obbligati", 0) + 1
		return
	duel["liberi"] = duel.get("liberi", 0) + 1
	var k := "+" + "/".join(moves)
	duel[k] = duel.get(k, 0) + 1


## Lo spettro scommette sul vivo più esposto: meno candele, poi chi è stanco.
func _ghost_pick(r: CerchioRules, rng: RandomNumberGenerator) -> int:
	var best := -1
	var best_v := 1e9
	for pid in r.alive_ids():
		var v := r.players[pid].candles - (0.5 if r.players[pid].tired else 0.0) + rng.randf() * 0.3
		if v < best_v:
			best_v = v
			best = pid
	return best


func _spettri() -> void:
	special_scope = "partita"
	initiative = "caso"
	fire_last = true
	candles = 5.0
	for gb in [false, true]:
		ghost_bets = gb
		print("\n== PUNTI 5 candele, scommessa dello spettro: %s" % str(gb))
		var s := _match_run("punti", "")
		_report(s, "punti")
		print("  vince la partita chi è morto per primo nella 1a manche: %.1f%%" % (100.0 * s["first_dead_wins"] / N))
		for pol in ["principiante", "attacca"]:
			var e := _match_run("punti", pol)
			print("  %-12s vince il %4.1f%%" % [pol, 100.0 * e["p0_wins"] / N])
