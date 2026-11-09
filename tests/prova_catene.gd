extends RefCounted
## Prova delle catene e del tavolo di pietra (22/10): la scena del gioco con N campioni legati (da 1 a 5 catene),
## foto dalla telecamera di gioco, primi piani della cintura e degli anelli del tavolo, carte mescolate e posate sul
## tavolo, un campione che brucia al suo posto. Misura anelli troppo distanti (catena allungata), capi staccati e
## punti di catena dentro la pietra del tavolo.
## Uso (dentro il gioco, che carica i servizi come i suoni):
##   godot --path . --resolution 1600x900 --position -20000,-20000 -- --prova-catene=CARTELLA [--scenario=N] [--giocatori=N]

var arena: Arena
var out := ""
var g: Node


func run(game: Node, folder: String, sc: int) -> void:
	g = game
	out = folder
	DirAccess.make_dir_recursive_absolute(out)
	game.hud.visible = false
	game._new_arena(maxi(sc, 0))
	arena = game.arena
	arena.orbit = false
	arena.set_view()
	var n: int = game.force_players if game.force_players >= 4 else 4
	arena.set_seats(n)
	for pid in n:
		var f := arena.place(pid, pid, Testi.CLASSI[pid]["nome"], Stile.font_head())
		f.is_me = pid == 0
	arena.game_mode()
	var counts := [1, 5, 3, 4, 2, 4, 1, 3]
	for pid in n:
		arena.set_chains(pid, counts[pid])
	await _wait(3.0)
	await _shot("1_tavolo_%d" % n)
	_check("ferme")
	# primo piano della cintura (campione con 5 catene) e degli anelli del tavolo
	var cam := arena.camera
	var f1: Figura = arena.seats[1]
	var belt := f1.belt_anchor(0)
	var inward := Vector3(-belt.x, 0, -belt.z).normalized()
	var side := Vector3.UP.cross(inward).normalized()
	arena.set_process(false)
	var lamp := OmniLight3D.new()             # solo per i primi piani
	lamp.light_energy = 1.5
	lamp.omni_range = 2.5
	arena.add_child(lamp)
	cam.global_transform = Transform3D(Basis(), belt - inward * 0.2 + side * 1.0 + Vector3(0, 0.2, 0)).looking_at(belt + inward * 0.25 + Vector3(0, -0.3, 0), Vector3.UP)
	lamp.global_position = cam.global_position
	await _wait(0.3)
	await _shot("2_cintura_e_catene")
	var ring := arena._ring_anchor(1, 0)
	cam.global_transform = Transform3D(Basis(), ring - inward * 1.1 + side * 0.45 + Vector3(0, 0.35, 0)).looking_at(ring, Vector3.UP)
	lamp.global_position = cam.global_position
	await _wait(0.1)
	await _shot("3_anelli_tavolo")
	# il tavolo da vicino, dall'altezza di un campione
	cam.global_transform = Transform3D(Basis(), Vector3(2.6, 1.7, 2.6)).looking_at(Vector3(0, 0.7, 0), Vector3.UP)
	await _wait(0.1)
	await _shot("4_tavolo_vicino")
	lamp.queue_free()
	arena.set_process(true)
	arena.set_view()
	await _wait(1.0)
	# carte: mescolate sul tavolo, poi una posata davanti a tre campioni
	var deck: Array[Node3D] = await arena.shuffle_cards(5, false, 1.0)
	await _shot("5_carte_mescolate")
	for k in 3:
		await arena.deal_card(deck[k], arena.seats[k + 1], [0, 1, 3][k], 1.0)
	await _shot("6_carte_posate")
	arena.clear_cards()
	# una catena in meno e una in più
	arena.set_chains(1, 4)
	arena.set_chains(0, 2)
	await _wait(0.5)
	await _shot("7_spezzata_e_nuova")
	await _wait(2.5)
	_check("dopo i cambi")
	# fine manche: il posto 3 brucia al suo posto, in catene
	arena.burn_seat(3)
	await _wait(1.6)
	await _shot("8_brucia")
	await _wait(4.0)
	await _shot("9_bruciato")
	_check("dopo il rogo")
	# 2/11: il Custode seduto sul trono, un campione seduto visto di fianco e le sedie viste dall'alto
	arena.set_process(false)
	var luce := OmniLight3D.new()
	luce.light_energy = 2.0
	luce.omni_range = 4.0
	arena.add_child(luce)
	cam.global_transform = Transform3D(Basis(), Arena.THRONE_POS + Vector3(1.8, 2.6, 6.5)).looking_at(Arena.THRONE_POS + Vector3(0, 2.4, 0), Vector3.UP)
	await _wait(0.3)
	await _shot("11_custode_trono")
	var f2: Figura = arena.seats[2]
	var radial := f2.global_position.normalized()
	var lato := Vector3.UP.cross(radial).normalized()
	cam.global_transform = Transform3D(Basis(), f2.global_position + lato * 2.2 + radial * 0.3 + Vector3(0, 1.1, 0)).looking_at(f2.global_position - radial * 0.3 + Vector3(0, 0.6, 0), Vector3.UP)
	luce.global_position = cam.global_position
	await _wait(0.3)
	await _shot("12_seduto_di_fianco")
	cam.global_transform = Transform3D(Basis(), f2.global_position + radial * 1.6 + Vector3(0, 1.6, 0)).looking_at(f2.global_position + Vector3(0, 0.6, 0), Vector3.UP)
	luce.global_position = cam.global_position
	await _wait(0.3)
	await _shot("13_seduto_da_dietro")
	cam.global_transform = Transform3D(Basis(), Vector3(0, 7.5, 0.01)).looking_at(Vector3.ZERO, Vector3(0, 0, -1))
	luce.global_position = Vector3(0, 3, 0)
	await _wait(0.3)
	await _shot("14_dall_alto")
	luce.queue_free()
	arena.set_process(true)
	arena.set_view()
	# la schermata del voto con tutti i ritratti (a 8 deve stare su una riga)
	var photos: Dictionary = await arena.portraits()
	var cards := []
	for pid in n:
		cards.append({"pid": pid, "nome": Testi.CLASSI[pid]["nome"], "colore": Testi.CLASSI[pid]["colore"],
			"sotto": "%d catene" % counts[pid], "photo": photos.get(pid), "votabile": pid != 0})
	game.hud.visible = true
	game.hud.open_vote(cards, "Chi è il sabotatore? Premi la sua carta. Servono %d voti su %d." % [n / 2 + 1, n])
	await _wait(0.8)
	await _shot("10_voto")
	print("FPS prova: %.0f" % Performance.get_monitor(Performance.TIME_FPS))
	g.get_tree().quit()


