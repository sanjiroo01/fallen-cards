extends SceneTree
## Prova dei caratteri per titoli e annunci: le stesse scritte del gioco in ogni carattere disponibile,
## alla dimensione d'uso, su fondo scuro e su fondo chiaro (fuoco). Uso:
##   godot --path . --resolution 1600x900 -s res://tests/prova_caratteri.gd -- USCITA.png

const RIGHE := ["Salta un turno", "Non era il sabotatore", "Le catene dell'altare", "Fine della prima manche",
	"Togli un anello · 12 candele · 1 Il 0O"]


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://caratteri.png"
	var fonts := [
		["Cinzel Decorative (oggi)", load("res://fonts/CinzelDecorative-Bold.ttf")],
		["Cinzel", load("res://fonts/Cinzel.ttf")],
		["IM Fell", load("res://fonts/IMFell.ttf")],
		["EB Garamond 600", Stile.font_head()],
	]
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.035, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var fire := ColorRect.new()          # metà destra chiara come il fuoco
	fire.color = Color(0.75, 0.42, 0.16)
	fire.anchor_left = 0.62
	fire.anchor_right = 1.0
	fire.anchor_bottom = 1.0
	root.add_child(fire)
	var v := VBoxContainer.new()
	v.position = Vector2(30, 20)
	v.add_theme_constant_override("separation", 4)
	root.add_child(v)
	for f in fonts:
		var tag := Label.new()
		tag.text = f[0]
		tag.add_theme_font_size_override("font_size", 16)
		tag.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		v.add_child(tag)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 40)
		v.add_child(h)
		for k in [0, 1]:
			var l := Label.new()
			l.text = RIGHE[k] if f[0] != "x" else ""
			l.add_theme_font_override("font", f[1])
			l.add_theme_font_size_override("font_size", 56)
			l.add_theme_color_override("font_color", Color(0.93, 0.78, 0.45))
			l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			l.add_theme_constant_override("outline_size", 10)
			h.add_child(l)
		var l2 := Label.new()
		l2.text = "%s   ·   %s   ·   %s" % [RIGHE[2], RIGHE[3], RIGHE[4]]
		l2.add_theme_font_override("font", f[1])
		l2.add_theme_font_size_override("font_size", 30)
		l2.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
		v.add_child(l2)
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out)
	quit()
