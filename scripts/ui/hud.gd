class_name Hud
extends CanvasLayer
## Interfaccia: menu, istruzioni, scelta della mossa, Presagio, classifica, racconto dei colpi.
## Non conosce le regole: il gioco (game.gd) le passa i dati e riceve le scelte con i segnali.

signal menu_play(cls: int, scenario: int)   # scenario -1 = a caso
signal menu_quit
signal choice_made(choice: Dictionary)
signal pact_answer(accept: bool)
signal ghost_bet(pid: int)
signal next_pressed
signal to_menu
signal menu_place(scenario: int)         # luogo cliccato nel menu: cambia lo sfondo (-1 = a caso)
signal explore(scenario: int)             # -1 = a caso
signal explore_next
signal explore_reseed
signal view_changed                     # cambiata l'inquadratura (Visuale)

const GOLD := Color(0.93, 0.78, 0.45)
const BONE := Color(0.92, 0.88, 0.8)
const DIM := Color(0.62, 0.58, 0.52)
const BLOOD := Color(0.85, 0.2, 0.15)

var title_font: Font
var head_font: Font
var body_font: Font
var italic_font: Font

var _root: Control
var _menu: Control
var _rules: Control
var _rules_page := 0
var _rules_title: Label
var _rules_text: Label
var _rules_num: Label
var _credits: Control
var _pause: Control
var _game_ui: Control
var _board: VBoxContainer
var _omen_box: PanelContainer
var _omen_title: Label
var _omen_text: Label
var _round_lbl: Label
var _custode_lbl: Label
var _banner: PanelContainer
var _banner_small: Label
var _banner_big: Label
var _banner_line: Label
var _my_lives: Label
var _my_state: Label
var _my_title: Label
var _log: RichTextLabel
var _log_panel: PanelContainer
var _log_lines: Array[String] = []
var _hint: Label
var _actions: HBoxContainer
var _timer_lbl: Label
var _big: Control
var _big_title: Label
var _big_text: Label
var _big_btn: Button
var _class_pick := 0
var _place_pick := -1
var _audio: Control
var _visual: Control
var shake_on := true            # scossoni della telecamera (accessibilità)
var flash_on := true            # lampi sullo schermo (accessibilità)
const OPT_CFG := "user://opzioni.cfg"
var _time_left := 0.0
var _timing := false
var _on_timeout: Callable
var _ask_args := []
var _cards_row: HBoxContainer
var _hand: Array = []            # le tue carte (id di CerchioRules.Card)
var _cards_note := ""            # perché non puoi giocare carte (vuoto = puoi)
var _card_names := {}            # pid -> nome, per le carte con bersaglio
var _card_pick := {}             # carta scelta per questo giro: {"card", "card_target"}              # ultima richiesta di mossa, per il pulsante Annulla


func _ready() -> void:
	layer = 5
	Carta.set_host(self)          # le carte 3D prendono la faccia dalle carte disegnate qui
	title_font = Stile.font_title()
	head_font = Stile.font_head()
	body_font = Stile.font_body()
	italic_font = Stile.font_italic()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_game_ui()
	_build_big()
	_build_menu()
	_build_rules()
	_build_credits()
	_build_pause()
	_build_audio()
	_build_preview()
	_build_explorer()
	# Regole, Visuale e Audio in alto a destra restano cliccabili anche sopra i messaggi grandi della partita
	_top_bar.reparent(_root, false)        # false: tiene ancore e margini (con true finiva fuori dallo schermo)
	_top_bar.visible = _game_ui.visible
	_game_ui.visibility_changed.connect(func() -> void: _top_bar.visible = _game_ui.visible)


func _process(delta: float) -> void:
	if not _timing:
		return
	_time_left -= delta
	_timer_lbl.text = "%d" % ceili(maxf(_time_left, 0.0))
	_timer_lbl.modulate = BLOOD if _time_left < 8.0 else DIM
	if _time_left <= 0.0:
		_timing = false
		_timer_lbl.text = ""
		if _on_timeout.is_valid():
			_on_timeout.call()


func _unhandled_input(e: InputEvent) -> void:
	# tasto V in partita: passa all'inquadratura successiva
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_V and _game_ui.visible:
		_set_view(Visuale.livello + 1)
		log_line("Visuale: %s" % Visuale.NOMI[Visuale.livello])
		get_viewport().set_input_as_handled()
		return
	# tasto M ovunque: audio spento / acceso
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_M:
		toggle_audio()
		get_viewport().set_input_as_handled()
		return
	if e.is_action_pressed("ui_cancel"):
		if _rules.visible:
			_rules.visible = false
		elif _game_ui.visible:
			_pause.visible = not _pause.visible
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ elementi comuni

func _lbl(text: String, font: Font, size: int, c := BONE, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	Stile.shadow(l)
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _panel(alpha := 0.82) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Stile.panel(alpha))
	return p


func _btn(text: String, cb: Callable, size := 26, c := BONE) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", head_font)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", c)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color(0.4, 0.38, 0.35))
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, Stile.button(st))
	b.add_theme_stylebox_override("focus", Stile.focus())
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	b.add_theme_constant_override("outline_size", 4)
	Stile.shadow(b)
	# il pulsante si alza appena sotto il mouse
	b.mouse_entered.connect(func() -> void:
		b.pivot_offset = b.size * 0.5
		b.create_tween().tween_property(b, "scale", Vector2.ONE * 1.04, 0.08)
		Sfx.play("click", -22.0, 1.6))
	b.mouse_exited.connect(func() -> void: b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.1))
	b.pressed.connect(func() -> void:
		Sfx.play("click", -6.0)
		cb.call())
	return b


func _fullscreen_dark(alpha: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, alpha)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	return r


# ------------------------------------------------------------------ menu

