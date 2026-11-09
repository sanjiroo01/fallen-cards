extends Node3D
## La partita: menu, tre manche, giri, rivelazione animata. Regole in CerchioRules, avversari in
## CerchioBot, scena in Arena/Figura, interfaccia in Hud.
##
## Argomenti per le prove (dopo "--"):
##   --auto          il computer gioca anche al posto tuo e la partita va avanti da sola
##   --veloce=X      moltiplica le attese (0.05 = quasi istantaneo)
##   --foto=CARTELLA salva le immagini dei momenti principali
##   --esci          chiude il gioco alla fine della partita

var hud: Hud
var arena: Arena
var font: Font
var rng := RandomNumberGenerator.new()

var auto := false
var speed := 1.0
var shots_dir := ""
var quit_at_end := false
var _shot_n := 0
var clicker := false             # --clic: prova dell'interfaccia, preme pulsanti a caso come un giocatore
var _menu_sc := -1                 # luogo mostrato ora dietro il menu
var views: Array[Vector3] = []      # vedute chieste con --vista (gradi, distanza, inclinazione)
var menu_only := false             # --solo-menu --foto=...: fotografa il menu e chiude (prove senza personaggi)
var explore_shots := -1           # --esplora=N: foto dello scenario N senza personaggi, poi esce
var _explore_sc := 0
var force_scenario := -1          # --scenario=N: sempre lo stesso luogo (prove)
var _fps: Array[float] = []        # fotogrammi al secondo misurati durante la partita (prove)
var _click_t := 0.0
var _prova: RefCounted
var force_players := -1             # --giocatori=N: quanti al tavolo (prove)
var cerchio := false               # --cerchio: il vecchio gioco del cerchio (candele-vita) invece delle Catene dell'altare

var classes: Array = []          # pid -> classe (pid 0 = tu)
var n_players := 4               # quanti al tavolo in questa partita
var names := {}                  # pid -> nome mostrato
var points := [0, 0, 0, 0]
var special := [true, true, true, true]
var last_place := [0, 0, 0, 0]
var manche := 0
var r: CerchioRules
var ghost_ok := [0, 0, 0, 0]
var ghost_paid := [false, false, false, false]
var manche_place := [0, 0, 0, 0]  # piazzamento nell'ultima manche (0 = primo a morire, 3 = ultimo vivo)
var _altar_shown := 0.0          # fiamme mostrate sull'altare durante le animazioni
var _post: ColorRect               # pellicola: vignettatura, grana, lampi
var _token := 0                 # cambia a ogni nuova partita: le attese della vecchia si fermano


func _ready() -> void:
	rng.randomize()
	for a in OS.get_cmdline_user_args():
		if a == "--auto":
			auto = true
		elif a.begins_with("--veloce="):
			speed = float(a.get_slice("=", 1))
		elif a.begins_with("--foto="):
			shots_dir = a.get_slice("=", 1)
		elif a == "--esci":
			quit_at_end = true
		elif a == "--solo-menu":
			menu_only = true
		elif a.begins_with("--vista="):       # --vista=gradi,distanza,inclinazione: una sola foto da lì
			views.append(Vector3(float(a.get_slice("=", 1).get_slice(",", 0)), float(a.get_slice(",", 1)), float(a.get_slice(",", 2))))
		elif a.begins_with("--esplora="):
			explore_shots = int(a.get_slice("=", 1))
		elif a.begins_with("--scenario="):
			force_scenario = int(a.get_slice("=", 1))
		elif a == "--cerchio":
			cerchio = true
			Testi.catene = false
		elif a.begins_with("--giocatori="):     # prova: quanti al tavolo (4-8)
			force_players = clampi(int(a.get_slice("=", 1)), 4, 8)
		elif a == "--clic":
			clicker = true
		elif a.begins_with("--grafica="):       # prova di un livello di qualità (0 Media, 1 Alta, 2 Ultra), senza salvarlo
			Grafica.carica()
			Grafica.livello = clampi(int(a.get_slice("=", 1)), 0, 2)
		elif a.begins_with("--visuale="):       # prova di un'inquadratura (0..4), senza salvarla
			Visuale.carica()
			Visuale.livello = clampi(int(a.get_slice("=", 1)), 0, Visuale.NOMI.size() - 1)
		elif a.begins_with("--difficolta="):    # prova degli avversari (0 Normale, 1 Adattivo), senza salvarla
			Difficolta.carica()
			Difficolta.livello = clampi(int(a.get_slice("=", 1)), 0, 1)
	font = Stile.font_head()
	Grafica.applica(get_viewport())
	get_tree().root.content_scale_factor = Cfg.UI_SCALE    # scritte e riquadri più piccoli (su ogni schermo)
	_build_post()
	hud = Hud.new()
	add_child(hud)
	hud.menu_play.connect(func(c: int, sc: int) -> void: _play_match(c, sc))
	hud.menu_quit.connect(func() -> void: get_tree().quit())
	hud.to_menu.connect(_show_menu)
	hud.menu_place.connect(func(sc: int) -> void: _menu_scene(sc))
	hud.view_changed.connect(func() -> void:
		if is_instance_valid(arena) and not arena.orbit:
			arena.set_view())
	hud.explore.connect(func(sc: int) -> void: _explore(sc if sc >= 0 else rng.randi() % Testi.SCENARI.size()))
	hud.explore_next.connect(func() -> void: _explore((_explore_sc + 1) % Testi.SCENARI.size()))
	hud.explore_reseed.connect(func() -> void: _explore(_explore_sc))
	Sfx.start_loops()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--prova-audio="):            # prova del pannello Audio con clic veri (tests/prova_audio.gd)
			_prova = load("res://tests/prova_audio.gd").new()
			_prova.call("run", self, a.get_slice("=", 1), force_scenario)
			return
		if a.begins_with("--prova-catene="):           # prova delle catene (tests/prova_catene.gd)
			_prova = load("res://tests/prova_catene.gd").new()     # tenuta qui: la prova vive finché non ha finito
			print("PROVA CATENE ", a.get_slice("=", 1))
			_prova.call("run", self, a.get_slice("=", 1), force_scenario)
			return
	_show_menu()
	if menu_only:
		await get_tree().create_timer(2.5).timeout
		await _shot("menu")
		if "--crediti" in OS.get_cmdline_user_args():     # anche il pannello dei Riconoscimenti
			hud._credits.visible = true
			await get_tree().create_timer(0.5).timeout
			await _shot("crediti")
			hud._credits.visible = false
		if "--opzioni" in OS.get_cmdline_user_args():     # anche il pannello Audio e schermo
			hud._audio.visible = true
			await get_tree().create_timer(0.5).timeout
			await _shot("opzioni")
		get_tree().quit()
		return
	if explore_shots >= 0:
		_explore(explore_shots)
		arena.follow_altar = "--segui-altare" in OS.get_cmdline_user_args()
		if "--dove-corvi" in OS.get_cmdline_user_args():     # prova: una foto puntata su ogni corvo posato
			var crows := arena.find_children("*", "Corvo", true, false)
			for c in crows.slice(0, 4):
				if (c as Corvo).flying:
					continue
				var cp: Vector3 = (c as Node3D).global_position
				views.append(Vector3(rad_to_deg(atan2(cp.x, cp.z)), Vector2(cp.x, cp.z).length() + 2.6, 0.18))
		for k in views.size():
			arena.orbit_yaw = deg_to_rad(views[k].x)
			arena.orbit_idle = -1000.0
			arena.orbit_dist = views[k].y
			arena.orbit_pitch = views[k].z
			await _wait(1.5)
			await _shot("vista%d_%d" % [explore_shots, k])
		for k in (0 if views.size() > 0 else 6):
			arena.orbit_yaw = TAU * k / 6.0
			arena.orbit_idle = 0.0
			arena.orbit_dist = minf(8.0 if k % 2 == 0 else 5.0, arena.orbit_max)
			arena.orbit_pitch = 0.38 if k % 2 == 0 else 0.22
			await _wait(1.5)
			await _shot("luogo%d_%d" % [explore_shots, k])
			print("FPS luogo %d veduta %d: %.0f" % [explore_shots, k, Performance.get_monitor(Performance.TIME_FPS)])
		get_tree().quit()
		return
	if clicker:
		await _wait(0.5)
		hud.menu_play.emit(rng.randi() % 4, -1)
	if auto:
		await get_tree().create_timer(2.5).timeout      # l'animazione d'entrata del menu è finita
		await _shot("menu")
		hud.show_rules(2)
		await _shot("regole")
		hud._rules.visible = false
		_play_match(rng.randi() % 4)


