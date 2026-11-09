extends SceneTree
## Prova di un personaggio importato: lo scheletro c'è, le ossa si muovono, i colori ci sono.
## Uso: godot --path . --resolution 900x900 -s res://tests/prova_personaggio.gd -- res://assets/personaggi/X/X.glb CARTELLA

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var scene: PackedScene = load(a[0])
	var out: String = a[1]
	var root := Node3D.new()
	get_root().add_child(root)
	var ch := scene.instantiate()
	root.add_child(ch)
	var sk: Skeleton3D = ch.find_children("*", "Skeleton3D", true, false)[0]
	print("ossa: ", sk.get_bone_count(), "  prima: ", sk.get_bone_name(0), "  braccio: ", sk.find_bone("LeftArm"))
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.25, 0.27)
	env.environment.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.environment.ambient_light_energy = 0.6
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 25, 0)
	root.add_child(sun)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.1
	cam.position = Vector3(0, 1.0, 4)
	for k in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out + "/godot_fermo.png")
	var i := sk.find_bone("LeftArm")
	sk.set_bone_pose_rotation(i, sk.get_bone_pose_rotation(i) * Quaternion(Vector3(1, 0, 0), deg_to_rad(70)))
	var j := sk.find_bone("RightUpLeg")
	sk.set_bone_pose_rotation(j, sk.get_bone_pose_rotation(j) * Quaternion(Vector3(1, 0, 0), deg_to_rad(-40)))
	for k in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out + "/godot_mosso.png")
	quit()
