extends RefCounted
## Prova del pannello Audio come la farebbe un giocatore: clic veri del mouse (eventi spediti alla finestra) sui
## cursori e sugli interruttori, nel menu e in partita (dal pulsante in alto e dalla pausa). Dopo ogni clic controlla
## che il suono cambi davvero: lettori e canali (bus) di musica, ambiente dei luoghi ed effetti.
## Uso: godot --path . --resolution 1600x900 --position -20000,-20000 -- --prova-audio=CARTELLA [--scenario=N]

var g: Node
var hud: Hud
var out := ""
var fails := 0


func run(game: Node, folder: String, sc: int) -> void:
	g = game
	hud = game.hud
	out = folder
	var saved := FileAccess.get_file_as_string(Sfx.AUDIO_CFG)     # le impostazioni del giocatore: rimesse a posto alla fine
	DirAccess.make_dir_recursive_absolute(out)
	# parte dai valori normali, senza toccare quelli salvati dal giocatore
	for k in ["music_vol", "amb_vol", "sfx_vol"]:
		Sfx.set(k, 0.8)
	Sfx.music_on = true
	Sfx.set_setting("sfx_vol", 0.8)
	game._show_menu()
	if sc >= 0:
		game._menu_scene(sc)
	await _wait(3.0)
	print("--- nel menu")
	await _check_panel("menu")
	# in partita: si apre il pannello dal pulsante in alto a destra, mentre il gioco aspetta
	game._play_match(0, maxi(sc, 0))
	await _wait(2.5)
	print("--- in partita (pulsante Audio in alto)")
	var top := _find_button(hud._top_bar, "AUDIO")
	_ok(top != null, "c'è il pulsante Audio in partita")
	if top:
		print("    pulsante ", top.get_global_rect(), " barra ", hud._top_bar.get_global_rect(), " visibile ", top.is_visible_in_tree(), " schermo ", g.get_viewport().get_visible_rect())
	await _shot("partita_inizio")
	if top:
		await _click(top)
		_ok(hud._audio.visible, "il pulsante Audio in partita apre il pannello")
		hud._audio.visible = false
	print("--- in partita (dalla pausa)")
	hud._pause.visible = true
	await _wait(0.3)
	var pb := _find_button(hud._pause, "Audio")
	_ok(pb != null, "c'è Audio nella pausa")
	if pb:
		await _click(pb)
		_ok(hud._audio.visible, "Audio dalla pausa apre il pannello")
	hud._audio.visible = true
	await _check_panel("partita")
	# tasto M in partita, a pannelli chiusi
	hud._audio.visible = false
	hud._pause.visible = false
	for k in 2:
		var before: bool = Sfx.audio_on
		for pressed in [true, false]:
			var e := InputEventKey.new()
			e.keycode = KEY_M
			e.pressed = pressed
			g.get_viewport().push_input(e)
			await g.get_tree().process_frame
		_ok(Sfx.audio_on != before and AudioServer.is_bus_mute(0) == not Sfx.audio_on, "tasto M: audio %s" % ("acceso" if Sfx.audio_on else "spento"))
	print("PROVA AUDIO: %s" % ("TUTTO BENE" if fails == 0 else "%d PROBLEMI" % fails))
	if saved != "":
		var fw := FileAccess.open(Sfx.AUDIO_CFG, FileAccess.WRITE)
		fw.store_string(saved)
		fw.close()
	g.get_tree().quit()


