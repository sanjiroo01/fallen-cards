class_name CateneMatch
extends RefCounted
## Una partita alle "Catene dell'altare" (docs/catene_altare.md, sezione REGOLE DEFINITIVE) contro tre avversari del
## computer, nella scena del gioco. Usa l'arena, i campioni e l'interfaccia preparati da game.gd; le regole sono in
## CateneRules, gli avversari in CateneBot. Il posto 0 sei tu (con --auto lo gioca il computer).

signal _sent(c: Dictionary)

const C := CateneRules.Card
const T_TURN := 20.0               # secondi per scegliere (poi vale quello che hai scelto finora)
const T_DRAW := 10.0               # secondi per scegliere una delle tre carte coperte
const T_VOTE := 20.0
const T_BURST := 30.0              # l'ultimo respiro
const PACE := 1.5                  # ritmo della partita vera: tutte le attese e le animazioni durano una volta e mezza (21/10, "succede tutto troppo in fretta")
const TESTI := [
	"Toglie una catena a chi scegli, anche a te. A zero catene sei libero.",
	"Aggiunge una catena a chi scegli.",
	"Aggiunge due catene a chi scegli.",
	"Chi scegli salta il prossimo turno: non tira e non gioca carte.",
	"A fine turno i legati votano chi è il sabotatore. Serve la maggioranza; con la parità non succede nulla.",
	"Solo il sabotatore può usarla: il ruolo passa in segreto a un altro legato, a caso. Per gli altri non fa nulla.",
]
const DONO := "Dono del Guardiano"
const DONO_TESTO := "Un «Togli una catena» nascosto: non conta fra le carte in gioco. Quando lo usi bruci anche una tua carta, così il totale cala come sempre."
const ROSSO := Color(1.0, 0.45, 0.35)
const ORO := Color(1.0, 0.82, 0.45)
const VERDE := Color(0.55, 0.95, 0.6)

var g: Node3D                      # game.gd
var hud: Hud
var arena: Arena
var r: CateneRules
var bots: Array[CateneBot] = []
var points := []
var n := 4                         # quanti al tavolo (4-8)
var elimination := false
var manche := 0
var shown := []                    # catene mostrate (durante le animazioni, prima che arrivino tutte le carte)
var _tk := 0
var _pick := {}                    # la tua carta di questo turno: {card, target}
var _pull := true


func _init(game: Node3D) -> void:
	g = game
	hud = game.hud
	arena = game.arena


func _alive() -> bool:
	return _tk == g._token and is_instance_valid(arena)


# ------------------------------------------------------------------ nomi nel racconto

func _who(pid: int) -> String:
	return "te" if pid == 0 else Testi.CLASSI[g.classes[pid]]["articolo"]


func _Who(pid: int) -> String:
	if pid == 0:
		return "Tu"
	var s: String = Testi.CLASSI[g.classes[pid]]["articolo"]
	return s.left(1).to_upper() + s.substr(1)


func _short(pid: int) -> String:
	return "te stesso" if pid == 0 else Testi.CLASSI[g.classes[pid]]["nome"].get_slice(" ", 0)


## Una frase con il soggetto giusto: "Il Cavaliere si libera." oppure, se sei tu, "Ti liberi."
func _say(pid: int, lui: String, tu: String) -> String:
	return tu if pid == 0 else "%s %s" % [_Who(pid), lui]


func _da(pid: int) -> String:
	return "da te" if pid == 0 else Testi.CLASSI[g.classes[pid]]["da"]


func _catene(n: int) -> String:
	return "1 catena" if n == 1 else "%d catene" % n


# ------------------------------------------------------------------ partita

func play(tk: int) -> void:
	_tk = tk
	if not g.auto and not g.clicker:
		g.speed = PACE            # le prove automatiche tengono la loro velocità (--veloce)
	n = g.n_players
	points = []
	points.resize(n)
	points.fill(0)
	shown.resize(n)
	shown.fill(0)
	elimination = "--eliminazione" in OS.get_cmdline_user_args()
	for pid in n:
		arena.seats[pid].build_candles(0)
		arena.seats[pid].set_cards(0)
	hud.set_order([])
	hud.set_omen(0)
	var others: String = ["tre", "quattro", "cinque", "sei", "sette"][n - 4]
	var who := "Uno di voi lavora in segreto per l'altare: è il sabotatore." if n < 6 else \
		"Due di voi lavorano in segreto per l'altare: sono i sabotatori, e si conoscono."
	var burn := "chi resta legato con più catene prende fuoco." if n < 6 else "i due più legati prendono fuoco."
	await g._big("Le catene dell'altare",
		"Sei incatenato al tavolo dell'altare con altri %s. Liberati prima che si spengano le candele:\n%s\n\n%s\n\nTre manche: vince chi fa più punti." % [others, burn, who],
		"Continua", "catene_intro")
	if not _alive():
		return
	elimination = elimination or hud.mode_pick == 1       # la modalità si sceglie nel menu, prima di «Gioca»
	for m in range(1, 4):
		manche = m
		await _manche()
		if not _alive():
			return
		await _standings()
		if not _alive():
			return
	await _final()


