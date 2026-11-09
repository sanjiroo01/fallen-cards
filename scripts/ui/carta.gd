class_name Carta
extends Button
## Una carta delle Catene dell'altare, disegnata al volo (niente immagini esterne): cornice di ferro scuro, pergamena
## invecchiata, titolo in IM Fell, un simbolo inciso per ogni carta, una riga di spiegazione e il tipo in basso.
## Il dorso è il cerchio rituale del pavimento, acceso come brace su pelle nera. La stessa carta serve sullo schermo
## (pesca, mano) e, attraverso texture(), sulle carte 3D della scena.

const DONO := 6                     # il "Togli" nascosto del sabotatore (dono del Guardiano)
const TIRA := 7                     # non è una carta: la mossa "tira la catena", disegnata come le carte
const NOMI := ["Togli una catena", "Aggiungi una catena", "Aggiungi due catene", "Salta un turno", "Voto",
	"Passa il testimone", "Dono del Guardiano", "Tira la catena"]
const RIGA := ["Spezza una catena a chi scegli, anche a te.", "Una catena in più a chi scegli.",
	"Due catene in più a chi scegli.", "Chi scegli salta il prossimo turno.", "A fine turno si vota il sabotatore.",
	"Il sabotatore passa il ruolo in segreto.", "Togli una catena, nascosto a tutti.",
	"Se tirano tutti, l'altare resta fermo e la candela non si spegne."]
const TIPO := ["liberazione", "sabotaggio", "sabotaggio", "sabotaggio", "accusa", "inganno", "dono del Guardiano",
	"al posto di una carta"]
const INK := [Color(0.42, 0.22, 0.04), Color(0.42, 0.03, 0.02), Color(0.42, 0.03, 0.02), Color(0.42, 0.03, 0.02),
	Color(0.17, 0.08, 0.27), Color(0.1, 0.07, 0.07), Color(0.52, 0.06, 0.02), Color(0.12, 0.1, 0.09)]   # inchiostri cupi (22/10)
const PAPER := Color(0.6, 0.52, 0.37)        # il colore medio della pergamena nuova (taglia la catena del Togli)
const IRON := Color(0.075, 0.055, 0.05)
const GOLD := Color(0.86, 0.68, 0.36)

var kind := 0
var face_up := true
var selected := false:
	set(v):
		selected = v
		queue_redraw()
var note := ""                      # riga in più sotto la spiegazione (es. "colpisce due campioni")
var _hover := 0.0

static var _paper_tex: Texture2D
const TEX_PAPER := "res://assets/carte/carta_pergamena.png"     # cuoce assets_src/carte/cuoci_carte.py (texture CC0)
const TEX_FRAME := "res://assets/carte/carta_cornice.png"
const TEX_BACK := "res://assets/carte/carta_dorso.png"
static var _host: Node               # dove vivono i SubViewport delle texture 3D (l'interfaccia)
static var _tex_cache := {}


static func make(k: int, up := true, w := 240.0) -> Carta:
	var c := Carta.new()
	c.kind = k
	c.face_up = up
	c.custom_minimum_size = Vector2(w, w * 1.5)
	c.size = c.custom_minimum_size
	return c


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	for st in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	mouse_entered.connect(func() -> void: _hover_to(1.0))
	mouse_exited.connect(func() -> void: _hover_to(0.0))
	focus_entered.connect(func() -> void: _hover_to(1.0))
	focus_exited.connect(func() -> void: _hover_to(0.0))
	resized.connect(queue_redraw)


func _hover_to(v: float) -> void:
	if disabled:
		v = 0.0
	create_tween().tween_method(func(x: float) -> void:
		_hover = x
		queue_redraw(), _hover, v, 0.12)