## Sul pannello aperto: tutto a zero e poi di nuovo su, con i clic.
func _check_panel(where: String) -> void:
	if not hud._audio.visible:
		hud._open_panel(hud._audio)
	await _wait(0.4)
	var sliders: Array = hud._audio.find_children("*", "HSlider", true, false)
	_ok(sliders.size() >= 3, "%s: ci sono i cursori (%d)" % [where, sliders.size()])
	await _shot("pannello_" + where)
	# ogni cursore portato in fondo a sinistra (zero) con un clic
	for s in sliders:
		await _click(s, Vector2(0.004, 0.5))
	await _wait(0.3)
	_report(where + ", cursori a zero")
	_ok(Sfx.music_vol <= 0.05 and Sfx.amb_vol <= 0.05 and Sfx.sfx_vol <= 0.05, "%s: i clic portano i cursori a zero" % where)
	_ok(_silent("Music") and _silent("Amb") and _silent("SFX"), "%s: a zero non si sente più nulla" % where)
	# e di nuovo a metà
	for s in sliders:
		await _click(s, Vector2(0.5, 0.5))
	await _wait(0.3)
	_report(where + ", cursori a metà")
	_ok(not _silent("Music") and not _silent("Amb") and not _silent("SFX"), "%s: a metà si sente di nuovo" % where)
	# l'interruttore generale, se c'è, spegne tutto
	var all_off := _find_check(hud._audio, "Audio")
	if all_off:
		await _click(all_off)
		await _wait(0.2)
		_report(where + ", audio spento")
		_ok(AudioServer.is_bus_mute(0), "%s: l'interruttore spegne tutto" % where)
		await _click(all_off)
		await _wait(0.2)
		_ok(not AudioServer.is_bus_mute(0), "%s: l'interruttore riaccende" % where)
	else:
		_ok(false, "%s: manca un interruttore per spegnere tutto l'audio" % where)
	await _shot("pannello_" + where + "_dopo")
	hud._audio.visible = false


## Un canale è muto se è spento o se il suo volume (canale + lettori che lo usano) è sotto i -60 dB.
func _silent(bus: String) -> bool:
	var i := AudioServer.get_bus_index(bus)
	if AudioServer.is_bus_mute(i) or AudioServer.is_bus_mute(0):
		return true
	var vol := AudioServer.get_bus_volume_db(i)
	# il lettore più forte che suona su quel canale
	var loud := -INF
	for p in g.get_tree().root.find_children("*", "AudioStreamPlayer", true, false) + g.get_tree().root.find_children("*", "AudioStreamPlayer3D", true, false):
		if p.bus == bus and p.playing:
			loud = maxf(loud, p.volume_db)
	if loud == -INF:
		return vol < -60.0
	return vol + loud < -60.0


func _report(when: String) -> void:
	var parts: Array[String] = []
	for b in ["Master", "Music", "Amb", "SFX"]:
		var i := AudioServer.get_bus_index(b)
		parts.append("%s %.0f dB%s" % [b, AudioServer.get_bus_volume_db(i), " muto" if AudioServer.is_bus_mute(i) else ""])
	var amb_players := 0
	for p in g.get_tree().root.find_children("*", "AudioStreamPlayer", true, false) + g.get_tree().root.find_children("*", "AudioStreamPlayer3D", true, false):
		if p.bus == "Amb" and p.playing:
			amb_players += 1
	print("  [%s] %s; valori %.2f/%.2f/%.2f; lettori ambiente accesi %d" % [when, ", ".join(parts), Sfx.music_vol, Sfx.amb_vol, Sfx.sfx_vol, amb_players])


func _ok(cond: bool, what: String) -> void:
	print("  %s %s" % ["ok  " if cond else "NO  ", what])
	if not cond:
		fails += 1


## Clic del mouse dentro un controllo, nel punto `at` (0..1 della sua larghezza e altezza): l'evento entra dalla
## finestra come un clic vero, quindi conta anche cosa c'è sopra il controllo.
func _click(c: Control, at := Vector2(0.5, 0.5)) -> void:
	var screen := c.get_global_transform_with_canvas() * (c.size * at)
	var mv := InputEventMouseMotion.new()
	mv.position = screen
	mv.global_position = screen
	c.get_viewport().push_input(mv, true)
	await g.get_tree().process_frame
	var hov := c.get_viewport().gui_get_hovered_control()
	if hov != c:
		print("    sotto il mouse c'è %s invece di %s" % [hov.get_path() if hov else "niente", c.name])
		for ch in hud._root.get_children():
			if (ch as Control).visible:
				print("      visibile: ", ch, " audio" if ch == hud._audio else "", " visuale" if ch == hud._visual else "", " grande" if ch == hud._big else "", " pausa" if ch == hud._pause else "", " barra" if ch == hud._top_bar else "")
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = screen
		e.global_position = screen
		c.get_viewport().push_input(e, true)
		await g.get_tree().process_frame
	await g.get_tree().process_frame


func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).visible and (b as Button).text.strip_edges().to_upper() == text.to_upper():
			return b
	return null


func _find_check(root: Node, start: String) -> CheckButton:
	for b in root.find_children("*", "CheckButton", true, false):
		if (b as CheckButton).text.begins_with(start):
			return b
	return null


func _wait(sec: float) -> void:
	await g.get_tree().create_timer(sec).timeout


func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	g.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, tag])
