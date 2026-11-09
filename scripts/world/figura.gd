class_name Figura
extends Node3D
## Un posto nel cerchio: il campione fatto di forme semplici (prototipo), le sue candele a terra,
## le scritte sopra la testa e le animazioni di ogni mossa.
## Il nodo sta sul cerchio e guarda il centro (-Z locale verso il centro).

const CANDLE_SCALE := 2.2

var cls := 0
var color := Color.WHITE
var label_name := ""
var is_me := false              # il tuo campione: niente scritte davanti alla telecamera
var actor := Node3D.new()        # la parte che si muove (le candele restano ferme): da seduto, il busto con perno all'anca
var _corpo := Node3D.new()        # il corpo costruito "in piedi", abbassato sulla sedia dentro l'actor
var _gambe := Node3D.new()        # cosce, stinchi e tunica sulle ginocchia: ferme sulla sedia
var _robe_m: StandardMaterial3D

## Seduti (2/11/2026): seduta di pietra a 42 cm, il corpo in piedi scende di SIT_DROP, il busto ruota attorno all'anca.
const SIT_DROP := 0.33
const HIP_Y := 0.54
const SIT_BACK := 0.04             # l'anca e' 4 cm dietro il punto del posto (la schiena davanti allo schienale)
var candles: Array[Candle] = []
var dragon: Node3D               # solo il domatore

var _meshes: Array[MeshInstance3D] = []
var _mats := {}                  # MeshInstance3D -> materiale originale
var _ghost := false
var _name_lbl: Label3D
var _move_lbl: Label3D
var _order_lbl: Label3D
var _state_lbl: Label3D
var _gem: MeshInstance3D
var _gem_mat: StandardMaterial3D
var _shield: MeshInstance3D
var _shield_mat: StandardMaterial3D
var _aura: MeshInstance3D
var _aura_mat: StandardMaterial3D
var _ring_mat: StandardMaterial3D
var _t := randf() * 10.0
var _tired := 0.0
var drag := 0.0                    # di quanti metri le catene tese lo trascinano verso l'altare (le calcola l'arena)
var _belt_rings: Array[Node3D] = []  # punti d'aggancio delle catene sugli anelli della cintura


func build(class_id: int, name_text: String, font: Font) -> Figura:
	cls = class_id
	color = Testi.CLASSI[cls]["colore"]
	label_name = name_text
	add_child(actor)
	actor.position = Vector3(0, HIP_Y, SIT_BACK)
	actor.add_child(_corpo)
	_corpo.position.y = -(SIT_DROP + HIP_Y)
	add_child(_gambe)
	_body()
	match cls:
		CerchioRules.Cls.CAVALIERE: _knight()
		CerchioRules.Cls.STREGA: _witch()
		CerchioRules.Cls.ELFO: _elf()
		CerchioRules.Cls.DOMATORE: _tamer()
		4: _priestess()
		5: _plague()
		6: _gravedigger()
		7: _gladiator()
	_belt()
	_legs()
	for n in actor.find_children("*", "MeshInstance3D", true, false) + _gambe.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		_meshes.append(mi)
		_mats[mi] = mi.material_override
	# anello di luce ai piedi, nel colore del campione
	_ring_mat = Mats.emissive(color, 0.7)
	Geo.add(self, Geo.torus(0.5, 0.54, 48, 6), _ring_mat, Vector3(0, 0.01, 0), Vector3.ZERO, false)
	# gemma dell'abilità: accesa finché l'abilità è disponibile
	_gem_mat = Mats.emissive(color, 3.0)
	_gem = Geo.add(_corpo, Geo.sphere(0.045, 4, 2), _gem_mat, Vector3(0.38, 1.75, 0), Vector3.ZERO, false)
	# scudo della difesa e aura del giuramento
	_shield_mat = Mats.emissive(color, 1.6)
	_shield_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shield_mat.albedo_color = Color(color, 0.06)
	_shield_mat.emission_energy_multiplier = 0.25
	_shield_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shield = Geo.add(self, Geo.cyl(0.42, 0.42, 0.01, 32), _shield_mat, Vector3.ZERO, Vector3.ZERO, false)
	var rim := Geo.add(_shield, Geo.torus(0.4, 0.44, 40, 6), Mats.emissive(color, 3.0), Vector3.ZERO, Vector3.ZERO, false)
	rim.name = "Bordo"
	_shield.visible = false
	_aura_mat = Mats.emissive(Color(1.0, 0.82, 0.35), 1.2)
	_aura_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_aura_mat.albedo_color = Color(1, 0.8, 0.3, 0.12)
	_aura = Geo.add(_corpo, Geo.sphere(0.95, 24, 12), _aura_mat, Vector3(0, 0.95, 0), Vector3.ZERO, false)
	_aura.visible = false
	_name_lbl = _label(font, 72, Vector3(0, 2.1 - SIT_DROP, 0), color.lerp(Color.WHITE, 0.5))
	_set_text(_name_lbl, name_text)
	_move_lbl = _label(font, 72, Vector3(0, 2.55 - SIT_DROP, 0), Color(1, 0.93, 0.8))
	_order_lbl = _label(font, 110, Vector3(0, 2.95 - SIT_DROP, 0), Color(1, 0.8, 0.4))
	_state_lbl = _label(font, 64, Vector3(0, 1.88 - SIT_DROP, 0), Color(0.75, 0.8, 1.0))
	# corpo invisibile per il mouse: passandoci sopra si apre la scheda del campione
	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = 2.2
	cs.shape = cap
	cs.position = Vector3(0, 1.1 - SIT_DROP, 0)
	body.add_child(cs)
	body.set_meta("figura", self)
	add_child(body)
	return self