func _manche() -> void:
	r = CateneRules.new()
	r.defer_votes = true
	r.wrong_vote_kills = elimination
	r.pull_or_card = true          # 21/10: o tiri la catena o giochi una carta (tests/sim_catene.gd tira_o_carta=1)
	r.sab_double = true            # 21/10: le carte del sabotatore colpiscono due campioni (sab_doppio=1)
	r.for_players(n)               # 22/10: da 6 in su due sabotatori, bruciano i due più legati (sim_catene.gd giocatori=N)
	r.setup(g.rng.randi())
	bots.clear()
	for i in n:
		bots.append(CateneBot.new(i, "furbo", g.rng.randi()))
	arena.clear_chains()
	arena.game_mode()                              # l'altare parte da terra, senza catene al suolo
	for pid in n:
		var f: Figura = arena.seats[pid]
		f.reset_for_manche()
		shown[pid] = r.players[pid].chains
		arena.set_chains(pid, shown[pid])
		f.set_state_text(_catene(shown[pid]))
	hud.clear_log()
	arena.altar_candles(r.start_candles)          # le candele della manche, sull'altare
	arena.altar_candles_lit(r.candles, false)
	_board()
	_status()
	var role := "In questa manche sei innocente.\nLiberati, e scopri chi è il sabotatore:\nlo voterete quando uscirà la carta Voto."
	if r.n_sabs > 1:
		role = "In questa manche sei innocente.\nLiberati, e scopri i due sabotatori:\nli voterete quando uscirà la carta Voto."
	if r.is_sab(0):
		role = "In questa manche sei il sabotatore.\nNon devi liberarti: tieni legati gli altri senza farti scoprire.\n"
		if r.sab_double:
			role += "Le tue carte da sabotaggio colpiscono due campioni alla volta,\ne il Guardiano ti dona un «Togli una catena» nascosto."
		else:
			role += "Il Guardiano ti dona un «Togli una catena» nascosto."
			if not _mates().is_empty():
				role += "\nIl tuo complice è %s: aiutatevi, ma senza farvi notare." % _who(_mates()[0])
	hud.log_line("— %s manche —" % g._ordinale(manche).capitalize())
	await g._big("%s manche" % g._ordinale(manche).capitalize(), "Ognuno ha %s. Ci sono %d candele accese.\n\n%s" % [
		_catene(r.start_chains), r.start_candles, role], "Inizia", "manche%d" % manche)
	if not _alive():
		return
	if r.is_sab(0):
		g._shot_after(0.8, "ruolo%d" % manche)
		var sub := "tieni legati gli altri e non farti scoprire"
		if not _mates().is_empty():
			sub = "il tuo complice è %s" % _who(_mates()[0])
		await hud.role_reveal("Sei il sabotatore", sub, Color(0.95, 0.16, 0.1), 2.6 * (g.speed if g.auto else 1.0))
	else:
		g._shot_after(0.8, "ruolo%d" % manche)
		await hud.role_reveal("Sei innocente", "liberati e scopri chi sabota", Color(0.93, 0.86, 0.72), 2.6 * (g.speed if g.auto else 1.0))
	if not _alive():
		return
	var guard := 0
	while not r.over and guard < 80:
		guard += 1
		await _turn()
		if not _alive():
			return
		if r.is_last_breath():
			await _last_breath()
			if not _alive():
				return
	await _end_manche()


func _turn() -> void:
	for b in bots:
		b.before_turn(r)
	var drawn := r.chained().size()
	var was_sab := r.is_sab(0)
	var mates_before := _mates()
	r.begin_turn()
	_round_label()
	_status()
	_board()
	for pid in n:
		arena.seats[pid].set_move_text("")
	# scelte segrete
	var choices := {}
	for pid in r.chained():
		if pid != 0 or g.auto:
			choices[pid] = bots[pid].choose(r)
	if 0 in r.chained() and not g.auto:
		await _ask_draw()
		if not _alive():
			return
		choices[0] = await _ask_turn()
		if not _alive():
			return
	elif not 0 in r.chained():
		hud.hint("Hai finito la manche: guardi gli altri.")
		await g._wait(1.2)
	hud.hint("")
	for pid in n:
		shown[pid] = r.players[pid].chains
	var candles_before := r.candles
	if manche == 1 and r.turn <= 1:
		await g._shot("turno")
	r.resolve(choices, Callable())
	await _show_events(0)
	if not _alive():
		return
	arena.clear_cards()
	# voti chiamati in questo turno
	while r.pending_votes > 0 and not r.over:
		await _open_vote()
		if not _alive():
			return
		var mine := {}
		if 0 in r.chained() and not g.auto:
			mine = await hud.vote_pick(T_VOTE, not r.guardian_used and _hidden_left(), g.clicker)
			if not _alive():
				return
		var from := r.run_vote(func(v: int) -> Variant: return _vote_of(v, mine))
		await _show_vote(from)
		if not _alive():
			return
	for b in bots:
		b.observe(r, drawn)
	# il testimone è arrivato a te, o l'hai passato
	if r.is_sab(0) and not was_sab:
		var sub := "il testimone è passato a te: solo tu lo sai"
		if not _mates().is_empty():
			sub = "il testimone è passato a te: il tuo complice è %s" % _who(_mates()[0])
		await hud.role_reveal("Ora sei il sabotatore", sub, Color(0.95, 0.16, 0.1), 2.6 * (g.speed if g.auto else 1.0))
	elif was_sab and not r.is_sab(0) and r.players[0].free == false:
		hud.log_line("Hai passato il testimone: non sai a chi è andato.")
	elif r.is_sab(0) and _mates() != mates_before and not _mates().is_empty():
		# il complice ha passato il testimone: i sabotatori si conoscono sempre
		hud.log_line("Il tuo complice ha passato il testimone: ora è %s." % _who(_mates()[0]))
	var lost := candles_before - r.candles
	if lost > 0:
		Sfx.play("blow", -3.0)
		hud.log_line("Si spegne una candela." if lost == 1 else "Si spengono %d candele." % lost)
	_round_label()
	_status()
	_board()
	await g._wait(0.8)


