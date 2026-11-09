extends SceneTree
## Prova delle regole nuove: niente classi e niente carte; i Patti del Custode e l'orrore di ogni luogo.
## Uso: godot --headless --path . -s res://tests/sim_patti.gd [-- N]
## Misura: durata, tempo da morti, duello, quanto conta saper giocare, strategie fisse, e per ogni patto
## quanto rende accettarlo (prova con accettazione a caso: stesso giocatore, stessa situazione, metà sì metà no).

const SEC_PER_ROUND := 30.0
const SEC_BREAK := 30.0

var N := 2000
var pacts := true
var place := -1
var pact_policy := "furbo"       # come accettano i bot
var pact_when := "morte"
var stats := {}                  # patto -> {offerte, si, no, punti_si, punti_no, vinte_si, vinte_no}
var place_hits := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0].is_valid_int():
		N = int(args[0])
	print("== BASE: niente classi, niente carte, niente Presagi, niente patti")
	pacts = false
	_full()
	pacts = true
	for w in ["giro", "morte"]:
		pact_when = w
		print("\n== PATTI mostrati %s, nessun luogo" % ("al 3o giro" if w == "giro" else "dopo la prima morte"))
		_full()
	for pl in 4:
		place = pl
		print("\n== PATTI + %s" % CerchioRules.PLACE_NAMES[pl].to_upper())
		_full()
	place = -1
	print("\n== QUANTO RENDE OGNI PATTO (bot che accettano a caso: confronto sì / no nella stessa situazione)")
	pact_policy = "caso"
	stats = {}
	for pl in [-1, 0, 1, 2, 3]:
		place = pl
		_match_run("", "")
	place = -1
	pact_policy = "furbo"
	var rows := []
	for k in stats:
		var s: Dictionary = stats[k]
		rows.append("  %-6s offerto %4d volte: punti nella manche %.2f se accetta, %.2f se rifiuta (%+.2f); vince la manche %2.0f%% contro %2.0f%%" % [
			k, s["si"] + s["no"], s["punti_si"] / maxf(s["si"], 1), s["punti_no"] / maxf(s["no"], 1),
			s["punti_si"] / maxf(s["si"], 1) - s["punti_no"] / maxf(s["no"], 1),
			100.0 * s["vinte_si"] / maxf(s["si"], 1), 100.0 * s["vinte_no"] / maxf(s["no"], 1)])
	rows.sort()
	for row in rows:
		print(row)
	quit()


func _full() -> void:
	place_hits = 0
	var s := _match_run("", "")
	_report(s)
	var txt := []
	for pol in ["principiante", "attacca", "difende", "sempre_patto", "due_patti", "mai_patto"]:
		var e := _match_run(pol, "")
		txt.append("%s %.1f%%" % [pol, 100.0 * e["p0_wins"] / N])
	print("  un giocatore diverso contro 3 bot (equilibrio 25%): " + ", ".join(txt))


func _new_rules(seed_value: int) -> CerchioRules:
	var r := CerchioRules.new()
	r.use_cards = false
	r.use_altar = true
	r.setup([0, 1, 2, 3], 4.0, seed_value, "B", false)
	r.initiative = "caso"
	r.order_hidden = true
	r.heal = true
	r.heal_cap = 3.0
	r.use_pacts = pacts
	r.pact_when = pact_when
	r.place = place
	for p in r.players:
		p.special_left = false            # le classi si rifaranno: qui nessuna abilità
	return r


## Una manche. pols[pid]: "" bot normale, "principiante", "attacca", "difende", "sempre_patto", "mai_patto".
func _manche(pols: Array, seed_value: int, rng: RandomNumberGenerator) -> Dictionary:
	var r := _new_rules(seed_value)
	var died: Array[int] = []
	var dead_rounds := [0, 0, 0, 0]
	var ghost_ok := [0, 0, 0, 0]
	var offers := []                      # [pid, patto, accettato]
	var duel_rounds := 0
	var guard := 0
	while not r.is_over() and guard < 300:
		guard += 1
		r.begin_round()
		if not r.offers.is_empty():
			for pid in r.offers.keys():
				if not r.players[pid].alive or r.is_over():
					continue
				var policy := pact_policy
				if pols[pid] == "sempre_patto":
					policy = "uno"
				elif pols[pid] == "mai_patto":
					policy = "mai"
				elif pols[pid] == "due_patti":
					policy = "due"
				var ch := CerchioBot.pact_choice(r, pid, rng, policy)
				if r.players[pid].candles >= 2.0 and not r.offers[pid].has(CerchioRules.Pact.NOME):
					offers.append([pid, -1, ch["picks"].size() == 2, 0])
				for k in r.offers[pid]:
					offers.append([pid, k, ch["picks"].has(k), ch["picks"].size()])
				r.take_pacts(pid, ch["picks"], ch["target"])
			for d in r.begin_deaths:
				died.append(d)
			if r.is_over():
				break
		# chi ha la mossa visibile sceglie per primo; gli altri scelgono sapendo
		var visible: Array[int] = []
		for pid in r.alive_ids():
			for v in r.alive_ids():
				if r.sees(v, pid) and not visible.has(pid):
					visible.append(pid)
		var order: Array[int] = visible.duplicate()
		for pid in r.alive_ids():
			if not order.has(pid):
				order.append(pid)
		var choices := {}
		for pid in order:
			var known := {}
			for q in visible:
				if choices.has(q) and r.sees(pid, q):
					known[q] = choices[q]
			match pols[pid]:
				"principiante":
					choices[pid] = CerchioBot.choose(r, pid, rng, 1.2, known)
				"attacca", "difende":
					choices[pid] = _exploit(r, pid, pols[pid], rng)
				_:
					choices[pid] = CerchioBot.choose(r, pid, rng, 0.3, known)
		if choices.size() == 2:
			duel_rounds += 1
		var bets := {}
		var before := {}
		for i in 4:
			if not r.players[i].alive:
				bets[i] = CerchioBot.ghost_pick(r, rng)
		for pid in r.alive_ids():
			before[pid] = r.players[pid].candles
		var rep := r.resolve(choices)
		place_hits += rep.get("place_hits", 0)
		for i in bets:
			var t: int = bets[i]
			if r.players[t].candles < before[t]:
				ghost_ok[i] += 1
		for d in rep["deaths"]:
			died.append(d)
		for i in 4:
			if not r.players[i].alive:
				dead_rounds[i] += 1
	var pact_of := []
	for i in 4:
		pact_of.append(r.players[i].pacts)
	return {"winner": r.winner(), "died": died, "rounds": r.round_no, "dead_rounds": dead_rounds,
		"ghost_ok": ghost_ok, "offers": offers, "pact_of": pact_of, "duel": duel_rounds}