func _label(font: Font, size: int, pos: Vector3, c: Color) -> Label3D:
	var l := Label3D.new()
	l.font = font
	l.font_size = size
	l.pixel_size = 0.0019
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = c
	l.outline_size = 14
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.no_depth_test = true
	l.render_priority = 2
	l.outline_render_priority = 1
	l.position = pos
	add_child(l)
	return l


static var _halo_tex: GradientTexture2D


## Alone scuro e morbido dietro una scritta: si legge sopra il fuoco e i muri chiari.
## Bordi sfumati, quindi si può allungare quanto serve senza deformarsi.
func _halo(l: Label3D) -> void:
	if _halo_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0.8))
		g.set_color(1, Color(0, 0, 0, 0.0))
		g.add_point(0.6, Color(0, 0, 0, 0.7))
		_halo_tex = GradientTexture2D.new()
		_halo_tex.gradient = g
		_halo_tex.fill = GradientTexture2D.FILL_RADIAL
		_halo_tex.fill_from = Vector2(0.5, 0.5)
		_halo_tex.fill_to = Vector2(0.5, 0.0)
		_halo_tex.width = 128
		_halo_tex.height = 128
	var h: Sprite3D = l.get_node_or_null("Alone")
	if h == null:
		h = Sprite3D.new()
		h.name = "Alone"
		h.texture = _halo_tex
		h.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		h.no_depth_test = true
		h.shaded = false
		h.render_priority = 0
		h.pixel_size = 0.01
		l.add_child(h)
	h.visible = l.text != ""
	if l.text == "":
		return
	var sz := l.font.get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_CENTER, -1, l.font_size)
	var w := sz.x * l.pixel_size * 1.7 + 0.25
	var hh := sz.y * l.pixel_size * 1.9 + 0.12
	h.scale = Vector3(w / 1.28, hh / 1.28, 1.0)


func _set_text(l: Label3D, t: String) -> void:
	l.text = t
	_halo(l)


# ------------------------------------------------------------------ forme

func _body() -> void:
	var robe := Mats.matte(color.darkened(0.72), 0.85)
	robe.rim_enabled = true
	robe.rim = 0.5
	robe.rim_tint = 0.7
	_robe_m = robe
	var prof := PackedVector2Array([Vector2(0.0, 0.8), Vector2(0.27, 0.8), Vector2(0.25, 0.9),
		Vector2(0.21, 1.25), Vector2(0.26, 1.36), Vector2(0.2, 1.46), Vector2(0.0, 1.47)])
	Geo.add(_corpo, Geo.lathe(prof, 24), robe)
	# braccia
	for s in [-1.0, 1.0]:
		var arm := Geo.add(_corpo, Geo.capsule(0.065, 0.62), robe, Vector3(0.29 * s, 1.08, -0.04), Vector3(10, 0, 8 * s))
		arm.name = "Braccio%s" % ("D" if s > 0 else "S")
	# testa scura con occhi che brillano
	Geo.add(_corpo, Geo.sphere(0.135), Mats.matte(Color(0.16, 0.13, 0.12)), Vector3(0, 1.6, 0))
	var eye := Mats.emissive(color.lerp(Color.WHITE, 0.3), 4.0)
	for s in [-1.0, 1.0]:
		Geo.add(_corpo, Geo.sphere(0.018, 8, 4), eye, Vector3(0.045 * s, 1.62, -0.12), Vector3.ZERO, false)


