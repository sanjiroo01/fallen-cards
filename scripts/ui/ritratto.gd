class_name Ritratto
extends Button
## La carta-ritratto di un campione per la schermata del voto: la stessa cornice di ferro delle carte, dentro la foto
## del campione scattata nella scena (Arena.portrait), sotto il nome e le sue catene. Si vota premendola.

var photo: Texture2D
var nome := ""
var colore := Color.WHITE
var sotto := ""                     # riga piccola sotto il nome (catene, "libero"...)
var selected := false:
	set(v):
		selected = v
		queue_redraw()
var _hover := 0.0


static func make(p: Texture2D, n: String, c: Color, s: String, w := 230.0) -> Ritratto:
	var r := Ritratto.new()
	r.photo = p
	r.nome = n
	r.colore = c
	r.sotto = s
	r.custom_minimum_size = Vector2(w, w * 1.5)
	return r


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	for st in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	mouse_entered.connect(func() -> void: _hover_to(1.0))
	mouse_exited.connect(func() -> void: _hover_to(0.0))
	focus_entered.connect(func() -> void: _hover_to(1.0))
	focus_exited.connect(func() -> void: _hover_to(0.0))


func _hover_to(v: float) -> void:
	if disabled:
		v = 0.0
	create_tween().tween_method(func(x: float) -> void:
		_hover = x
		queue_redraw(), _hover, v, 0.12)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var r := Rect2(0, -8.0 * _hover * w / 230.0, w, h)
	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0, 0, 0, 0)
	sh.set_corner_radius_all(int(w * 0.05))
	sh.shadow_color = Color(0, 0, 0, 0.6)
	sh.shadow_size = int(w * 0.06 + 10.0 * _hover)
	sh.shadow_offset = Vector2(0, w * 0.02)
	sh.draw(get_canvas_item(), r)
	if selected or _hover > 0.01:
		var glow := StyleBoxFlat.new()
		glow.bg_color = Color(0, 0, 0, 0)
		glow.set_corner_radius_all(int(w * 0.07))
		glow.set_border_width_all(int(maxf(3.0, w * 0.016)))
		glow.border_color = Color(1.0, 0.3, 0.2, 0.95) if selected else Color(1.0, 0.82, 0.45, 0.6 * _hover)
		glow.draw(get_canvas_item(), r.grow(w * 0.02))
	var m := w * 0.04
	draw_texture_rect(Carta._tex(Carta.TEX_PAPER), Rect2(r.position + Vector2(m, m), r.size - Vector2(m, m) * 2.0), false)
	# la foto, con un filo scuro attorno come una stampa incollata sulla pergamena
	var pr := Rect2(r.position + Vector2(w * 0.1, w * 0.1), Vector2(w * 0.8, h * 0.66))
	draw_rect(pr.grow(w * 0.012), Color(0.12, 0.08, 0.05))
	if photo:
		draw_texture_rect(photo, pr, false)
	draw_rect(pr, Color(0, 0, 0, 0.0), false)
	draw_texture_rect(Carta._tex(Carta.TEX_FRAME), r, false)
	# nome e catene
	var tf := Stile.font_title()
	var ts := int(w * 0.11)
	var tl := tf.get_string_size(nome, HORIZONTAL_ALIGNMENT_CENTER, -1, ts)
	if tl.x > w * 0.84:
		ts = int(ts * w * 0.84 / tl.x)
	draw_string(tf, Vector2(r.position.x + w * 0.08, r.position.y + h * 0.84), nome, HORIZONTAL_ALIGNMENT_CENTER,
		w * 0.84, ts, colore.darkened(0.55))
	draw_string(Stile.font_head(), Vector2(r.position.x + w * 0.08, r.position.y + h * 0.915), sotto,
		HORIZONTAL_ALIGNMENT_CENTER, w * 0.84, int(w * 0.065), Color(0.25, 0.16, 0.1))
	if disabled:
		draw_rect(r, Color(0, 0, 0, 0.5))
