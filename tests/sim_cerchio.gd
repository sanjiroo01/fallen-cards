extends SceneTree
## Prototipo del gioco nuovo (docs/progetto.md): gioca migliaia di partite fra bot e misura durata,
## equilibrio delle classi, giri senza sangue, mosse usate e strategie dominanti.
## Uso: godot --headless --path . -s res://tests/sim_cerchio.gd
## La stima dei minuti assume SEC_PER_ROUND secondi per giro (scelta + rivelazione animata).

const SEC_PER_ROUND := 30.0

var fire_counter := false


func _init() -> void:
	if OS.get_cmdline_user_args().has("correzioni"):
		fire_counter = true
		for c in [4.0, 8.0, 10.0, 12.0]:
			print("\n== CORREZIONE: soffio con contrattacco, %d candele" % c)
			_report(_run(2000, c, "B", true, ""))
		quit()
		return
	print("== BASE: 4 candele, stanchezza B, Presagi")
	_report(_run(3000, 4.0, "B", true, ""))
	for v in [[3.0, "B", true, "3 candele"], [5.0, "B", true, "5 candele"], [4.0, "A", true, "stanchezza A (mezza candela)"],
			[4.0, "B", false, "senza Presagi"]]:
		print("\n== VARIANTE: ", v[3])
		_report(_run(2000, v[0], v[1], v[2], ""))
	print("\n== STRATEGIE FURBE (un giocatore contro 3 bot normali; equilibrio = 25%)")
	for pol in ["attacca", "difende", "casuale"]:
		var s := _run(2000, 4.0, "B", true, pol)
		print("  %-8s vince il %4.1f%%   (pareggi %4.1f%%)" % [pol, 100.0 * s["exploit_wins"] / s["games"],
			100.0 * s["draws"] / s["games"]])
	quit()


## Gioca n partite. exploit: politica del giocatore 0 ("" = tutti bot normali).
func _run(n: int, candles: float, fatigue: String, omens: bool, exploit: String) -> Dictionary:
	var s := {"games": n, "rounds": [], "draws": 0, "wins": {}, "stall": 0, "stall_streak": 0, "round_total": 0,
		"moves": {"attacco": 0, "difesa": 0, "speciale": 0}, "counters": 0, "hits": 0, "tired": 0, "fire": 0,
		"oath": 0, "ira": 0, "exploit_wins": 0, "special_round": {}, "special_unused": 0}
	var rng := RandomNumberGenerator.new()
	for g in n:
		rng.seed = g * 7919 + 13
		var classes := [CerchioRules.Cls.CAVALIERE, CerchioRules.Cls.STREGA, CerchioRules.Cls.ELFO, CerchioRules.Cls.DOMATORE]
		for i in range(3, 0, -1):
			var j := rng.randi() % (i + 1)
			var t = classes[i]
			classes[i] = classes[j]
			classes[j] = t
		var r := CerchioRules.new()
		r.setup(classes, candles, g, fatigue, omens)
		r.fire_counter = fire_counter
		var streak := 0
		var guard := 0
		while not r.is_over() and guard < 300:
			guard += 1
			r.begin_round()
			var choices := {}
			var witches: Array[int] = []
			for pid in r.alive_ids():
				if pid == 0 and exploit != "":
					choices[pid] = _exploit(r, pid, exploit, rng)
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
			for pid in choices:
				var c: Dictionary = choices[pid]
				match c["move"]:
					CerchioRules.Move.ATTACK: s["moves"]["attacco"] += 1
					CerchioRules.Move.DEFEND: s["moves"]["difesa"] += 1
					CerchioRules.Move.SPECIAL: s["moves"]["speciale"] += 1
				if c["move"] == CerchioRules.Move.SPECIAL or c.has("peek"):
					var k: String = CerchioRules.CLS_NAMES[r.players[pid].cls]
					s["special_round"][k] = s["special_round"].get(k, []) + [r.round_no]
			var rep := r.resolve(choices)
			s["counters"] += rep["counters"]
			s["hits"] += rep["hits"]
			s["tired"] += rep["tired_new"]
			s["fire"] += rep["fire"]
			s["oath"] += rep["oath_saves"]
			s["ira"] += 1 if rep["ira"] else 0
			if rep["damage"] == 0.0:
				s["stall"] += 1
				streak += 1
				s["stall_streak"] = maxi(s["stall_streak"], streak)
			else:
				streak = 0
		s["rounds"].append(r.round_no)
		s["round_total"] += r.round_no
		for p in r.players:
			if p.special_left:
				s["special_unused"] += 1
		var w := r.winner()
		if w < 0:
			s["draws"] += 1
		else:
			var k: String = CerchioRules.CLS_NAMES[r.players[w].cls]
			s["wins"][k] = s["wins"].get(k, 0) + 1
			if exploit != "" and w == 0:
				s["exploit_wins"] += 1
	return s