func _process(delta: float) -> void:
	if shots_dir != "" and Engine.get_process_frames() % 30 == 0:
		_fps.append(Performance.get_monitor(Performance.TIME_FPS))
	if not clicker:
		return
	_click_t -= delta
	if _click_t > 0.0:
		return
	_click_t = 0.15
	if hud._big.visible:
		hud._big_btn.pressed.emit()
		return
	var bs: Array[Button] = []
	for c in hud._actions.get_children() + hud._cards_row.get_children():
		if c is Button and not c.is_queued_for_deletion():
			bs.append(c)
	if not bs.is_empty():
		bs[rng.randi() % bs.size()].pressed.emit()


## Il mouse su un campione lo illumina (la scheda sopra la visuale è stata tolta su richiesta dell'utente).
var _hover: Figura


func _physics_process(_delta: float) -> void:
	if hud == null or arena == null or arena.camera == null or hud.blocking() or names.is_empty():
		if _hover:
			_hover.highlight(false)
			_hover = null
			if hud:
				hud.show_preview({}, null)
		return
	var cam := arena.camera
	var mp := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mp)
	var q := PhysicsRayQueryParameters3D.create(from, from + cam.project_ray_normal(mp) * 40.0, 2)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var fig: Figura = null
	if not hit.is_empty() and hit["collider"].has_meta("figura"):
		fig = hit["collider"].get_meta("figura")
	if fig != _hover:
		if _hover:
			_hover.highlight(false)
		_hover = fig
		if fig:
			fig.highlight(true)
	if fig == null:
		hud.show_preview({}, null)
		return
	# niente scheda sopra la visuale (richiesta dell'utente): resta solo la luce sul campione
	hud.show_preview({}, null)


func _preview_info(pid: int) -> Dictionary:
	var c: Dictionary = Testi.CLASSI[classes[pid]]
	var p := r.players[pid] if r else null
	var lines: Array[String] = []
	if p:
		if p.alive:
			var dots := ""
			for k in int(Cfg.CANDLES):
				dots += "●" if k < int(ceil(p.candles)) else "○"
			lines.append("Candele: " + dots)
		else:
			lines.append("Spettro fino alla fine della manche")
		if p.tired and p.alive:
			lines.append("Stanco: al prossimo giro può solo attaccare")
		if p.cursed:
			lines.append("Maledetto: niente carte in questa manche")
		lines.append("Carte del Custode: %d" % p.hand.size())
		if pid == 0 and not p.hand.is_empty():
			var hn: Array[String] = []
			for k in p.hand:
				hn.append(Testi.CARTE[k]["nome"])
			lines.append("  (" + ", ".join(hn) + ")")
	lines.append("Punti: %d" % points[pid])
	var ready: bool = p.special_left if p else special[pid]
	lines.append("")
	lines.append("%s — %s" % [c["abilita"].to_upper(), "pronta" if ready else "già usata"])
	lines.append(c["desc_abilita"])
	return {"nome": "Tu" if pid == 0 else c["nome"], "classe": c["nome"] + " · «" + c["motto"] + "»" if pid == 0 else "«" + c["motto"] + "»",
		"colore": c["colore"].lerp(Color.WHITE, 0.25), "testo": "\n".join(lines)}


func _wait(sec: float) -> void:
	await get_tree().create_timer(maxf(sec * speed, 0.01)).timeout


func _shot(tag: String) -> void:
	if shots_dir == "":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(shots_dir)
	_shot_n += 1
	get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [shots_dir, _shot_n, tag])


func _new_arena(scenario: int) -> void:
	if arena:
		arena.queue_free()
	arena = Arena.new()
	add_child(arena)
	arena.build(scenario, rng.randi())


## Esplora un luogo: solo scenario, cerchio e altare acceso, telecamera libera attorno.
func _explore(sc: int) -> void:
	_token += 1
	_explore_sc = sc
	names = {}
	_new_arena(sc)
	arena.orbit = true
	hud.show_explorer(Testi.SCENARI[sc]["nome"])


func _unhandled_input(e: InputEvent) -> void:
	if arena == null or not arena.orbit or hud.blocking():
		return
	if e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
		arena.orbit_drag(e.relative.x, e.relative.y)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			arena.orbit_zoom(0.9)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			arena.orbit_zoom(1.1)


# ------------------------------------------------------------------ menu

func _show_menu() -> void:
	_token += 1
	Engine.time_scale = 1.0
	Sfx.heartbeat(false)

	_menu_scene(hud._place_pick)
	hud.show_menu(true)


