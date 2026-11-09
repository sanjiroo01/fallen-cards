class_name Stile
extends RefCounted
## Lo stile dell'interfaccia, disegnato al volo (niente immagini esterne): cornici scure con doppio bordo
## dorato e angoli ornati, pulsanti con la grana del cuoio, testi con ombra.
## Le immagini sono piccole e si allungano come "nove fette": gli angoli restano nitidi.

const GOLD := Color(0.86, 0.68, 0.36)
const GOLD_DIM := Color(0.5, 0.38, 0.2)

static var _cache := {}


# ------------------------------------------------------------------ caratteri
# Due famiglie (21/10, l'utente non era soddisfatto delle scritte): IM Fell, stampa antica con l'inchiostro
# irregolare, per la voce del gioco (titoli, annunci, nomi delle carte, il Custode), in minuscolo e senza numeri
# (le sue cifre sono piccole e il suo "1" sembra una I). Tutto ciò che si legge per decidere è EB Garamond, con
# numeri moderni (lnum). Cinzel Decorative non si usa più: unisce le lettere ("LE", "MANCHE").

static func _var(path: String, weight: int, features: Array, spacing := 0) -> FontVariation:
	var key := "f%s%d%s%d" % [path, weight, features, spacing]
	if not _cache.has(key):
		var ts := TextServerManager.get_primary_interface()
		var fv := FontVariation.new()
		fv.base_font = load(path)
		fv.variation_opentype = {ts.name_to_tag("wght"): weight}
		var feats := {}
		for f in features:
			feats[ts.name_to_tag(f)] = 1
		fv.opentype_features = feats
		fv.spacing_glyph = spacing
		_cache[key] = fv
	return _cache[key]


## Titoli e annunci (menu, fine manche, scritte al centro, carte): la voce del gioco.
static func font_title() -> Font:
	if not _cache.has("ftitle"):
		_cache["ftitle"] = load("res://fonts/IMFell.ttf")
	return _cache["ftitle"]


## La voce del Custode e le frasi d'atmosfera.
static func font_voice() -> Font:
	if not _cache.has("fvoice"):
		_cache["fvoice"] = load("res://fonts/IMFell-Italic.ttf")
	return _cache["fvoice"]


## Intestazioni, nomi, pulsanti: semigrassetto, lettere un po' distanziate (il maiuscoletto rovina i numeri).
static func font_head() -> Font:
	return _var("res://fonts/EBGaramond.ttf", 600, ["lnum"], 1)


## Testo normale.
static func font_body() -> Font:
	return _var("res://fonts/EBGaramond.ttf", 500, ["lnum"])


static func font_italic() -> Font:
	return _var("res://fonts/EBGaramond-Italic.ttf", 500, ["lnum"])


## Numeri grandi (candele perse, conto alla rovescia): spessi e netti.
static func font_num() -> Font:
	return _var("res://fonts/EBGaramond.ttf", 800, ["lnum"])


## Cornice dei pannelli: fondo quasi nero, angoli appena smussati, un solo filo sottile color bronzo
## (prima: doppio filo d'oro su ogni riquadro, tutti con lo stesso peso).
static func panel(alpha := 0.88) -> StyleBoxTexture:
	var key := "p%s" % alpha
	if not _cache.has(key):
		var s := 64
		var rad := 6.0
		var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
		var h := s * 0.5
		for y in s:
			for x in s:
				var qx := absf(x + 0.5 - h) - (h - rad)
				var qy := absf(y + 0.5 - h) - (h - rad)
				var d := Vector2(maxf(qx, 0.0), maxf(qy, 0.0)).length() + minf(maxf(qx, qy), 0.0) - rad + 0.5
				var cov := clampf(0.5 - d, 0.0, 1.0)
				if cov <= 0.0:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
					continue
				var c := Color(0.045, 0.035, 0.032).lerp(Color(0.02, 0.016, 0.016), float(y) / s)
				c.a = alpha
				var ring := clampf(1.0 - absf(d + 1.0) / 0.9, 0.0, 1.0) * 0.7
				c = c.lerp(Color(GOLD_DIM, 1.0), ring)
				c.a = maxf(c.a, ring) * cov
				img.set_pixel(x, y, c)
		var tb := StyleBoxTexture.new()
		tb.texture = ImageTexture.create_from_image(img)
		tb.set_texture_margin_all(10)
		tb.set_content_margin_all(20)
		_cache[key] = tb
	return _cache[key]