## Partita a tre manche a punti (3-2-1-0, la terza doppia).
func _match_run(p0: String, _x: String) -> Dictionary:
	var s := {"minutes": [], "waiting": 0.0, "p0_wins": 0, "duel": 0, "early": 0, "comeback": 0, "pacts": 0}
	var rng := RandomNumberGenerator.new()
	for g in N:
		rng.seed = g * 104729 + 7 + (place + 1) * 31
		var pols := [p0, "", "", ""]
		var points := [0, 0, 0, 0]
		var last_place := [0, 0, 0, 0]
		var total_rounds := 0
		var spectate := [0, 0, 0, 0]
		var leader_after_1 := -1
		for manche_no in range(1, 4):
			var m := _manche(pols, g * 10 + manche_no + (place + 1) * 100000, rng)
			total_rounds += m["rounds"]
			s["duel"] += m["duel"]
			for pid in 4:
				spectate[pid] += m["dead_rounds"][pid]
			var order := []
			for d in m["died"]:
				order.append(d)
			if m["winner"] >= 0:
				order.append(m["winner"])
			var mult := 2 if manche_no == 3 else 1
			var gained := [0, 0, 0, 0]
			for k in 4:
				gained[k] += mini(1, m["ghost_ok"][k] / 2)
			for pl in order.size():
				var pid: int = order[pl]
				var pts: int = pl * mult
				gained[pid] += pts
				if manche_no == 3:
					last_place[pid] = pl
			for pid in 4:
				points[pid] += gained[pid]
			for o in m["offers"]:
				s["pacts"] += 1 if o[2] and o[1] >= 0 else 0
				var name: String = "DUE PATTI" if o[1] < 0 else CerchioRules.PACT_NAMES[o[1]]
				if not stats.has(name):
					stats[name] = {"si": 0, "no": 0, "punti_si": 0.0, "punti_no": 0.0, "vinte_si": 0, "vinte_no": 0}
				var key := "si" if o[2] else "no"
				stats[name][key] += 1
				stats[name]["punti_" + key] += float(gained[o[0]]) / mult
				if m["winner"] == o[0]:
					stats[name]["vinte_" + key] += 1
			if manche_no == 1:
				leader_after_1 = m["winner"]
			if manche_no == 2:
				var sorted := points.duplicate()
				sorted.sort()
				if sorted[3] - sorted[2] > 6:
					s["early"] += 1
		var best := 0
		for pid in 4:
			if points[pid] > points[best] or (points[pid] == points[best] and last_place[pid] > last_place[best]):
				best = pid
		if best == 0:
			s["p0_wins"] += 1
		if leader_after_1 >= 0 and leader_after_1 != best:
			s["comeback"] += 1
		s["minutes"].append((total_rounds * SEC_PER_ROUND + 2 * SEC_BREAK) / 60.0)
		var share := 0.0
		for pid in 4:
			share += float(spectate[pid]) / total_rounds
		s["waiting"] += share / 4.0
	return s


func _exploit(r: CerchioRules, me: int, pol: String, rng: RandomNumberGenerator) -> Dictionary:
	var weakest := -1
	for t in r.attack_targets(me):
		if weakest < 0 or r.players[t].candles < r.players[weakest].candles:
			weakest = t
	if pol == "difende" and not r.must_attack(me):
		var opts := r.legal_choices(me)
		var defs := opts.filter(func(c): return c["move"] == CerchioRules.Move.DEFEND)
		if not defs.is_empty():
			var last: Array[int] = r.players[me].attacked_me_last
			if not last.is_empty() and r.alive_ids().has(last[0]):
				return {"move": CerchioRules.Move.DEFEND, "target": last[0]}
			return defs[rng.randi() % defs.size()]
	return {"move": CerchioRules.Move.ATTACK, "target": weakest}


func _report(s: Dictionary) -> void:
	var mins: Array = s["minutes"]
	mins.sort()
	var avg := 0.0
	for x in mins:
		avg += x
	avg /= mins.size()
	print("  durata: media %.1f min (10%% %.1f, 90%% %.1f); duello %.1f giri a partita; patti accettati %.1f a partita; colpi del luogo %.1f a partita" % [
		avg, mins[int(0.1 * (N - 1))], mins[int(0.9 * (N - 1))], float(s["duel"]) / N, float(s["pacts"]) / N, float(place_hits) / N])
	print("  tempo da morti %.0f%%; rimonte (vince chi non ha vinto la 1a manche) %.0f%%; già decise prima della 3a %.1f%%" % [
		100.0 * s["waiting"] / N, 100.0 * s["comeback"] / N, 100.0 * s["early"] / N])