func _knight() -> void:
	var steel := Mats.matte(Color(0.55, 0.58, 0.62), 0.35)
	steel.metallic = 0.9
	Geo.add(_corpo, Geo.cyl(0.15, 0.15, 0.2, 20), steel, Vector3(0, 1.66, 0))
	Geo.add(_corpo, Geo.sphere(0.152, 20, 10), steel, Vector3(0, 1.76, 0))
	Geo.add(_corpo, Geo.box(Vector3(0.6, 0.12, 0.3)), steel, Vector3(0, 1.4, 0))       # spallacci
	# spada alzata nella mano destra
	var sword := Node3D.new()
	sword.position = Vector3(0.36, 0.85, -0.18)
	sword.rotation_degrees = Vector3(-20, 0, 0)
	_corpo.add_child(sword)
	Geo.add(sword, Geo.box(Vector3(0.05, 0.85, 0.012)), steel, Vector3(0, 0.5, 0))
	Geo.add(sword, Geo.box(Vector3(0.22, 0.03, 0.04)), Mats.matte(Color(0.5, 0.4, 0.15), 0.4), Vector3(0, 0.08, 0))
	Geo.add(sword, Geo.cyl(0.018, 0.018, 0.14), Mats.matte(Color(0.15, 0.08, 0.05)), Vector3(0, 0.0, 0))
	# scudo sul braccio sinistro
	var sh := Geo.add(_corpo, Geo.cyl(0.24, 0.24, 0.04, 6), Mats.matte(color.darkened(0.3), 0.5),
		Vector3(-0.36, 0.95, -0.12), Vector3(90, 0, 0))
	sh.rotation_degrees = Vector3(80, -20, 0)


func _witch() -> void:
	var dark := Mats.matte(Color(0.08, 0.05, 0.1))
	Geo.add(_corpo, Geo.cyl(0.42, 0.42, 0.02, 32), dark, Vector3(0, 1.7, 0))           # tesa
	var hat := Geo.add(_corpo, Geo.cyl(0.0, 0.17, 0.62, 20), dark, Vector3(0.04, 2.0, 0.03))
	hat.rotation_degrees = Vector3(-8, 0, -10)
	# bastone con la sfera viola
	Geo.add(_corpo, Geo.cyl(0.02, 0.025, 1.7, 8), Mats.matte(Color(0.2, 0.12, 0.07)), Vector3(0.4, 0.85, -0.15))
	Geo.add(_corpo, Geo.sphere(0.08), Mats.emissive(color, 3.5), Vector3(0.4, 1.74, -0.15), Vector3.ZERO, false)


func _elf() -> void:
	var hood := Mats.matte(color.darkened(0.55))
	var h := Geo.add(_corpo, Geo.cyl(0.02, 0.19, 0.42, 20), hood, Vector3(0, 1.72, 0.03))
	h.rotation_degrees = Vector3(12, 0, 0)
	# orecchie a punta
	for s in [-1.0, 1.0]:
		Geo.add(_corpo, Geo.cyl(0.0, 0.03, 0.16, 6), Mats.matte(Color(0.3, 0.25, 0.2)),
			Vector3(0.15 * s, 1.64, 0), Vector3(0, 0, -70 * s))
	# arco e faretra
	var bow := Geo.add(_corpo, Geo.torus(0.55, 0.58, 32, 6), Mats.matte(Color(0.35, 0.22, 0.1), 0.6),
		Vector3(-0.38, 1.05, -0.2), Vector3(0, 0, 90))
	bow.scale = Vector3(1, 1, 0.35)
	Geo.add(_corpo, Geo.cyl(0.07, 0.06, 0.5, 12), Mats.matte(Color(0.25, 0.15, 0.08)), Vector3(0.12, 1.25, 0.24), Vector3(-15, 0, 20))


func _tamer() -> void:
	var horn := Mats.matte(Color(0.8, 0.75, 0.6), 0.5)
	Geo.add(_corpo, Geo.sphere(0.15, 20, 10), Mats.matte(Color(0.25, 0.12, 0.06), 0.6), Vector3(0, 1.66, 0))
	for s in [-1.0, 1.0]:
		Geo.add(_corpo, Geo.cyl(0.0, 0.04, 0.26, 8), horn, Vector3(0.15 * s, 1.8, 0), Vector3(0, 0, -40 * s))
	# il drago sulla spalla
	dragon = Node3D.new()
	dragon.position = Vector3(-0.38, 1.5, 0.05)
	_corpo.add_child(dragon)
	var scale_m := Mats.matte(Color(0.45, 0.1, 0.05), 0.5)
	Geo.add(dragon, Geo.capsule(0.07, 0.3), scale_m, Vector3.ZERO, Vector3(90, 0, 0))
	Geo.add(dragon, Geo.sphere(0.07), scale_m, Vector3(0, 0.08, -0.17))
	Geo.add(dragon, Geo.cyl(0.0, 0.04, 0.12, 6), scale_m, Vector3(0, 0.06, -0.27), Vector3(-90, 0, 0))
	for s in [-1.0, 1.0]:
		var w := Geo.add(dragon, Geo.box(Vector3(0.32, 0.01, 0.18)), scale_m, Vector3(0.18 * s, 0.06, 0.02), Vector3(0, 0, 25 * s))
		w.name = "Ala"
	var eye := Mats.emissive(Color(1, 0.7, 0.1), 5.0)
	for s in [-1.0, 1.0]:
		Geo.add(dragon, Geo.sphere(0.012, 6, 3), eye, Vector3(0.035 * s, 0.11, -0.22), Vector3.ZERO, false)