## Gira la carta (a metà giro cambia faccia).
func flip(to_face := true, dur := 0.35) -> void:
	pivot_offset = size * 0.5
	var tw := create_tween()
	tw.tween_property(self, "scale:x", 0.0, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		face_up = to_face
		queue_redraw())
	tw.tween_property(self, "scale:x", 1.0, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished


# ------------------------------------------------------------------ disegno

func _draw() -> void:
	var w := size.x
	var h := size.y
	var lift := -6.0 * _hover * w / 240.0
	var r := Rect2(0, lift, w, h)
	var rad := w * 0.055
	# ombra e alone quando è sotto il mouse o scelta
	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0, 0, 0, 0)
	sh.set_corner_radius_all(int(rad))
	sh.shadow_color = Color(0, 0, 0, 0.55)
	sh.shadow_size = int(w * 0.05 + 8.0 * _hover)
	sh.shadow_offset = Vector2(0, w * 0.02)
	sh.draw(get_canvas_item(), r)
	if selected or _hover > 0.01:
		var glow := StyleBoxFlat.new()
		glow.bg_color = Color(0, 0, 0, 0)
		glow.set_corner_radius_all(int(rad + 4))
		glow.set_border_width_all(int(maxf(2.0, w * 0.012)))
		glow.border_color = Color(1.0, 0.82, 0.45, 0.95 if selected else 0.55 * _hover)
		glow.draw(get_canvas_item(), r.grow(w * 0.018))
	if face_up:
		_draw_face(r, rad)
	else:
		_draw_back(r, rad)
	if disabled:
		draw_rect(r, Color(0, 0, 0, 0.45))


func _frame(r: Rect2, rad: float, fill: Color, edge: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(int(rad))
	sb.set_border_width_all(int(maxf(1.0, r.size.x * 0.008)))
	sb.border_color = edge
	sb.anti_aliasing = true
	sb.draw(get_canvas_item(), r)


func _draw_face(r: Rect2, rad: float) -> void:
	var w := r.size.x
	var h := r.size.y
	var ink: Color = Color(INK[kind], 0.9)        # inchiostro appena trasparente: si vede la grana della carta
	# pergamena vera e cornice di ferro con gli angoli d'ottone (immagini cotte da texture fotografiche CC0)
	var m := w * 0.04
	# sotto la pergamena bruciata: il fondo carbonizzato (dove il fuoco l'ha mangiata non resta un buco)
	_frame(r.grow(-m), rad, Color(0.03, 0.018, 0.012), Color(0.03, 0.018, 0.012))
	draw_texture_rect(_tex(TEX_PAPER), Rect2(r.position + Vector2(m, m), r.size - Vector2(m, m) * 2.0), false)
	draw_texture_rect(_tex(TEX_FRAME), r, false)
	# titolo
	var title_font := Stile.font_title()
	var ts := int(w * 0.095)
	var tw := w * 0.72              # dentro il bordo bruciato della pergamena
	var tl := title_font.get_string_size(NOMI[kind], HORIZONTAL_ALIGNMENT_CENTER, -1, ts)
	if tl.x > tw:
		ts = int(ts * tw / tl.x)
	draw_string(title_font, Vector2(r.position.x + w * 0.14, r.position.y + h * 0.15), NOMI[kind],
		HORIZONTAL_ALIGNMENT_CENTER, tw, ts, Color(0.16, 0.07, 0.04))
	# ornamento sotto il titolo
	var oy := r.position.y + h * 0.19
	var cxm := r.position.x + w * 0.5
	draw_line(Vector2(cxm - w * 0.26, oy), Vector2(cxm - w * 0.04, oy), Color(ink, 0.7), maxf(1.0, w * 0.006))
	draw_line(Vector2(cxm + w * 0.04, oy), Vector2(cxm + w * 0.26, oy), Color(ink, 0.7), maxf(1.0, w * 0.006))
	_diamond(Vector2(cxm, oy), w * 0.02, ink)
	# il simbolo, dentro un doppio cerchio
	var c := Vector2(cxm, r.position.y + h * 0.43)
	var cr := w * 0.24
	# il simbolo è marchiato a fuoco: alone di brace attorno, la carta annerita appena sotto il segno
	for k in 6:
		draw_circle(c, cr * (1.32 - k * 0.07), Color(1.0, 0.42, 0.08, 0.035))
	draw_circle(c, cr, Color(0.12, 0.05, 0.02, 0.16))
	draw_arc(c, cr, 0, TAU, 64, Color(ink, 0.8), maxf(1.5, w * 0.009), true)
	draw_arc(c, cr * 0.9, 0, TAU, 64, Color(ink, 0.45), maxf(1.0, w * 0.004), true)
	for k in 24:
		var a := TAU * k / 24.0
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * cr * 0.9, c + d * cr * (0.94 if k % 2 else 0.97), Color(ink, 0.6), maxf(1.0, w * 0.004))
	_emblem(c, cr * 0.7, ink, w)
	# spiegazione
	var body := Stile.font_body()
	var bs := int(w * 0.068)
	draw_multiline_string(body, Vector2(r.position.x + w * 0.13, r.position.y + h * 0.72), RIGA[kind],
		HORIZONTAL_ALIGNMENT_CENTER, w * 0.74, bs, 3, Color(0.17, 0.11, 0.07))
	if note != "":
		draw_string(Stile.font_italic(), Vector2(r.position.x + w * 0.1, r.position.y + h * 0.835), note,
			HORIZONTAL_ALIGNMENT_CENTER, w * 0.8, int(w * 0.058), Color(0.5, 0.05, 0.03))
	# il tipo, in basso
	var tipo: String = TIPO[kind].to_upper()
	var ks := int(w * 0.046)
	draw_string(Stile.font_head(), Vector2(r.position.x + w * 0.1, r.position.y + h * 0.895), tipo,
		HORIZONTAL_ALIGNMENT_CENTER, w * 0.8, ks, Color(ink, 0.9))