## Sfondo del menu: il luogo scelto (o uno a caso, diverso da quello di prima), con una breve dissolvenza.
func _menu_scene(sc: int) -> void:
	if sc < 0:
		sc = rng.randi() % Testi.SCENARI.size()
		if sc == _menu_sc and arena != null:
			sc = (sc + 1 + rng.randi() % (Testi.SCENARI.size() - 1)) % Testi.SCENARI.size()
	elif sc == _menu_sc and arena != null:
		return
	_menu_sc = sc
	var tk := _token
	if arena != null:
		await hud.fade(1.0, 0.25)
		if tk != _token:
			hud.fade(0.0, 0.2)
			return
	_new_arena(sc)
	names = {}
	arena.orbit = true
	arena.orbit_dist = 7.2     # dentro la radura: niente alberi fra la telecamera e il falò
	arena.orbit_pitch = 0.5
	hud.fade(0.0, 0.5)


# ------------------------------------------------------------------ partita

func _play_match(my_cls: int, place := -1) -> void:
	_token += 1
	var tk := _token
	var scenario := place if place >= 0 else rng.randi() % Testi.SCENARI.size()
	if force_scenario >= 0:
		scenario = force_scenario
	_new_arena(scenario)
	# quanti al tavolo: 4 nel vecchio gioco; nelle Catene da 4 a 8 (scelta nel menu)
	n_players = 4 if cerchio else (force_players if force_players >= 4 else hud.players_pick)
	arena.set_seats(n_players)
	var pool: Array = []
	for c in (Testi.CLASSI.size() if not cerchio else Testi.CLASSI_CERCHIO):
		if c != my_cls:
			pool.append(c)
	pool.shuffle()
	# i quattro campioni di sempre per primi, poi quelli nuovi
	pool.sort_custom(func(a: int, b: int) -> bool: return int(a >= Testi.CLASSI_CERCHIO) < int(b >= Testi.CLASSI_CERCHIO))
	var others := pool.slice(0, n_players - 1)
	others.shuffle()
	classes = [my_cls] + others
	names = {0: "Tu"}
	for pid in range(1, n_players):
		names[pid] = Testi.CLASSI[classes[pid]]["nome"]
	for pid in n_players:
		var label: String = "Tu (%s)" % Testi.CLASSI[my_cls]["nome"] if pid == 0 else names[pid]
		var fig := arena.place(pid, classes[pid], label, font)
		fig.is_me = pid == 0
	points = [0, 0, 0, 0]
	special = [true, true, true, true]
	last_place = [0, 0, 0, 0]
	hud.show_menu(false)
	hud.clear_log()
	hud.set_round("")
	hud.set_omen(0)
	if not cerchio:
		# il gioco nuovo (decisione dell'utente del 21/10/2026): Le catene dell'altare
		await CateneMatch.new(self).play(tk)
		return
	var sc: Dictionary = Testi.SCENARI[scenario]
	arena.custode_speak()
	await _big(sc["nome"], "%s\n\n«%s»\n\nSei %s. Tre manche: la terza vale doppio.\nPremi «?» in qualsiasi momento per rileggere le regole." % [
		sc["sotto"], Testi.a_caso(Testi.CUSTODE_INIZIO), Testi.CLASSI[my_cls]["articolo"]], "Entra nel cerchio")
	if tk != _token:
		return
	for m in range(1, Cfg.MANCHE + 1):
		manche = m
		await _play_manche(tk)
		if tk != _token:
			return
		await _standings()
		if tk != _token:
			return
	await _final()


func _big(title: String, text: String, button := "Continua", tag := "", rows := []) -> void:
	hud.show_big(title, text, button, rows)
	arena.labels(false)
	if tag != "":
		await _shot(tag)
	if auto:
		await _wait(1.0)
		hud._big.visible = false
	else:
		await hud.next_pressed
	if is_instance_valid(arena):
		arena.labels(true)


func _play_manche(tk: int) -> void:
	r = CerchioRules.new()
	r.order_rotate = true            # ordine dei colpi visibile prima delle scelte, a rotazione
	r.use_cards = false              # carte del Custode e Presagi spenti (decisione dell'utente): il codice resta
	r.setup(classes, Cfg.CANDLES, rng.randi(), "B", false)
	for pid in 4:
		r.players[pid].special_left = special[pid]
	ghost_ok = [0, 0, 0, 0]
	ghost_paid = [false, false, false, false]
	for pid in 4:
		var f := arena.seats[pid]
		f.set_ghost(false)
		f.build_candles(int(Cfg.CANDLES))
		f.show_candles(Cfg.CANDLES, false)
		f.clear_pose()
		f.set_ability(special[pid])
	_altar_shown = 0.0
	arena.set_altar(0.0)
	hud.clear_log()
	hud.set_order([])
	_board()
	var died: Array[int] = []
	await _big("%s manche" % _ordinale(manche).capitalize(),
		"Tutti con %d candele.%s%s" % [int(Cfg.CANDLES),
			(" Ricevi 3 carte del Custode: %s." % _hand_text()) if not r.players[0].hand.is_empty() else "",   # carte spente: non se ne parla
			"\nQuesta manche vale DOPPIO." if manche == Cfg.MANCHE else ""],
		"Inizia", "manche%d" % manche)
	if tk != _token:
		return
	var guard := 0
	while not r.is_over() and guard < 200:
		guard += 1
		var deaths: Array = await _play_round(tk)
		if tk != _token:
			return
		for d in deaths:
			died.append(d)
	# punti per piazzamento
	var order: Array[int] = died.duplicate()
	if r.winner() >= 0:
		order.append(r.winner())
	var mult := 2 if manche == Cfg.MANCHE else 1
	for place in order.size():
		points[order[place]] += Cfg.POINTS[place] * mult
		manche_place[order[place]] = place
		if manche == Cfg.MANCHE:
			last_place[order[place]] = place
	for pid in 4:
		special[pid] = r.players[pid].special_left
	print("MANCHE %d: giri %d, ordine di morte %s, punti %s" % [manche, r.round_no, str(order), str(points)])
	_board()