# ------------------------------------------------------------------ le tue scelte

## Tre carte coperte grandi al centro dello schermo: ne scegli una (la carta è già stata pescata dalle regole: la
## scelta è alla cieca), si gira e mostra cosa hai preso.
func _ask_draw() -> void:
	var me := r.players[0]
	if me.hand.is_empty():
		return
	hud.clear_cards()
	hud.clear_actions()
	hud.hint("")
	if g.clicker and manche == 1 and r.turn <= 1:
		g._shot_after(0.35, "pesca")
	await hud.pick_card(me.hand[me.hand.size() - 1], T_DRAW, g.clicker)


func _ask_turn() -> Dictionary:
	var me := r.players[0]
	if me.skip:
		hud.hint("Salti questo turno: qualcuno ti ha giocato «Salta un turno».")
		await g._wait(1.8)
		return {"pull": false, "card": -1, "burn": me.hand.size() - 1}
	_pick = {}
	_pull = true
	_render_turn()
	hud.start_timer(T_TURN, func() -> void: _confirm(true))
	if g.clicker and manche == 1 and r.turn <= 2:     # prova dell'interfaccia: foto della scelta prima del clic
		g._click_t = 1.0
		g._shot_after(0.4, "scelta")
	var c: Dictionary = await _sent
	hud.stop_timer()
	hud.clear_cards()
	hud.clear_actions()
	return c


## Le carte da sabotatore colpiscono due campioni (regola del 21/10: il sabotatore da solo non bastava).
func _double(k: int) -> bool:
	return r.sab_double and r.is_sab(0) and k in [C.AGGIUNGI, C.AGGIUNGI2, C.SALTA]


## Il tuo turno: le tue carte e, a parte, «Tira la catena». O giochi una carta o tiri: non tutte e due.
func _render_turn() -> void:
	var me := r.players[0]
	hud.clear_cards()
	hud.clear_actions()
	hud.hint("Gioca una carta oppure tira la catena. Nessuno saprà chi ha giocato le carte.")
	var hand := []
	for i in me.hand.size():
		hand.append([i, me.hand[i]])
	if r.is_sab(0) and me.secret > 0:
		hand.append([CateneRules.SECRET, Carta.DONO])
	for it in hand:
		var i: int = it[0]
		var k: int = it[1]
		var card := Carta.make(k, true, 176)
		card.selected = not _pull and _pick.get("card", -99) == i
		if _double(k):
			card.note = "colpisce due campioni"
		var full: String = DONO_TESTO if k == Carta.DONO else TESTI[k]
		card.mouse_entered.connect(func() -> void: hud._show_tip(Carta.NOMI[k], full, card))
		card.mouse_exited.connect(hud._hide_tip)
		card.tree_exiting.connect(hud._hide_tip)
		card.pressed.connect(func() -> void: _choose(i, k))
		hud._cards_row.add_child(card)
	if not hand.is_empty():
		var o := hud._row_lbl("oppure", Stile.font_voice(), 40, Hud.DIM)
		hud._cards_row.add_child(hud._gap(10))
		hud._cards_row.add_child(o)
		hud._cards_row.add_child(hud._gap(10))
	var pull := Carta.make(Carta.TIRA, true, 176)
	pull.selected = _pull
	pull.pressed.connect(func() -> void:
		_pull = true
		_pick = {}
		_render_turn())
	hud._cards_row.add_child(pull)
	# bersagli della carta scelta
	var ready := true
	if not _pull and not _pick.is_empty():
		var k: int = _pick["k"]
		if k != C.VOTO:
			var need := 2 if _double(k) else 1
			var tg: Array = _pick.get("targets", [])
			ready = tg.size() >= mini(need, _candidates(k).size())
			hud._actions.add_child(hud._row_lbl("Su chi?" if need == 1 else "Su chi? (due campioni)", hud.head_font, 24, Hud.GOLD))
			for q in _candidates(k):
				var b: Button = hud._btn(_short(q), func() -> void:
					var cur: Array = _pick.get("targets", [])
					if q in cur:
						cur.erase(q)
					else:
						cur.append(q)
						while cur.size() > need:
							cur.pop_front()
					_pick["targets"] = cur
					_render_turn(), 24)
				b.toggle_mode = true
				b.set_pressed_no_signal(q in tg)
				b.add_theme_stylebox_override("pressed", Stile.card_selected())
				b.add_theme_stylebox_override("hover_pressed", Stile.card_selected())
				hud._actions.add_child(b)
			hud._actions.add_child(hud._gap(30))
	var ok: Button = hud._btn("Conferma", func() -> void: _confirm(false), 30, Hud.GOLD)
	ok.custom_minimum_size = Vector2(240, 0)
	ok.disabled = not ready
	hud._actions.add_child(ok)