## Il dorso (22/10): pelle quasi nera con il cerchio rituale del pavimento impresso e acceso come brace, cornice di
## ferro ribattuta. Tutto nell'immagine cotta da assets_src/carte/cuoci_carte.py.
func _draw_back(r: Rect2, _rad: float) -> void:
	draw_texture_rect(_tex(TEX_BACK), r, false)


# ------------------------------------------------------------------ simboli

func _emblem(c: Vector2, s: float, ink: Color, w: float) -> void:
	var lw := maxf(2.0, w * 0.016)
	match kind:
		0:  # Togli: un anello spezzato, i due pezzi che si allontanano
			_stadium(c + Vector2(-s * 0.5, s * 0.14), s * 0.5, s * 0.27, -0.45, ink, lw * 1.3)
			_stadium(c + Vector2(s * 0.5, -s * 0.14), s * 0.5, s * 0.27, -0.45, ink, lw * 1.3)
			draw_circle(c, s * 0.16, PAPER)
			for k in 5:
				var a := -1.2 + k * 0.6
				var d := Vector2(cos(a), sin(a))
				draw_line(c + d * s * 0.05, c + d * s * 0.22, Color(ink, 0.85), maxf(1.0, lw * 0.6), true)
				draw_line(c - d * s * 0.05, c - d * s * 0.22, Color(ink, 0.85), maxf(1.0, lw * 0.6), true)
		1, 2:  # Aggiungi: catena di anelli, e il numero inciso in un sigillo
			var n := 3 if kind == 1 else 5
			var step := s * (0.62 if kind == 1 else 0.42)
			for k in n:
				var x := (k - (n - 1) * 0.5) * step
				if k % 2 == 0:
					_stadium(c + Vector2(x, -s * 0.12), step * 0.62, s * 0.22, 0.0, ink, lw * 1.2)
				else:
					draw_line(c + Vector2(x - step * 0.42, -s * 0.12), c + Vector2(x + step * 0.42, -s * 0.12), ink, lw * 2.2, true)
			var sc := c + Vector2(0, s * 0.55)
			draw_circle(sc, s * 0.3, ink)
			draw_string(Stile.font_num(), sc + Vector2(-s * 0.3, s * 0.13), "+1" if kind == 1 else "+2",
				HORIZONTAL_ALIGNMENT_CENTER, s * 0.6, int(s * 0.38), PAPER)
		3:  # Salta: clessidra
			var top := c + Vector2(0, -s * 0.7)
			var bot := c + Vector2(0, s * 0.7)
			draw_line(top + Vector2(-s * 0.5, 0), top + Vector2(s * 0.5, 0), ink, lw * 1.4, true)
			draw_line(bot + Vector2(-s * 0.5, 0), bot + Vector2(s * 0.5, 0), ink, lw * 1.4, true)
			var glass := PackedVector2Array([top + Vector2(-s * 0.38, 0), top + Vector2(s * 0.38, 0), c + Vector2(s * 0.06, 0),
				bot + Vector2(s * 0.38, 0), bot + Vector2(-s * 0.38, 0), c + Vector2(-s * 0.06, 0), top + Vector2(-s * 0.38, 0)])
			draw_polyline(glass, ink, lw, true)
			draw_colored_polygon(PackedVector2Array([bot + Vector2(-s * 0.3, -s * 0.04), bot + Vector2(s * 0.3, -s * 0.04),
				c + Vector2(0, s * 0.35)]), Color(ink, 0.6))
			draw_line(c, bot + Vector2(0, -s * 0.05), Color(ink, 0.6), maxf(1.0, lw * 0.4))
		4:  # Voto: l'occhio che accusa
			_eye(c, s * 0.75, ink, w)
		5:  # Passa il testimone: due frecce che si scambiano il posto
			for half: float in [0.0, PI]:
				var a0 := half + 0.35
				var a1 := half + PI - 0.35
				draw_arc(c, s * 0.62, a0, a1, 24, ink, lw * 1.3, true)
				var tip := c + Vector2(cos(a1), sin(a1)) * s * 0.62
				var tang := Vector2(-sin(a1), cos(a1))
				var nrm := Vector2(cos(a1), sin(a1))
				draw_colored_polygon(PackedVector2Array([tip + tang * s * 0.22, tip + nrm * s * 0.16, tip - nrm * s * 0.16]), ink)
			draw_circle(c, s * 0.16, ink)
		7:  # Tira la catena: tre anelli in verticale e la freccia che tira verso il basso
			for k in 3:
				var y := (k - 1) * s * 0.42 - s * 0.15
				if k % 2 == 0:
					_stadium(c + Vector2(-s * 0.15, y), s * 0.27, s * 0.16, PI * 0.5, ink, lw * 1.2)
				else:
					draw_line(c + Vector2(-s * 0.15, y - s * 0.24), c + Vector2(-s * 0.15, y + s * 0.24), ink, lw * 2.2, true)
			var ax := c.x + s * 0.42
			draw_line(Vector2(ax, c.y - s * 0.55), Vector2(ax, c.y + s * 0.45), ink, lw * 1.2, true)
			draw_colored_polygon(PackedVector2Array([Vector2(ax - s * 0.17, c.y + s * 0.4), Vector2(ax + s * 0.17, c.y + s * 0.4),
				Vector2(ax, c.y + s * 0.7)]), ink)
		6:  # Dono del Guardiano: la fiamma nascosta
			var fl := PackedVector2Array()
			for k in 41:
				var t := float(k) / 40.0
				var a := TAU * t
				var rr := s * (0.42 + 0.05 * sin(a * 3.0))
				var p := Vector2(sin(a) * rr, -cos(a) * rr)
				if p.y < 0.0:
					p.y *= 1.0 + 1.1 * (1.0 - absf(p.x) / rr)
					p.x *= 1.0 + 0.6 * (p.y / s)
				fl.append(c + p + Vector2(0, s * 0.25))
			draw_colored_polygon(fl, ink)
			var inner := PackedVector2Array()
			for p in fl:
				inner.append(c + Vector2(0, s * 0.42) + (p - c - Vector2(0, s * 0.42)) * 0.5)
			draw_colored_polygon(inner, Color(1.0, 0.75, 0.35))