func _play_round(tk: int) -> Array:
	Arena.shake_on = hud.shake_on
	r.begin_round()
	hud.set_round("Manche %d di %d   —   giro %d" % [manche, Cfg.MANCHE, r.round_no])
	hud.set_omen(0)
	if r.omen != CerchioRules.Omen.NONE:
		arena.custode_speak()
		Sfx.play("shuffle", -4.0)
		hud.hint("Il Custode estrae un Presagio…")
		await arena.draw_omen(Testi.PRESAGI[r.omen]["nome"], Testi.PRESAGI[r.omen]["testo"], speed,
			func() -> void: Sfx.play("flip", -2.0))
		if r.round_no <= 3 and manche == 1:
			await _shot("presagio")
		await _wait(Cfg.T_OMEN)
		arena.drop_omen()
		if tk != _token:
			return []
		Sfx.play("bell", -6.0)
		hud.hint("")
		hud.set_omen(r.omen)
		hud.log_line("Presagio: %s" % Testi.PRESAGI[r.omen]["nome"])
	_board()
	# Presagi che agiscono subito (Scambio, Tributo)
	for ev in r.begin_events:
		match ev["t"]:
			"scambio":
				hud.log_line("Scambio: %s e %s si scambiano le candele." % [_subj(ev["a"]), _obj(ev["b"])])
				arena.shoot(arena.seats[ev["a"]].chest(), arena.seats[ev["b"]].chest(), Color(1, 0.7, 0.3), 0.5)
				arena.shoot(arena.seats[ev["b"]].chest(), arena.seats[ev["a"]].chest(), Color(1, 0.7, 0.3), 0.5)
				await _wait(0.6)
				arena.seats[ev["a"]].show_candles(r.players[ev["a"]].candles)
				arena.seats[ev["b"]].show_candles(r.players[ev["b"]].candles)
			"tributo":
				hud.log_line("Tributo: %s offre una candela all'altare." % _subj(ev["pid"]))
				arena.shoot(arena.seats[ev["pid"]].chest(), arena.altar_pos(), Color(1, 0.6, 0.2), 0.5)
				await _wait(0.6)
				arena.seats[ev["pid"]].show_candles(r.players[ev["pid"]].candles)
		Sfx.play("blow", -4.0)
		await _wait(Cfg.T_EVENT)
	_altar_shown = r.altar
	arena.set_altar(r.altar)
	_board()
	# l'ordine dei colpi si conosce PRIMA di scegliere: targhette sopra la frase di aiuto (la tua in oro)
	var shown: Array = []
	for pid in r.order:
		shown.append({"nome": names[pid], "colore": Testi.CLASSI[classes[pid]]["colore"], "me": pid == 0})
	hud.set_order(shown)
	# scelte segrete degli avversari (la strega con l'occhio sceglie per ultima)
	var choices := {}
	var witches: Array[int] = []
	for pid in r.alive_ids():
		if pid == 0:
			continue
		if r.players[pid].cls == CerchioRules.Cls.STREGA and r.players[pid].special_left:
			witches.append(pid)
		else:
			choices[pid] = CerchioBot.pick_card(r, pid, CerchioBot.choose(r, pid, rng, Cfg.BOT_TEMP, {}, Difficolta.adattivo()), rng)
	var bets := {}
	for pid in 4:
		if pid != 0 and not r.players[pid].alive:
			bets[pid] = CerchioBot.ghost_pick(r, rng)
	if r.players[0].alive:
		var c: Dictionary = await _ask_human(choices, witches, tk)
		if tk != _token:
			return []
		choices[0] = c
	else:
		bets[0] = await _ask_bet(tk)
		if tk != _token:
			return []
	for w in witches:
		var peek := CerchioBot.witch_peek(r, w, rng)
		var known := {}
		if peek >= 0 and choices.has(peek):
			known[peek] = choices[peek]
		var c := CerchioBot.choose(r, w, rng, Cfg.BOT_TEMP, known, Difficolta.adattivo())
		if not known.is_empty():
			c["peek"] = peek
		choices[w] = CerchioBot.pick_card(r, w, c, rng)
	return await _reveal(choices, bets, tk)


## La tua mossa. Restituisce la scelta (con "peek" se la strega ha usato l'occhio).
func _ask_human(choices: Dictionary, witches: Array[int], tk: int) -> Dictionary:
	var me := r.players[0]
	var can_peek := me.cls == CerchioRules.Cls.STREGA and me.special_left and r.abilities_allowed()
	var peeked := {}
	var others := {}
	for pid in r.alive_ids():
		if pid != 0:
			others[pid] = names[pid]
	if auto:
		if r.round_no == 1 and manche == 1 and shots_dir != "":
			hud.hint("Scegli la tua mossa. Nessuno la vedrà fino alla rivelazione.")
			hud.set_hand(me.hand, "", others)
			hud.ask_move(r.legal_choices(0), others, me.cls, can_peek, peeked)
			await _shot("scelta")
			hud.show_first_card_tip()
			await get_tree().create_timer(0.3).timeout
			await _shot("anteprima_carta")
			hud.clear_actions()
			hud.clear_cards()
			hud.hint("")
		return CerchioBot.pick_card(r, 0, CerchioBot.choose(r, 0, rng, Cfg.BOT_TEMP), rng)
	var note := ""
	if me.cursed:
		note = "Sei maledetto: niente carte per questa manche."
	elif r.omen == CerchioRules.Omen.SILENZIO:
		note = "Silenzio: niente carte in questo giro."
	hud.set_hand(me.hand, note, others)
	while true:
		var opts := r.legal_choices(0)
		if r.must_attack(0):
			hud.hint("Sei stanco (o il Presagio ti obbliga): puoi solo attaccare.")
		elif not peeked.is_empty():
			hud.hint("Hai visto la sua mossa. Ora scegli la tua.")
		else:
			hud.hint("Scegli la tua mossa. Nessuno la vedrà fino alla rivelazione.")
		hud.ask_move(opts, others, me.cls, can_peek, peeked)
		var normal: Array = []
		for o in opts:
			if o["move"] != CerchioRules.Move.SPECIAL:
				normal.append(o)
		hud.start_timer(Cfg.TURN_TIME, func() -> void:
			hud.hint("Tempo scaduto: ha scelto il destino.")
			hud._send(normal[rng.randi() % normal.size()]))
		if r.round_no == 1 and manche == 1:
			await _shot("scelta")
		var c: Dictionary = await hud.choice_made
		if tk != _token:
			return {}
		if c["move"] == -2:
			var t: int = c["peek_target"]
			if not choices.has(t):
				# spiata un'altra strega che non ha ancora scelto: decide adesso, senza occhio
				choices[t] = CerchioBot.choose(r, t, rng, Cfg.BOT_TEMP, {}, Difficolta.adattivo())
				witches.erase(t)
			peeked = {t: choices[t]}
			hud.log_line("Occhio della strega: %s %s." % [_subj(t), _move_text(t, choices[t], true)])
			continue
		if not peeked.is_empty():
			c["peek"] = peeked.keys()[0]
		return c
	return {}


func _ask_bet(tk: int) -> int:
	var alive := {}
	for pid in r.alive_ids():
		alive[pid] = names[pid]
	if auto:
		return CerchioBot.ghost_pick(r, rng)
	hud.ask_bet(alive)
	hud.start_timer(Cfg.TURN_TIME, func() -> void:
		hud.clear_actions()
		hud.ghost_bet.emit(-1))
	var pid: int = await hud.ghost_bet
	if tk != _token:
		return -1
	return pid


# ------------------------------------------------------------------ rivelazione