## Su chi si può giocare una carta: tutti i legati (te compreso per "Togli"); il testimone va a un altro.
func _candidates(k: int) -> Array:
	if k == C.TESTIMONE or k == C.AGGIUNGI or k == C.AGGIUNGI2 or k == C.SALTA:
		return r.chained().filter(func(q: int) -> bool: return q != 0)
	return r.chained()


func _card_btn(title: String, text: String, cb: Callable, col := Color(1.0, 0.82, 0.55)) -> Button:
	var b: Button = hud._btn(title, cb, 22, col)
	b.mouse_entered.connect(func() -> void: hud._show_tip(title, text, b))
	b.mouse_exited.connect(hud._hide_tip)
	b.tree_exiting.connect(hud._hide_tip)
	return b


## Hai scelto una carta (la stessa di nuovo: torni a tirare). "Togli" parte già su di te, il bersaglio più comune.
func _choose(i: int, k: int) -> void:
	if not _pull and _pick.get("card", -99) == i:
		_pull = true
		_pick = {}
	else:
		_pull = false
		_pick = {"card": i, "k": k, "targets": [0] if k == C.TOGLI or k == Carta.DONO else []}
	_render_turn()


func _confirm(timeout: bool) -> void:
	var me := r.players[0]
	var ci: int = -1 if _pull else _pick.get("card", -1)
	var tg: Array = _pick.get("targets", [])
	if ci >= 0 or ci == CateneRules.SECRET:
		var k: int = _pick["k"]
		if k != C.VOTO and tg.is_empty():
			if not timeout:
				return
			ci = -1                       # tempo scaduto senza bersaglio: tiri la catena
	var c := {"pull": ci == -1, "card": ci, "target": tg[0] if not tg.is_empty() else 0,
		"target2": tg[1] if tg.size() > 1 else -1, "burn": -1}
	# con 4 carte in mano e nessuna giocata se ne brucia una
	var left := me.hand.size() - (1 if ci >= 0 else 0)
	if left > r.hand_max and ci != CateneRules.SECRET:
		if timeout:
			c["burn"] = 0
		else:
			_ask_burn(c)
			return
	hud.stop_timer()
	_sent.emit(c)


func _ask_burn(c: Dictionary) -> void:
	var me := r.players[0]
	hud.clear_cards()
	hud.clear_actions()
	hud.hint("Hai 4 carte: scegline una da bruciare nel fuoco (nessuno saprà quale).")
	for i in me.hand.size():
		if i == c["card"]:
			continue
		var k: int = me.hand[i]
		var card := Carta.make(k, true, 176)
		card.pressed.connect(func() -> void:
			c["burn"] = i if c["card"] < 0 or i < c["card"] else i - 1
			hud.stop_timer()
			hud.clear_cards()
			_sent.emit(c))
		hud._cards_row.add_child(card)


## Il voto di ognuno: il tuo, o quello di un avversario (che chiede il Guardiano solo a volte, quando è incerto).
func _vote_of(v: int, mine: Dictionary) -> Variant:
	if v == 0 and not mine.is_empty():
		return mine
	return {"v": bots[v].vote(r), "g": bots[v].wants_guardian(r) and g.rng.randf() < 0.35}


# ------------------------------------------------------------------ rivelazione

