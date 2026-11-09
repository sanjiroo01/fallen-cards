extends SceneTree
func _initialize() -> void:
	var name := OS.get_cmdline_user_args()[0]
	await process_frame
	var m := MeshInstance3D.new()
	m.mesh = SphereMesh.new()
	m.material_override = Mats.make(name, {})
	root.add_child(m)
	var c := Camera3D.new()
	c.position = Vector3(0, 0, 3)
	root.add_child(c)
	var l := OmniLight3D.new()
	l.position = Vector3(1, 1, 2)
	root.add_child(l)
	for k in 10:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/sh_%s.png" % name)
	print("SAVED ", name)
	quit()