# i campioni in più per le partite da 5 a 8 (22/10): sagome provvisorie come le altre, finché non arrivano i
# personaggi veri

func _priestess() -> void:
	var cloth := Mats.matte(color.darkened(0.6))
	var cowl := Geo.add(_corpo, Geo.cyl(0.05, 0.2, 0.46, 20), cloth, Vector3(0, 1.7, 0.03))
	cowl.rotation_degrees = Vector3(8, 0, 0)
	# velo che scende sulle spalle e medaglione di bronzo
	Geo.add(_corpo, Geo.cyl(0.2, 0.3, 0.32, 20), cloth, Vector3(0, 1.38, 0.02))
	var bronze := Mats.matte(Color(0.45, 0.3, 0.12), 0.45)
	bronze.metallic = 0.8
	Geo.add(_corpo, Geo.torus(0.035, 0.05, 16, 6), bronze, Vector3(0, 1.22, -0.25), Vector3(90, 0, 0))


func _plague() -> void:
	var dark := Mats.matte(Color(0.07, 0.06, 0.06), 0.6)
	Geo.add(_corpo, Geo.cyl(0.33, 0.33, 0.02, 32), dark, Vector3(0, 1.74, 0))           # tesa larga
	Geo.add(_corpo, Geo.cyl(0.14, 0.15, 0.18, 20), dark, Vector3(0, 1.84, 0))
	# maschera col becco, lenti tonde
	var mask := Mats.matte(Color(0.42, 0.36, 0.28), 0.5)
	Geo.add(_corpo, Geo.cyl(0.0, 0.06, 0.3, 12), mask, Vector3(0, 1.57, -0.26), Vector3(-90 - 12, 0, 0))
	for s in [-1.0, 1.0]:
		Geo.add(_corpo, Geo.torus(0.022, 0.034, 12, 4), Mats.matte(Color(0.2, 0.18, 0.14), 0.4), Vector3(0.05 * s, 1.63, -0.125), Vector3(90, 0, 0))
	# bastone
	Geo.add(_corpo, Geo.cyl(0.015, 0.02, 1.4, 8), Mats.matte(Color(0.12, 0.08, 0.05)), Vector3(0.38, 0.7, -0.15))


func _gravedigger() -> void:
	var cap := Mats.matte(Color(0.18, 0.15, 0.12))
	Geo.add(_corpo, Geo.cyl(0.16, 0.17, 0.08, 20), cap, Vector3(0, 1.72, 0))
	Geo.add(_corpo, Geo.cyl(0.23, 0.23, 0.015, 24), cap, Vector3(0, 1.69, -0.04))
	# la vanga, appoggiata alla spalla
	var spade := Node3D.new()
	spade.position = Vector3(0.36, 0.2, -0.1)
	spade.rotation_degrees = Vector3(0, 0, 8)
	_corpo.add_child(spade)
	Geo.add(spade, Geo.cyl(0.02, 0.022, 1.3, 8), Mats.matte(Color(0.25, 0.17, 0.1)), Vector3(0, 0.75, 0))
	var blade := Mats.matte(Color(0.3, 0.29, 0.27), 0.45)
	blade.metallic = 0.7
	Geo.add(spade, Geo.box(Vector3(0.2, 0.26, 0.015)), blade, Vector3(0, 0.03, 0))


func _gladiator() -> void:
	var bronze := Mats.matte(Color(0.5, 0.36, 0.16), 0.4)
	bronze.metallic = 0.85
	Geo.add(_corpo, Geo.sphere(0.155, 20, 10), bronze, Vector3(0, 1.64, 0))
	Geo.add(_corpo, Geo.box(Vector3(0.04, 0.12, 0.32)), Mats.matte(color.darkened(0.2), 0.8), Vector3(0, 1.82, 0.02))   # cresta
	Geo.add(_corpo, Geo.box(Vector3(0.24, 0.1, 0.26)), bronze, Vector3(-0.2, 1.38, 0), Vector3(0, 0, 20))              # spallaccio
	var sh := Geo.add(_corpo, Geo.cyl(0.26, 0.26, 0.04, 24), Mats.matte(color.darkened(0.35), 0.6), Vector3(-0.38, 0.95, -0.12))
	sh.rotation_degrees = Vector3(80, -20, 0)


