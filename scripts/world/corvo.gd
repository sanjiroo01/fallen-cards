class_name Corvo
extends Node3D
## Corvo nero: posato (gira la testa, becca, ogni tanto apre le ali) oppure in volo in cerchio sopra il
## luogo (battiti d'ala e planate). Fatto di forme semplici unite, lungo circa 45 cm (apertura d'ali 1 m).

var flying := false
var center := Vector3.ZERO
var radius := 10.0
var height := 10.0
var speed := 0.12                 # giri al secondo (in radianti: velocità angolare)

var _head: Node3D
var _wings: Array[Node3D] = []
var _t := 0.0
var _angle := 0.0
var _next := 1.0                  # tra quanto fa la prossima mossa (posato)
var _flap := 0.0                  # apertura delle ali (posato)
var _glide := 0.0                 # tempo di planata rimasto (in volo)

static var _mat: StandardMaterial3D
static var _beak: StandardMaterial3D
static var _wing_mat: StandardMaterial3D

## Sagoma dell'ala destra vista dall'alto (x verso l'esterno, z in avanti): bordo d'attacco dritto,
## in punta le "dita" delle penne remiganti aperte, bordo d'uscita sfrangiato.
const WING := [Vector2(0.0, 0.07), Vector2(0.12, 0.085), Vector2(0.26, 0.078), Vector2(0.34, 0.05),
	Vector2(0.47, 0.022), Vector2(0.415, 0.004), Vector2(0.49, -0.018), Vector2(0.425, -0.034),
	Vector2(0.48, -0.058), Vector2(0.405, -0.07), Vector2(0.44, -0.096), Vector2(0.355, -0.092),
	Vector2(0.3, -0.112), Vector2(0.25, -0.1), Vector2(0.19, -0.122), Vector2(0.13, -0.108),
	Vector2(0.07, -0.124), Vector2(0.0, -0.095)]


func build(fly: bool, rng: RandomNumberGenerator) -> Corvo:
	flying = fly
	_t = rng.randf() * 10.0
	_angle = rng.randf() * TAU
	_next = rng.randf_range(0.5, 3.0)
	if _mat == null:
		# piume nere opache, con appena un filo di lucido (niente riflessi da plastica)
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = Color(0.03, 0.03, 0.035)
		_mat.roughness = 0.62
		_mat.metallic_specular = 0.35
		_mat.rim_enabled = true              # la luce della luna sfiora il bordo delle piume nere
		_mat.rim = 0.5
		_mat.rim_tint = 0.6
		_beak = StandardMaterial3D.new()
		_beak.albedo_color = Color(0.045, 0.042, 0.04)
		_beak.roughness = 0.45
		_wing_mat = _mat.duplicate() as StandardMaterial3D
		_wing_mat.cull_mode = BaseMaterial3D.CULL_DISABLED      # ali e coda sono sottili: si vedono da sopra e da sotto
	# corpo allungato, inclinato in avanti come un corvo posato; petto più pieno
	var body := Geo.add(self, Geo.superellipsoid(Vector3(0.105, 0.11, 0.25), 0.75, 0.85, 16, 12), _mat, Vector3(0, 0.13, 0))
	body.rotation.x = -0.42 if not fly else 0.0
	# coda a ventaglio: penne lunghe, aperta in volo, chiusa da posato
	var fan := 1.0 if fly else 0.55
	var tail := Geo.add(self, _flat(PackedVector2Array([Vector2(-0.025, 0.02), Vector2(0.025, 0.02),
		Vector2(0.075 * fan, -0.17), Vector2(0.04 * fan, -0.195), Vector2(0.0, -0.19), Vector2(-0.04 * fan, -0.195),
		Vector2(-0.075 * fan, -0.17)])), _wing_mat, Vector3(0, 0.085 if not fly else 0.13, -0.1))
	tail.rotation.x = -0.6 if not fly else -0.05
	# testa piccola su un collo corto, becco lungo e robusto un po' piegato in giù
	_head = Node3D.new()
	_head.position = Vector3(0, 0.205, 0.095) if not fly else Vector3(0, 0.14, 0.13)
	add_child(_head)
	Geo.add(_head, Geo.superellipsoid(Vector3(0.06, 0.062, 0.085), 0.8, 0.9, 12, 8), _mat, Vector3(0, 0.0, 0.015))
	var beak := Geo.add(_head, Geo.cyl(0.0, 0.0125, 0.068, 8), _beak, Vector3(0, -0.008, 0.085))
	beak.rotation.x = deg_to_rad(90.0) + 0.16          # punta in avanti, appena piegata in giù
	beak.scale = Vector3(0.85, 1.0, 1.3)              # più alto che largo, come il becco di un corvo
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.015, 0.012, 0.01)
	eye.roughness = 0.2
	for sx in [-1.0, 1.0]:
		Geo.add(_head, Geo.sphere(0.006, 6, 4), eye, Vector3(0.028 * sx, 0.01, 0.03), Vector3.ZERO, false)
	# zampe con le dita
	if not fly:
		for sx in [-1.0, 1.0]:
			Geo.add(self, Geo.cyl(0.005, 0.006, 0.08, 5), _beak, Vector3(0.025 * sx, 0.04, 0.01), Vector3.ZERO, false)
			for d in [-0.4, 0.0, 0.4]:
				var toe := Geo.add(self, Geo.cyl(0.003, 0.004, 0.035, 4), _beak, Vector3(0.025 * sx + sin(d) * 0.015, 0.003, 0.025 + cos(d) * 0.012), Vector3.ZERO, false)
				toe.rotation = Vector3(deg_to_rad(90.0), d, 0)
	# ali: chiuse sui fianchi da posato, spiegate in volo; il perno è la spalla. Punte a "dita" di piume.
	for sx in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.045 * sx, 0.17 if not fly else 0.15, 0.06)
		add_child(pivot)
		var outline := PackedVector2Array()
		for q in WING:
			outline.append(Vector2(q.x * sx, q.y))
		if sx < 0.0:
			outline.reverse()
		Geo.add(pivot, _flat(outline), _wing_mat)
		_wings.append(pivot)
	_pose_wings(1.0 if fly else 0.0, 0.0)
	return self