## Pulsante tondo (a pillola): cuoio scuro con grana, filo d'oro lungo il bordo, luce in alto.
## kind: "normal", "hover", "pressed", "disabled".
static func button(kind: String) -> StyleBoxTexture:
	var key := "b" + kind
	if not _cache.has(key):
		var top := Color(0.12, 0.085, 0.065)
		var bot := Color(0.06, 0.045, 0.038)
		var edge := GOLD_DIM
		match kind:
			"hover":
				top = Color(0.24, 0.14, 0.08)
				bot = Color(0.12, 0.07, 0.045)
				edge = GOLD
			"pressed":
				top = Color(0.1, 0.06, 0.04)
				bot = Color(0.22, 0.12, 0.07)
				edge = GOLD
			"disabled":
				top = Color(0.1, 0.09, 0.09)
				bot = Color(0.06, 0.05, 0.05)
				edge = Color(0.25, 0.22, 0.2)
		_cache[key] = _pill(top, bot, edge, edge.darkened(0.4), 0.96, true)
	return _cache[key]


## Disegna una pillola: angoli tondi con bordo sfumato (niente scalini), filo esterno e filo interno.
static func _pill(top: Color, bot: Color, edge: Color, inner: Color, alpha: float, grain: bool) -> StyleBoxTexture:
	# angoli appena smussati e un solo filo: le pillole con doppio filo e riflesso sembravano un modello web
	var s := 48
	var rad := 5.0
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var h := s * 0.5
	for y in s:
		for x in s:
			var qx := absf(x + 0.5 - h) - (h - rad)
			var qy := absf(y + 0.5 - h) - (h - rad)
			var d := Vector2(maxf(qx, 0.0), maxf(qy, 0.0)).length() + minf(maxf(qx, qy), 0.0) - rad + 0.5
			var cov := clampf(0.5 - d, 0.0, 1.0)          # quanto il pixel sta dentro la forma
			if cov <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var c := top.lerp(bot, float(y) / s)
			if grain:
				c = c * (0.95 + rng.randf() * 0.1)           # grana leggera
			c = c.lerp(inner, clampf(1.0 - absf(d + 3.0) / 0.8, 0.0, 1.0) * 0.35)
			c = c.lerp(edge, clampf(1.0 - absf(d + 1.0) / 1.0, 0.0, 1.0))
			c.a = alpha * cov
			img.set_pixel(x, y, c)
	var tb := StyleBoxTexture.new()
	tb.texture = ImageTexture.create_from_image(img)
	tb.set_texture_margin_all(9)
	tb.content_margin_left = 24
	tb.content_margin_right = 24
	tb.content_margin_top = 9
	tb.content_margin_bottom = 9
	return tb


static func _frame(img: Image, s: int, inset: int, outer: Color, inner: Color) -> void:
	for i in s:
		for d in [inset, s - 1 - inset]:
			img.set_pixel(i, d, outer)
			img.set_pixel(d, i, outer)
		for d in [inset + 3, s - 4 - inset]:
			if i > inset + 2 and i < s - inset - 3:
				img.set_pixel(i, d, inner)
				img.set_pixel(d, i, inner)


static func _corners(img: Image, s: int) -> void:
	for cx in [5, s - 6]:
		for cy in [5, s - 6]:
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					if absi(dx) + absi(dy) <= 3:
						img.set_pixel(cx + dx, cy + dy, GOLD if absi(dx) + absi(dy) <= 1 else GOLD_DIM)


## Maiuscoletto spaziato per voci di menu, etichette e il pulsante principale.
static func font_caps() -> Font:
	return _var("res://fonts/EBGaramond.ttf", 600, ["lnum"], 4)


## Voce del menu: nessun riquadro; sotto il mouse un filo d'oro a sinistra, un velo caldo e il testo che rientra.
static func nav(kind: String) -> StyleBoxFlat:
	var key := "nav" + kind
	if not _cache.has(key):
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0, 0, 0, 0)
		s.content_margin_left = 0
		s.content_margin_right = 12
		s.content_margin_top = 6
		s.content_margin_bottom = 6
		if kind in ["hover", "focus", "pressed"]:
			s.bg_color = Color(1.0, 0.75, 0.4, 0.07)
			s.border_width_left = 3
			s.border_color = Color(1.0, 0.8, 0.45, 0.95)
			s.content_margin_left = 18
		_cache[key] = s
	return _cache[key]


