extends SceneTree
## Foglio di controllo delle animazioni di un personaggio: ogni animazione fotografata a metà, vista di tre quarti.
## Uso: godot --path . --resolution 400x560 -s res://tests/prova_animazioni.gd -- res://...glb USCITA.png [frazione]

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var ch: Node3D = (load(a[0]) as PackedScene).instantiate()
	var frac := float(a[2]) if a.size() > 2 else 0.5
	var root := Node3D.new()
	get_root().add_child(root)
	root.add_child(ch)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.25, 0.27)
	env.environment.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.environment.ambient_light_energy = 0.7
	root.add_child(env)
	var floor := MeshInstance3D.new()          # pavimento: senza, chi cade sembra sospeso
	var pm := PlaneMesh.new()
	pm.size = Vector2(4, 4)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.38, 0.36, 0.34)
	floor.material_override = fm
	root.add_child(floor)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-45, 35, 0)
	root.add_child(sun)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6
	await process_frame
	cam.look_at_from_position(Vector3(2.6, 1.1, 2.6), Vector3(0, 0.9, 0))
	var ap: AnimationPlayer = ch.find_children("*", "AnimationPlayer", true, false)[0]
	var names := ap.get_animation_list()
	print("animazioni: ", names)
	var shots: Array[Image] = []
	for n in names:
		ap.play(n)
		ap.seek(ap.get_animation(n).length * frac, true)
		ap.pause()
		for k in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		img.resize(300, 420)
		shots.append(img)
	var w := shots[0].get_width()
	var h := shots[0].get_height()
	var cols := 6
	var sheet := Image.create(w * cols, h * int(ceil(shots.size() / float(cols))), false, Image.FORMAT_RGB8)
	for i in shots.size():
		sheet.blit_rect(shots[i], Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	sheet.save_png(a[1])
	quit()