func _build_menu() -> void:
	_menu = Control.new()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_menu)
	# bordi scuri: il luogo resta visibile al centro, a sinistra (titolo e voci) si fa più buio
	var vign := TextureRect.new()
	vign.set_anchors_preset(Control.PRESET_FULL_RECT)
	vign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vign.stretch_mode = TextureRect.STRETCH_SCALE
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.05))
	g.add_point(0.55, Color(0, 0, 0, 0.35))
	g.set_color(g.get_point_count() - 1, Color(0, 0, 0, 0.9))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.55, 0.45)
	gt.fill_to = Vector2(1.1, 0.95)
	gt.width = 256
	gt.height = 256
	vign.texture = gt
	_menu.add_child(vign)
	var side := TextureRect.new()
	side.anchor_bottom = 1.0
	side.offset_right = 760
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.stretch_mode = TextureRect.STRETCH_SCALE
	var sg := Gradient.new()
	sg.set_color(0, Color(0, 0, 0, 0.78))
	sg.set_color(1, Color(0, 0, 0, 0.0))
	var st := GradientTexture2D.new()
	st.gradient = sg
	st.width = 64
	st.height = 4
	side.texture = st
	_menu.add_child(side)
	# braci che salgono dal basso
	var em := CPUParticles2D.new()
	em.amount = 60
	em.lifetime = 7.0
	em.preprocess = 7.0
	em.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	em.emission_rect_extents = Vector2(1100, 10)
	em.direction = Vector2(0, -1)
	em.spread = 20.0
	em.initial_velocity_min = 25.0
	em.initial_velocity_max = 70.0
	em.gravity = Vector2(8, -6)
	em.scale_amount_min = 1.5
	em.scale_amount_max = 3.5
	var eg := Gradient.new()
	eg.set_color(0, Color(1.0, 0.6, 0.2, 0.0))
	eg.add_point(0.15, Color(1.0, 0.55, 0.15, 0.8))
	eg.set_color(eg.get_point_count() - 1, Color(0.8, 0.2, 0.05, 0.0))
	em.color_ramp = eg
	var cm := CanvasItemMaterial.new()
	cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	em.material = cm
	var em_host := Control.new()
	em_host.anchor_left = 0.5
	em_host.anchor_right = 0.5
	em_host.anchor_top = 1.0
	em_host.anchor_bottom = 1.0
	em_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(em_host)
	em_host.add_child(em)
	_menu_parts.clear()
	# in alto a sinistra: il titolo
	var top := VBoxContainer.new()
	top.position = Vector2(96, 70)
	top.add_theme_constant_override("separation", 0)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(top)
	_menu_title = _lbl("PROGETTO", title_font, 150, GOLD)
	_menu_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_menu_title.add_theme_constant_override("outline_size", 0)
	top.add_child(_menu_title)
	var tag := _lbl("Da quattro a otto condannati, un altare, le candele." if Testi.catene else "Quattro campioni. Un cerchio. Uno solo vedrà l'alba.",
		Stile.font_voice(), 34, Color(0.85, 0.78, 0.66))
	tag.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(tag)
	_menu_parts.append(top)
	# a sinistra: le voci, senza riquadri
	var nav := VBoxContainer.new()
	nav.anchor_top = 0.5
	nav.anchor_bottom = 0.5
	nav.offset_left = 96
	nav.offset_right = 520
	nav.offset_top = -40
	nav.offset_bottom = 380
	nav.add_theme_constant_override("separation", 6)
	_menu.add_child(nav)
	nav.add_child(_nav("Come si gioca", func() -> void: show_rules(0)))
	nav.add_child(_nav("Esplora i luoghi", func() -> void: explore.emit(_place_pick)))
	nav.add_child(_nav("Visuale", func() -> void: _open_panel(_visual)))
	nav.add_child(_nav("Audio", func() -> void: _open_panel(_audio)))
	nav.add_child(_nav("Riconoscimenti", func() -> void: _credits.visible = true))
	nav.add_child(_nav("Esci", func() -> void: menu_quit.emit()))
	_menu_parts.append(nav)
	# a destra: la nuova partita, tutto scelto prima di «Gioca»
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Stile.sheet())
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.2
	panel.anchor_bottom = 0.2
	panel.offset_left = -640
	panel.offset_right = -90
	panel.offset_top = 0
	panel.offset_bottom = 0
	_menu.add_child(panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 14)
	panel.add_child(pv)
	pv.add_child(_lbl("Nuova partita", title_font, 54, GOLD))
	var champs: Array = []
	for c in (Testi.CLASSI if Testi.catene else Testi.CLASSI.slice(0, Testi.CLASSI_CERCHIO)):
		champs.append([c["nome"], "" if Testi.catene else c["abilita"], c["colore"].lerp(Color.WHITE, 0.3)])
	pv.add_child(_selector("Campione", champs, 0, func(i: int) -> void: _pick_class(i)))
	var places: Array = [["A caso", "Il Custode sceglie per te.", BONE]]
	for k in Testi.SCENARI.size():
		places.append([Testi.SCENARI[k]["nome"], Testi.SCENARI[k]["sotto"], BONE])
	pv.add_child(_selector("Luogo", places, 0, func(i: int) -> void: _pick_place(i - 1)))
	pv.add_child(_selector("Modalità", [["Normale", "Se il voto condanna un innocente, non succede nulla.", BONE],
		["A eliminazione", "Chi viene condannato a torto brucia subito.", Color(1.0, 0.5, 0.4)]], mode_pick,
		func(i: int) -> void: mode_pick = i))
	if Testi.catene:
		var counts := []
		for k in range(4, 9):
			counts.append(["%d giocatori" % k, "Un sabotatore. Il più legato brucia." if k <= 5 else
				"Due sabotatori che si conoscono. Bruciano i due più legati.", BONE if k <= 5 else Color(1.0, 0.62, 0.45)])
		pv.add_child(_selector("Al tavolo", counts, players_pick - 4, func(i: int) -> void: players_pick = i + 4))
	Difficolta.carica()
	pv.add_child(_selector("Avversari", [["Normali", "Giocano bene, ma non ricordano le tue mosse.", BONE],
		["Adattivi", "Ricordano le tue mosse e cercano di non farsi leggere.", BONE]], Difficolta.livello,
		func(i: int) -> void: _set_diff(i)))
	_play_btn = Button.new()
	_play_btn.text = "GIOCA"
	_play_btn.custom_minimum_size = Vector2(0, 92)
	_play_btn.add_theme_font_override("font", Stile.font_caps())
	_play_btn.add_theme_font_size_override("font_size", 40)
	_play_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
	_play_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.8))
	_play_btn.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.8))
	_play_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.8))
	for k in ["normal", "hover", "pressed", "focus"]:
		_play_btn.add_theme_stylebox_override(k, Stile.primary(k))
	_play_btn.mouse_entered.connect(func() -> void: Sfx.play("click", -22.0, 1.6))
	_play_btn.pressed.connect(func() -> void:
		Sfx.play("click", -6.0)
		menu_play.emit(_class_pick, _place_pick))
	# «Gioca» fisso in basso a destra, sotto il riquadro: sempre sullo schermo
	_play_btn.anchor_left = 1.0
	_play_btn.anchor_right = 1.0
	_play_btn.anchor_top = 1.0
	_play_btn.anchor_bottom = 1.0
	_play_btn.offset_left = -640
	_play_btn.offset_right = -90
	_play_btn.offset_top = -150
	_play_btn.offset_bottom = -58
	_menu.add_child(_play_btn)
	_menu_parts.append(panel)
	_pick_class(0)
	_pick_place(-1)


var _menu_parts: Array[Control] = []
var mode_pick := 0                 # modalità scelta nel menu: 0 normale, 1 a eliminazione
var players_pick := 4              # quanti al tavolo (4-8): tu e gli avversari del computer
var _view_opt: OptionButton


## Voce del menu principale: solo testo, maiuscoletto spaziato; sotto il mouse si accende e compare un filo d'oro.
func _nav(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", Stile.font_caps())
	b.add_theme_font_size_override("font_size", 27)
	b.add_theme_color_override("font_color", Color(0.78, 0.72, 0.64))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.55))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.86, 0.55))
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.7))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	b.add_theme_constant_override("outline_size", 4)
	for k in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, Stile.nav(k))
	b.mouse_entered.connect(func() -> void: Sfx.play("click", -24.0, 1.7))
	b.pressed.connect(func() -> void:
		Sfx.play("click", -6.0)
		cb.call())
	return b


## Una riga di scelta con le frecce: titolo piccolo, ‹ valore ›, una riga di spiegazione sotto.
## items: [[nome, spiegazione, colore]]; on_change(indice).
func _selector(title: String, items: Array, start: int, on_change: Callable) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(_lbl(title.to_upper(), Stile.font_caps(), 17, DIM))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	var val := _lbl("", head_font, 32, BONE, HORIZONTAL_ALIGNMENT_CENTER)
	val.autowrap_mode = TextServer.AUTOWRAP_OFF
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var desc := _lbl("", italic_font, 21, Color(0.78, 0.73, 0.66), HORIZONTAL_ALIGNMENT_CENTER)
	desc.custom_minimum_size = Vector2(0, 30)
	var idx := [start]
	var show := func() -> void:
		var it: Array = items[idx[0]]
		val.text = it[0]
		val.add_theme_color_override("font_color", it[2])
		desc.text = it[1]
	var step := func(d: int) -> void:
		idx[0] = (idx[0] + d + items.size()) % items.size()
		show.call()
		on_change.call(idx[0])
	h.add_child(_arrow("‹", func() -> void: step.call(-1)))
	h.add_child(val)
	h.add_child(_arrow("›", func() -> void: step.call(1)))
	v.add_child(desc)
	show.call()
	return v


func _arrow(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(54, 50)
	b.add_theme_font_override("font", head_font)
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_color_override("font_color", Color(0.86, 0.68, 0.36))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.65))
	for k in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, Stile.arrow(k))
	b.pressed.connect(func() -> void:
		Sfx.play("click", -8.0, 1.2)
		cb.call())
	return b


func _set_view(i: int) -> void:
	Visuale.scegli(i)
	if _view_opt:
		_view_opt.select(Visuale.livello)
	view_changed.emit()


## Difficoltà degli avversari (scelta nel menu).
func _set_diff(i: int, save := true) -> void:
	if save:
		Difficolta.scegli(i)
var _menu_title: Label
var _play_btn: Button


## Apre un pannello delle impostazioni e chiude l'altro.
func _open_panel(p: Control) -> void:
	for q in [_audio, _visual]:
		if q != p:
			q.visible = false
	p.visible = not p.visible


