extends SceneTree
## Prova della stanchezza: chi si difende da chi aveva SCELTO di attaccarlo non diventa stanco, anche se
## l'attaccante muore prima del suo turno; chi si difende da chi non l'attacca diventa stanco.
## Uso: godot --headless --path . -s res://tests/prova_stanchezza.gd

var errori := 0


func _init() -> void:
	# A (0) ha 1 candela e attacca B (1); C (2) attacca A e agisce prima: A muore e il suo colpo non parte.
	# B si difende da A: aveva letto giusto -> non stanco, niente contrattacco. D (3) si difende da C, che
	# non lo attacca -> stanco.
	var r := _rules()
	r.players[0].candles = 1.0
	r.begin_round()
	r.order_hidden = false
	r.order = [2, 0, 1, 3]
	var rep := r.resolve({
		0: {"move": CerchioRules.Move.ATTACK, "target": 1},
		1: {"move": CerchioRules.Move.DEFEND, "target": 0},
		2: {"move": CerchioRules.Move.ATTACK, "target": 0},
		3: {"move": CerchioRules.Move.DEFEND, "target": 2}})
	_check(not r.players[0].alive, "A muore prima del suo turno")
	_check(r.players[1].candles == 4.0, "B non perde candele")
	_check(not r.players[1].tired, "B aveva letto giusto: non è stanco")
	_check(r.players[3].tired, "D si è difeso da chi non lo attaccava: è stanco")
	_check(rep["counters"] == 0, "nessun contrattacco (il colpo di A non è partito)")
	# controllo: lo stesso giro con A che agisce per primo -> contrattacco di B, A muore, B non stanco
	r = _rules()
	r.players[0].candles = 1.0
	r.begin_round()
	r.order_hidden = false
	r.order = [0, 2, 1, 3]
	rep = r.resolve({
		0: {"move": CerchioRules.Move.ATTACK, "target": 1},
		1: {"move": CerchioRules.Move.DEFEND, "target": 0},
		2: {"move": CerchioRules.Move.ATTACK, "target": 0},
		3: {"move": CerchioRules.Move.DEFEND, "target": 2}})
	_check(rep["counters"] == 1, "A agisce per primo: contrattacco di B")
	_check(not r.players[1].tired, "B non è stanco")
	print("PROVA STANCHEZZA: %s" % ("TUTTO BENE" if errori == 0 else "%d ERRORI" % errori))
	quit(1 if errori > 0 else 0)


func _rules() -> CerchioRules:
	var r := CerchioRules.new()
	r.use_cards = false
	r.setup([0, 1, 2, 3], 4.0, 1, "B", false)
	return r


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  NO   ") + what)
	if not ok:
		errori += 1