## Testo della mossa: "attacca la Strega", "si difende dal Cavaliere"...
func _move_text(pid: int, c: Dictionary, third := false) -> String:
	var who := func(t: int) -> String: return "te" if t == 0 else Testi.CLASSI[classes[t]]["articolo"]
	var me_first := pid == 0 and not third
	match c["move"]:
		CerchioRules.Move.ATTACK:
			return ("attacchi " if me_first else "attacca ") + who.call(c["target"])
		CerchioRules.Move.DEFEND:
			return ("ti difendi " if me_first else "si difende ") + _da(c["target"])
		CerchioRules.Move.HEAL:
			return "riaccendi una candela" if me_first else "riaccende una candela"
		CerchioRules.Move.SPECIAL:
			var ab: String = Testi.CLASSI[classes[pid]]["abilita"]
			if c.has("targets"):
				return "%s contro %s e %s" % [ab, who.call(c["targets"][0]), who.call(c["targets"][1])]
			return ab
	return ""


func _label_text(pid: int, c: Dictionary) -> String:
	var short := func(t: int) -> String: return "te" if t == 0 else Testi.CLASSI[classes[t]]["nome"].get_slice(" ", 0)
	match c["move"]:
		CerchioRules.Move.ATTACK:
			return "Attacca " + short.call(c["target"])
		CerchioRules.Move.DEFEND:
			return "Si difende da " + short.call(c["target"])
		CerchioRules.Move.HEAL:
			return "Riaccende"
		CerchioRules.Move.SPECIAL:
			return Testi.CLASSI[classes[pid]]["abilita"]
	return ""


func _reveal(choices: Dictionary, bets: Dictionary, tk: int) -> Array:
	hud.clear_actions()
	hud.stop_timer()
	hud.hint("")
	Sfx.play("drum", -2.0)
	arena.circle_pulse(Color(1.0, 0.3, 0.15))
	hud.log_line("— Rivelazione —")
	var lives := {}
	for pid in 4:
		lives[pid] = r.players[pid].candles
	for pid in choices:
		var c: Dictionary = choices[pid]
		var f := arena.seats[pid]
		var lt := _label_text(pid, c)
		if c.has("card") and r.can_play_card(pid):
			lt += "\n+ carta"
		f.set_move_text(lt)
		if c["move"] == CerchioRules.Move.DEFEND:
			f.defend_toward(arena.seats[c["target"]].global_position)
		elif c["move"] == CerchioRules.Move.SPECIAL and classes[pid] == CerchioRules.Cls.CAVALIERE:
			f.oath(true)
		if pid == 0:
			hud.log_line("La tua mossa: %s." % _move_text(0, c))
		if c.has("peek"):
			hud.log_line("%s ha usato l'Occhio della strega." % _subj(pid))
	await _wait(Cfg.T_REVEAL)
	if r.round_no <= 2 and manche == 1:
		await _shot("rivelazione")
	if tk != _token:
		return []
	var rep := r.resolve(choices)
	var fire_done := {}
	# prima si scoprono le carte, poi si ricorda l'ordine dei colpi (già noto prima delle scelte)
	var evs: Array = rep["events"]
	var split := evs.size()
	for i in evs.size():
		if not ["carta", "maledetto", "carta_annullata", "furto", "catena", "patto", "fiamma", "perde", "muore",
				"respiro"].has(evs[i]["t"]):
			split = i
			break
	for i in split:
		if tk != _token:
			return []
		await _play_event(evs[i], rep, lives, fire_done)
	var order: Array = rep["order"]
	for k in order.size():
		arena.seats[order[k]].set_order(k + 1)
	var line: Array[String] = []
	for k in order.size():
		line.append("%d  %s" % [k + 1, names[order[k]]])
	var first: int = order[0]
	hud.banner("ORDINE DEI COLPI", "Colpisci per primo tu!" if first == 0 else "Colpisce per primo " + _obj(first),
		"     ".join(line), Cfg.T_ORDER * speed)
	Sfx.play("whoosh", -6.0)
	if manche == 1 and r.round_no <= 2:
		await _wait(Cfg.T_ORDER * 0.4)
		await _shot("ordine")
		await _wait(Cfg.T_ORDER * 0.6)
	else:
		await _wait(Cfg.T_ORDER)
	if tk != _token:
		return []
	for i in range(split, evs.size()):
		if tk != _token:
			return []
		await _play_event(evs[i], rep, lives, fire_done)
	_altar_shown = r.altar
	arena.set_altar(r.altar)
	arena.focus_home()
	Engine.time_scale = 1.0
	# fine giro
	if tk != _token:
		return []
	for pid in 4:
		var f := arena.seats[pid]
		f.clear_pose()
		f.set_tired(r.players[pid].tired and r.players[pid].alive)
		f.set_ability(r.players[pid].special_left and r.players[pid].alive)
		f.show_candles(r.players[pid].candles)
	if rep["damage"] == 0.0 and not rep["ira"] and rng.randf() < 0.5:
		arena.custode_speak()
		hud.custode(Testi.a_caso(Testi.CUSTODE_NULLA))
	# scommesse degli spettri
	for pid in bets:
		var t: int = bets[pid]
		if t < 0:
			continue
		if _lost(rep, t):
			ghost_ok[pid] += 1
			var who: String = "Lo spettro " + _di(pid) + " ha"
			hud.log_line("%s indovinato: %s ha perso una candela." % [who, _subj(t).left(1).to_lower() + _subj(t).substr(1)])
			if ghost_ok[pid] >= Cfg.GHOST_HITS_PER_POINT and not ghost_paid[pid]:
				ghost_paid[pid] = true
				points[pid] += 1
				hud.log_line("Lo spettro %s guadagna 1 punto." % _di(pid))
	_board()
	await _wait(Cfg.T_END_ROUND)
	return rep["deaths"]


func _lost(rep: Dictionary, pid: int) -> bool:
	for ev in rep["events"]:
		if ev["t"] == "perde" and ev["pid"] == pid:
			return true
	return false