func _eye(c: Vector2, s: float, ink: Color, w: float) -> void:
	var lw := maxf(1.5, w * 0.012)
	var up := PackedVector2Array()
	var dn := PackedVector2Array()
	for k in 25:
		var t := float(k) / 24.0
		var x := (t - 0.5) * 2.0 * s
		var y := sin(t * PI) * s * 0.45
		up.append(c + Vector2(x, -y))
		dn.append(c + Vector2(x, y))
	draw_polyline(up, ink, lw, true)
	draw_polyline(dn, ink, lw, true)
	draw_circle(c, s * 0.3, ink)
	draw_circle(c, s * 0.12, Color(0.05, 0.02, 0.02))
	draw_circle(c + Vector2(-s * 0.09, -s * 0.09), s * 0.05, Color(1, 1, 1, 0.7))


## Un anello di catena visto di fianco: due mezzi cerchi uniti da due tratti dritti.
func _stadium(c: Vector2, half_len: float, half_w: float, ang: float, col: Color, lw: float) -> void:
	var pts := PackedVector2Array()
	var straight := maxf(half_len - half_w, 0.0)
	for k in 13:
		var a := -PI * 0.5 + PI * k / 12.0
		pts.append(Vector2(straight + cos(a) * half_w, sin(a) * half_w))
	for k in 13:
		var a := PI * 0.5 + PI * k / 12.0
		pts.append(Vector2(-straight + cos(a) * half_w, sin(a) * half_w))
	pts.append(pts[0])
	var rot := Transform2D(ang, c)
	draw_polyline(rot * pts, col, lw, true)