## La cintura: fascia di cuoio scuro alla vita, borchie e nove anelli di ferro davanti e sui fianchi, dove si
## agganciano le catene. È figlia del corpo che si muove, così segue respiro, strattoni e cadute.
const BELT_Y := 0.9
const BELT_R := 0.247
const BELT_ORDER := [0, 1, -1, 2, -2, 3, -3, 4, -4]   # prima il centro davanti, poi verso i fianchi


func _belt() -> void:
	var belt := Node3D.new()
	belt.name = "Cintura"
	belt.position = Vector3(0, BELT_Y, 0)
	_corpo.add_child(belt)
	var band := PackedVector2Array([Vector2(BELT_R - 0.006, -0.03), Vector2(BELT_R + 0.008, -0.03),
		Vector2(BELT_R + 0.011, -0.022), Vector2(BELT_R + 0.011, 0.022), Vector2(BELT_R + 0.008, 0.03),
		Vector2(BELT_R - 0.006, 0.03)])
	Geo.add(belt, Geo.lathe(band, 40), Mats.worn_leather())
	var iron := Mats.rust_iron(8.0)
	# fibbia di ferro dietro e borchie lungo la fascia
	Geo.add(belt, Geo.box(Vector3(0.07, 0.066, 0.014)), iron, Vector3(0, 0, BELT_R + 0.012))
	for k in 16:
		var a := TAU * (k + 0.5) / 16.0
		Geo.add(belt, Geo.sphere(0.008, 8, 4), iron, Vector3(sin(a), 0, cos(a)) * (BELT_R + 0.012), Vector3.ZERO, false)
	# anelli: piastrina ribattuta sulla fascia e anello che pende (piano verticale, rivolto verso l'altare)
	var ring_mesh := Geo.torus(0.016, 0.026, 16, 6)
	for k in BELT_ORDER.size():
		var a := PI + float(BELT_ORDER[k]) * 0.36            # davanti è -Z (verso l'altare)
		var n := Vector3(sin(a), 0, cos(a))
		var side := Vector3.UP.cross(n).normalized()
		var plate := Geo.add(belt, Geo.box(Vector3(0.03, 0.03, 0.008)), iron, n * (BELT_R + 0.013))
		plate.look_at_from_position(plate.position, plate.position + n, Vector3.UP)
		var ring := Geo.add(belt, ring_mesh, iron, n * (BELT_R + 0.022) + Vector3(0, -0.032, 0))
		# toro nel piano di "n" e "su": il suo asse è il fianco
		ring.basis = Basis(n, side, Vector3.UP)
		var hook := Node3D.new()
		hook.position = n * (BELT_R + 0.03) + Vector3(0, -0.055, 0)     # il fondo dell'anello: lì passa la catena
		belt.add_child(hook)
		_belt_rings.append(hook)



## Le gambe sedute (sagoma provvisoria): cosce sulla seduta, ginocchia oltre il bordo, stinchi giu' fino a terra,
## la tunica che scende dalle ginocchia. -Z e' verso il tavolo.
func _legs() -> void:
	var robe := _robe_m
	var dark := Mats.matte(Color(0.1, 0.085, 0.075), 0.9)
	# grembo: la tunica tesa sulle cosce
	Geo.add(_gambe, Geo.box(Vector3(0.44, 0.15, 0.5)), robe, Vector3(0, HIP_Y + 0.01, SIT_BACK - 0.21))
	for s in [-1.0, 1.0]:
		# coscia (capsula orizzontale) e ginocchio
		Geo.add(_gambe, Geo.capsule(0.085, 0.52), robe, Vector3(0.105 * s, HIP_Y, SIT_BACK - 0.2), Vector3(90, 0, 0))
		# stinco verticale e piede
		Geo.add(_gambe, Geo.capsule(0.062, 0.5), robe, Vector3(0.105 * s, 0.26, SIT_BACK - 0.43), Vector3(4, 0, 0))
		Geo.add(_gambe, Geo.box(Vector3(0.1, 0.07, 0.22)), dark, Vector3(0.105 * s, 0.035, SIT_BACK - 0.5))
	# la tunica che ricade davanti agli stinchi
	Geo.add(_gambe, Geo.box(Vector3(0.46, 0.42, 0.04)), robe, Vector3(0, 0.3, SIT_BACK - 0.5), Vector3(4, 0, 0))