func _show_events(from: int, fast := false) -> void:
	var evs := r.events
	var shuffled := false
	var display := []                 # campioni su cui escono le carte, a partire da quello scelto dal Guardiano
	var di := 0
	var deck: Array[Node3D] = []      # le carte coperte uscite dalla mescolata
	var last_card_pos := Vector3.ZERO
	for i in range(from, evs.size()):
		if not _alive():
			return
		var e: Dictionary = evs[i]
		var t: String = e["t"]
		if t in ["togli", "aggiungi", "salta", "voto_chiamato", "togli_nulla"] and not fast:
			var kind := C.VOTO if t == "voto_chiamato" else (C.TOGLI if t.begins_with("togli") else (C.SALTA if t == "salta" else (C.AGGIUNGI if e.get("n", 1) == 1 else C.AGGIUNGI2)))
			if not shuffled:
				# le carte coperte girano in cerchio davanti al fuoco, poi ne vola una su ogni campione, a partire da
				# uno a caso; la carta segreta resta nel fuoco e si gira per ultima
				shuffled = true
				Sfx.play("shuffle", -4.0)
				var ch := r.order()
				var start: int = ch[g.rng.randi() % ch.size()] if not ch.is_empty() else 0
				for k in n:
					var q := (start + k) % n
					if q in ch:
						display.append(q)
				var n_cards := 0
				var secret := false
				for j in range(i, evs.size()):
					var ej: Dictionary = evs[j]
					if ej["t"] in ["togli", "aggiungi", "salta", "voto_chiamato", "togli_nulla"] and not ej.get("bis", false):
						if ej.get("segreta", false):
							secret = true
						else:
							n_cards += 1
				hud.banner("", "Le carte si mescolano", "nessuno sa chi le ha giocate", 1.8 * g.speed)
				deck = await arena.shuffle_cards(n_cards, secret, g.speed)
				if not _alive():
					return
			var from_pos: Vector3
			if e.get("bis", false):
				from_pos = last_card_pos             # il secondo colpo della stessa carta del sabotatore
				hud.log_line("La stessa carta colpisce ancora.")
			elif e.get("segreta", false):
				from_pos = await arena.reveal_secret(g.speed)
				hud.log_line("Dal fuoco, la carta segreta del Guardiano.")
			else:
				var over: int = display[di % display.size()] if not display.is_empty() else 0
				var node: Node3D = deck[di] if di < deck.size() else null
				di += 1
				Sfx.play("flip", -2.0)
				from_pos = await arena.deal_card(node, arena.seats[over], kind, g.speed)
				if manche == 1 and r.turn <= 3 and di == 1:
					g._shot_after(0.1, "carta")
				await g._wait(0.4)
			last_card_pos = from_pos
			if e.has("pid"):
				arena.shoot(from_pos, arena.seats[e["pid"]].chest(), ORO if t == "togli" else ROSSO, 0.35)
				await g._wait(0.35)
		match t:
			"saltato":
				arena.seats[e["pid"]].set_move_text("Salta il turno")
				hud.log_line(_say(e["pid"], "salta il turno.", "Salti il turno."))
			"tirano":
				var no: Array = []
				if manche == 1 and r.turn <= 2:
					g._shot_after(0.5, "tirano")
				for q in e["chi"]:
					var yes: bool = q in e["pids"]
					arena.seats[q].set_move_text("Tira" if yes else "Non tira")
					if not yes:
						no.append(q)
				if no.is_empty():
					hud.log_line("Tirano tutti.")
				elif no.size() == 1:
					hud.log_line(_say(no[0], "non tira.", "Tirano tutti tranne te."))
				else:
					hud.log_line("Non tirano: %s." % ", ".join(no.map(func(q: int) -> String: return "tu" if q == 0 else _who(q))))
				Sfx.play("chop", -8.0, 0.6)
				await g._wait(0.4 if fast else 1.6)
			"togli":
				var p: int = e["pid"]
				shown[p] = maxi(shown[p] - 1, 0)
				arena.sparks(arena.seats[p].chest(), Color(1.0, 0.8, 0.4), 22)
				arena.damage_number(arena.seats[p].chest() + Vector3(0, 0.6, 0), "-1", Color(1.0, 0.85, 0.45))
				Sfx.play("chop", -4.0, 1.3)
				hud.log_line("Si spezza una delle tue catene." if p == 0 else "Si spezza una catena: %s." % _who(p))
			"aggiungi":
				var p: int = e["pid"]
				shown[p] += int(e["n"])
				arena.sparks(arena.seats[p].chest(), Color(1.0, 0.25, 0.15), 22)
				arena.damage_number(arena.seats[p].chest() + Vector3(0, 0.6, 0), "+%d" % int(e["n"]), Color(1.0, 0.35, 0.25))
				Sfx.play("slam", -6.0, 0.8)
				hud.log_line(("Hai %s in più." if p == 0 else _Who(p) + ": %s in più.") % ("una catena" if e["n"] == 1 else "due catene"))
			"salta":
				if not fast:
					hud.log_line(_say(e["pid"], "salterà il prossimo turno.", "Salterai il prossimo turno."))
				else:
					hud.log_line(_say(e["pid"], "è fermato: non gioca più carte.", "Sei fermato: non giochi più carte."))
			"voto_chiamato":
				hud.log_line("È uscito il Voto: a fine turno si vota.")
			"libero":
				var p: int = e["pid"]
				shown[p] = 0
				arena.tether(p, false)
				arena.seats[p].set_state_text("LIBERO", VERDE)
				Sfx.play("bell", -2.0, 1.2)
				hud.banner("", "Le tue catene cadono" if p == 0 else "%s si libera" % _Who(p), "nessuno si era liberato prima" if p == r.first_freed else "", 2.0 * g.speed, VERDE)
				var first := " prima di tutti" if p == r.first_freed else ""
				hud.log_line(_say(p, "si libera%s." % first, "Ti liberi%s." % first))
				await g._wait(0.5 if fast else 1.6)
			"altare_fermo":
				hud.banner("", "L'altare resta fermo", "tutti hanno tirato: la candela non si spegne", 2.0 * g.speed)
				hud.log_line("Tutti hanno tirato: l'altare resta fermo.")
				arena.shake(0.4)
				await g._wait(1.6)
		if e.has("pid") and t in ["togli", "aggiungi"]:
			arena.seats[e["pid"]].set_state_text(_catene(shown[e["pid"]]))
			if not r.players[e["pid"]].free:
				arena.set_chains(e["pid"], shown[e["pid"]])
			_board()
			await g._wait(0.25 if fast else 0.9)


## Il voto è pubblico: uno alla volta, sopra ogni votante compare chi ha votato e una scia va verso di lui.
## Si apre la schermata del voto: le foto di tutti i campioni, scattate adesso nella scena.
func _open_vote() -> void:
	var photos: Dictionary = await arena.portraits()
	var cards := []
	var me_votes := 0 in r.chained()
	for pid in n:
		var p := r.players[pid]
		var sub := _catene(p.chains)
		if p.dead:
			sub = "eliminato"
		elif p.free:
			sub = "libero"
		cards.append({"pid": pid, "nome": g.names[pid], "colore": Testi.CLASSI[g.classes[pid]]["colore"], "sotto": sub,
			"photo": photos.get(pid), "votabile": me_votes and pid != 0 and pid in r.chained()})
	var n := r.chained().size()
	var line := "Chi è il sabotatore? Premi la sua carta. Servono %d voti su %d." % [n / 2 + 1, n]
	if not me_votes:
		line = "Votano i legati: tu guardi. Servono %d voti su %d." % [n / 2 + 1, n]
	Sfx.play("bell", -4.0)
	hud.open_vote(cards, line)
	if g.shots_dir != "":
		g._shot_after(0.6, "voto_scelta")
	await g._wait(0.5)