func _diamond(c: Vector2, s: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]), col)


static var _texs := {}


## Le immagini cotte delle carte, caricate una volta sola.
static func _tex(path: String) -> Texture2D:
	if not _texs.has(path):
		_texs[path] = ImageTexture.create_from_image((load(path) as Texture2D).get_image())
	return _texs[path]


## Pergamena invecchiata: grana, macchie e bordi più scuri. Fatta una volta sola.
static func _paper() -> Texture2D:
	if _paper_tex != null:
		return _paper_tex
	var W := 200
	var H := 300
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 3
	n.frequency = 0.012
	n.fractal_octaves = 4
	var g := FastNoiseLite.new()
	g.seed = 9
	g.frequency = 0.35
	for y in H:
		for x in W:
			var u := float(x) / W - 0.5
			var v := float(y) / H - 0.5
			var edge := clampf((maxf(absf(u) * 2.0, absf(v) * 2.0) - 0.62) / 0.38, 0.0, 1.0)
			var stain := n.get_noise_2d(x, y) * 0.5 + 0.5
			var grain := g.get_noise_2d(x, y) * 0.5 + 0.5
			var c := PAPER.darkened(0.05 + 0.12 * stain * stain + 0.06 * grain + 0.4 * edge * edge)
			c = c.lerp(Color(0.55, 0.38, 0.2), 0.08 * stain)
			img.set_pixel(x, y, c)
	_paper_tex = ImageTexture.create_from_image(img)
	return _paper_tex


# ------------------------------------------------------------------ texture per le carte 3D

## Chi ospita i SubViewport delle texture (l'interfaccia lo imposta all'avvio).
static func set_host(n: Node) -> void:
	_host = n


## La faccia (o il dorso, k < 0) di una carta come texture, per le carte 3D della scena.
static func texture(k: int) -> Texture2D:
	if _tex_cache.has(k):
		return _tex_cache[k]
	if _host == null:
		return null
	var vp := SubViewport.new()
	vp.size = Vector2i(320, 480)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var c := Carta.make(maxi(k, 0), k >= 0, 300)
	c.position = Vector2(10, 15)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp.add_child(c)
	_host.add_child(vp)
	_tex_cache[k] = vp.get_texture()
	return _tex_cache[k]