## Ali: open 0 = chiuse lungo il corpo, 1 = spiegate; beat = angolo del battito (radianti).
func _pose_wings(open: float, beat: float) -> void:
	for i in _wings.size():
		var sx := -1.0 if i == 0 else 1.0
		var w := _wings[i]
		w.rotation = Vector3(lerpf(-0.35, 0.0, open), lerpf(1.42 * sx, 0.0, open), lerpf(-0.3 * sx, beat * sx, open))
		w.scale = Vector3(lerpf(0.62, 1.0, open), 1.0, 1.0)      # chiusa, l'ala ripiegata è più corta


func _process(delta: float) -> void:
	_t += delta
	if flying:
		# in cerchio sopra il luogo: battiti d'ala, poi una planata; sale e scende un poco
		_angle += speed * delta
		var p := center + Vector3(sin(_angle) * radius, height + 0.6 * sin(_t * 0.5), cos(_angle) * radius)
		var ahead := center + Vector3(sin(_angle + 0.05) * radius, height, cos(_angle + 0.05) * radius)
		look_at_from_position(p, ahead, Vector3.UP)
		rotate_object_local(Vector3.FORWARD, -0.35)        # inclinato in curva
		rotate_object_local(Vector3.UP, PI)               # il corvo guarda verso +Z
		if _glide > 0.0:
			_glide -= delta
			_pose_wings(1.0, 0.08)
		else:
			_pose_wings(1.0, sin(_t * 9.0) * 0.6)
			if fmod(_t, 4.0) < delta:
				_glide = randf_range(1.2, 2.5)
		return
	# posato: gira la testa, becca, ogni tanto apre e richiude le ali
	_next -= delta
	if _next <= 0.0:
		_next = randf_range(0.8, 3.5)
		var roll := randf()
		if roll < 0.55:
			create_tween().tween_property(_head, "rotation", Vector3(randf_range(-0.2, 0.3), randf_range(-1.2, 1.2), 0), 0.15)
		elif roll < 0.8:
			var tw := create_tween()
			tw.tween_property(_head, "rotation:x", 0.9, 0.12)
			tw.tween_property(_head, "rotation:x", 0.0, 0.18)
		else:
			_flap = 1.2
	if _flap > 0.0:
		_flap -= delta
		var open := clampf(sin(clampf(_flap / 1.2, 0.0, 1.0) * PI) * 1.3, 0.0, 1.0)
		_pose_wings(open * 0.8, sin(_t * 14.0) * 0.5 * open)


## Lamina piatta nel piano orizzontale (x, z) da un contorno, con un filo di spessore al centro.
static func _flat(outline: PackedVector2Array) -> ArrayMesh:
	var idx := Geometry2D.triangulate_polygon(outline)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in idx:
		var q := outline[i]
		st.add_vertex(Vector3(q.x, 0.004 * (1.0 - clampf(absf(q.x) * 4.0, 0.0, 1.0)), q.y))
	st.generate_normals()
	return st.commit()
