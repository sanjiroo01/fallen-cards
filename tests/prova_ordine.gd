extends SceneTree
## Prova dell'ordine visibile a rotazione e di come lo usano gli avversari.
## Uso: godot --headless --path . -s res://tests/prova_ordine.gd

var errori := 0


func _init() -> void:
	# 1. rotazione: il primo posto passa al vivo successivo, i morti si saltano, l'ordine non cambia dopo le scelte
	var r := _rules()
	r.begin_round()
	var f1: int = r.order[0]
	_check(r.order.size() == 4 and not r.order_hidden, "giro 1: ordine di 4, visibile prima delle scelte")
	var before := r.order.duplicate()
	r.resolve(_all_heal(r))
	_check(r.order == before, "la risoluzione usa lo stesso ordine mostrato")
	r.begin_round()
	_check(r.order[0] == (f1 + 1) % 4, "giro 2: il primo è il successivo (%d -> %d)" % [f1, r.order[0]])
	var dead := (r.order[0] + 1) % 4
	r.players[dead].alive = false
	r.players[dead].candles = 0.0
	r.resolve(_all_heal(r))
	var f2: int = r.order[0]
	r.begin_round()
	var expect := (f2 + 1) % 4
	if expect == dead:
		expect = (expect + 1) % 4
	_check(r.order[0] == expect and not r.order.has(dead), "un morto viene saltato (%d -> %d)" % [f2, r.order[0]])
	_check(r.order.size() == 3, "l'ordine contiene solo i vivi")
	# 2. gli Adattivi usano l'ordine: duello, io (0) con 1 candela, l'avversario (1) attacca spesso
	var att_after := _attack_rate(1)     # l'avversario colpisce DOPO di me
	var att_before := _attack_rate(0)    # l'avversario colpisce PRIMA di me
	print("  Adattivo con 1 candela attacca: %.0f%% se colpisce per primo, %.0f%% se colpisce per secondo" % [att_after * 100, att_before * 100])
	_check(att_before < att_after, "l'Adattivo attacca meno quando chi lo può uccidere colpisce prima")
	var n_after := _attack_rate(1, false)
	var n_before := _attack_rate(0, false)
	print("  (Normale, per confronto: %.0f%% e %.0f%%)" % [n_after * 100, n_before * 100])
	print("PROVA ORDINE: %s" % ("TUTTO BENE" if errori == 0 else "%d ERRORI" % errori))
	quit(1 if errori > 0 else 0)


func _rules() -> CerchioRules:
	var r := CerchioRules.new()
	r.use_cards = false
	r.order_rotate = true
	r.setup([0, 1, 2, 3], 4.0, 5, "B", false)
	for p in r.players:
		p.special_left = false
	return r


func _all_heal(r: CerchioRules) -> Dictionary:
	var c := {}
	for pid in r.alive_ids():
		c[pid] = {"move": CerchioRules.Move.DEFEND, "target": r.attack_targets(pid)[0]}
	return c


## Quante volte il giocatore 0 (1 candela) sceglie di attaccare nel duello contro 1 (1 candela, che negli
## ultimi giri ha sempre attaccato 0). opp_rank: posizione dell'avversario nell'ordine (0 = prima di me).
func _attack_rate(opp_rank: int, adaptive := true) -> float:
	var n := 0
	var att := 0
	for seed in 600:
		var r := _rules()
		for pid in [2, 3]:
			r.players[pid].alive = false
			r.players[pid].candles = 0.0
		r.players[0].candles = 1.0
		r.players[1].candles = 1.0
		r.altar = 3.0
		for k in 6:
			r.players[1].history.append({"move": CerchioRules.Move.ATTACK, "target": 0, "forced": false})
			r.players[0].history.append({"move": [0, 1, 3][k % 3], "target": 1, "forced": false})
		r.order_hidden = false
		r.order.assign([1, 0] if opp_rank == 0 else [0, 1])
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var c := CerchioBot.choose(r, 0, rng, 0.3, {}, adaptive)
		n += 1
		if c["move"] == CerchioRules.Move.ATTACK:
			att += 1
	return float(att) / n


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  NO   ") + what)
	if not ok:
		errori += 1