func _play_event(ev: Dictionary, rep: Dictionary, lives: Dictionary, fire_done: Dictionary) -> void:
	match ev["t"]:
		"colpo":
			var a: int = ev["da"]
			var t: int = ev["a"]
			var fa := arena.seats[a]
			var ft := arena.seats[t]
			# un colpo alla volta, in primo piano: la telecamera arriva, un attimo di silenzio, poi il colpo
			var base := 2.0 if r.omen == CerchioRules.Omen.SANGUE_DOPPIO else 1.0
			var big: bool = ev["esito"] == "contrattacco" and lives[a] - base <= 0.0 \
				or ev["esito"] == "colpito" and lives[t] - float(ev.get("n", 1.0)) <= 0.0 \
				or ev["esito"] == "specchio" and lives[a] - float(ev.get("n", 1.0)) <= 0.0
			if not ev["fuoco"]:
				arena.focus_pair(fa.global_position, ft.global_position)
				await _wait(0.6)
				if manche == 1 and r.round_no <= 2 and _shot_n < 14:
					_shot_after(0.5, "scontro")
			if ev["fuoco"]:
				if not fire_done.has(a):
					fire_done[a] = true
					var pts: Array[Vector3] = []
					for e2 in rep["events"]:
						if e2["t"] == "colpo" and e2["da"] == a and e2["fuoco"]:
							pts.append(arena.seats[e2["a"]].chest())
					hud.log_line("%s scatena il Soffio del drago!" % _subj(a))
					Sfx.play("whoosh", 0.0, 0.7)
					await arena.dragon_fire(fa, pts)
			else:
				_attack_anim(a, t)
				if big or ev["esito"] == "contrattacco":
					await _wait(0.22)
					_slowmo(0.3, 0.9)      # il colpo che decide arriva al rallentatore
				await _wait(0.45 if not big else 0.23)
			match ev["esito"]:
				"colpito":
					ft.hurt()
					_hit_stop(0.1 if big else 0.06)
					arena.shake(0.5 if big else 0.3)
					arena.sparks(ft.chest(), Color(1.0, 0.3, 0.15), 30 if big else 18)
					arena.damage_number(ft.chest() + Vector3(0, 0.6, 0), "-%d" % int(ev.get("n", 1.0)), Color(1.0, 0.25, 0.2))
					if t == 0:
						_post_flash(Color(0.7, 0.02, 0.02), 0.55)
					Sfx.play("chop", -4.0)
					hud.log_line("%s colpisce %s." % [_subj(a), _obj(t)])
				"contrattacco":
					ft.shield_flash()
					ft.lunge(fa.global_position, 0.3, 0.45)
					await _wait(0.2)
					fa.hurt()
					_hit_stop(0.12)
					arena.shake(0.7)
					arena.sparks(fa.chest(), Color(0.6, 0.8, 1.0), 34)
					arena.damage_number(fa.chest() + Vector3(0, 0.6, 0), "-%d" % int(base), Color(0.6, 0.85, 1.0))
					if a == 0:
						_post_flash(Color(0.7, 0.02, 0.02), 0.55)
					hud.banner("", "CONTRATTACCO!", "%s respinge %s" % [_subj(t), _obj(a)], 1.6 * speed, Color(0.65, 0.85, 1.0))
					Sfx.play("slam", -2.0)
					hud.log_line("CONTRATTACCO! %s respinge %s." % [_subj(t), _obj(a)])
				"giuramento":
					Sfx.play("bell", -4.0, 1.4)
					hud.log_line("Il Giuramento %s respinge %s, che diventa stanco." % [_di(t), _obj(a)])
				"parato":
					ft.shield_flash()
					hud.log_line("%s para il colpo %s." % [_subj(t), _di(a)])
				"ombra":
					Sfx.play("ghost", -8.0, 1.5)
					hud.log_line("Il colpo %s attraversa l'Ombra %s." % [_di(a), _di(t)])
				"specchio":
					ft.shield_flash()
					arena.shoot(ft.chest(), fa.chest(), Color(0.7, 0.85, 1.0), 0.3)
					arena.damage_number(fa.chest() + Vector3(0, 0.6, 0), "-%d" % int(ev.get("n", 1.0)), Color(0.7, 0.85, 1.0))
					_hit_stop(0.08)
					Sfx.play("slam", -4.0, 1.3)
					hud.log_line("Lo Specchio %s rimanda il colpo a %s!" % [_di(t), _obj(a)])
			if ev.get("n", 1.0) > 1.0 and ev["esito"] == "colpito":
				hud.log_line("Il colpo spegne %d candele!" % int(ev["n"]))
			await _wait(Cfg.T_EVENT * 0.5)
		"perde":
			var pid: int = ev["pid"]
			lives[pid] = lives[pid] - float(ev["n"])
			arena.seats[pid].show_candles(lives[pid])
			if pid == 0:
				_my_lives(lives[0])
			Sfx.play("blow", -3.0)
			if ev.get("perche", "") != "fiamma":
				_altar_shown += float(ev["n"])
				arena.shoot(arena.seats[pid].global_position + Vector3(0, 0.5, 0), arena.altar_pos(), Color(1.0, 0.6, 0.2), 0.6, 0.5)
				_altar_later()
			await _wait(Cfg.T_EVENT * 0.4)
		"carta":
			var pid: int = ev["pid"]
			var k: int = ev["card"]
			var tgt: int = ev.get("target", -1)
			Sfx.play("flip", -2.0)
			if pid == 0:
				hud.banner("LA TUA CARTA", Testi.CARTE[k]["nome"], Testi.CARTE[k]["testo"], Cfg.T_EVENT * 1.5 * speed)
			else:
				arena.flash_card(arena.seats[pid], Testi.CARTE[k]["nome"])
			hud.log_line("%s gioca %s%s." % [_subj(pid), Testi.CARTE[k]["nome"].to_upper(),
				(" su " + _obj(tgt)) if tgt >= 0 else ""])
			_board()
			await _wait(Cfg.T_EVENT)
		"maledetto":
			arena.shoot(arena.seats[ev["da"]].chest(), arena.seats[ev["a"]].chest(), Color(0.6, 0.2, 0.9), 0.4)
			Sfx.play("ghost", -4.0, 0.7)
			hud.log_line("%s è maledetto: niente carte per tutta la manche." % _subj(ev["a"]))
			await _wait(Cfg.T_EVENT * 0.7)
		"carta_annullata":
			hud.log_line("La carta %s (%s) svanisce." % [_di(ev["pid"]), Testi.CARTE[ev["card"]]["nome"]])
			await _wait(Cfg.T_EVENT * 0.5)
		"furto":
			arena.shoot(arena.seats[ev["a"]].chest(), arena.seats[ev["da"]].chest(), Color(0.9, 0.85, 0.6), 0.4)
			hud.log_line("%s ruba una carta %s." % [_subj(ev["da"]), _a(ev["a"])])
			_board()
			await _wait(Cfg.T_EVENT * 0.7)
		"catena":
			var t: int = ev["a"]
			arena.shoot(arena.seats[ev["da"]].chest(), arena.seats[t].chest(), Color(0.6, 0.6, 0.65), 0.4)
			Sfx.play("chop", -6.0, 0.6)
			arena.seats[t].shield_fade()
			arena.seats[t].set_move_text("Attacca " + ("te" if ev["da"] == 0 else Testi.CLASSI[classes[ev["da"]]]["nome"].get_slice(" ", 0)) + "\n(catena)")
			hud.log_line("La Catena trascina %s: deve attaccare %s." % [_obj(t), _obj(ev["da"])])
			await _wait(Cfg.T_EVENT * 0.8)
		"patto":
			var a: int = ev["da"]
			var b: int = ev["a"]
			var x: float = lives[a]
			lives[a] = maxf(1.0, lives[b] - r.patto_cost)
			lives[b] = x
			arena.shoot(arena.seats[a].chest(), arena.seats[b].chest(), Color(0.8, 0.05, 0.05), 0.5)
			arena.shoot(arena.seats[b].chest(), arena.seats[a].chest(), Color(0.8, 0.05, 0.05), 0.5)
			Sfx.play("heart", 0.0)
			await _wait(0.55)
			arena.seats[a].show_candles(lives[a])
			arena.seats[b].show_candles(lives[b])
			if a == 0 or b == 0:
				_my_lives(lives[0])
			hud.log_line("Patto di sangue: %s e %s si scambiano le candele." % [_subj(a), _obj(b)])
			await _wait(Cfg.T_EVENT * 0.7)
		"fiamma":
			var a: int = ev["da"]
			var t: int = ev["a"]
			await arena.shoot(arena.seats[t].global_position + Vector3(0, 0.5, 0), arena.seats[a].global_position + Vector3(0, 0.5, 0), Color(1.0, 0.55, 0.15), 0.5)
			lives[a] = minf(Cfg.CANDLES, lives[a] + 1.0)
			arena.seats[a].show_candles(lives[a])
			if a == 0:
				_my_lives(lives[0])
			Sfx.play("relight", -2.0)
			hud.log_line("%s ruba una fiamma %s." % [_subj(a), _a(t)])
		"respiro":
			Sfx.play("heart", 0.0)
			hud.log_line("Ultimo respiro: %s resta in vita con 1 candela!" % _obj(ev["pid"]))
			await _wait(Cfg.T_EVENT * 0.6)
		"sete":
			var pid: int = ev["pid"]
			lives[pid] = minf(Cfg.CANDLES, lives[pid] + 1.0)
			_altar_shown -= 1.0
			arena.shoot(arena.altar_pos(), arena.seats[pid].global_position + Vector3(0, 0.5, 0), Color(1.0, 0.6, 0.2), 0.5, 0.5)
			arena.set_altar(_altar_shown)
			arena.seats[pid].show_candles(lives[pid])
			if pid == 0:
				_my_lives(lives[0])
			hud.log_line("La Sete %s riaccende una candela." % _di(pid))
			await _wait(Cfg.T_EVENT * 0.5)
		"muore":
			var pid: int = ev["pid"]
			hud.log_line("%s muore." % _subj(pid))
			Sfx.play("ghost", -2.0)
			arena.custode_speak()
			hud.custode(Testi.a_caso(Testi.CUSTODE_MORTE))
			arena.focus_one(arena.seats[pid].global_position)
			arena.shake(0.8)
			if pid == 0:
				hud.banner("", "SEI CADUTO", "il cerchio ti reclama", 2.6 * speed, Color(0.85, 0.12, 0.08))
				_post_flash(Color(0.5, 0.0, 0.0), 0.8)
			else:
				hud.banner("", "%s CADE" % names[pid].to_upper(), "", 1.8 * speed, Color(0.85, 0.12, 0.08))
			await arena.seats[pid].die()
			arena.sparks(arena.seats[pid].chest(), Color(0.5, 0.8, 1.0), 40, 2.0)
			_board()
			await _wait(Cfg.T_EVENT * 0.5)
		"fermato":
			hud.log_line("%s cade prima del suo turno: il suo colpo non parte." % _subj(ev["pid"]))
			await _wait(Cfg.T_EVENT * 0.6)
		"a_vuoto":
			var pid: int = ev["pid"]
			arena.seats[pid].shield_fade()
			hud.log_line("%s si difende %s, che non attacca: stanco." % [_subj(pid), _da(ev["da"])])
			await _wait(Cfg.T_EVENT * 0.6)
		"riaccende":
			var pid: int = ev["pid"]
			var n: float = ev.get("n", 1.0)
			await arena.shoot(arena.altar_pos(), arena.seats[pid].global_position + Vector3(0, 0.5, 0), Color(1.0, 0.6, 0.2), 0.5, 0.5)
			_altar_shown -= n
			arena.set_altar(_altar_shown)
			lives[pid] = lives[pid] + n
			arena.seats[pid].show_candles(lives[pid])
			if pid == 0:
				_my_lives(lives[0])
			Sfx.play("relight", -2.0)
			hud.log_line("%s prende una fiamma dall'altare e riaccende una candela." % _subj(pid))
			await _wait(Cfg.T_EVENT * 0.7)
		"riaccende_fallito":
			hud.log_line("%s non riesce a riaccendere: è stato attaccato." % _subj(ev["pid"]))
			await _wait(Cfg.T_EVENT * 0.4)
		"ira":
			arena.custode_speak()
			arena.circle_pulse(Color(1, 0.1, 0.05))
			arena.shake(1.0)
			hud.custode("Nessuno sanguina? Allora sanguinate tutti!")
			Sfx.play("slam", 0.0, 0.6)
			await _wait(Cfg.T_EVENT)
		"stanco":
			pass