## I voti si scoprono uno alla volta: sotto la carta di chi è stato votato compare il nome di chi l'ha votato.
## Poi l'eventuale Guardiano e l'esito, sulla stessa schermata.
func _show_vote(from: int) -> void:
	var tally := r.last_tally
	var parts: Array[String] = []
	for q in tally:
		parts.append("%s %d" % [_short(q) if q != 0 else "tu", tally[q]])
	hud.log_line("— Voto —")
	if r.events.slice(from).any(func(e: Dictionary) -> bool: return e["t"] == "voto"):
		await g._wait(0.6)
		for v in r.order():
			if not r.last_votes.has(v):
				continue
			var t: int = r.last_votes[v]
			hud.vote_mark(t, "Tu" if v == 0 else g.names[v], Color(Testi.CLASSI[g.classes[v]]["colore"]).lerp(Color.WHITE, 0.35))
			hud.log_line("Hai votato %s." % _who(t) if v == 0 else "%s vota %s." % [_Who(v), "te" if t == 0 else _who(t)])
			await g._wait(0.9)
			if not _alive():
				return
	var res_big := ""
	var res_line := ""
	var res_col := Color(0.85, 0.8, 1.0)
	var res_pid := -1
	for i in range(from, r.events.size()):
		var e: Dictionary = r.events[i]
		match e["t"]:
			"guardiano":
				await g._wait(0.4)
				hud.vote_mark(e["pid"], "il Guardiano", Color(1.0, 0.75, 0.35))
				hud.log_line("Il Guardiano indica %s." % _who(e["pid"]))
				arena.custode_speak()
				await g._wait(1.0)
			"voto":
				hud.log_line("Totale: %s." % ", ".join(parts))
				g._shot_after(0.4, "voto%d" % manche)
				match e["esito"]:
					"scoperto":
						var p: int = e["pid"]
						shown[p] = r.players[p].chains
						arena.seats[p].set_state_text("SABOTATORE · " + _catene(shown[p]), ROSSO)
						arena.set_chains(p, shown[p])
						res_big = "Sabotatore scoperto"
						res_line = ("eri tu: " if p == 0 else "%s: " % _who(p)) + "due catene in più, e niente più passaggi del testimone"
						res_col = ROSSO
						res_pid = p
						Sfx.play("slam", 0.0, 0.7)
						arena.shake(0.8)
						hud.log_line("Ti hanno scoperto: eri il sabotatore." if p == 0 else "Scoperto il sabotatore: %s." % _who(p))
					"innocente":
						res_big = "Non eri il sabotatore" if e["pid"] == 0 else "Non era il sabotatore"
						res_line = "il voto ha indicato %s" % _who(e["pid"])
						res_pid = e["pid"]
						hud.log_line(_say(e["pid"], "non era il sabotatore.", "Il voto ha indicato te, ma non eri il sabotatore."))
					"nessuna maggioranza":
						res_big = "Nessuna maggioranza"
						res_line = "non succede nulla"
						hud.log_line("Nessuna maggioranza.")
					"già scoperto":
						res_big = "Già scoperto"
						res_line = "il sabotatore era già stato scoperto: non succede nulla"
						hud.log_line("Votato di nuovo il sabotatore già scoperto: nulla.")
				await hud.vote_result(res_big, res_line, res_col, res_pid, 2.8 * g.speed)
				arena.clear_portraits()
			"eliminato":
				var p: int = e["pid"]
				arena.seats[p].set_state_text("ELIMINATO", ROSSO)
				hud.banner("", "Bruci" if p == 0 else "%s brucia" % _Who(p), "condanna sbagliata: il sabotatore resta nascosto", 2.6 * g.speed, ROSSO)
				Sfx.play("ghost", -2.0)
				arena.burn_seat(p)          # brucia al suo posto, in catene (22/10)
				await g._wait(2.2)
				hud.log_line(_say(p, "brucia: condanna sbagliata.", "Bruci: condanna sbagliata."))
				await g._wait(1.0)
	hud.close_vote()
	arena.clear_portraits()
	_board()
	_status()


# ------------------------------------------------------------------ ultimo respiro