func _menu_intro() -> void:
	var k := 0
	for part in _menu_parts:
		part.modulate.a = 0.0
		var dy := 24.0 if k != 0 else -24.0
		part.position.y += dy
		var tw := part.create_tween()
		tw.tween_interval(0.12 * k)
		tw.tween_property(part, "modulate:a", 1.0, 0.6)
		tw.parallel().tween_property(part, "position:y", part.position.y - dy, 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		k += 1


func _pick_place(k: int) -> void:
	var changed := k != _place_pick
	_place_pick = k
	if changed:
		menu_place.emit(k)


func _pick_class(i: int) -> void:
	_class_pick = i


func show_menu(on: bool) -> void:
	_menu.visible = on
	if on:
		_menu_intro.call_deferred()
	if on and _explorer:
		_explorer.visible = false
	_game_ui.visible = not on
	_pause.visible = false
	if on:
		_big.visible = false


# ------------------------------------------------------------------ istruzioni

func _build_rules() -> void:
	_rules = Control.new()
	_rules.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rules.visible = false
	_root.add_child(_rules)
	_rules.add_child(_fullscreen_dark(0.7))
	var p := _panel(0.95)
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -560
	p.offset_right = 560
	p.offset_top = -400
	p.offset_bottom = 400
	_rules.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	_rules_num = _lbl("", head_font, 22, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_rules_num)
	_rules_title = _lbl("", title_font, 50, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_rules_title)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	_rules_text = _lbl("", body_font, 30, BONE)
	_rules_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_rules_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)
	row.add_child(_btn("◀ Indietro", func() -> void: _rules_go(-1), 24))
	row.add_child(_btn("Chiudi", func() -> void: _rules.visible = false, 24, GOLD))
	row.add_child(_btn("Avanti ▶", func() -> void: _rules_go(1), 24))