## Nomi nel racconto: "il Cavaliere", "dalla Strega"... Il tuo campione porta "(tu)".
func _obj(pid: int) -> String:
	return "te" if pid == 0 else Testi.CLASSI[classes[pid]]["articolo"]


func _subj(pid: int) -> String:
	var s: String = Testi.CLASSI[classes[pid]]["articolo"]
	return s.left(1).to_upper() + s.substr(1) + (" (tu)" if pid == 0 else "")


func _da(pid: int) -> String:
	return "da te" if pid == 0 else Testi.CLASSI[classes[pid]]["da"]


func _a(pid: int) -> String:
	return "a te" if pid == 0 else Testi.CLASSI[classes[pid]]["da"].substr(1)


## L'altare si aggiorna quando la fiamma arriva.
func _altar_later() -> void:
	await _wait(0.6)
	if is_instance_valid(arena):
		arena.set_altar(_altar_shown)


func _di(pid: int) -> String:
	return Testi.CLASSI[classes[pid]]["di"] + (" (tu)" if pid == 0 else "")


## Animazione dell'attacco normale, diversa per classe.
func _attack_anim(a: int, t: int) -> void:
	var fa := arena.seats[a]
	var ft := arena.seats[t]
	var col: Color = Testi.CLASSI[classes[a]]["colore"]
	match classes[a]:
		CerchioRules.Cls.CAVALIERE:
			Sfx.play("whoosh", -4.0, 1.2)
			fa.lunge(ft.global_position, 0.55, 0.6)
		CerchioRules.Cls.STREGA:
			fa.lunge(ft.global_position, 0.12, 0.4)
			arena.shoot(fa.chest() + Vector3(0, 0.5, 0), ft.chest(), col, 0.4)
		CerchioRules.Cls.ELFO:
			fa.lunge(ft.global_position, 0.08, 0.35)
			arena.shoot(fa.chest() + Vector3(0, 0.1, 0), ft.chest(), col, 0.25, 0.6)
		CerchioRules.Cls.DOMATORE:
			fa.lunge(ft.global_position, 0.15, 0.4)
			arena.shoot(fa.dragon.global_position, ft.chest(), Color(1.0, 0.45, 0.1), 0.4)