func _last_breath() -> void:
	r.burst_begin()
	arena.custode_speak()
	hud.custode("L'altare si agita. Trenta respiri, poi il fuoco.")
	hud.banner("", "Ultimo respiro", "30 secondi: gioca subito Togli, Aggiungi e Salta", 2.6 * g.speed, ROSSO)
	Sfx.heartbeat(true, 0.9)
	await g._wait(2.0)
	if not _alive():
		return
	var scale_t: float = g.speed if g.auto else 1.0
	var end_ms := Time.get_ticks_msec() + int(T_BURST * scale_t * 1000.0)
	var next := {}
	for pid in r.burst_active:
		if pid != 0 or g.auto:
			next[pid] = Time.get_ticks_msec() + int(g.rng.randf_range(1.5, 4.5) * scale_t * 1000.0)
	_pick = {}
	if 0 in r.burst_active and not g.auto:
		_render_burst()
	hud.start_timer(T_BURST * scale_t, func() -> void: pass)
	var from := r.events.size()
	g._shot_after(1.5, "respiro%d" % manche)
	var shake_ms := 0
	while Time.get_ticks_msec() < end_ms and not r.burst_active.is_empty() and r.chained().size() > 1:
		await g.get_tree().process_frame
		if not _alive():
			return
		var now := Time.get_ticks_msec()
		if now > shake_ms:
			arena.shake(0.25 + 0.5 * (1.0 - float(end_ms - now) / (T_BURST * scale_t * 1000.0)))
			shake_ms = now + 700
		for pid in next.keys():
			if not pid in r.burst_active:
				next.erase(pid)
			elif now >= next[pid]:
				var c: Dictionary = bots[pid].burst(r)
				if not r.burst_play(pid, c.get("card", -1), c.get("target", pid)):
					r.burst_active.erase(pid)
				next[pid] = now + int(g.rng.randf_range(1.2, 3.5) * scale_t * 1000.0)
		if r.events.size() > from:
			var f := from
			from = r.events.size()
			await _show_events(f, true)
			if 0 in r.burst_active and not g.auto:
				_render_burst()
			elif not g.auto:
				hud.clear_cards()
				hud.clear_actions()
	hud.stop_timer()
	hud.clear_cards()
	hud.clear_actions()
	hud.hint("")
	Sfx.heartbeat(false)
	r.burst_end()


func _render_burst() -> void:
	var me := r.players[0]
	hud.clear_cards()
	hud.clear_actions()
	if not _pick.is_empty():
		var k: int = _pick["k"]
		hud.hint("%s su chi?" % (DONO if _pick["i"] == CateneRules.SECRET else CateneRules.NOMI[k]))
		var ci: int = _pick["i"]
		for q in r.chained():
			hud._cards_row.add_child(hud._btn(_short(q), func() -> void:
				# un secondo clic veloce trovava la scelta già azzerata e fermava la partita
				if _pick.is_empty():
					return
				_pick = {}
				hud.clear_cards()
				r.burst_play(0, ci, q), 24))
		hud._cards_row.add_child(hud._btn("Annulla", func() -> void:
			_pick = {}
			_render_burst(), 20, Hud.DIM))
		return
	hud.hint("Ultimo respiro: gioca subito le tue carte.")
	var any := false
	for i in me.hand.size():
		var k: int = me.hand[i]
		if r.burst_allowed(k):
			any = true
			hud._cards_row.add_child(_card_btn(CateneRules.NOMI[k], TESTI[k], func() -> void:
				_pick = {"i": i, "k": k}
				_render_burst()))
	if r.is_sab(0) and me.secret > 0:
		any = true
		hud._cards_row.add_child(_card_btn(DONO, DONO_TESTO, func() -> void:
			_pick = {"i": CateneRules.SECRET, "k": C.TOGLI}
			_render_burst(), ROSSO))
	if not any:
		hud.hint("Non hai carte da giocare: puoi solo aspettare.")


# ------------------------------------------------------------------ fine manche e partita

func _end_manche() -> void:
	_status()                  # dopo l'ultimo respiro il riquadro in basso mostrava ancora le catene di prima
	_board()
	for pid in n:
		arena.seats[pid].set_move_text("")
	hud.banner("", "Il fuoco diventa blu", "brucia chi ha più catene" if r.burn_top <= 1 else "bruciano i due più legati",
		2.4 * g.speed, Color(0.5, 0.7, 1.0))
	arena.circle_pulse(Color(0.3, 0.5, 1.0))
	Sfx.play("slam", 0.0, 0.6)
	await g._wait(1.6)
	# 22/10: l'altare non vola più. Chi brucia prende fuoco al suo posto e resta lì, accasciato contro il tavolo e
	# ancora in catene; gli altri legati restano in piedi, salvi
	var any := false
	for pid in n:
		var p := r.players[pid]
		if p.free or pid in r.eliminated:
			continue
		if pid in r.burned:
			arena.burn_seat(pid)
			arena.seats[pid].set_state_text("BRUCIA", ROSSO)
			hud.log_line(_say(pid, "prende fuoco, ancora in catene.", "Prendi fuoco, ancora in catene."))
			any = true
		else:
			arena.seats[pid].set_state_text("SALVO · " + _catene(shown[pid]), VERDE)
			hud.log_line(_say(pid, "resta in catene, ma il fuoco lo risparmia.", "Resti in catene, ma il fuoco ti risparmia."))
	if any:
		Sfx.play("whoosh", 0.0, 0.6)
		await g._wait(3.5)
	await g._shot("rogo%d" % manche)