## Riconoscimenti: autori e licenze di tutto quello che il gioco usa (testo in CREDITI.txt, licenze
## complete nella cartella LICENZE accanto al gioco).
func _build_credits() -> void:
	_credits = Control.new()
	_credits.set_anchors_preset(Control.PRESET_FULL_RECT)
	_credits.visible = false
	_root.add_child(_credits)
	_credits.add_child(_fullscreen_dark(0.7))
	var p := _panel(0.95)
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -620
	p.offset_right = 620
	p.offset_top = -420
	p.offset_bottom = 420
	_credits.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	v.add_child(_lbl("Riconoscimenti", title_font, 50, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var text := FileAccess.get_file_as_string("res://CREDITI.txt")
	text += "
LICENZA DI GODOT ENGINE
" + Engine.get_license_text()
	var t := _lbl(text, body_font, 22, BONE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(t)
	var c := _btn("Chiudi", func() -> void: _credits.visible = false, 24, GOLD)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(c)


func show_rules(page: int) -> void:
	_rules_page = page
	_rules.visible = true
	_rules_go(0)


func _rules_go(d: int) -> void:
	_rules_page = clampi(_rules_page + d, 0, Testi.regole().size() - 1)
	var p := Testi.pagina(_rules_page)
	_rules_num.text = "Come si gioca — %d di %d" % [_rules_page + 1, Testi.regole().size()]
	_rules_title.text = p[0]
	_rules_text.text = p[1]


## Scheda del campione sotto il mouse: ritratto dal vivo (seconda telecamera) e informazioni.
var _prev: PanelContainer
var _prev_cam: Camera3D
var _prev_vp: SubViewport
var _prev_name: Label
var _prev_cls: Label
var _prev_info: Label


func _build_preview() -> void:
	_prev = _panel(0.94)
	_prev.visible = false
	_prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prev.custom_minimum_size = Vector2(340, 0)
	_root.add_child(_prev)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prev.add_child(v)
	_prev_name = _lbl("", title_font, 32, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_prev_name)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(300, 300)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(svc)
	_prev_vp = SubViewport.new()
	_prev_vp.size = Vector2i(300, 300)
	_prev_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_prev_vp.msaa_3d = Viewport.MSAA_4X
	svc.add_child(_prev_vp)
	_prev_cam = Camera3D.new()
	_prev_cam.fov = 32.0
	_prev_vp.add_child(_prev_cam)
	_prev_cls = _lbl("", italic_font, 22, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_prev_cls)
	_prev_info = _lbl("", body_font, 22, BONE)
	_prev_info.custom_minimum_size = Vector2(300, 0)
	v.add_child(_prev_info)


## info: {nome, classe, colore, testo}; fig: il campione da riprendere.
func show_preview(info: Dictionary, fig: Node3D) -> void:
	if fig == null:
		_prev.visible = false
		return
	var p := fig.global_position
	var toward := (-p).normalized() if p.length() > 0.1 else Vector3.BACK
	_prev_cam.global_transform = Transform3D(Basis(), p + toward * 2.4 + Vector3(0, 1.55, 0)).looking_at(
		p + Vector3(0, 1.25, 0), Vector3.UP)
	_prev_name.text = info["nome"]
	_prev_name.add_theme_color_override("font_color", info["colore"])
	_prev_cls.text = info["classe"]
	_prev_info.text = info["testo"]
	_prev.visible = true
	_place_preview()


func _place_preview() -> void:
	var mp := get_viewport().get_mouse_position()
	var vs := get_viewport().get_visible_rect().size
	var sz := _prev.get_combined_minimum_size()
	var pos := mp + Vector2(28, 20)
	if pos.x + sz.x > vs.x - 10:
		pos.x = mp.x - sz.x - 28
	pos.y = clampf(pos.y, 10, vs.y - sz.y - 10)
	_prev.position = pos
	_prev.size = sz


var _explorer: Control
var _explorer_title: Label


func _build_explorer() -> void:
	var p := _panel(0.85)
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 1.0
	p.anchor_bottom = 1.0
	p.offset_left = -560
	p.offset_right = 560
	p.offset_top = -190
	p.offset_bottom = -24
	p.visible = false
	_root.add_child(p)
	_explorer = p
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	_explorer_title = _lbl("", title_font, 36, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_explorer_title)
	v.add_child(_lbl("Trascina col mouse per girare attorno al cerchio, rotella per avvicinarti. Se non tocchi niente gira da sola.",
		italic_font, 22, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	row.add_child(_btn("Altro luogo", func() -> void: explore_next.emit(), 24))
	row.add_child(_btn("Nuova disposizione", func() -> void: explore_reseed.emit(), 24))
	row.add_child(_btn("Torna al menu", func() -> void:
		_explorer.visible = false
		to_menu.emit(), 24, GOLD))


func show_explorer(title: String) -> void:
	_menu.visible = false
	_game_ui.visible = false
	_explorer_title.text = title
	_explorer.visible = true


func blocking() -> bool:
	return _menu.visible or _rules.visible or _big.visible or _pause.visible or _audio.visible or _visual.visible or _vote_layer != null


var _audio_check: CheckButton
var _top_bar: Control


## Il tasto M accende e spegne tutto l'audio, nel menu e in partita.
func toggle_audio() -> void:
	Sfx.set_setting("audio_on", not Sfx.audio_on)
	_audio_check.set_pressed_no_signal(Sfx.audio_on)
	if _game_ui.visible:
		log_line("Audio acceso." if Sfx.audio_on else "Audio spento (tasto M per riaccenderlo).")


## Due pannelli separati (richiesta dell'utente del 21/10): Audio (volumi e scossoni) e Visuale (inquadratura e
## qualità grafica). Si aprono dal menu e, in partita, dai pulsanti in alto a destra e dalla pausa (Esc).
func _build_audio() -> void:
	_load_opts()
	_audio = _settings_panel("Audio")
	var v: VBoxContainer = _audio.get_meta("box")
	# interruttore generale: spegne tutto (anche col tasto M, in qualsiasi momento)
	_audio_check = _check("Audio acceso   (tasto M)", Sfx.audio_on, func(on: bool) -> void: Sfx.set_setting("audio_on", on))
	v.add_child(_audio_check)
	for row in [["Generale", "master_vol"], ["Musica", "music_vol"], ["Ambiente", "amb_vol"], ["Effetti", "sfx_vol"]]:
		var h := HBoxContainer.new()
		var l := _lbl(row[0], body_font, 24, BONE)
		l.custom_minimum_size = Vector2(150, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		h.add_child(l)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = float(Sfx.get(row[1]))
		s.custom_minimum_size = Vector2(300, 30)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var key: String = row[1]
		s.value_changed.connect(func(x: float) -> void: Sfx.set_setting(key, x))
		h.add_child(s)
		v.add_child(h)
	v.add_child(_check("Musica accesa", Sfx.music_on, func(on: bool) -> void: Sfx.set_setting("music_on", on)))
	v.add_child(_check("Scossoni della telecamera", shake_on, func(on: bool) -> void:
		shake_on = on
		_save_opts()))
	v.add_child(_check("Lampi sullo schermo", flash_on, func(on: bool) -> void:
		flash_on = on
		_save_opts()))
	v.add_child(_close_btn(_audio))
	_build_visual()


func _build_visual() -> void:
	_visual = _settings_panel("Visuale")
	var v: VBoxContainer = _visual.get_meta("box")
	Visuale.carica()
	var views: Array = []
	for nome in Visuale.NOMI:
		views.append([nome, "In partita puoi cambiarla anche col tasto V.", BONE])
	v.add_child(_selector("Inquadratura", views, Visuale.livello, func(i: int) -> void: _set_view(i)))
	Grafica.carica()
	var q: Array = []
	for nome in Grafica.NOMI:
		q.append([nome, "Lo schermo cambia subito; luce e ombre dei luoghi dal prossimo luogo.", BONE])
	v.add_child(_selector("Qualità grafica", q, Grafica.livello, func(i: int) -> void: Grafica.scegli(i, get_viewport())))
	v.add_child(_close_btn(_visual))


## Pannello delle impostazioni al centro dello schermo, sopra un velo scuro.
func _settings_panel(title: String) -> Control:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.visible = false
	_root.add_child(layer)
	var dark := _fullscreen_dark(0.55)
	dark.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			layer.visible = false)
	layer.add_child(dark)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Stile.sheet())
	p.custom_minimum_size = Vector2(620, 0)
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(_lbl(title, title_font, 50, GOLD))
	layer.set_meta("box", v)
	return layer


func _check(text: String, on: bool, cb: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.add_theme_font_override("font", body_font)
	c.add_theme_font_size_override("font_size", 24)
	c.add_theme_color_override("font_color", BONE)
	c.button_pressed = on
	c.toggled.connect(cb)
	return c


func _close_btn(p: Control) -> Button:
	var b := _nav("Chiudi", func() -> void: p.visible = false)
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return b


func _load_opts() -> void:
	var cf := ConfigFile.new()
	if cf.load(OPT_CFG) == OK:
		shake_on = bool(cf.get_value("schermo", "scossoni", true))
		flash_on = bool(cf.get_value("schermo", "lampi", true))


func _save_opts() -> void:
	var cf := ConfigFile.new()
	cf.set_value("schermo", "scossoni", shake_on)
	cf.set_value("schermo", "lampi", flash_on)
	cf.save(OPT_CFG)


func _build_pause() -> void:
	_pause = Control.new()
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.visible = false
	_root.add_child(_pause)
	_pause.add_child(_fullscreen_dark(0.6))
	var v := VBoxContainer.new()
	v.anchor_left = 0.5
	v.anchor_right = 0.5
	v.anchor_top = 0.5
	v.anchor_bottom = 0.5
	v.offset_left = -220
	v.offset_right = 220
	v.offset_top = -235
	v.offset_bottom = 235
	v.add_theme_constant_override("separation", 14)
	_pause.add_child(v)
	v.add_child(_lbl("Pausa", title_font, 52, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(_btn("Riprendi", func() -> void: _pause.visible = false, 28))
	v.add_child(_btn("Come si gioca", func() -> void: show_rules(0), 28))
	v.add_child(_btn("Audio", func() -> void: _open_panel(_audio), 28))
	v.add_child(_btn("Visuale", func() -> void: _open_panel(_visual), 28))
	v.add_child(_btn("Abbandona la partita", func() -> void:
		_pause.visible = false
		to_menu.emit(), 28))


# ------------------------------------------------------------------ partita

func _build_game_ui() -> void:
	_game_ui = Control.new()
	_game_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_ui.visible = false
	_root.add_child(_game_ui)
	# classifica in alto a sinistra
	var bp := _panel(0.62)
	bp.position = Vector2(20, 20)
	bp.custom_minimum_size = Vector2(440, 0)
	_game_ui.add_child(bp)
	_board = VBoxContainer.new()
	_board.add_theme_constant_override("separation", 4)
	bp.add_child(_board)
	# manche e giro in alto al centro, senza riquadro (è contesto, non una scelta); Presagio sotto
	_round_lbl = _lbl("", head_font, 26, Color(0.9, 0.8, 0.6), HORIZONTAL_ALIGNMENT_CENTER)
	_round_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_round_lbl.anchor_left = 0.5
	_round_lbl.anchor_right = 0.5
	_round_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_round_lbl.offset_top = 22
	_game_ui.add_child(_round_lbl)
	_omen_box = _panel(0.85)
	_omen_box.anchor_left = 0.5
	_omen_box.anchor_right = 0.5
	_omen_box.offset_left = -330
	_omen_box.offset_right = 330
	_omen_box.offset_top = 66
	_omen_box.visible = false
	_game_ui.add_child(_omen_box)
	var ov := VBoxContainer.new()
	_omen_box.add_child(ov)
	ov.add_child(_lbl("PRESAGIO", head_font, 18, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_omen_title = _lbl("", title_font, 34, BLOOD.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER)
	ov.add_child(_omen_title)
	_omen_text = _lbl("", body_font, 26, BONE, HORIZONTAL_ALIGNMENT_CENTER)
	ov.add_child(_omen_text)
	# il Custode parla
	_custode_lbl = _lbl("", Stile.font_voice(), 38, Color(1.0, 0.6, 0.5), HORIZONTAL_ALIGNMENT_CENTER)
	_custode_lbl.add_theme_stylebox_override("normal", Stile.soft_shadow())     # si legge anche sopra il fuoco
	_custode_lbl.modulate.a = 0.0          # senza parole non si vede nemmeno la sua ombra
	_custode_lbl.anchor_left = 0.5
	_custode_lbl.anchor_right = 0.5
	_custode_lbl.anchor_top = 0.36
	_custode_lbl.offset_left = -560
	_custode_lbl.offset_right = 560
	_game_ui.add_child(_custode_lbl)
	# scritta al centro (carta pescata, voto, liberazione): su un'ombra morbida, così non si mescola con i
	# nomi sopra i campioni e con il fuoco
	_banner = PanelContainer.new()
	_banner.add_theme_stylebox_override("panel", Stile.soft_shadow())
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.anchor_top = 0.40
	_banner.offset_left = -720
	_banner.offset_right = 720
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	_game_ui.add_child(_banner)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 2)
	bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(bv)
	_banner_small = _lbl("", head_font, 22, Color(0.85, 0.78, 0.66), HORIZONTAL_ALIGNMENT_CENTER)
	_banner_small.add_theme_constant_override("outline_size", 6)
	bv.add_child(_banner_small)
	_banner_big = _lbl("", title_font, 72, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_banner_big.add_theme_constant_override("outline_size", 8)
	bv.add_child(_banner_big)
	_banner_line = _lbl("", body_font, 30, BONE, HORIZONTAL_ALIGNMENT_CENTER)
	_banner_line.add_theme_constant_override("outline_size", 8)
	bv.add_child(_banner_line)
	# le tue candele, in basso a sinistra
	var mp := _panel(0.7)
	mp.anchor_top = 1.0
	mp.anchor_bottom = 1.0
	mp.offset_left = 20
	mp.offset_top = -200
	mp.offset_bottom = -20
	mp.custom_minimum_size = Vector2(300, 0)
	mp.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_game_ui.add_child(mp)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 0)
	mp.add_child(mv)
	_my_title = _lbl("LE TUE CANDELE", head_font, 18, DIM)
	_my_title.autowrap_mode = TextServer.AUTOWRAP_OFF     # prima, col riquadro vuoto, andava a capo a ogni lettera
	mv.add_child(_my_title)
	_my_lives = _lbl("", body_font, 62, Color(1.0, 0.72, 0.3))
	_my_lives.autowrap_mode = TextServer.AUTOWRAP_OFF
	mv.add_child(_my_lives)
	_my_state = _lbl("", body_font, 22, DIM)
	_my_state.autowrap_mode = TextServer.AUTOWRAP_OFF
	mv.add_child(_my_state)
	# racconto dei colpi a destra
	var lp := _panel(0.55)
	lp.anchor_left = 1.0
	lp.anchor_right = 1.0
	lp.offset_left = -470
	lp.offset_right = -20
	lp.offset_top = 72
	_game_ui.add_child(lp)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.fit_content = true
	_log.scroll_active = false
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.custom_minimum_size = Vector2(410, 0)
	_log.add_theme_font_override("normal_font", body_font)
	_log.add_theme_font_override("bold_font", head_font)
	_log.add_theme_font_size_override("normal_font_size", 22)
	_log.add_theme_font_size_override("bold_font_size", 18)
	_log.add_theme_color_override("default_color", BONE)
	_log.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_log.add_theme_constant_override("outline_size", 4)
	lp.add_child(_log)
	_log_panel = lp
	lp.visible = false
	# aiuto, tempo e mosse in basso
	var bottom := VBoxContainer.new()
	bottom.anchor_left = 0.0
	bottom.anchor_right = 1.0
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_top = -500       # c'è posto per le carte della mano
	bottom.offset_bottom = -24
	bottom.offset_left = 40
	bottom.offset_right = -40
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 10)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_ui.add_child(bottom)
	# ordine dei colpi del giro, noto prima di scegliere: una fila di targhette (la tua in oro)
	_order_row = HBoxContainer.new()
	_order_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_order_row.add_theme_constant_override("separation", 10)
	_order_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_order_row.visible = false
	bottom.add_child(_order_row)
	var hrow := HBoxContainer.new()
	hrow.alignment = BoxContainer.ALIGNMENT_CENTER
	hrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(hrow)
	# la frase di aiuto e, accanto, il tempo che resta (prima era isolato sul bordo destro)
	hrow.add_theme_constant_override("separation", 18)
	_hint = _lbl("", body_font, 28, BONE, HORIZONTAL_ALIGNMENT_CENTER)
	_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	hrow.add_child(_hint)
	_timer_lbl = _lbl("", Stile.font_num(), 30, DIM)
	_timer_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	hrow.add_child(_timer_lbl)
	_cards_row = HBoxContainer.new()
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override("separation", 12)
	bottom.add_child(_cards_row)
	_actions = HBoxContainer.new()
	_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_actions.add_theme_constant_override("separation", 14)
	bottom.add_child(_actions)
	# in alto a destra, sempre: regole, inquadratura, audio (solo testo, come le voci del menu)
	var tr := HBoxContainer.new()
	tr.anchor_left = 1.0
	tr.anchor_right = 1.0
	tr.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tr.offset_right = -24
	tr.offset_top = 14
	tr.add_theme_constant_override("separation", 4)
	_game_ui.add_child(tr)
	_top_bar = tr
	for it in [["Regole", func() -> void: show_rules(0)], ["Visuale", func() -> void: _open_panel(_visual)],
			["Audio", func() -> void: _open_panel(_audio)]]:
		var b := _nav(it[0], it[1])
		b.add_theme_font_size_override("font_size", 19)
		tr.add_child(b)


func _build_big() -> void:
	_big = Control.new()
	_big.set_anchors_preset(Control.PRESET_FULL_RECT)
	_big.visible = false
	_root.add_child(_big)
	_big.add_child(_fullscreen_dark(0.55))
	# il riquadro prende l'altezza del contenuto (prima era fisso e restava mezzo vuoto)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_big.add_child(cc)
	var p := _panel(0.92)
	p.custom_minimum_size = Vector2(820, 0)
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	p.add_child(v)
	_big_title = _lbl("", title_font, 64, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_big_title.add_theme_constant_override("outline_size", 0)
	v.add_child(_big_title)
	_big_text = _lbl("", body_font, 28, BONE, HORIZONTAL_ALIGNMENT_CENTER)
	_big_text.custom_minimum_size = Vector2(760, 0)
	v.add_child(_big_text)
	_big_table = GridContainer.new()
	_big_table.columns = 4
	_big_table.add_theme_constant_override("h_separation", 34)
	_big_table.add_theme_constant_override("v_separation", 8)
	_big_table.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_big_table)
	_big_btn = _btn("Continua", func() -> void:
		_big.visible = false
		next_pressed.emit(), 30, GOLD)
	_big_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_big_btn.custom_minimum_size = Vector2(240, 0)
	v.add_child(_big_btn)


var _big_table: GridContainer


## Finestra grande (inizio manche, classifica, vincitore). Il pulsante emette next_pressed.
## rows (facoltativo): tabella sotto il testo, [{nome, colore, esito, punti_manche, totale, io}]; la prima riga
## è l'intestazione delle colonne.
func show_big(title: String, text: String, button := "Continua", rows := []) -> void:
	_big_title.text = title
	_big_text.text = text
	_big_text.visible = text != ""
	_big_btn.text = button
	for c in _big_table.get_children():
		c.queue_free()
	_big_table.visible = not rows.is_empty()
	for i in rows.size():
		var r: Dictionary = rows[i]
		var head := i == 0
		var me: bool = r.get("io", false)
		var name_c: Color = DIM if head else (GOLD if me else Color(r.get("colore", BONE)).lerp(BONE, 0.35))
		var cells := [
			_lbl(r["nome"], head_font, 18 if head else 28, name_c),
			_lbl(r["esito"], head_font if head else body_font, 18 if head else 26, DIM),
			_lbl(r["punti_manche"], head_font if head else Stile.font_num(), 18 if head else 26,
				DIM if head else (Color(0.55, 0.95, 0.6) if r["punti_manche"] != "+0" else DIM), HORIZONTAL_ALIGNMENT_RIGHT),
			_lbl(r["totale"], head_font if head else Stile.font_num(), 18 if head else 30, DIM if head else GOLD, HORIZONTAL_ALIGNMENT_RIGHT),
		]
		for c in cells:
			(c as Label).autowrap_mode = TextServer.AUTOWRAP_OFF
			_big_table.add_child(c)
	_big.visible = true
	_big_btn.grab_focus()


func set_round(t: String) -> void:
	_round_lbl.text = t
	_round_lbl.visible = t != ""


func set_omen(omen: int) -> void:
	_omen_box.visible = omen != 0
	if omen != 0:
		_omen_title.text = Testi.PRESAGI[omen]["nome"]
		_omen_text.text = Testi.PRESAGI[omen]["testo"]


## Scritta grande al centro dello schermo (es. chi colpisce per primo).
func banner(small: String, big: String, line: String, dur: float, col := GOLD) -> void:
	_banner_big.add_theme_color_override("font_color", col)
	_banner_small.text = small
	_banner_big.text = big
	_banner_line.text = line
	_banner.scale = Vector2.ONE
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(maxf(dur - 0.6, 0.1))
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4)


## La pesca: tre carte coperte grandi al centro dello schermo; ne scegli una, si gira e mostra `kind` (la carta
## pescata la decidono le regole: la scelta è alla cieca). Senza scelta entro `secs` secondi ne prende una a caso.
func pick_card(kind: int, secs: float, auto := false) -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(layer)
	layer.add_child(_fullscreen_dark(0.62))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 26)
	layer.add_child(v)
	var title := _lbl("Il Custode ti offre tre carte", title_font, 56, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(title)
	var sub := _lbl("Scegline una. Sono coperte: nessuno sa cosa c'è sotto.", body_font, 26, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(sub)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 46)
	v.add_child(row)
	var cards: Array[Carta] = []
	var picked := [-1]
	for i in 3:
		var c := Carta.make(0, false, 270)
		c.pressed.connect(func() -> void:
			if picked[0] < 0:
				picked[0] = i
				Sfx.play("click", -6.0))
		row.add_child(c)
		cards.append(c)
	var tl := _lbl("", Stile.font_num(), 30, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(tl)
	# entrata: le carte salgono una dopo l'altra
	layer.modulate.a = 0.0
	create_tween().tween_property(layer, "modulate:a", 1.0, 0.25)
	var left := secs
	while picked[0] < 0 and left > 0.0:
		await get_tree().process_frame
		left -= get_process_delta_time()
		tl.text = "%d" % ceili(left)
		tl.modulate = BLOOD if left < 4.0 else Color.WHITE
		if auto and left < secs - 0.6:
			picked[0] = randi() % 3
	if picked[0] < 0:
		picked[0] = randi() % 3
	tl.text = ""
	for i in 3:
		cards[i].disabled = i != picked[0]
		if i != picked[0]:
			cards[i].create_tween().tween_property(cards[i], "modulate:a", 0.15, 0.3)
	var chosen := cards[picked[0]]
	chosen.kind = kind
	Sfx.play("flip", -2.0)
	await chosen.flip(true, 0.4)
	title.text = "Hai pescato"
	sub.text = Carta.RIGA[kind]
	sub.add_theme_color_override("font_color", BONE)
	chosen.pivot_offset = chosen.size * 0.5
	chosen.create_tween().tween_property(chosen, "scale", Vector2.ONE * 1.12, 0.25).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(0.5 if auto else 1.5).timeout
	var tw := create_tween()
	tw.tween_property(layer, "modulate:a", 0.0, 0.3)
	await tw.finished
	layer.queue_free()


## La schermata del voto: le carte-ritratto di tutti i campioni in fila; si vota premendo una carta, e sotto ogni
## carta compaiono i nomi di chi l'ha votata. cards: [{pid, nome, colore, sotto, photo, votabile}].
var _vote_layer: Control
var _vote_cards := {}               # pid -> Ritratto
var _vote_lists := {}               # pid -> VBoxContainer con i nomi di chi l'ha votato
var _vote_title: Label
var _vote_line: Label
var _vote_extra: HBoxContainer
signal _voted(pid: int)


func open_vote(cards: Array, line: String) -> void:
	close_vote(true)
	_vote_layer = Control.new()
	_vote_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_vote_layer)
	_vote_layer.add_child(_fullscreen_dark(0.78))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 22)
	_vote_layer.add_child(v)
	_vote_title = _lbl("Il voto", title_font, 72, Color(0.85, 0.8, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_vote_title)
	_vote_line = _lbl(line, body_font, 28, BONE, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_vote_line)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	# fino a cinque carte grandi; al tavolo da otto più strette, tutte su una riga
	var w := 250 if cards.size() <= 5 else (210 if cards.size() <= 6 else 180)
	row.add_theme_constant_override("separation", 40 if cards.size() <= 5 else 20)
	v.add_child(row)
	_vote_cards.clear()
	_vote_lists.clear()
	for c in cards:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		col.custom_minimum_size = Vector2(w, 0)
		row.add_child(col)
		var card := Ritratto.make(c["photo"], c["nome"], c["colore"], c["sotto"], w)
		card.disabled = not c["votabile"]
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var pid: int = c["pid"]
		card.pressed.connect(func() -> void: _voted.emit(pid))
		col.add_child(card)
		var names := VBoxContainer.new()
		names.add_theme_constant_override("separation", 2)
		names.custom_minimum_size = Vector2(0, 150)
		col.add_child(names)
		_vote_cards[pid] = card
		_vote_lists[pid] = names
	_vote_extra = HBoxContainer.new()
	_vote_extra.alignment = BoxContainer.ALIGNMENT_CENTER
	_vote_extra.add_theme_constant_override("separation", 20)
	v.add_child(_vote_extra)
	_vote_layer.modulate.a = 0.0
	create_tween().tween_property(_vote_layer, "modulate:a", 1.0, 0.35)


## Aspetta il tuo voto (premi una carta). Con il Guardiano ancora disponibile puoi chiederlo prima di votare.
## Senza scelta entro `secs` vota a caso fra le carte votabili.
func vote_pick(secs: float, guardian: bool, auto := false) -> Dictionary:
	var ask := [false]
	for c in _vote_extra.get_children():
		c.queue_free()
	if guardian:
		var gb := _btn("Chiedi il Guardiano: NO", func() -> void: pass, 24, DIM)
		gb.toggle_mode = true
		gb.add_theme_stylebox_override("pressed", Stile.card_selected())
		gb.add_theme_stylebox_override("hover_pressed", Stile.card_selected())
		gb.toggled.connect(func(on: bool) -> void:
			ask[0] = on
			gb.text = "Chiedi il Guardiano: %s" % ("SÌ" if on else "NO"))
		_vote_extra.add_child(gb)
		_vote_extra.add_child(_lbl("se in due lo chiedete, aggiunge un voto: metà delle volte dice il vero", italic_font, 21, DIM))
	var tl := _lbl("", Stile.font_num(), 30, DIM)
	_vote_extra.add_child(tl)
	var picked := [-1]
	var on_vote := func(pid: int) -> void:
		if picked[0] < 0:
			picked[0] = pid
	_voted.connect(on_vote)
	var left := secs
	var ok: Array = _vote_cards.keys().filter(func(p: int) -> bool: return not (_vote_cards[p] as Ritratto).disabled)
	while picked[0] < 0 and left > 0.0:
		await get_tree().process_frame
		left -= get_process_delta_time()
		tl.text = "%d" % ceili(left)
		tl.modulate = BLOOD if left < 6.0 else Color.WHITE
		if auto and left < secs - 0.8 and not ok.is_empty():
			picked[0] = ok[randi() % ok.size()]
	_voted.disconnect(on_vote)
	if picked[0] < 0 and not ok.is_empty():
		picked[0] = ok[randi() % ok.size()]
	for c in _vote_extra.get_children():
		c.queue_free()
	for p in _vote_cards:
		(_vote_cards[p] as Ritratto).selected = p == picked[0]
		(_vote_cards[p] as Ritratto).disabled = true
	_vote_line.text = "Hai votato. Si scoprono i voti."
	Sfx.play("click", -6.0)
	return {"v": picked[0], "g": ask[0]}


## Sotto la carta di `target` compare il nome di chi l'ha votata.
func vote_mark(target: int, voter: String, col := BONE) -> void:
	if not _vote_lists.has(target):
		return
	var l := _lbl(voter, head_font, 28, col, HORIZONTAL_ALIGNMENT_CENTER)
	l.modulate.a = 0.0
	l.position.y += 10
	(_vote_lists[target] as VBoxContainer).add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.3)
	Sfx.play("flip", -5.0, 0.9)


## L'esito sulla stessa schermata, poi si chiude.
func vote_result(big: String, line: String, col: Color, target := -1, hold := 2.6) -> void:
	if _vote_layer == null:
		return
	_vote_title.text = big
	_vote_title.add_theme_color_override("font_color", col)
	_vote_line.text = line
	if _vote_cards.has(target):
		var c: Ritratto = _vote_cards[target]
		c.pivot_offset = c.size * 0.5
		c.create_tween().tween_property(c, "scale", Vector2.ONE * 1.08, 0.3).set_trans(Tween.TRANS_BACK)
		c.selected = true
	await get_tree().create_timer(hold).timeout
	close_vote()


func close_vote(now := false) -> void:
	if _vote_layer == null:
		return
	var l := _vote_layer
	_vote_layer = null
	if now:
		l.queue_free()
		return
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


## A inizio manche, il tuo ruolo in grande al centro: resta almeno 2,5 secondi e poi sbiadisce (in rosso se sei il
## sabotatore). Si vede solo sul tuo schermo.
func role_reveal(big: String, line: String, col: Color, hold := 2.6) -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(layer)
	var dark := _fullscreen_dark(0.6)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dark)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(v)
	v.add_child(_lbl("IL TUO RUOLO IN QUESTA MANCHE", head_font, 24, Color(0.85, 0.78, 0.66), HORIZONTAL_ALIGNMENT_CENTER))
	var b := _lbl(big, title_font, 130, col, HORIZONTAL_ALIGNMENT_CENTER)
	b.add_theme_constant_override("outline_size", 10)
	v.add_child(b)
	v.add_child(_lbl(line, body_font, 30, BONE, HORIZONTAL_ALIGNMENT_CENTER))
	layer.modulate.a = 0.0
	b.pivot_offset = Vector2(800, 80)
	b.scale = Vector2.ONE * 1.08
	var tw := create_tween()
	tw.tween_property(layer, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(b, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(layer, "modulate:a", 0.0, 0.9)
	await tw.finished
	layer.queue_free()


## Le tue vite sempre in vista.
func set_my_lives(lives: float, max_lives: float, alive: bool, tired: bool, ability: String, cards := "") -> void:
	if not alive:
		_my_lives.text = "spettro"
		_my_lives.add_theme_color_override("font_color", Color(0.5, 0.75, 0.9))
		_my_state.text = "Scommetti su chi perderà una candela."
		return
	_my_lives.add_theme_color_override("font_color", Color(1.0, 0.72, 0.3))
	var t := ""
	for k in int(max_lives):
		t += ("●" if k < int(ceil(lives)) else "○") + " "
	_my_lives.text = t.strip_edges()
	var st: Array[String] = []
	if tired:
		st.append("stanco: puoi solo attaccare")
	st.append(("abilità pronta: " + ability) if ability != "" else "abilità già usata")
	_my_state.text = "  ·  ".join(st) + ("\ncarte: " + cards if cards != "" else "")


## Il riquadro in basso a sinistra con un titolo e un testo liberi (Catene dell'altare: catene, ruolo, carte).
func set_panel(title: String, big: String, small: String, big_col := Color(1.0, 0.72, 0.3)) -> void:
	_my_title.text = title
	_my_lives.text = big
	_my_lives.add_theme_color_override("font_color", big_col)
	_my_state.text = small


func custode(t: String) -> void:
	_custode_lbl.text = t
	_custode_lbl.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_custode_lbl, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.8)
	tw.tween_property(_custode_lbl, "modulate:a", 0.0, 0.8)


func log_line(t: String) -> void:
	_log_lines.append(t)
	while _log_lines.size() > 8:
		_log_lines.pop_front()
	# le righe più vecchie sbiadiscono; "— Titolo —" diventa un'intestazione in oro
	var out: Array[String] = []
	var n := _log_lines.size()
	for k in n:
		var line: String = _log_lines[k].replace("[", "(").replace("]", ")")
		var a := lerpf(0.45, 1.0, float(k + 1) / n)
		if line.begins_with("—") and line.ends_with("—"):
			out.append("[b][color=#%s]%s[/color][/b]" % [Color(GOLD, a).to_html(), line.trim_prefix("—").trim_suffix("—").strip_edges().to_upper()])
		else:
			out.append("[color=#%s]%s[/color]" % [Color(BONE, a).to_html(), line])
	_log.text = "\n".join(out)
	# il riquadro compare con il primo fatto, non con il solo titolo della manche
	_log_panel.visible = _log_lines.any(func(l: String) -> bool: return not (l.begins_with("—") and l.ends_with("—")))


func clear_log() -> void:
	_log_lines.clear()
	_log.text = ""
	_log_panel.visible = false


var _order_row: HBoxContainer


## Ordine dei colpi del giro. items: [{nome, colore, me}] nell'ordine in cui colpiscono; vuoto = nascosto.
func set_order(items: Array) -> void:
	for c in _order_row.get_children():
		c.queue_free()
	_order_row.visible = not items.is_empty()
	if items.is_empty():
		return
	var title := _lbl("Ordine dei colpi", head_font, 20, DIM)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_order_row.add_child(title)
	for k in items.size():
		var it: Dictionary = items[k]
		var me: bool = it.get("me", false)
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Stile.tag(it["colore"], me))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(h)
		var num := _lbl(str(k + 1), Stile.font_num(), 24, GOLD if me else BONE)
		num.autowrap_mode = TextServer.AUTOWRAP_OFF
		h.add_child(num)
		var n := _lbl(it["nome"], head_font, 22, GOLD if me else Color(it["colore"]).lerp(BONE, 0.45))
		n.autowrap_mode = TextServer.AUTOWRAP_OFF
		h.add_child(n)
		p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_order_row.add_child(p)
		if k < items.size() - 1:
			var arrow := _lbl("›", head_font, 26, Stile.GOLD_DIM)
			arrow.autowrap_mode = TextServer.AUTOWRAP_OFF
			arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			_order_row.add_child(arrow)


func hint(t: String) -> void:
	_hint.text = t


## rows: [{nome, colore, candele, max, punti, stato}] (stato: "", "stanco", "spettro"). Con "testo" la seconda
## colonna mostra quel testo invece dei pallini, e "nota" va in fondo alla riga; col = titolo della seconda colonna.
func set_board(rows: Array, col2 := "Candele") -> void:
	for c in _board.get_children():
		c.queue_free()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	for col in [["Campioni", 250], [col2, 110], ["Punti", 60]]:
		var hl := _lbl(col[0], head_font, 17, DIM)
		hl.custom_minimum_size = Vector2(col[1], 0)
		hl.autowrap_mode = TextServer.AUTOWRAP_OFF
		head.add_child(hl)
	_board.add_child(head)
	for r in rows:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var name_l := _lbl(r["nome"], head_font, 22, Color(r["colore"]).lerp(BONE, 0.25))
		name_l.custom_minimum_size = Vector2(250, 0)
		name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
		h.add_child(name_l)
		var dots := ""
		for k in int(r["max"]):
			dots += "●" if k < int(ceil(r["candele"])) else "○"
		var cl := _lbl(dots if r["stato"] != "spettro" else "spettro", body_font, 22,
			Color(1.0, 0.7, 0.3) if r["stato"] != "spettro" else Color(0.5, 0.75, 0.9))
		if r.has("testo"):
			cl.text = r["testo"]
			cl.add_theme_color_override("font_color", r.get("colore_testo", Color(0.78, 0.76, 0.8)))
		cl.custom_minimum_size = Vector2(110, 0)
		cl.autowrap_mode = TextServer.AUTOWRAP_OFF
		h.add_child(cl)
		var pl := _lbl(str(r["punti"]), Stile.font_num(), 22, GOLD)
		pl.custom_minimum_size = Vector2(60, 0)
		h.add_child(pl)
		var extra := ""
		if r["stato"] == "stanco":
			extra = "stanco"
		if r.get("abilita", false):
			extra += ("  " if extra != "" else "") + "✦"
		if r.get("carte", 0) > 0:
			extra += ("  " if extra != "" else "") + "carte %d" % r["carte"]
		if r.get("nota", "") != "":
			extra += ("  " if extra != "" else "") + r["nota"]
		var el := _lbl(extra, body_font, 20, DIM)
		el.autowrap_mode = TextServer.AUTOWRAP_OFF
		h.add_child(el)
		_board.add_child(h)


func start_timer(sec: float, on_timeout: Callable) -> void:
	_time_left = sec
	_timing = true
	_on_timeout = on_timeout


func stop_timer() -> void:
	_timing = false
	_timer_lbl.text = ""


func clear_actions() -> void:
	for c in _actions.get_children():
		c.queue_free()


## Prima scelta: la mossa. opts = scelte legali di CerchioRules; names = pid -> nome; extra: info della classe.
func ask_move(opts: Array, names: Dictionary, my_cls: int, can_peek: bool, peeked: Dictionary) -> void:
	_ask_args = [opts, names, my_cls, can_peek, peeked]
	clear_actions()
	var has_attack := false
	var has_defend := false
	var has_heal := false
	var special: Array = []
	for o in opts:
		match o["move"]:
			CerchioRules.Move.ATTACK: has_attack = true
			CerchioRules.Move.DEFEND: has_defend = true
			CerchioRules.Move.HEAL: has_heal = true
			CerchioRules.Move.SPECIAL: special.append(o)
	if has_attack:
		_actions.add_child(_btn("Attacca…", func() -> void: _ask_target(opts, names, CerchioRules.Move.ATTACK, my_cls, can_peek, peeked), 28, Color(1.0, 0.6, 0.5)))
	if has_defend:
		_actions.add_child(_btn("Difenditi da…", func() -> void: _ask_target(opts, names, CerchioRules.Move.DEFEND, my_cls, can_peek, peeked), 28, Color(0.6, 0.8, 1.0)))
	if has_heal:
		_actions.add_child(_btn("Riaccendi una candela", func() -> void: _send({"move": CerchioRules.Move.HEAL}), 28, Color(1.0, 0.8, 0.45)))
	var ab: String = Testi.CLASSI[my_cls]["abilita"]
	if not special.is_empty():
		if my_cls == CerchioRules.Cls.ELFO:
			_actions.add_child(_btn(ab + "…", func() -> void: _ask_two(special, names, my_cls, can_peek, peeked), 28, GOLD))
		else:
			_actions.add_child(_btn(ab, func() -> void: _send(special[0]), 28, GOLD))
	if can_peek and peeked.is_empty():
		_actions.add_child(_btn(ab + "…", func() -> void: _ask_peek(names), 28, GOLD))


func _ask_target(opts: Array, names: Dictionary, move: int, my_cls: int, can_peek: bool, peeked: Dictionary) -> void:
	clear_actions()
	for o in opts:
		if o["move"] == move:
			var t: int = o["target"]
			_actions.add_child(_btn(names[t], func() -> void: _send(o), 28))
	_actions.add_child(_btn("Annulla", _reask, 22, DIM))
	hint("Attacca chi?" if move == CerchioRules.Move.ATTACK else "Da chi ti difendi? Se ti attacca, lo contrattacchi.")


func _ask_two(special: Array, names: Dictionary, my_cls: int, can_peek: bool, peeked: Dictionary) -> void:
	clear_actions()
	for o in special:
		var ts: Array = o["targets"]
		_actions.add_child(_btn("%s + %s" % [names[ts[0]], names[ts[1]]], func() -> void: _send(o), 26))
	_actions.add_child(_btn("Annulla", _reask, 22, DIM))
	hint("Freccia doppia: scegli i due bersagli.")


func _ask_peek(names: Dictionary) -> void:
	clear_actions()
	for pid in names:
		_actions.add_child(_btn(names[pid], func() -> void: _send({"move": -2, "peek_target": pid}), 28, GOLD))
	_actions.add_child(_btn("Annulla", _reask, 22, DIM))
	hint("Occhio della strega: di chi vuoi vedere la mossa?")


func _reask() -> void:
	hint("Scegli la tua mossa. Nessuno la vedrà fino alla rivelazione.")
	ask_move(_ask_args[0], _ask_args[1], _ask_args[2], _ask_args[3], _ask_args[4])


func _send(c: Dictionary) -> void:
	clear_actions()
	stop_timer()
	if c.get("move", -1) >= 0 and not _card_pick.is_empty():
		c = c.duplicate()
		c.merge(_card_pick)
	if c.get("move", -1) >= 0:
		_card_pick = {}
		clear_cards()
	choice_made.emit(c)


# ------------------------------------------------------------------ carte del Custode

## Le tue carte per questo giro. note: perché non si possono giocare ("" = si possono).
func set_hand(hand: Array, note: String, names: Dictionary) -> void:
	_hand = hand.duplicate()
	_cards_note = note
	_card_names = names
	_card_pick = {}
	_render_cards()


func clear_cards() -> void:
	for c in _cards_row.get_children():
		c.queue_free()


func _card_btn(k: int, cb: Callable) -> Button:
	var b := _btn(Testi.CARTE[k]["nome"], cb, 22, Color(1.0, 0.82, 0.55))
	b.mouse_entered.connect(func() -> void: _show_tip(Testi.CARTE[k]["nome"], Testi.CARTE[k]["testo"], b))
	b.mouse_exited.connect(_hide_tip)
	b.tree_exiting.connect(_hide_tip)
	b.set_meta("carta", k)
	return b


## Per le foto di prova: mostra l'anteprima della prima carta in mano, come se il mouse ci fosse sopra.
func show_first_card_tip() -> void:
	for c in _cards_row.get_children():
		if c is Button and c.has_meta("carta"):
			var k: int = c.get_meta("carta")
			_show_tip(Testi.CARTE[k]["nome"], Testi.CARTE[k]["testo"], c)
			return


var _tip: PanelContainer
var _tip_title: Label
var _tip_text: Label


## Riquadro con l'effetto di una carta, sopra il suo pulsante: fondo scuro quasi trasparente, nome in oro.
func _show_tip(title: String, text: String, over: Control) -> void:
	if _tip == null:
		_tip = _panel(0.55)
		_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tip.custom_minimum_size = Vector2(380, 0)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tip.add_child(v)
		_tip_title = _lbl("", head_font, 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(_tip_title)
		var sep := ColorRect.new()
		sep.color = Color(GOLD, 0.45)
		sep.custom_minimum_size = Vector2(0, 1)
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(sep)
		_tip_text = _lbl("", body_font, 22, BONE, HORIZONTAL_ALIGNMENT_CENTER)
		_tip_text.custom_minimum_size = Vector2(340, 0)
		v.add_child(_tip_text)
		_root.add_child(_tip)
	_tip_title.text = title
	_tip_text.text = text
	_tip.size = Vector2.ZERO
	_tip.visible = true
	_tip.modulate.a = 0.0
	_tip.create_tween().tween_property(_tip, "modulate:a", 1.0, 0.12)
	# misura dopo che il testo è andato a capo (due fotogrammi), poi si mette sopra la carta e sopra la frase
	# di aiuto, così non copre nulla
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(over) or not _tip.visible:
		return
	_tip.reset_size()
	var sz := _tip.size
	var vs := get_viewport().get_visible_rect().size
	var r := over.get_global_rect()
	var top := r.position.y
	if _hint and _hint.text != "" and _hint.is_visible_in_tree():
		top = minf(top, _hint.get_global_rect().position.y)
	var pos := Vector2(r.position.x + r.size.x * 0.5 - sz.x * 0.5, top - sz.y - 12)
	if pos.y < 10:
		pos.y = r.end.y + 14
	pos.x = clampf(pos.x, 10, vs.x - sz.x - 10)
	_tip.position = pos
	_tip.size = sz


func _hide_tip() -> void:
	if _tip:
		_tip.visible = false


func _render_cards() -> void:
	clear_cards()
	if _hand.is_empty():
		return
	if _cards_note != "":
		_cards_row.add_child(_row_lbl(_cards_note, italic_font, 24, DIM))
		return
	if not _card_pick.is_empty():
		var k: int = _card_pick["card"]
		var t: int = _card_pick.get("card_target", -1)
		var txt := "Giocherai: %s" % Testi.CARTE[k]["nome"] + ("  su %s" % _card_names[t] if t >= 0 else "")
		_cards_row.add_child(_row_lbl(txt, head_font, 24, GOLD))
		_cards_row.add_child(_btn("Togli la carta", func() -> void:
			_card_pick = {}
			_render_cards(), 20, DIM))
		return
	_cards_row.add_child(_row_lbl("Le tue carte:", italic_font, 24, DIM))
	for k in _hand:
		_cards_row.add_child(_card_btn(k, func() -> void: _choose_card(k)))


func _choose_card(k: int) -> void:
	hint("%s: %s" % [Testi.CARTE[k]["nome"], Testi.CARTE[k]["testo"]])
	if CerchioRules.CARD_TARGETED.has(k):
		clear_cards()
		_cards_row.add_child(_row_lbl("%s su chi?" % Testi.CARTE[k]["nome"], head_font, 24, GOLD))
		for pid in _card_names:
			_cards_row.add_child(_btn(_card_names[pid], func() -> void:
				_card_pick = {"card": k, "card_target": pid}
				_render_cards(), 22))
		_cards_row.add_child(_btn("Annulla", _render_cards, 20, DIM))
		return
	_card_pick = {"card": k}
	_render_cards()


func ask_pact() -> void:
	clear_actions()
	_actions.add_child(_btn("Accetta il patto (−1 candela, abilità di nuovo)", func() -> void:
		clear_actions()
		pact_answer.emit(true), 26, BLOOD.lightened(0.3)))
	_actions.add_child(_btn("Rifiuta", func() -> void:
		clear_actions()
		pact_answer.emit(false), 26))
	hint("Il Custode ti offre un patto.")


func ask_bet(names: Dictionary) -> void:
	clear_actions()
	for pid in names:
		_actions.add_child(_btn(names[pid], func() -> void:
			stop_timer()
			clear_actions()
			ghost_bet.emit(pid), 26, Color(0.6, 0.85, 1.0)))
	_actions.add_child(_btn("Non scommetto", func() -> void:
		stop_timer()
		clear_actions()
		ghost_bet.emit(-1), 22, DIM))
	hint("Sei uno spettro. Chi perderà una candela in questo giro? (2 previsioni giuste = 1 punto)")


## Scritta su una riga sola, per le file di pulsanti.
func _row_lbl(text: String, font: Font, size: int, c: Color) -> Label:
	var l := _lbl(text, font, size, c)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


## Spazio vuoto in una fila di pulsanti (separa la conferma dalle risposte).
func _gap(w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


var _veil: ColorRect
var _veil_tw: Tween


## Velo nero sopra il mondo 3D ma sotto l'interfaccia (per cambiare luogo senza scatti). Restituisce
## il segnale di fine, così si può aspettare.
func fade(alpha: float, time: float) -> Signal:
	if _veil == null:
		_veil = ColorRect.new()
		_veil.color = Color(0, 0, 0, 0)
		_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
		_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(_veil)
		_root.move_child(_veil, 0)
	if _veil_tw:
		_veil_tw.kill()
	_veil_tw = _veil.create_tween()
	_veil_tw.tween_property(_veil, "color:a", alpha, time)
	return _veil_tw.finished