## Strategie semplici per cercare mosse dominanti.
func _exploit(r: CerchioRules, me: int, pol: String, rng: RandomNumberGenerator) -> Dictionary:
	var opts := r.legal_choices(me)
	if pol == "casuale":
		return opts[rng.randi() % opts.size()]
	var weakest := -1
	for t in r.attack_targets(me):
		if weakest < 0 or r.players[t].candles < r.players[weakest].candles:
			weakest = t
	if pol == "difende" and not r.must_attack(me):
		var last: Array[int] = r.players[me].attacked_me_last
		var from := last[0] if not last.is_empty() else r.defend_targets(me)[rng.randi() % r.defend_targets(me).size()]
		return {"move": CerchioRules.Move.DEFEND, "target": from}
	return {"move": CerchioRules.Move.ATTACK, "target": weakest}


func _report(s: Dictionary) -> void:
	var rounds: Array = s["rounds"]
	rounds.sort()
	var n: int = s["games"]
	var avg := float(s["round_total"]) / n
	var p := func(q: float) -> int: return rounds[int(q * (rounds.size() - 1))]
	print("  giri a partita: media %.1f  (10%% %d, metà %d, 90%% %d)  -> circa %.0f minuti (%.0f-%.0f)" % [avg, p.call(0.1),
		p.call(0.5), p.call(0.9), avg * SEC_PER_ROUND / 60.0, p.call(0.1) * SEC_PER_ROUND / 60.0, p.call(0.9) * SEC_PER_ROUND / 60.0])
	print("  pareggi (gli ultimi muoiono insieme): %.1f%%" % (100.0 * s["draws"] / n))
	var wins := []
	for k in CerchioRules.CLS_NAMES:
		wins.append("%s %.1f%%" % [k, 100.0 * s["wins"].get(k, 0) / n])
	print("  vittorie per classe: ", ", ".join(wins))
	print("  giri senza sangue: %.1f%%  (serie più lunga %d)   ira del Custode: %d" % [100.0 * s["stall"] / s["round_total"],
		s["stall_streak"], s["ira"]])
	var m: Dictionary = s["moves"]
	var tot := float(m["attacco"] + m["difesa"] + m["speciale"])
	print("  mosse: attacco %.0f%%, difesa %.0f%%, speciale %.0f%%   a giro: colpi %.2f, contrattacchi %.2f, nuovi stanchi %.2f" % [
		100.0 * m["attacco"] / tot, 100.0 * m["difesa"] / tot, 100.0 * m["speciale"] / tot, float(s["hits"]) / s["round_total"],
		float(s["counters"]) / s["round_total"], float(s["tired"]) / s["round_total"]])
	var sp := []
	for k in CerchioRules.CLS_NAMES:
		var lst: Array = s["special_round"].get(k, [])
		if not lst.is_empty():
			var sum := 0
			for x in lst:
				sum += x
			sp.append("%s giro %.1f" % [k, float(sum) / lst.size()])
	print("  abilità usate in media al: ", ", ".join(sp), "   mai usate: %.0f%% dei giocatori" % (100.0 * s["special_unused"] / (n * 4.0)))
