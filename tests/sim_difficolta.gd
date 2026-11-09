extends SceneTree
## Confronto delle difficoltà con le regole VERE del gioco di oggi (classi, carte del Custode, Presagi,
## altare, ordine visibile a rotazione; argomenti: senza_carte, ordine_nascosto): quanto vince un giocatore contro tre avversari Normali o Adattivi, e com'è il
## duello. Gli avversari scelgono come nel gioco (CerchioBot.choose + pick_card, strega con l'occhio).
## Uso: godot --headless --path . -s res://tests/sim_difficolta.gd [-- N]

var N := 2000
var st := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0].is_valid_int():
		N = int(args[0])
	print("Manche singole, %d per prova; equilibrio 25%%." % N)
	for row in [["normale", false, "contro 3 Normali (riferimento)"], ["adattivo", false, "ADATTIVO contro 3 Normali"],
			["normale", true, "Normale contro 3 ADATTIVI"], ["principiante", false, "principiante contro 3 Normali"],
			["principiante", true, "principiante contro 3 ADATTIVI"]]:
		var w := _run(row[0], row[1])
		print("  %-32s vince il %4.1f%%   (posti 0-3: %s)" % [row[2], 100.0 * w / N, [st.get("vince_0", 0), st.get("vince_1", 0), st.get("vince_2", 0), st.get("vince_3", 0), st.get("vince_-1", 0)]])
		st = {}
	for all_adaptive in [false, true]:
		st = {}
		_run("adattivo" if all_adaptive else "normale", all_adaptive)
		var m := float(N)
		var lib: float = maxf(st.get("d_lib", 0), 1)
		print("Tutti %s: %.1f giri a manche; duello %.1f giri; nel duello attacco %.0f%%, difesa %.0f%%, riaccendi %.0f%%, abilità %.0f%%; obbligati %.0f%%" % [
			"ADATTIVI" if all_adaptive else "NORMALI", st["giri"] / m, st.get("d_giri", 0) / m,
			100 * st.get("d_0", 0) / lib, 100 * st.get("d_1", 0) / lib, 100 * st.get("d_3", 0) / lib, 100 * st.get("d_2", 0) / lib,
			100 * st.get("d_obb", 0) / maxf(st.get("d_obb", 0) + lib, 1)])
	quit()


func _add(k: String, v := 1.0) -> void:
	st[k] = st.get(k, 0.0) + v


## Gioca N manche; il giocatore 0 usa pol0, gli altri tre sono Adattivi o Normali. Restituisce le vittorie di 0.
func _run(pol0: String, others_adaptive: bool) -> int:
	var wins := 0
	var rng := RandomNumberGenerator.new()
	for g in N:
		rng.seed = g * 7919 + 11
		var classes := [0, 1, 2, 3]
		for i in range(3, 0, -1):
			var j := rng.randi() % (i + 1)
			var t = classes[i]
			classes[i] = classes[j]
			classes[j] = t
		var r := CerchioRules.new()
		r.use_cards = not ("senza_carte" in OS.get_cmdline_user_args())
		r.order_rotate = not ("ordine_nascosto" in OS.get_cmdline_user_args())   # come nel gioco
		r.setup(classes, 4.0, g)
		while not r.is_over() and r.round_no < 300:
			r.begin_round()
			var choices := {}
			var witches: Array[int] = []
			for pid in r.alive_ids():
				if r.players[pid].cls == CerchioRules.Cls.STREGA and r.players[pid].special_left:
					witches.append(pid)
				else:
					choices[pid] = _pick(r, pid, rng, pol0, others_adaptive, {})
			for w in witches:
				var peek := CerchioBot.witch_peek(r, w, rng)
				var known := {}
				if peek >= 0 and choices.has(peek):
					known[peek] = choices[peek]
				var c := _pick(r, w, rng, pol0, others_adaptive, known)
				if not known.is_empty():
					c["peek"] = peek
				choices[w] = c
			if choices.size() == 2:
				_add("d_giri")
				for pid in choices:
					if r.must_attack(pid):
						_add("d_obb")
					else:
						_add("d_lib")
						_add("d_%d" % choices[pid]["move"])
			r.resolve(choices)
			_add("giri")
		_add("vince_%d" % r.winner())
		if r.winner() == 0:
			wins += 1
	return wins


func _pick(r: CerchioRules, pid: int, rng: RandomNumberGenerator, pol0: String, others_adaptive: bool, known: Dictionary) -> Dictionary:
	var adaptive := others_adaptive if pid != 0 else pol0 == "adattivo"
	var temp := 1.2 if pid == 0 and pol0 == "principiante" else Cfg.BOT_TEMP
	return CerchioBot.pick_card(r, pid, CerchioBot.choose(r, pid, rng, temp, known, adaptive), rng)