## Controlla ogni catena agganciata: nessun tratto più lungo del passo (gli anelli non si separano), capi attaccati e
## nessun punto dentro la pietra del tavolo.
func _check(when: String) -> void:
	var worst := 0.0
	var off_belt := 0.0
	var off_ring := 0.0
	var inside := 0
	var total := 0
	for i in arena._tethers:
		for s in arena._tethers[i]:
			var pts: PackedVector3Array = s["pts"]
			for j in pts.size() - 1:
				worst = maxf(worst, pts[j].distance_to(pts[j + 1]) - Arena.LINK_P)
			for j in range(1, pts.size() - 1):
				total += 1
				if pts[j].distance_to(arena._off_table(pts[j])) > 0.005:
					inside += 1
			if s["belt"]:
				off_belt = maxf(off_belt, pts[0].distance_to((arena.seats[i] as Figura).belt_anchor(s["k"])))
			off_ring = maxf(off_ring, pts[pts.size() - 1].distance_to(arena._ring_anchor(i, s["k"])))
	print("CATENE %s: tratto oltre il passo %.1f mm, distanza dalla cintura %.1f mm, dal tavolo %.1f mm, punti nella pietra %d su %d, trascinati %s" % [
		when, worst * 1000.0, off_belt * 1000.0, off_ring * 1000.0, inside, total,
		str(arena.seats.map(func(f: Figura) -> String: return "%.2f" % f.drag))])


func _wait(sec: float) -> void:
	await g.get_tree().create_timer(sec).timeout


func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	g.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, tag])