## Dove si aggancia la catena k (0 = davanti al centro) sulla cintura, in coordinate del mondo.
func belt_anchor(k: int) -> Vector3:
	if _belt_rings.is_empty():
		return _corpo.global_position + Vector3(0, BELT_Y, 0)
	return _belt_rings[clampi(k, 0, _belt_rings.size() - 1)].global_position


## Le candele a terra davanti al campione.
func build_candles(n: int) -> void:
	for c in candles:
		c.queue_free()
	candles.clear()
	for i in n:
		var c := Candle.new()
		c.height = 0.16 + 0.03 * randf()
		c.energy = 0.55
		c.light_range = 2.2
		c.shadows = false
		c.build()
		c.scale = Vector3.ONE * CANDLE_SCALE
		var a := (float(i) - (n - 1) * 0.5) * 0.36
		c.position = Vector3(sin(a) * 0.95, 0, -cos(a) * 0.95 + 0.0)
		if is_me:
			# le tue candele ai lati, così il tuo campione (visto da dietro) non le copre
			var side := -1.0 if i < n / 2 else 1.0
			var k := i if i < n / 2 else n - 1 - i
			c.position = Vector3(side * (0.55 + 0.3 * k), 0, -0.45 + 0.25 * k)
		add_child(c)
		candles.append(c)


## Accende tante candele quante sono le vite (con un piccolo ritardo per ogni spegnimento).
func show_candles(lives: float, animated := true) -> void:
	var n := int(ceil(lives))
	for i in candles.size():
		var on := i < n
		if candles[i].lit == on:
			continue
		if not animated:
			candles[i].set_lit_instant(on)
		elif on:
			candles[i].relight()
		else:
			candles[i].blow_out()


# ------------------------------------------------------------------ stato e scritte

func set_ability(available: bool) -> void:
	_gem.visible = available and not _ghost


func set_tired(on: bool) -> void:
	_state_lbl.text = "STANCO" if on else ""
	var tw := create_tween()
	tw.tween_property(self, "_tired", 1.0 if on else 0.0, 0.5)


func set_move_text(t: String) -> void:
	_set_text(_move_lbl, t)
	# la mossa ha un colore suo, diverso dal nome: rossa l'attacco, azzurra la difesa, oro il resto
	if t.begins_with("Attacca"):
		_move_lbl.modulate = Color(1.0, 0.55, 0.45)
	elif t.begins_with("Si difende"):
		_move_lbl.modulate = Color(0.6, 0.82, 1.0)
	else:
		_move_lbl.modulate = Color(1.0, 0.85, 0.5)
	if t != "":
		_move_lbl.scale = Vector3.ONE * 0.3
		create_tween().tween_property(_move_lbl, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)


## Scritta piccola sotto il nome (Catene dell'altare: quante catene ha, "libero", "scoperto"...).
func set_state_text(t: String, c := Color(0.75, 0.8, 1.0)) -> void:
	_state_lbl.text = t
	_state_lbl.modulate = c


## Brucia e vola via con l'altare: sale prendendo fuoco e sparisce.
## Portato via dall'altare che vola: ancora incatenato, sale con lui (l'altezza la decide l'arena) e, se brucia,
## prende fuoco. Sparisce quando è in alto, fuori dalla scena.
var carried := false


var slump := 0.0                   # 0 in piedi, 1 accasciato contro il tavolo (bruciato)


