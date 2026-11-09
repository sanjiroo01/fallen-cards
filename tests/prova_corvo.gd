extends SceneTree
## Foto ravvicinata dei corvi (posato e in volo) su fondo grigio, per controllarne la forma.
## Uso: godot --path . --resolution 1200x700 --script tests/prova_corvo.gd -- CARTELLA


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var root := Node3D.new()
	get_root().add_child(root)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.47, 0.5)
	env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.4
	root.add_child(sun)
	var rng := RandomNumberGenerator.new()
	var sit := Corvo.new().build(false, rng)
	if "--solo-volo" in OS.get_cmdline_user_args():
		sit.visible = false
	root.add_child(sit)
	sit.position = Vector3(-0.35, 0, 0)
	sit.rotation.y = 0.6
	sit.set_process(false)
	var fly := Corvo.new().build(true, rng)
	root.add_child(fly)
	fly.radius = 0.45
	fly.height = 0.3
	fly.speed = 0.02
	fly.position = Vector3(0.5, 0.3, -0.2)
	fly.rotation.y = -0.4
	fly.set_process(false)
	fly._pose_wings(1.0, 0.35)
	var cam := Camera3D.new()
	cam.fov = 35
	root.add_child(cam)
	cam.position = Vector3(0, 0.55, 1.6)
	cam.look_at(Vector3(0, 0.18, 0))
	for k in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out + "/corvi_davanti.png")
	cam.position = Vector3(1.4, 0.3, 0.6)
	cam.look_at(Vector3(0, 0.18, 0))
	for k in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out + "/corvi_fianco.png")
	cam.fov = 60
	cam.position = Vector3(0.2, 1.4, 1.8)
	cam.look_at(Vector3(0.1, 0.2, 0))
	for k in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out + "/corvi_alto.png")
	quit()