func _standings() -> void:
	var how := {}
	var gained := {}
	for pid in n:
		var s := r.score(pid)
		points[pid] += s
		gained[pid] = s
		# verbi invece di aggettivi: valgono per ogni campione, maschio o femmina
		if pid in r.eliminated:
			how[pid] = "brucia per un voto sbagliato"
		elif pid in r.burned:
			how[pid] = "brucia in catene"
		elif r.players[pid].free:
			how[pid] = "si libera prima di tutti" if pid == r.first_freed else "si libera"
		else:
			how[pid] = "resta in catene, ma si salva"
		if pid in r.escaped:
			how[pid] += " (da sabotatore non vale)"
	var sabs := r.sabs()
	var head := ""
	for s in sabs:
		var line := ""
		if r.n_sabs <= 1:
			line = "Il sabotatore eri tu" if s == 0 else "Il sabotatore era %s" % _who(s)
		else:
			line = "Eri un sabotatore" if s == 0 else "Sabotatore: %s" % _who(s)
		if r.players[s].unmasked:
			line += (", e ti hanno scoperto" if s == 0 else ", scoperto")
		head += ("\n" if head != "" else "") + line + "."
	if r.passes > 0:
		head += "\nIl testimone è passato di mano %s." % ("una volta" if r.passes == 1 else "%d volte" % r.passes)
	var rows := [{"nome": "", "esito": "in questa manche", "punti_manche": "punti", "totale": "totale"}]
	for pid in _ranking():
		rows.append({"nome": g.names[pid], "colore": Testi.CLASSI[g.classes[pid]]["colore"], "esito": how[pid],
			"punti_manche": "+%d" % gained[pid], "totale": str(points[pid]), "io": pid == 0})
	print("CATENE MANCHE %d (%d al tavolo): turni %d, liberi %s, bruciati %s, sabotatori %s%s, punti %s" % [manche, n, r.turn,
		str(range(n).filter(func(q: int) -> bool: return r.players[q].free)), str(r.burned), str(sabs), " scoperto" if r.unmasked else "", str(points)])
	await g._big("Fine della %s manche" % g._ordinale(manche), head, "Continua" if manche < 3 else "Verdetto", "classifica%d" % manche, rows)


func _ranking() -> Array:
	var ids := range(n)
	ids.sort_custom(func(a: int, b: int) -> bool: return points[a] > points[b])
	return ids


func _final() -> void:
	var rank := _ranking()
	var win: int = rank[0]
	Sfx.play("win" if win == 0 else "bell", -2.0)
	arena.custode_speak()
	var rows := [{"nome": "", "esito": "", "punti_manche": "", "totale": "punti"}]
	for pid in rank:
		rows.append({"nome": g.names[pid], "colore": Testi.CLASSI[g.classes[pid]]["colore"], "esito": "", "punti_manche": "",
			"totale": str(points[pid]), "io": pid == 0})
	print("CATENE FINE: vince %s, punti %s" % [g.names[win], str(points)])
	g.print_fps()
	await g._big("Hai vinto" if win == 0 else "Vince %s" % _who(win), "«L'altare ha scelto.»", "Torna al menu", "finale", rows)
	if not _alive():
		return
	if g.quit_at_end:
		g.get_tree().quit()
		return
	g._show_menu()


# ------------------------------------------------------------------ interfaccia

func _round_label() -> void:
	var c := maxi(r.candles, 0)
	arena.altar_candles_lit(c)
	hud.set_round("Manche %d di 3   ·   turno %d   ·   %s   ·   %d carte in gioco" % [
		manche, r.turn, ("1 candela accesa" if c == 1 else "%d candele accese" % c), r.cards_total()])


func _status() -> void:
	var me := r.players[0]
	var big := _catene(r.players[0].chains)
	var col := Color(1.0, 0.72, 0.3)
	if me.dead:
		big = "eliminato"
		col = ROSSO
	elif me.free:
		big = "libero"
		col = VERDE
	var role := "Sei innocente"
	if r.is_sab(0):
		role = "Sei il sabotatore" + (" (scoperto)" if me.unmasked else "") + _mates_text() + (" · dono del Guardiano pronto" if me.secret > 0 else "")
	# candele e carte stanno già nella riga in alto: qui solo ciò che è tuo (catene e ruolo segreto)
	hud.set_panel("LE TUE CATENE", big, role, col)


func _board() -> void:
	var rows := []
	for pid in n:
		var p := r.players[pid]
		var txt := _catene(shown[pid])
		var col := Color(0.78, 0.76, 0.8)
		var note := ""
		if p.dead:
			txt = "eliminato"
			col = ROSSO
		elif p.free:
			txt = "libero"
			col = VERDE
		if r.is_sab(pid) and r.players[pid].unmasked:
			note = "sabotatore"
		elif p.skip_next and not p.free:
			note = "salta il turno"
		rows.append({"nome": g.names[pid], "colore": Testi.CLASSI[g.classes[pid]]["colore"], "candele": 0, "max": 0,
			"punti": points[pid], "stato": "", "testo": txt, "colore_testo": col, "nota": note})
	hud.set_board(rows, "Catene")


# ------------------------------------------------------------------ sabotatori (uno fino a 5 campioni, due da 6 in su)

## Gli altri sabotatori, che conosci se lo sei anche tu.
func _mates() -> Array[int]:
	var out: Array[int] = []
	if r.is_sab(0):
		for q in r.sabs():
			if q != 0:
				out.append(q)
	return out


func _mates_text() -> String:
	var m := _mates()
	return "" if m.is_empty() else " · complice: %s" % _short(m[0])


## C'è ancora un sabotatore nascosto (il Guardiano si può chiamare solo allora).
func _hidden_left() -> bool:
	return r.sabs().any(func(q: int) -> bool: return not r.players[q].unmasked)