# ------------------------------------------------------------------ classifica

func _board() -> void:
	var rows := []
	for pid in 4:
		var p := r.players[pid] if r else null
		var st := ""
		if p and not p.alive:
			st = "spettro"
		elif p and p.tired:
			st = "stanco"
		rows.append({"nome": names[pid], "colore": Testi.CLASSI[classes[pid]]["colore"],
			"candele": p.candles if p else Cfg.CANDLES, "max": Cfg.CANDLES, "punti": points[pid], "stato": st,
			"abilita": p.special_left if p else special[pid], "carte": p.hand.size() if p else 0})
	hud.set_board(rows)
	for pid in 4:
		if r and arena.seats.size() > pid and arena.seats[pid]:
			arena.seats[pid].set_cards(r.players[pid].hand.size() if r.players[pid].alive else 0)
	_my_lives(r.players[0].candles if r else Cfg.CANDLES)


func _my_lives(n: float) -> void:
	var p := r.players[0] if r else null
	var ab: String = Testi.CLASSI[classes[0]]["abilita"] if (p.special_left if p else special[0]) else ""
	hud.set_my_lives(n, Cfg.CANDLES, n > 0.0 and (p == null or p.alive), p != null and p.tired, ab,
		_hand_text() if p and p.alive and r.use_cards else "")
	var danger := n <= 1.0 and n > 0.0 and (p == null or p.alive)
	Sfx.heartbeat(danger, 0.75)
	if _post:
		(_post.material as ShaderMaterial).set_shader_parameter("darkness", 0.22 if danger else 0.0)


func _hand_text() -> String:
	var out: Array[String] = []
	if r:
		for k in r.players[0].hand:
			out.append(Testi.CARTE[k]["nome"])
	return ", ".join(out) if not out.is_empty() else "nessuna"


func _pts(n: int) -> String:
	return "1 punto" if n == 1 else "%d punti" % n


func _ranking() -> Array:
	var ids := [0, 1, 2, 3]
	ids.sort_custom(func(a: int, b: int) -> bool:
		if points[a] != points[b]:
			return points[a] > points[b]
		return last_place[a] > last_place[b])
	return ids


func _standings() -> void:
	var mult := 2 if manche == Cfg.MANCHE else 1
	var place_names := ["primo a morire", "secondo a morire", "secondo in vita", "ultimo in vita"]
	var t := "In questa manche%s:\n" % (" (vale doppio)" if mult == 2 else "")
	for place in [3, 2, 1, 0]:
		for pid in 4:
			if manche_place[pid] == place:
				var extra := "  (+1 dallo spettro)" if ghost_paid[pid] else ""
				t += "%s: %s, +%d%s\n" % [names[pid], place_names[place], Cfg.POINTS[place] * mult, extra]
	t += "\nClassifica della partita:\n"
	var k := 1
	for pid in _ranking():
		t += "%d.  %s   —   %s\n" % [k, names[pid], _pts(points[pid])]
		k += 1
	if manche < Cfg.MANCHE:
		t += "\nLa prossima manche vale %s." % ("DOPPIO" if manche + 1 == Cfg.MANCHE else "come questa")
	var w := r.winner()
	var head := "Sopravvive %s." % _obj(w) if w > 0 else ("Sei sopravvissuto tu!" if w == 0 else "")
	await _big("Fine della %s manche" % _ordinale(manche), head + "\n\n" + t, "Continua" if manche < Cfg.MANCHE else "Verdetto", "classifica%d" % manche)


func _final() -> void:
	var rank := _ranking()
	var win: int = rank[0]
	var title := "Hai vinto!" if win == 0 else "Vince %s" % _obj(win)
	Sfx.play("win" if win == 0 else "bell", -2.0)
	arena.custode_speak()
	var t := ""
	for pid in rank:
		t += "%s   —   %s\n" % [names[pid], _pts(points[pid])]
	print("FINE: vince %s, punti %s" % [names[win], str(points)])
	print_fps()
	await _big(title, "«Il cerchio ha scelto.»\n\n" + t, "Torna al menu", "finale")
	if quit_at_end:
		get_tree().quit()
		return
	_show_menu()


# ------------------------------------------------------------------ sensazione dei colpi

## Fermo immagine brevissimo sull'impatto (tempo reale, non rallentato).
func _hit_stop(sec: float) -> void:
	if auto and speed < 0.2:
		return
	var old := Engine.time_scale
	Engine.time_scale = 0.05
	await get_tree().create_timer(sec, true, false, true).timeout
	Engine.time_scale = old if old > 0.06 else 1.0


## Rallentatore per i colpi che decidono (tempo reale).
func _slowmo(scale: float, sec: float) -> void:
	if auto and speed < 0.2:
		return
	Engine.time_scale = scale
	await get_tree().create_timer(sec, true, false, true).timeout
	Engine.time_scale = 1.0


## Lampo di colore sullo schermo (quando colpiscono te).
func _post_flash(c: Color, amount: float) -> void:
	if _post == null or not hud.flash_on:
		return
	var m := _post.material as ShaderMaterial
	m.set_shader_parameter("flash_col", c)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: m.set_shader_parameter("flash", v), amount, 0.0, 0.6)


func _build_post() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_post = ColorRect.new()
	_post.set_anchors_preset(Control.PRESET_FULL_RECT)
	_post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/post.gdshader")
	m.set_shader_parameter("vignette", 0.62)
	m.set_shader_parameter("grain", 0.04)
	_post.material = m
	layer.add_child(_post)


## Fotogrammi al secondo misurati durante la partita (solo nelle prove con --foto).
func print_fps() -> void:
	if not _fps.is_empty():
		var s := _fps.duplicate()
		s.sort()
		print("FPS: mediana %.0f, peggiore 10%% %.0f, minimo %.0f" % [s[s.size() / 2], s[s.size() / 10], s[0]])


func _shot_after(sec: float, tag: String) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout
	await _shot(tag)


## "prima", "seconda"... per i titoli: nel carattere decorativo il numero 1 sembra una I.
func _ordinale(n: int) -> String:
	return ["prima", "seconda", "terza", "quarta", "quinta"][clampi(n - 1, 0, 4)]
