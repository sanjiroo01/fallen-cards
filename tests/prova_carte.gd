extends SceneTree
## Prova delle carte (scripts/ui/carta.gd): tutte le facce e il dorso alla dimensione della pesca, più la mano
## in piccolo. Uso: godot --path . --resolution 1600x900 -s res://tests/prova_carte.gd -- USCITA.png


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://carte.png"
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.035)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var row := HBoxContainer.new()
	row.position = Vector2(30, 30)
	row.add_theme_constant_override("separation", 22)
	root.add_child(row)
	for k in [-1, 0, 1, 3]:
		var c := Carta.make(maxi(k, 0), k >= 0, 230)
		row.add_child(c)
	var row2 := HBoxContainer.new()
	row2.position = Vector2(30, 420)
	row2.add_theme_constant_override("separation", 22)
	root.add_child(row2)
	for k in [2, 4, 5, 6, 7]:
		var c := Carta.make(k, true, 230)
		if k == 2:
			c.note = "colpisce due campioni"
		if k == 4:
			c.selected = true
		row2.add_child(c)
	var row3 := HBoxContainer.new()
	row3.position = Vector2(1060, 520)
	row3.add_theme_constant_override("separation", 12)
	root.add_child(row3)
	for k in [0, 1, 3]:
		row3.add_child(Carta.make(k, true, 140))
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out)
	quit()