## Brucia al suo posto (dal 22/10 l'altare non porta più via nessuno): si annerisce con la brace sotto, si accascia
## in avanti contro il tavolo e resta lì, carbonizzato e ancora in catene, fino alla manche dopo.
func burn_in_place() -> void:
	# carbone vero, non una sagoma arancione: la stessa brace dei ceppi del falò (crepe che pulsano su nero opaco),
	# viva mentre brucia e poi sempre più spenta
	var ember := ShaderMaterial.new()
	ember.shader = load("res://shaders/brace.gdshader")
	ember.set_shader_parameter("heat", 0.0)
	for mi in _meshes:
		mi.material_override = ember
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: ember.set_shader_parameter("heat", v), 0.0, 1.1, 1.2)
	tw.parallel().tween_property(self, "slump", 1.0, 1.3).set_delay(0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_interval(2.6)
	tw.tween_method(func(v: float) -> void: ember.set_shader_parameter("heat", v), 1.1, 0.18, 3.5)


func carry_away(fire: bool) -> void:
	carried = true
	labels(false)
	if fire:
		_ignite()


func _ignite() -> void:
	# si annerisce e si accende piano (prima: tutto arancione pieno da subito, una sagoma piatta senza volume)
	var tw := create_tween()
	for mi in _meshes:
		if mi.material_override is StandardMaterial3D:
			var m := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			m.albedo_color = m.albedo_color.darkened(0.6)
			m.emission_enabled = true
			m.emission = Color(0.95, 0.24, 0.04)
			m.emission_energy_multiplier = 0.0
			mi.material_override = m
			tw.parallel().tween_property(m, "emission_energy_multiplier", 0.7, 1.4)


func burn_away() -> void:
	var tw := create_tween()
	for mi in _meshes:
		if mi.material_override is StandardMaterial3D:
			var m := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			m.albedo_color = m.albedo_color.darkened(0.6)
			m.emission_enabled = true
			m.emission = Color(0.95, 0.24, 0.04)
			m.emission_energy_multiplier = 0.0
			mi.material_override = m
			tw.parallel().tween_property(m, "emission_energy_multiplier", 0.7, 1.4)
	labels(false)
	tw.tween_property(self, "position:y", 5.0, 2.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(actor, "scale", Vector3.ONE * 0.2, 2.6)
	await tw.finished
	visible = false


## Torna com'era a inizio manche (dopo un rogo o un'eliminazione).
func reset_for_manche() -> void:
	visible = true
	carried = false
	slump = 0.0
	position.y = 0.0
	actor.scale = Vector3.ONE
	set_ghost(false)
	for mi in _meshes:
		mi.material_override = _mats[mi]
	clear_pose()
	set_state_text("")
	labels(true)


func set_order(n: int) -> void:
	_order_lbl.text = "" if n <= 0 else str(n)


func set_name_text(t: String) -> void:
	_set_text(_name_lbl, t)


func highlight(on: bool) -> void:
	_ring_mat.emission_energy_multiplier = 2.4 if on else 0.7


func chest() -> Vector3:
	return _corpo.global_position + Vector3(0, 1.15, 0)


# ------------------------------------------------------------------ animazioni

func _process(delta: float) -> void:
	_t += delta
	if _ghost:
		actor.position.y = HIP_Y + 0.35 + sin(_t * 1.3) * 0.08
		return
	var breath := sin(_t * 1.6) * 0.012
	var strain := sin(_t * 7.0) * 0.01 * minf(drag * 4.0, 1.0)     # resiste, a strattoni
	actor.position.y = HIP_Y + (breath - _tired * 0.04) * (1.0 - slump) - 0.06 * slump
	if drag > 0.001:                # solo quando le catene tirano: non disturba gli scatti delle altre animazioni
		actor.position.z = SIT_BACK - minf(drag, 0.12) + strain     # seduto: scivola poco in avanti sulla sedia
	# seduto si piega in avanti dall'anca; bruciato si accascia sul tavolo
	actor.rotation.x = (-_tired * 0.15 - minf(drag * 0.9, 0.45)) * (1.0 - slump) - 0.75 * slump
	if dragon:
		for w in dragon.get_children():
			if w.name.begins_with("Ala"):
				w.rotation.z = (0.4 + sin(_t * 9.0) * 0.25) * signf(w.position.x)


## Scatto verso un punto e ritorno: l'attacco di base.
func lunge(target: Vector3, amount := 0.45, dur := 0.55) -> void:
	var start := actor.position
	var local_t := to_local(target)
	local_t.y = 0.0
	var dst := start + local_t * amount
	var tw := create_tween()
	tw.tween_property(actor, "position", start + (start - dst) * 0.12, dur * 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_property(actor, "position", dst, dur * 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_property(actor, "position", start, dur * 0.5).set_trans(Tween.TRANS_SINE)
	await tw.finished


## Colpo subito: lampo e rinculo.
func hurt() -> void:
	for mi in _meshes:
		if mi.material_override is StandardMaterial3D and mi.material_override != _gem_mat:
			var m := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			m.emission_enabled = true
			m.emission = Color(1, 0.15, 0.1)
			m.emission_energy_multiplier = 2.0
			mi.material_override = m
	var tw := create_tween()
	tw.tween_property(actor, "rotation:x", 0.35, 0.08)
	tw.tween_property(actor, "rotation:x", 0.0, 0.35).set_trans(Tween.TRANS_ELASTIC)
	await get_tree().create_timer(0.18).timeout
	if not _ghost:
		for mi in _meshes:
			mi.material_override = _mats[mi]


## Scudo rivolto verso chi si teme.
func defend_toward(target: Vector3) -> void:
	var p := global_position + (target - global_position).normalized() * 0.55 + Vector3(0, 1.05 - SIT_DROP, 0)
	_shield.global_position = p
	_shield.look_at(target + Vector3(0, 1.05 - SIT_DROP, 0), Vector3.UP)
	_shield.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	_shield.visible = true
	_shield.scale = Vector3.ONE * 0.2
	create_tween().tween_property(_shield, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)


func shield_flash() -> void:
	var tw := create_tween()
	tw.tween_property(_shield_mat, "emission_energy_multiplier", 2.0, 0.08)
	tw.tween_property(_shield_mat, "emission_energy_multiplier", 0.25, 0.4)


func shield_fade() -> void:
	if not _shield.visible:
		return
	var tw := create_tween()
	tw.tween_property(_shield, "scale", Vector3.ONE * 0.01, 0.35)
	tw.tween_callback(func() -> void: _shield.visible = false)


func oath(on: bool) -> void:
	_aura.visible = on
	if on:
		_aura.scale = Vector3.ONE * 0.3
		create_tween().tween_property(_aura, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK)


func clear_pose() -> void:
	shield_fade()
	oath(false)
	set_move_text("")
	set_order(0)


## Muore: si accascia e torna come spettro.
func die() -> void:
	var tw := create_tween()
	tw.tween_property(actor, "rotation:x", -0.8, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(actor, "position:y", HIP_Y - 0.05, 0.6)
	await tw.finished
	set_ghost(true)


func set_ghost(on: bool) -> void:
	_ghost = on
	var gm := Mats.ghost()
	gm.set_shader_parameter("tint", color.lerp(Color(0.4, 0.7, 0.85), 0.6))
	for mi in _meshes:
		mi.material_override = gm if on else _mats[mi]
	actor.rotation = Vector3.ZERO
	_ring_mat.emission_energy_multiplier = 0.15 if on else 0.7
	_gem.visible = _gem.visible and not on
	set_tired(false)
	_set_text(_name_lbl, label_name + ("  (spettro)" if on else ""))


## Mostra o nasconde le scritte sopra la testa (spente sotto i pannelli e nel menu).
func labels(on: bool) -> void:
	for l in [_name_lbl, _move_lbl, _order_lbl, _state_lbl]:
		l.visible = on and not is_me
	if is_me:
		_order_lbl.visible = on       # le tue catene sono nel riquadro in basso: qui coprivano gli annunci
	if _fan:
		_fan.visible = on and not is_me and not _ghost


# ------------------------------------------------------------------ carte in mano (visibili a tutti)

var _fan: Node3D
var _fan_lbl: Label3D
var _fan_cards: Array[MeshInstance3D] = []


## Ventaglio di carte coperte accanto al campione: tutti vedono quante ne ha, non quali.
func set_cards(n: int) -> void:
	if _fan == null:
		_fan = Node3D.new()
		_fan.position = Vector3(-0.55, 1.55, 0.0)
		add_child(_fan)
		var back := Mats.matte(Color(0.25, 0.03, 0.03), 0.6)
		back.emission_enabled = true
		back.emission = Color(0.5, 0.06, 0.03)
		back.emission_energy_multiplier = 0.8
		for k in 6:
			var c := Geo.add(_fan, Geo.box(Vector3(0.13, 0.19, 0.006)), back, Vector3.ZERO, Vector3.ZERO, false)
			c.visible = false
			_fan_cards.append(c)
		_fan_lbl = Label3D.new()
		_fan_lbl.font = _name_lbl.font
		_fan_lbl.font_size = 44
		_fan_lbl.pixel_size = 0.0019
		_fan_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_fan_lbl.no_depth_test = true
		_fan_lbl.outline_size = 10
		_fan_lbl.modulate = Color(1.0, 0.8, 0.55)
		_fan_lbl.position = Vector3(0, -0.2, 0)
		_fan.add_child(_fan_lbl)
	var shown := mini(n, _fan_cards.size())
	for k in _fan_cards.size():
		var c := _fan_cards[k]
		var was := c.visible
		c.visible = k < shown
		var a := (float(k) - (shown - 1) * 0.5) * 0.28
		c.position = Vector3(sin(a) * 0.09, cos(a) * 0.09 - 0.09, k * 0.004)
		c.rotation = Vector3(0, 0, -a)
		if c.visible and not was:
			c.scale = Vector3.ONE * 0.1
			create_tween().tween_property(c, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	_fan_lbl.text = "%d carte" % n if n != 1 else "1 carta"
	_fan_lbl.visible = n > 0 and not _ghost
	_fan.visible = not _ghost and not is_me


## Il ventaglio guarda sempre la telecamera.
func face_fan(cam: Vector3) -> void:
	if _fan:
		_fan.look_at(cam, Vector3.UP)
		_fan.rotate_object_local(Vector3.UP, PI)