## Il pulsante principale (Gioca): rosso scurissimo, filo d'oro, si scalda sotto il mouse.
static func primary(kind: String) -> StyleBoxFlat:
	var key := "pri" + kind
	if not _cache.has(key):
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.3, 0.06, 0.035)
		s.border_color = Color(0.86, 0.62, 0.3)
		s.set_border_width_all(2)
		s.set_corner_radius_all(3)
		s.shadow_color = Color(0, 0, 0, 0.5)
		s.shadow_size = 10
		if kind in ["hover", "focus"]:
			s.bg_color = Color(0.46, 0.1, 0.05)
			s.border_color = Color(1.0, 0.82, 0.5)
			s.shadow_color = Color(0.9, 0.3, 0.08, 0.35)
			s.shadow_size = 18
		elif kind == "pressed":
			s.bg_color = Color(0.22, 0.04, 0.025)
		_cache[key] = s
	return _cache[key]


## Le frecce delle scelte (‹ ›): quasi invisibili, si accendono sotto il mouse.
static func arrow(kind: String) -> StyleBoxFlat:
	var key := "arr" + kind
	if not _cache.has(key):
		var s := StyleBoxFlat.new()
		s.bg_color = Color(1, 1, 1, 0.03)
		s.set_corner_radius_all(3)
		s.border_color = Color(GOLD_DIM, 0.6)
		s.set_border_width_all(1)
		if kind in ["hover", "focus"]:
			s.bg_color = Color(1.0, 0.7, 0.35, 0.12)
			s.border_color = GOLD
		_cache[key] = s
	return _cache[key]


## Foglio dei pannelli grandi (nuova partita, impostazioni): nero caldo quasi pieno, un filo d'oro solo in alto.
static func sheet() -> StyleBoxFlat:
	if not _cache.has("sheet"):
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.035, 0.026, 0.024, 0.9)
		s.border_width_top = 2
		s.border_color = Color(0.86, 0.62, 0.3, 0.9)
		s.set_content_margin_all(36)
		s.shadow_color = Color(0, 0, 0, 0.5)
		s.shadow_size = 30
		_cache["sheet"] = s
	return _cache["sheet"]


## Contorno del pulsante scelto con la tastiera (Tab, frecce): visibile ma sottile.
static func focus() -> StyleBoxFlat:
	if not _cache.has("focus"):
		var f := StyleBoxFlat.new()
		f.draw_center = false
		f.set_border_width_all(2)
		f.border_color = Color(1.0, 0.86, 0.55, 0.9)
		f.set_corner_radius_all(6)
		f.set_expand_margin_all(3)
		_cache["focus"] = f
	return _cache["focus"]


## Ombra morbida dietro le scritte al centro dello schermo: un'ellisse scura che sfuma ai bordi.
static func soft_shadow() -> StyleBoxTexture:
	if not _cache.has("soft"):
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0.72))
		g.add_point(0.6, Color(0, 0, 0, 0.5))
		g.set_color(g.get_point_count() - 1, Color(0, 0, 0, 0.0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(0.5, 0.0)
		t.width = 128
		t.height = 128
		var sb := StyleBoxTexture.new()
		sb.texture = t
		sb.content_margin_top = 36
		sb.content_margin_bottom = 36
		sb.content_margin_left = 120
		sb.content_margin_right = 120
		_cache["soft"] = sb
	return _cache["soft"]


## Ombra sotto il testo: si legge su qualsiasi sfondo.
static func shadow(c: Control) -> void:
	c.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	c.add_theme_constant_override("shadow_offset_x", 2)
	c.add_theme_constant_override("shadow_offset_y", 2)
	c.add_theme_constant_override("shadow_outline_size", 4)


## Scheda scelta: fondo più caldo e bordo d'oro acceso (tonda come i pulsanti).
static func card_selected() -> StyleBoxTexture:
	if not _cache.has("sel"):
		_cache["sel"] = _pill(Color(0.32, 0.17, 0.08), Color(0.14, 0.07, 0.04), Color(1.0, 0.82, 0.45), GOLD, 0.97, false)
	return _cache["sel"]


## Targhetta piccola (ordine dei colpi, nomi): fondo scuro, bordo nel colore del campione; la tua più calda.
static func tag(col: Color, me := false) -> StyleBoxTexture:
	var key := "t%s%s" % [col.to_html(), me]
	if not _cache.has(key):
		var top := Color(0.24, 0.13, 0.06) if me else Color(0.09, 0.07, 0.07)
		var bot := Color(0.11, 0.06, 0.03) if me else Color(0.035, 0.03, 0.03)
		var edge := Color(1.0, 0.82, 0.45) if me else col.lerp(Color.WHITE, 0.15)
		var tb := _pill(top, bot, edge, edge.darkened(0.55), 0.9, false)
		tb.content_margin_left = 16
		tb.content_margin_right = 18
		tb.content_margin_top = 4
		tb.content_margin_bottom = 4
		_cache[key] = tb
	return _cache[key]
