class_name Scenari
extends RefCounted
## I luoghi della partita, costruiti da regole e da un seme: ogni partita è diversa (posizione degli alberi,
## delle rocce, dei tronchi caduti), ma lo stesso seme ridà lo stesso luogo.
## Materiali fotografici e oggetti scansionati da Poly Haven (CC0, elenco in assets/scenari/FONTI.txt);
## gli alberi sono costruiti qui, con la corteccia vera. Le forme ripetute si fondono in poche mesh.

const SAFE_R := 3.9      # dentro questo raggio niente ostacoli: ci sono il cerchio e i campioni
const TEX := "res://assets/scenari/texture/%s/%s_%s_2k.jpg"
const PROP := "res://assets/scenari/modelli/%s.glb"

static var _mats := {}
static var _scenes := {}


static func build(host: Node3D, scenario: int, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	match scenario:
		1:
			_cemetery(host, rng)
		2:
			_crypt(host, rng)
		3:
			_frozen_lake(host, rng)
		_:
			_forest(host, rng)


# ------------------------------------------------------------------ attrezzi

## Materiale fotografico (colore, rilievo, ruvidezza) proiettato dall'alto e dai lati: niente UV da preparare.
static func pbr(id: String, tile: float, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "%s_%s_%s" % [id, tile, tint]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(TEX % [id, id, "diff"])
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = load(TEX % [id, id, "nor_gl"])
	m.roughness_texture = load(TEX % [id, id, "rough"])
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / tile
	m.uv1_triplanar_sharpness = 4.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = m
	return m


## Un oggetto scansionato, posato a terra.
static func prop(host: Node3D, id: String, pos: Vector3, rot_y := 0.0, s := 1.0) -> Node3D:
	if not _scenes.has(id):
		_scenes[id] = load(PROP % id)
	var ps: PackedScene = _scenes[id]
	if ps == null:
		return null
	var n: Node3D = ps.instantiate()
	host.add_child(n)
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * s
	return n


## Unisce pezzi [mesh, Transform3D] in una sola mesh con un solo materiale.
static func _merge(parts: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in parts:
		var m: Mesh = p[0]
		st.append_from(m, 0, p[1])
	st.generate_normals()
	return st.commit()


static func _seg(a: Vector3, b: Vector3, r0: float, r1: float, sides := 6) -> Array:
	var n := Node3D.new()
	Geo.orient_between(n, a, b)
	var t := n.transform
	n.free()
	return [Geo.cyl(r1, r0, a.distance_to(b), sides, false), t]


static func _add(host: Node3D, mesh: Mesh, mat: Material, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(mi)
	return mi


## Punto a caso su un anello, lontano dagli angoli vietati [[angolo, ampiezza], ...].
static func _ring_point(rng: RandomNumberGenerator, r0: float, r1: float, avoid: Array = []) -> Vector3:
	for i in 40:
		var a := rng.randf() * TAU
		var ok := true
		for av in avoid:
			if absf(wrapf(a - av[0], -PI, PI)) < av[1]:
				ok = false
		if ok:
			var d := rng.randf_range(r0, r1)
			return Vector3(sin(a) * d, 0, cos(a) * d)
	return Vector3(0, 0, r1)


## Punto i di n distribuito a spicchi sull'anello (con un po' di caso dentro lo spicchio): copre tutto il giro.
static func _strat(rng: RandomNumberGenerator, i: int, n: int, off: float, r0: float, r1: float, avoid: Array) -> Vector3:
	for tries in 12:
		var a := off + TAU * (i + rng.randf_range(0.1, 0.9)) / n
		var ok := true
		for av in avoid:
			if absf(wrapf(a - av[0], -PI, PI)) < av[1]:
				ok = false
		if ok:
			var d := rng.randf_range(r0, r1)
			return Vector3(sin(a) * d, 0, cos(a) * d)
	return _ring_point(rng, r0, r1, avoid)


## Trasformazione per un elemento del bosco: rotazione e grandezza a caso, leggera inclinazione.
static func _tf(p: Vector3, rng: RandomNumberGenerator, s0: float, s1: float) -> Transform3D:
	var b := Basis(Vector3.UP, rng.randf() * TAU)
	b = b.rotated(Vector3(1, 0, 0), rng.randf_range(-0.04, 0.04)).rotated(Vector3(0, 0, 1), rng.randf_range(-0.04, 0.04))
	return Transform3D(b.scaled(Vector3.ONE * rng.randf_range(s0, s1)), p)


## Tante copie dello stesso modello in un solo oggetto (MultiMesh): centinaia di alberi senza appesantire.
## Le foglie sono ritagli con trasparenza: le si rende "a forbice" (nette, senza problemi di ordine).
static var _multi_mesh := {}


static func _multi(host: Node3D, id: String, xforms: Array, shadow: bool) -> void:
	if xforms.is_empty():
		return
	if not _multi_mesh.has(id):
		var ps: PackedScene = load("res://assets/scenari/vegetazione_cc0/%s.glb" % id)
		var inst := ps.instantiate()
		var mi: MeshInstance3D = inst.find_children("*", "MeshInstance3D", true, false)[0]
		var mesh: Mesh = mi.mesh.duplicate()
		for i in mesh.get_surface_count():
			var m := mesh.surface_get_material(i)
			if m is BaseMaterial3D:
				var mm := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
				mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				mm.alpha_scissor_threshold = 0.4
				mm.cull_mode = BaseMaterial3D.CULL_DISABLED
				# aghi e foglie più cupi; la corteccia resta chiara, come i tronchi alla luna
				var bark := mm.resource_name.ends_with("corteccia")
				mm.albedo_color = mm.albedo_color * (Color(1.5, 1.5, 1.5) if bark else Color(0.75, 0.78, 0.78))
				# vicino alla telecamera la vegetazione si dissolve: non copre mai la vista
				mm.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
				mm.distance_fade_min_distance = 1.2
				mm.distance_fade_max_distance = 3.0
				mesh.surface_set_material(i, mm)
		inst.free()
		_multi_mesh[id] = mesh
	var mm3 := MultiMesh.new()
	mm3.transform_format = MultiMesh.TRANSFORM_3D
	mm3.mesh = _multi_mesh[id]
	mm3.instance_count = xforms.size()
	for i in xforms.size():
		mm3.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm3
	if not shadow:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(mmi)


## Altezza del punto più basso del terreno sotto un oggetto largo r: così niente resta sospeso.
static func _low(noise: FastNoiseLite, p: Vector3, bumps: float, r: float) -> float:
	var y := _height(noise, p, bumps)
	for k in 8:
		var a := TAU * k / 8.0
		y = minf(y, _height(noise, p + Vector3(sin(a), 0, cos(a)) * r, bumps))
	return y


## Terreno con rilievi fuori dal cerchio (dentro resta piano).
static func _terrain(host: Node3D, rng: RandomNumberGenerator, mat: Material, bumps: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.07
	noise.fractal_octaves = 3
	var pm := PlaneMesh.new()
	pm.size = Vector2(150, 150)
	pm.subdivide_width = 190
	pm.subdivide_depth = 190
	var st := SurfaceTool.new()
	st.create_from(pm, 0)
	var mdt := MeshDataTool.new()
	mdt.create_from_surface(st.commit(), 0)
	for i in mdt.get_vertex_count():
		var v := mdt.get_vertex(i)
		v.y = _height(noise, v, bumps)
		mdt.set_vertex(i, v)
	var out := ArrayMesh.new()
	mdt.commit_to_surface(out)
	var st2 := SurfaceTool.new()
	st2.create_from(out, 0)
	st2.generate_normals()
	st2.generate_tangents()
	_add(host, st2.commit(), mat)
	return noise


static func _height(noise: FastNoiseLite, p: Vector3, bumps: float) -> float:
	var r := Vector2(p.x, p.z).length()
	var k := smoothstep(SAFE_R + 0.5, 12.0, r)
	return (noise.get_noise_2d(p.x, p.z) * 0.6 + 0.35) * bumps * k + k * k * 0.8 + _hills(p.x, p.z)


## Colline lontane tutto attorno: chiudono l'orizzonte (coperte di bosco e sfumate nella foschia).
static func _hills(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	var a := atan2(x, z)
	var wave := 0.75 + 0.25 * sin(a * 3.0 + 1.3) + 0.15 * sin(a * 7.0)
	return smoothstep(20.0, 55.0, r) * 11.0 * wave


## Bosco lontano sulle colline (senza ombre: costa poco), per tutti i luoghi tranne il lago.
static func _far_forest(host: Node3D, rng: RandomNumberGenerator, ground: Callable, r0: float) -> void:
	var list: Array = []
	for k in 420:
		var p: Vector3 = _strat(rng, k, 420, rng.randf() * TAU, r0, 68.0, [])
		p.y = ground.call(p.x, p.z) - 0.3
		list.append(_tf(p, rng, 1.0, 1.6))
	_multi(host, "pino_lontano", list, false)


# ------------------------------------------------------------------ foresta cupa

static func _forest(host: Node3D, rng: RandomNumberGenerator) -> void:
	var bumps := 1.4
	var noise := _terrain(host, rng, pbr("forest_leaves_02", 2.2, Color(0.75, 0.72, 0.65)), bumps)
	var h := func(p: Vector3) -> Vector3: return Vector3(p.x, _height(noise, p, bumps), p.z)
	var behind := [[PI, 0.3]]          # dietro il Custode resta un varco scuro
	# bosco vero (pini costruiti da materiale CC0, tools/blender/vegetazione_alberi.py), disegnati tutti insieme
	var trees := {"pino_alto": [], "pino_basso": [], "pino_medio": []}
	for k in 46:      # primo anello, vicino al cerchio: si vedono bene
		var p: Vector3 = h.call(_strat(rng, k, 46, 0.2, 6.2, 13.0, behind))
		var kind: String = ["pino_alto", "pino_alto", "pino_basso", "pino_medio"][rng.randi() % 4]
		trees[kind].append(_tf(p - Vector3(0, 0.2, 0), rng, 0.8, 1.25))
	for k in 160:     # bosco fitto dietro, che sparisce nella nebbia
		var p: Vector3 = h.call(_strat(rng, k, 160, 0.7, 13.0, 30.0, []))
		trees["pino_alto" if rng.randf() < 0.7 else "pino_basso"].append(_tf(p - Vector3(0, 0.2, 0), rng, 0.9, 1.4))
	for kind in trees:
		_multi(host, kind, trees[kind], true)
	_far_forest(host, rng, func(x: float, z: float) -> float: return _height(noise, Vector3(x, 0, z), bumps), 30.0)
	# sottobosco: cespugli, ortiche, arbusti ed erba (Poly Haven)
	var avoid_ring := [[0.0, 0.25], [PI * 0.5, 0.25], [PI, 0.3], [-PI * 0.5, 0.25]]
	for spec in [["cespuglio_a", 26, 4.6, 14.0, 1.0], ["cespuglio_b", 26, 4.6, 14.0, 1.0],
			["arbusto_a", 30, 4.4, 12.0, 3.0], ["arbusto_b", 18, 5.0, 13.0, 2.0],
			["erba_a", 90, 4.2, 12.0, 3.0], ["erba_b", 90, 4.2, 12.0, 1.2]]:
		var list: Array = []
		var off := rng.randf() * TAU
		for i in spec[1]:
			var p: Vector3 = h.call(_strat(rng, i, spec[1], off, spec[2], spec[3], avoid_ring))
			list.append(_tf(p - Vector3(0, 0.03, 0), rng, spec[4] * 0.8, spec[4] * 1.25))
		_multi(host, spec[0], list, false)
	# massi veri attorno al cerchio, appoggiati al terreno (nessuno davanti ai posti dei campioni)
	for k in 8:
		var a := TAU * k / 8.0 + PI / 8.0 + rng.randf_range(-0.15, 0.15)
		if absf(wrapf(a - PI, -PI, PI)) < 0.3:
			continue
		var d := rng.randf_range(5.0, 5.8)
		var q := Vector3(sin(a) * d, 0, cos(a) * d)
		var sc := rng.randf_range(0.55, 0.8)
		q.y = _low(noise, q, bumps, 0.8 * sc) - 0.1
		prop(host, "boulder_01", q, rng.randf() * TAU, sc)
	# oggetti veri, distribuiti a spicchi tutto intorno (nessuna zona vuota): tronchi caduti, ceppi,
	# radici, rocce col muschio, massi, rami secchi, felci
	var avoid_seats := [[0.0, 0.32], [PI * 0.5, 0.32], [PI, 0.38], [-PI * 0.5, 0.32]]
	for spec in [["dead_tree_trunk_02", 3, 6.0, 10.0, 1.0], ["dead_tree_trunk", 3, 5.5, 9.5, 1.0],
			["tree_stump_01", 3, 4.8, 8.5, 1.0], ["tree_stump_02", 3, 4.8, 8.5, 1.0],
			["root_cluster_01", 3, 5.5, 9.0, 0.9], ["rock_moss_set_01", 3, 6.5, 11.0, 0.8],
			["rock_moss_set_02", 3, 6.0, 11.0, 0.8], ["boulder_01", 3, 7.0, 12.0, 1.2],
			["dry_branches_medium_01", 12, 4.3, 9.5, 1.0], ["fern_02", 48, 4.3, 11.0, 1.0]]:
		var off := rng.randf() * TAU
		for i in spec[1]:
			var p: Vector3 = _strat(rng, i, spec[1], off, spec[2], spec[3], avoid_seats)
			p.y = _low(noise, p, bumps, 0.9 * spec[4]) - 0.08
			prop(host, spec[0], p, rng.randf() * TAU, spec[4] * rng.randf_range(0.85, 1.2))
	# storia: un campione che ha perso, accanto alle sue candele spente e alla sua lanterna
	var lost := h.call(_ring_point(rng, 5.6, 6.4, avoid_seats)) as Vector3
	prop(host, "wooden_candlestick", lost + Vector3(0.4, 0, 0.2), 0.3)
	prop(host, "wooden_candlestick", lost + Vector3(-0.3, 0, 0.35), 1.2)
	var bones := [] as Array
	for j in 7:
		bones.append([Geo.sphere(0.07 + 0.04 * rng.randf(), 8, 5), Transform3D(Basis().scaled(Vector3(1.4, 0.6, 0.8)).rotated(Vector3.UP, rng.randf() * TAU), lost + Vector3(rng.randf_range(-0.5, 0.5), 0.05, rng.randf_range(-0.5, 0.5)))])
	bones.append([Geo.sphere(0.11, 12, 8), Transform3D(Basis(), lost + Vector3(0.1, 0.1, -0.1))])
	_add(host, _merge(bones), Mats.matte(Color(0.5, 0.46, 0.38), 0.75))
	# fuochi fatui
	for k in 6:
		_wisp(host, rng, _ring_point(rng, 5.5, 11.0) + Vector3(0, rng.randf_range(0.8, 2.4), 0))
	# notte nel bosco: vento fra i pini, grilli, un gufo, lupi lontani, tronchi che scricchiolano
	_loop_sound(host, "foresta", -5.0)
	_falling_leaves(host)


## Ramo ricorsivo: si divide due o tre volte, sempre più sottile e storto.
static func _branch(parts: Array, a: Vector3, dir: Vector3, len: float, r: float, depth: int,
		rng: RandomNumberGenerator) -> void:
	# il tronco non è dritto: due tratti leggermente piegati
	var mid := a + dir * len * 0.5 + Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15)) * len * 0.15
	var b := mid + (dir + Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))).normalized() * len * 0.5
	parts.append(_seg(a, mid, r, r * 0.8, 8 if depth > 1 else 5))
	parts.append(_seg(mid, b, r * 0.8, r * 0.6, 8 if depth > 1 else 5))
	if depth <= 0:
		return
	var n := 2 if depth < 3 else 3
	for i in n:
		var side := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 0.5), rng.randf_range(-1, 1)).normalized()
		var nd := (dir * 0.5 + side * 0.8).normalized()
		var start := mid.lerp(b, rng.randf_range(0.2, 1.0))
		_branch(parts, start, nd, len * rng.randf_range(0.45, 0.62), r * 0.5, depth - 1, rng)


static func _wisp(host: Node3D, rng: RandomNumberGenerator, at: Vector3) -> void:
	var n := Node3D.new()
	host.add_child(n)
	n.position = at
	Geo.add(n, Geo.sphere(0.04, 8, 4), Mats.emissive(Color(0.5, 1.0, 0.9), 6.0), Vector3.ZERO, Vector3.ZERO, false)
	var l := OmniLight3D.new()
	l.light_color = Color(0.4, 0.95, 0.85)
	l.light_energy = 0.6
	l.omni_range = 2.2
	n.add_child(l)
	var tw := n.create_tween().set_loops()
	for i in 4:
		var to := at + Vector3(rng.randf_range(-1.2, 1.2), rng.randf_range(-0.4, 0.4), rng.randf_range(-1.2, 1.2))
		tw.tween_property(n, "position", to, rng.randf_range(2.5, 4.5)).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "position", at, 3.0).set_trans(Tween.TRANS_SINE)


# ------------------------------------------------------------------ cimitero dimenticato

## Lapidi, croci, obelischi e un mausoleo in pietra muschiosa vera; cancello di ferro scansionato,
## recinzione, pini e tronchi veri, qualche candela accesa sulle tombe. Ogni partita le tombe cambiano.
static func _cemetery(host: Node3D, rng: RandomNumberGenerator) -> void:
	var bumps := 0.7
	var wet := pbr("mud_forest", 2.0, Color(0.5, 0.48, 0.45)).duplicate() as StandardMaterial3D
	wet.roughness = 0.45          # bagnato dalla pioggia: lucido, riflette candele e fulmini
	var noise := _terrain(host, rng, wet, bumps)
	var h := func(p: Vector3) -> Vector3: return Vector3(p.x, _height(noise, p, bumps), p.z)
	var stone := pbr("mossy_rock", 0.7, Color(0.72, 0.72, 0.7))
	var dark_stone := pbr("castle_wall_varriation", 1.2, Color(0.55, 0.55, 0.56))
	var avoid := [[0.0, 0.3], [PI * 0.5, 0.3], [-PI * 0.5, 0.3], [PI, 0.42]]
	var graves: Array = []
	var perches: Array = []
	# tombe a file irregolari, come in un vecchio cimitero
	for row in 5:
		var r := 5.2 + row * 1.5 + rng.randf_range(-0.2, 0.2)
		var n := int(TAU * r / 1.35)
		var off := rng.randf() * TAU
		for i in n:
			var a := off + TAU * i / n + rng.randf_range(-0.06, 0.06)
			var bad := false
			for av in avoid:
				if absf(wrapf(a - av[0], -PI, PI)) < av[1] * (5.2 / r) + 0.08:
					bad = true
			if bad or rng.randf() < 0.18:
				continue
			var p: Vector3 = h.call(Vector3(sin(a) * r, 0, cos(a) * r))
			var face := atan2(-p.x, -p.z)          # guardano il cerchio
			var lean := Basis(Vector3.UP, face + rng.randf_range(-0.25, 0.25))
			lean = lean.rotated(Vector3(cos(face), 0, -sin(face)), rng.randf_range(-0.22, 0.22))
			lean = lean.rotated(Vector3(sin(face), 0, cos(face)), rng.randf_range(-0.12, 0.12))
			p.y = _low(noise, p, bumps, 0.4) - 0.12
			_grave(graves, rng.randi() % 6, lean, p, rng, perches)
	_add(host, _merge(graves), stone)
	# mausoleo alle spalle del cerchio, con il cancello di ferro come porta
	var maus: Array = []
	var mz := -11.0
	var base := _low(noise, Vector3(0, 0, mz), bumps, 2.5) - 0.2
	maus.append([Geo.box(Vector3(5.2, 0.5, 4.4)), Transform3D(Basis(), Vector3(0, base + 0.25, mz))])
	maus.append([Geo.box(Vector3(4.6, 3.6, 3.8)), Transform3D(Basis(), Vector3(0, base + 2.3, mz - 0.1))])
	maus.append([Geo.box(Vector3(5.0, 0.35, 4.2)), Transform3D(Basis(), Vector3(0, base + 4.25, mz - 0.1))])
	maus.append([Geo.cyl(0.0, 3.2, 1.6, 4, true), Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.8)).rotated(Vector3.UP, PI * 0.25), Vector3(0, base + 5.2, mz - 0.1))])
	for sx in [-1.0, 1.0]:
		maus.append([Geo.cyl(0.25, 0.3, 3.6, 12, true), Transform3D(Basis(), Vector3(1.75 * sx, base + 2.3, mz + 1.95))])
	maus.append([Geo.box(Vector3(1.4, 0.6, 0.2)), Transform3D(Basis(), Vector3(0, base + 4.75, mz + 1.95))])
	_add(host, _merge(maus), dark_stone)
	prop(host, "large_iron_gate", Vector3(0, base + 0.5, mz + 1.92), 0.0, 0.62)
	for sx in [-1.0, 1.0]:
		_flame_post(host, Vector3(1.75 * sx, base + 4.3, mz + 2.2))
	# recinzione di ferro attorno, interrotta dal cancello davanti
	var bars: Array = []
	var fr := 13.5
	var nb := 260
	for i in nb:
		var a := TAU * i / nb
		if absf(wrapf(a, -PI, PI)) < 0.12:
			continue
		var p: Vector3 = h.call(Vector3(sin(a) * fr, 0, cos(a) * fr))
		bars.append([Geo.cyl(0.018, 0.018, 1.9, 6, false), Transform3D(Basis(), p + Vector3(0, 0.95, 0))])
		bars.append([Geo.cyl(0.0, 0.035, 0.14, 4, true), Transform3D(Basis(), p + Vector3(0, 1.97, 0))])
		if i % 13 == 0:
			bars.append([Geo.box(Vector3(0.14, 2.1, 0.14)), Transform3D(Basis(), p + Vector3(0, 1.05, 0))])
	for k in 2:
		var y := 0.35 + k * 1.3
		for i in 120:
			var a0 := TAU * i / 120
			var a1 := TAU * (i + 1) / 120
			if absf(wrapf(a0, -PI, PI)) < 0.12 or absf(wrapf(a1, -PI, PI)) < 0.12:
				continue
			var p0: Vector3 = h.call(Vector3(sin(a0) * fr, 0, cos(a0) * fr)) + Vector3(0, y, 0)
			var p1: Vector3 = h.call(Vector3(sin(a1) * fr, 0, cos(a1) * fr)) + Vector3(0, y, 0)
			bars.append(_seg(p0, p1, 0.015, 0.015, 4))
	var iron := Mats.matte(Color(0.06, 0.055, 0.05), 0.45)
	iron.metallic = 0.85
	_add(host, _merge(bars), iron)
	prop(host, "large_iron_gate", h.call(Vector3(0, 0, fr)) - Vector3(0, 0.05, 0), PI, 0.9)
	# alberi: pochi pini neri dentro, bosco fitto oltre la recinzione
	var trees := {"pino_alto": [], "pino_basso": []}
	for k in 14:
		var p: Vector3 = h.call(_strat(rng, k, 14, 0.4, 9.5, 12.8, [[PI, 0.5]]))
		trees["pino_basso" if rng.randf() < 0.6 else "pino_alto"].append(_tf(p - Vector3(0, 0.2, 0), rng, 0.8, 1.15))
	for k in 140:
		var p: Vector3 = h.call(_strat(rng, k, 140, 0.9, 15.0, 32.0, []))
		trees["pino_alto"].append(_tf(p - Vector3(0, 0.2, 0), rng, 0.9, 1.4))
	for kind in trees:
		_multi(host, kind, trees[kind], true)
	_far_forest(host, rng, func(x: float, z: float) -> float: return _height(noise, Vector3(x, 0, z), bumps), 32.0)
	var weeds: Array = []
	for k in 160:
		var p: Vector3 = h.call(_strat(rng, k, 160, 0.3, 4.4, 13.2, [[0.0, 0.2], [PI * 0.5, 0.2], [-PI * 0.5, 0.2]]))
		weeds.append(_tf(p - Vector3(0, 0.03, 0), rng, 2.2, 3.6) if k < 80 else _tf(p - Vector3(0, 0.03, 0), rng, 0.9, 1.5))
	_multi(host, "erba_a", weeds.slice(0, 80), false)
	_multi(host, "erba_b", weeds.slice(80), false)
	# tronchi caduti e rami secchi tra le tombe
	for spec in [["dead_tree_trunk", 2, 9.0, 12.5, 1.0], ["dry_branches_medium_01", 8, 5.0, 12.0, 1.0],
			["tree_stump_02", 2, 9.5, 12.5, 1.0]]:
		var off := rng.randf() * TAU
		for i in spec[1]:
			var p: Vector3 = _strat(rng, i, spec[1], off, spec[2], spec[3], avoid)
			p.y = _low(noise, p, bumps, 0.9) - 0.08
			prop(host, spec[0], p, rng.randf() * TAU, spec[4])
	# candele accese su qualche tomba
	var coff := rng.randf() * TAU
	for k in 7:
		var p: Vector3 = _strat(rng, k, 7, coff, 5.0, 8.5, avoid)
		p.y = _height(noise, p, bumps)
		prop(host, "wooden_candlestick", p, rng.randf() * TAU, 1.3)
		_flame_post(host, p + Vector3(0, 0.3, 0))
	for k in 4:
		_wisp(host, rng, _ring_point(rng, 6.0, 12.0) + Vector3(0, rng.randf_range(0.6, 1.8), 0))
	rain(host)
	_loop_sound(host, "cimitero", -6.0)        # corvi, un cancello che cigola
	lightning(host)


## Una tomba: 0 lapide arrotondata, 1 croce, 2 obelisco, 3 lastra a terra, 4 lapide alta, 5 croce celtica.
static func _grave(parts: Array, kind: int, b: Basis, p: Vector3, rng: RandomNumberGenerator, perches: Array = []) -> void:
	var s := rng.randf_range(0.85, 1.2)
	if kind == 0 or kind == 4:          # cima piatta o tonda: un corvo ci si può posare
		perches.append([p + b * Vector3(0, (0.645 if kind == 0 else 1.075) * s - 0.01, 0), b])
	match kind:
		0:
			parts.append([Geo.superellipsoid(Vector3(0.32, 0.45, 0.07) * s, 0.25, 0.2, 16, 12), Transform3D(b, p + b * Vector3(0, 0.42 * s, 0))])
			parts.append([Geo.superellipsoid(Vector3(0.4, 0.08, 0.16) * s, 0.2, 0.2, 12, 6), Transform3D(b, p + b * Vector3(0, 0.05, 0))])
		1:
			parts.append([Geo.superellipsoid(Vector3(0.07, 0.55, 0.07) * s, 0.2, 0.2, 10, 8), Transform3D(b, p + b * Vector3(0, 0.55 * s, 0))])
			parts.append([Geo.superellipsoid(Vector3(0.3, 0.07, 0.07) * s, 0.2, 0.2, 10, 6), Transform3D(b, p + b * Vector3(0, 0.78 * s, 0))])
			parts.append([Geo.superellipsoid(Vector3(0.25, 0.1, 0.2) * s, 0.2, 0.2, 10, 6), Transform3D(b, p + b * Vector3(0, 0.06, 0))])
		2:
			parts.append([Geo.box(Vector3(0.5, 0.3, 0.5) * s), Transform3D(b, p + b * Vector3(0, 0.15 * s, 0))])
			parts.append([Geo.cyl(0.12 * s, 0.2 * s, 1.5 * s, 4, true), Transform3D(b.rotated(Vector3.UP, PI * 0.25), p + b * Vector3(0, 1.05 * s, 0))])
			parts.append([Geo.cyl(0.0, 0.12 * s, 0.25 * s, 4, true), Transform3D(b.rotated(Vector3.UP, PI * 0.25), p + b * Vector3(0, 1.92 * s, 0))])
		3:
			parts.append([Geo.superellipsoid(Vector3(0.42, 0.12, 0.95) * s, 0.25, 0.2, 12, 8), Transform3D(b, p + b * Vector3(0, 0.08, 0))])
			parts.append([Geo.superellipsoid(Vector3(0.3, 0.32, 0.06) * s, 0.25, 0.2, 12, 8), Transform3D(b, p + b * Vector3(0, 0.32 * s, -0.9 * s))])
		4:
			parts.append([Geo.superellipsoid(Vector3(0.28, 0.75, 0.09) * s, 0.15, 0.15, 12, 10), Transform3D(b, p + b * Vector3(0, 0.7 * s, 0))])
		5:
			parts.append([Geo.superellipsoid(Vector3(0.08, 0.6, 0.08) * s, 0.2, 0.2, 10, 8), Transform3D(b, p + b * Vector3(0, 0.6 * s, 0))])
			parts.append([Geo.superellipsoid(Vector3(0.32, 0.08, 0.08) * s, 0.2, 0.2, 10, 6), Transform3D(b, p + b * Vector3(0, 0.88 * s, 0))])
			parts.append([Geo.torus(0.16 * s, 0.22 * s, 20, 6), Transform3D(b.rotated(b.x, PI * 0.5), p + b * Vector3(0, 0.88 * s, 0))])


## Fiammella con luce tremolante (candele delle tombe, lanterne del mausoleo).
static func _flame_post(host: Node3D, at: Vector3) -> void:
	Geo.add(host, Geo.cyl(0.0, 0.025, 0.08, 8), Mats.emissive(Color(1.0, 0.6, 0.2), 6.0), at, Vector3.ZERO, false)
	var fl := FlickerLight.new()
	fl.light_color = Color(1.0, 0.55, 0.25)
	fl.base_energy = 0.7
	fl.omni_range = 2.8
	fl.position = at + Vector3(0, 0.12, 0)
	host.add_child(fl)


# ------------------------------------------------------------------ tempo atmosferico

## Pioggia: gocce sottili e sfumate di lunghezze diverse, schizzi sul terreno, rumore in loop.
static func rain(host: Node3D) -> void:
	var p := GPUParticles3D.new()
	p.amount = 9000
	p.lifetime = 0.8
	p.preprocess = 0.8
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(13, 0.5, 13)
	m.direction = Vector3(0.1, -1, 0.04)
	m.spread = 1.5
	m.initial_velocity_min = 16.0
	m.initial_velocity_max = 19.0
	m.scale_min = 0.5
	m.scale_max = 1.4
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(0.008, 0.5)
	var img := Image.create(4, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var v := float(y) / 63.0
		var a2 := sin(v * PI) * 0.9 * (0.4 + 0.6 * v)      # sfumata ai due capi, più densa in basso
		for x in 4:
			img.set_pixel(x, y, Color(1, 1, 1, a2 * (1.0 if x in [1, 2] else 0.4)))
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_texture = ImageTexture.create_from_image(img)
	sm.albedo_color = Color(0.72, 0.78, 0.9, 0.16)
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	q.material = sm
	p.draw_pass_1 = q
	p.position = Vector3(0, 11, 0)
	p.visibility_aabb = AABB(Vector3(-15, -15, -15), Vector3(30, 18, 30))
	host.add_child(p)
	# schizzi: piccoli anelli che si allargano e spariscono sul terreno
	var sp := GPUParticles3D.new()
	sp.amount = 900
	sp.lifetime = 0.3
	sp.preprocess = 0.3
	var sm2 := ParticleProcessMaterial.new()
	sm2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	sm2.emission_box_extents = Vector3(11, 0.0, 11)
	sm2.gravity = Vector3.ZERO
	sm2.scale_min = 0.6
	sm2.scale_max = 1.2
	var c := Curve.new()
	c.add_point(Vector2(0, 0.2))
	c.add_point(Vector2(1, 1.0))
	var ct := CurveTexture.new()
	ct.curve = c
	sm2.scale_curve = ct
	var g := Gradient.new()
	g.set_color(0, Color(0.8, 0.85, 0.95, 0.35))
	g.set_color(1, Color(0.8, 0.85, 0.95, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	sm2.color_ramp = gt
	sp.process_material = sm2
	var ring := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 15.5
			ring.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - absf(d - 0.75) * 6.0, 0.0, 1.0)))
	var rq := QuadMesh.new()
	rq.size = Vector2(0.14, 0.14)
	rq.orientation = PlaneMesh.FACE_Y
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.vertex_color_use_as_albedo = true
	rm.albedo_texture = ImageTexture.create_from_image(ring)
	rq.material = rm
	sp.draw_pass_1 = rq
	sp.position = Vector3(0, 0.04, 0)
	host.add_child(sp)
	_loop_sound(host, "pioggia", -4.0)


## Suono d'ambiente in loop per il luogo (pioggia, vento): si ferma quando il luogo viene tolto.
static func _loop_sound(host: Node3D, name: String, db: float) -> void:
	if not ResourceLoader.exists("res://audio/%s.wav" % name):
		return
	var st := load("res://audio/%s.wav" % name) as AudioStreamWAV
	if st == null:
		return
	st = st.duplicate() as AudioStreamWAV
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = int(st.get_length() * st.mix_rate)
	var pl := AudioStreamPlayer.new()
	pl.stream = st
	pl.volume_db = db
	pl.bus = "Amb"
	pl.autoplay = true
	host.add_child(pl)


## Neve: fiocchi che ondeggiano; ogni tanto una folata li spinge di lato. Vento in sottofondo.
static func snowfall(host: Node3D) -> void:
	var p := GPUParticles3D.new()
	p.amount = 4200
	p.lifetime = 8.0
	p.preprocess = 8.0
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(17, 0.5, 17)
	m.direction = Vector3(0, -1, 0)
	m.spread = 25.0
	m.initial_velocity_min = 0.7
	m.initial_velocity_max = 1.3
	m.gravity = Vector3(0.2, -0.35, 0)
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.8
	m.turbulence_noise_scale = 3.0
	m.scale_min = 0.5
	m.scale_max = 1.5
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(0.04, 0.04)
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length() / 7.5
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d * d, 0.0, 1.0)))
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_texture = ImageTexture.create_from_image(img)
	sm.albedo_color = Color(0.88, 0.92, 1.0, 0.85)
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = sm
	p.draw_pass_1 = q
	p.position = Vector3(0, 10, 0)
	p.visibility_aabb = AABB(Vector3(-19, -14, -19), Vector3(38, 18, 38))
	host.add_child(p)
	# folate: il vento cambia forza e direzione ogni pochi secondi
	var timer := Timer.new()
	host.add_child(timer)
	timer.timeout.connect(func() -> void:
		var tw := host.create_tween()
		var a := randf() * TAU
		var f := randf_range(0.3, 2.2)
		tw.tween_property(m, "gravity", Vector3(cos(a) * f, -0.35, sin(a) * f), randf_range(1.0, 2.5)).set_trans(Tween.TRANS_SINE)
		timer.start(randf_range(3.0, 7.0)))
	timer.start(2.0)
	_loop_sound(host, "vento", -8.0)


## Fulmini: ogni tanto un lampo bianco (una o due scariche) illumina tutto, poi arriva il tuono.
static func lightning(host: Node3D) -> void:
	var flash := DirectionalLight3D.new()
	flash.light_color = Color(0.8, 0.85, 1.0)
	flash.light_energy = 0.0
	flash.shadow_enabled = true
	flash.rotation_degrees = Vector3(-60, 160, 0)
	flash.light_volumetric_fog_energy = 4.0
	host.add_child(flash)
	var timer := Timer.new()
	timer.one_shot = true
	host.add_child(timer)
	var strike := func() -> void:
		var tw := host.create_tween()
		for k in (1 if randf() < 0.5 else 2):
			tw.tween_property(flash, "light_energy", randf_range(5.0, 9.0), 0.03)
			tw.tween_property(flash, "light_energy", 0.4, 0.08)
			tw.tween_interval(randf_range(0.05, 0.15))
		tw.tween_property(flash, "light_energy", 0.0, 0.35)
		var far := randf_range(0.6, 2.2)          # più è lontano, più il tuono tarda
		host.get_tree().create_timer(far).timeout.connect(func() -> void:
			if is_instance_valid(host):
				Sfx.play("tuono_%d" % (1 if far < 1.0 else (2 if far < 1.6 else 3)), -2.0 - far * 2.0, randf_range(0.9, 1.05)))
		timer.start(randf_range(6.0, 16.0))
	timer.timeout.connect(strike)
	timer.start(randf_range(2.0, 5.0))


# ------------------------------------------------------------------ terreni su misura

## Terreno con altezza data da una funzione (x, z) -> y.
static func _terrain_fn(host: Node3D, mat: Material, fn: Callable, size := 150.0, subdiv := 200) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(size, size)
	pm.subdivide_width = subdiv
	pm.subdivide_depth = subdiv
	var st := SurfaceTool.new()
	st.create_from(pm, 0)
	var mdt := MeshDataTool.new()
	mdt.create_from_surface(st.commit(), 0)
	for i in mdt.get_vertex_count():
		var v := mdt.get_vertex(i)
		v.y = fn.call(v.x, v.z)
		mdt.set_vertex(i, v)
	var out := ArrayMesh.new()
	mdt.commit_to_surface(out)
	var st2 := SurfaceTool.new()
	st2.create_from(out, 0)
	st2.generate_normals()
	st2.generate_tangents()
	_add(host, st2.commit(), mat)


static func _plane(host: Node3D, mat: Material, y: float, size := 80.0) -> void:
	var p := PlaneMesh.new()
	p.size = Vector2(size, size)
	Geo.add(host, p, mat, Vector3(0, y, 0), Vector3.ZERO, false)


# ------------------------------------------------------------------ cripta sepolta

const CRYPT_R := 8.6        # raggio interno dei muri
const CRYPT_WALL_H := 3.8   # dove nasce la volta
const CRYPT_TOP := 7.6      # colmo della volta (al centro un'apertura: entra un raggio di luna)
const OCULUS_R := 0.95


## Una sala rotonda sotto terra: muri di pietra antica, otto colonne con torce, costoloni che salgono a
## un'apertura nella volta, e fra le colonne otto campate diverse: il portone, un cancello sul buio,
## due sarcofagi, due statue, due pareti di loculi.
static func _crypt(host: Node3D, rng: RandomNumberGenerator) -> void:
	var floor_mat := pbr("monastery_stone_floor", 2.4, Color(0.72, 0.68, 0.62))
	var wall_mat := pbr("old_stone_wall", 2.6, Color(0.66, 0.62, 0.56))
	var block := pbr("medieval_blocks_05", 1.6, Color(0.72, 0.68, 0.62))
	var dark := pbr("dark_rock", 1.5, Color(0.55, 0.52, 0.5))
	var vault_mat := wall_mat.duplicate() as StandardMaterial3D
	vault_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# pavimento
	var pm := PlaneMesh.new()
	pm.size = Vector2(CRYPT_R * 2.0 + 2.0, CRYPT_R * 2.0 + 2.0)
	_add(host, pm, floor_mat)
	# muri a sedici lati, zoccolo e cornice
	var walls: Array = []
	var trims: Array = []
	for k in 16:
		var a := TAU * k / 16.0
		var b := Basis(Vector3.UP, a)
		var rr := CRYPT_R + 0.3
		var chord := 2.0 * (CRYPT_R + 0.6) * tan(PI / 16.0) + 0.05
		walls.append([Geo.box(Vector3(chord, CRYPT_WALL_H + 0.6, 0.6)), Transform3D(b, Vector3(sin(a) * rr, (CRYPT_WALL_H + 0.6) * 0.5, cos(a) * rr))])
		var ci := 2.0 * CRYPT_R * tan(PI / 16.0) + 0.04
		trims.append([Geo.box(Vector3(ci, 0.32, 0.22)), Transform3D(b, Vector3(sin(a) * (CRYPT_R - 0.1), 0.16, cos(a) * (CRYPT_R - 0.1)))])
		trims.append([Geo.box(Vector3(ci, 0.22, 0.3)), Transform3D(b, Vector3(sin(a) * (CRYPT_R - 0.12), CRYPT_WALL_H - 0.05, cos(a) * (CRYPT_R - 0.12)))])
	_add(host, _merge(walls), wall_mat)
	_add(host, _merge(trims), block)
	# volta: superficie di rotazione, aperta al centro
	var prof := PackedVector2Array()
	for i in 25:
		var th := PI * 0.5 * i / 24.0
		var r := CRYPT_R * cos(th)
		if r < OCULUS_R:
			break
		prof.append(Vector2(r, CRYPT_WALL_H + (CRYPT_TOP - CRYPT_WALL_H) * sin(th)))
	var top_y := prof[prof.size() - 1].y
	_add(host, Geo.lathe(prof, 48), vault_mat)
	# anello dell'apertura e una vera di pietra sopra
	var ring := Geo.add(host, Geo.torus(OCULUS_R + 0.05, OCULUS_R + 0.32, 32, 8), block, Vector3(0, top_y - 0.02, 0))
	ring.scale = Vector3(1, 0.6, 1)
	_moonbeam(host, top_y)
	_dust(host, top_y)
	# colonne addossate ai muri, con costoloni che salgono fino all'apertura e una torcia ciascuna
	var col_prof := PackedVector2Array([Vector2(0.44, 0.0), Vector2(0.44, 0.26), Vector2(0.36, 0.31), Vector2(0.31, 0.4),
		Vector2(0.27, 0.48), Vector2(0.27, 3.3), Vector2(0.31, 3.38), Vector2(0.38, 3.52), Vector2(0.46, 3.66), Vector2(0.46, CRYPT_WALL_H - 0.05)])
	var col_mesh := Geo.lathe(col_prof, 18)
	var ribs: Array = []
	for k in 8:
		var a := TAU * (k + 0.5) / 8.0
		var dir := Vector3(sin(a), 0, cos(a))
		Geo.add(host, col_mesh, block, dir * (CRYPT_R - 0.3))
		var rib := Geo.tube(func(t: float) -> Vector3:
				var th := t * acos(OCULUS_R / (CRYPT_R - 0.3))
				return dir * (CRYPT_R - 0.3) * cos(th) + Vector3(0, CRYPT_WALL_H + (CRYPT_TOP - CRYPT_WALL_H - 0.1) * sin(th), 0),
			func(_t: float) -> float: return 0.17, 6, 28)
		ribs.append([rib, Transform3D()])
		_torch(host, dir * (CRYPT_R - 0.78) + Vector3(0, 2.25, 0), -dir, k % 2 == 0)
	_add(host, _merge(ribs), block)
	# le otto campate: 0 è alle spalle della telecamera iniziale, 4 di fronte
	for k in 8:
		var a := TAU * k / 8.0
		var bay := Node3D.new()
		host.add_child(bay)
		bay.position = Vector3(sin(a), 0, cos(a)) * CRYPT_R
		bay.rotation.y = a + PI            # il +Z del nodo guarda il centro della sala
		match k:
			4:
				_crypt_door(bay, block, dark)
			0:
				_crypt_gate(bay, dark)
			2, 6:
				_niche(bay, block, dark)
				_sarcophagus(bay, block, rng)
			1, 7:
				_niche(bay, block, dark)
				var ped := Geo.add(bay, Geo.box(Vector3(1.45, 0.8, 1.3)), block, Vector3(0, 0.4, 0.8))
				ped.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				prop(bay, "gothic_statue", Vector3(0, 0.8, 0.75), 0.0, 1.05)
				prop(bay, "wooden_candlestick", Vector3(-0.7, 0, 0.9), 0.0, 1.6)
				prop(bay, "wooden_candlestick", Vector3(0.7, 0, 0.9), 0.0, 1.6)
			_:
				_loculi(bay, block, rng)
	# macerie: pietre cadute vicino ai muri e un pezzo di colonna rotta
	for k in 9:
		var a := rng.randf() * TAU
		var r := rng.randf_range(6.6, 7.7)
		var n := prop(host, "rock_face_02", Vector3(sin(a) * r, -0.05, cos(a) * r), rng.randf() * TAU, rng.randf_range(0.12, 0.22))
		if n:
			for mi in n.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_override = dark
	var fa := rng.randf() * TAU
	var broken := Geo.add(host, Geo.cyl(0.27, 0.27, 1.6, 16), block, Vector3(sin(fa) * 6.4, 0.27, cos(fa) * 6.4))
	broken.rotation = Vector3(0, fa + PI * 0.5, PI * 0.5)
	# radici che scendono da una crepa della volta
	for k in 2:
		var a := rng.randf() * TAU
		var r := 5.2
		var th := acos(r / CRYPT_R)
		var root := prop(host, "root_cluster_01", Vector3(sin(a) * r, CRYPT_WALL_H + (CRYPT_TOP - CRYPT_WALL_H) * sin(th) + 0.2, cos(a) * r), a, 0.7)
		if root:
			root.rotation.x = PI
	# gocce di polvere nella luce e una bassa foschia che si muove
	_fog_banks(host, rng, Color(0.5, 0.46, 0.4), 5)
	_loop_sound(host, "cripta", -6.0)


## Raggio di luna dall'apertura della volta: una luce fredda che cade sull'altare e un cono di pulviscolo
## che si vede appena (più chiaro in alto, svanisce verso il pavimento e ai bordi).
static func _moonbeam(host: Node3D, top_y: float) -> void:
	var spot := SpotLight3D.new()
	spot.light_color = Color(0.62, 0.74, 1.0)
	spot.light_energy = 2.2
	spot.spot_range = top_y + 2.0
	spot.spot_angle = 14.0
	spot.spot_attenuation = 0.6
	spot.spot_angle_attenuation = 3.5      # bordi sfumati: niente cono a spigoli vivi nella foschia
	spot.light_volumetric_fog_energy = 0.45
	spot.shadow_enabled = true
	spot.light_specular = 0.15
	spot.position = Vector3(0, top_y + 0.8, 0)
	spot.rotation.x = -PI * 0.5
	host.add_child(spot)
	var cone := CylinderMesh.new()
	cone.top_radius = OCULUS_R * 0.92
	cone.bottom_radius = OCULUS_R * 1.9
	cone.height = top_y
	cone.radial_segments = 32
	cone.cap_top = false
	cone.cap_bottom = false
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
uniform vec3 tint = vec3(0.45, 0.55, 0.85);
varying float h;
void vertex() { h = VERTEX.y; }
void fragment() {
	float up = clamp(h / %f + 0.5, 0.0, 1.0);
	float edge = pow(clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float drift = 0.75 + 0.25 * sin(TIME * 0.4 + UV.x * 18.0 + h * 1.3);
	ALBEDO = tint;
	ALPHA = 1.0;
	EMISSION = vec3(0.0);
	ALBEDO = tint * (0.32 * up * up * edge * drift);
}""" % cone.height
	var m := ShaderMaterial.new()
	m.shader = sh
	var mi := MeshInstance3D.new()
	mi.mesh = cone
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0, top_y * 0.5, 0)
	host.add_child(mi)


## Torcia su un braccio di ferro: bastone, fiamma vera (materiale "fuoco") e luce che trema.
static func _torch(host: Node3D, at: Vector3, facing: Vector3, shadow: bool) -> void:
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.09, 0.08, 0.08)
	iron.metallic = 0.8
	iron.roughness = 0.5
	var wood := pbr("pine_bark", 0.4, Color(0.35, 0.25, 0.18))
	var arm := Node3D.new()
	host.add_child(arm)
	Geo.orient_between(arm, at - facing * 0.4 + Vector3(0, -0.15, 0), at)
	Geo.add(arm, Geo.cyl(0.018, 0.018, at.distance_to(at - facing * 0.4 + Vector3(0, -0.15, 0)), 6), iron)
	Geo.add(host, Geo.cyl(0.07, 0.05, 0.1, 10), iron, at + Vector3(0, 0.02, 0))
	var stick := Geo.add(host, Geo.cyl(0.03, 0.022, 0.55, 8), wood, at + Vector3(0, 0.12, 0) + facing * 0.05)
	stick.rotation = Vector3(0, 0, 0)
	stick.rotate(facing.cross(Vector3.UP).normalized(), -0.25)
	var tip := at + Vector3(0, 0.4, 0) + facing * 0.12
	var shader: Shader = load("res://shaders/fuoco.gdshader")
	for i in 3:
		var hgt := randf_range(0.32, 0.5)
		var q := QuadMesh.new()
		q.size = Vector2(hgt * 0.55, hgt)
		q.center_offset = Vector3(0, hgt * 0.5, 0)
		var fm := ShaderMaterial.new()
		fm.shader = shader
		fm.set_shader_parameter("seed", randf() * 10.0)
		fm.set_shader_parameter("speed", randf_range(1.8, 2.6))
		fm.set_shader_parameter("strength", 0.75)
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = fm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = tip + Vector3(randf_range(-0.03, 0.03), -0.04, randf_range(-0.03, 0.03))
		host.add_child(mi)
	var fl := FlickerLight.new()
	fl.light_color = Color(1.0, 0.5, 0.2)
	fl.base_energy = 1.3
	fl.omni_range = 6.5
	fl.shadow_enabled = shadow
	fl.position = tip + Vector3(0, 0.3, 0) + facing * 0.15
	host.add_child(fl)


## Nicchia ad arco nel muro: due lesene, un arco, il fondo scuro.
static func _niche(bay: Node3D, block: Material, dark: Material) -> void:
	var w := 2.6
	var h := 2.4
	var parts: Array = []
	for sx in [-1.0, 1.0]:
		parts.append([Geo.box(Vector3(0.3, h, 0.3)), Transform3D(Basis(), Vector3(sx * (w * 0.5 + 0.15), h * 0.5, 0.15))])
	var arch := Geo.tube(func(t: float) -> Vector3: return Vector3(cos(PI * t) * (w * 0.5 + 0.15), h + sin(PI * t) * (w * 0.5 + 0.15), 0.15),
		func(_t: float) -> float: return 0.15, 6, 20, Vector2.ONE, Vector3.FORWARD)
	parts.append([arch, Transform3D()])
	_add(bay, _merge(parts), block)
	Geo.add(bay, Geo.box(Vector3(w + 0.2, h + w * 0.5 + 0.1, 0.04)), dark, Vector3(0, (h + w * 0.5) * 0.5, 0.02))


## Sarcofago di pietra con coperchio a spioventi, riquadri scolpiti sui fianchi e una croce sul coperchio;
## candele e un forziere d'offerta.
static func _sarcophagus(bay: Node3D, block: Material, rng: RandomNumberGenerator) -> void:
	var stone := pbr("castle_wall_varriation", 1.0, Color(0.68, 0.66, 0.62))
	var parts: Array = []
	var z := 0.9
	var box := func(size: Vector3, pos: Vector3, rot := Basis()) -> void:
		parts.append([Geo.box(size), Transform3D(rot, pos + Vector3(0, 0, z))])
	box.call(Vector3(2.4, 0.14, 1.06), Vector3(0, 0.07, 0))
	box.call(Vector3(2.16, 0.62, 0.86), Vector3(0, 0.45, 0))
	box.call(Vector3(2.26, 0.07, 0.94), Vector3(0, 0.79, 0))
	box.call(Vector3(2.22, 0.09, 0.92), Vector3(0, 0.87, 0))
	for sz in [-1.0, 1.0]:
		box.call(Vector3(2.0, 0.08, 0.5), Vector3(0, 0.97, sz * 0.2), Basis(Vector3.RIGHT, sz * 0.35))
		for i in 3:
			box.call(Vector3(0.5, 0.34, 0.03), Vector3((i - 1) * 0.66, 0.46, sz * 0.44))
	box.call(Vector3(1.3, 0.05, 0.08), Vector3(0, 1.06, 0))
	box.call(Vector3(0.08, 0.05, 0.42), Vector3(-0.3, 1.06, 0))
	_add(bay, _merge(parts), stone)
	prop(bay, "brass_candleholders", Vector3(0, 0, 0.12), 0.0, 0.9)
	prop(bay, "wooden_candlestick", Vector3(-1.05, 0.87, z + 0.3), 0.0, 1.2)
	prop(bay, "wooden_candlestick", Vector3(1.05, 0.87, z - 0.3), 0.0, 1.2)
	if rng.randf() < 0.6:
		prop(bay, "treasure_chest", Vector3(rng.randf_range(-0.6, 0.6), 0, 1.75), rng.randf_range(-0.3, 0.3), 0.75)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.6, 0.3)
	glow.light_energy = 0.5
	glow.omni_range = 2.5
	glow.light_specular = 0.2
	glow.position = Vector3(0, 1.4, 0.6)
	bay.add_child(glow)


## Parete di loculi: tre per tre, alcuni chiusi da una lastra, altri aperti con vasi, coppe o un busto.
static func _loculi(bay: Node3D, block: Material, rng: RandomNumberGenerator) -> void:
	var parts: Array = []
	var w := 3.3
	for y in [0.42, 1.24, 2.06, 2.88]:
		parts.append([Geo.box(Vector3(w, 0.12, 0.55)), Transform3D(Basis(), Vector3(0, y, 0.27))])
	for x in [-1.6, -0.53, 0.53, 1.6]:
		parts.append([Geo.box(Vector3(0.12, 2.58, 0.55)), Transform3D(Basis(), Vector3(x, 1.65, 0.27))])
	parts.append([Geo.box(Vector3(w + 0.2, 0.42, 0.62)), Transform3D(Basis(), Vector3(0, 0.21, 0.31))])
	_add(bay, _merge(parts), block)
	var back := StandardMaterial3D.new()
	back.albedo_color = Color(0.03, 0.025, 0.02)
	back.roughness = 1.0
	Geo.add(bay, Geo.box(Vector3(w, 2.5, 0.04)), back, Vector3(0, 1.65, 0.03))
	var plaque := pbr("castle_wall_varriation", 0.8, Color(0.6, 0.58, 0.54))
	for row in 3:
		for col in 3:
			var c := Vector3((col - 1) * 1.065, 0.48 + row * 0.82, 0.0)
			var roll := rng.randf()
			if roll < 0.45:
				var p := Geo.add(bay, Geo.box(Vector3(0.9, 0.66, 0.05)), plaque, c + Vector3(0, 0.38, 0.5))
				p.rotation.z = rng.randf_range(-0.03, 0.03)
			elif roll < 0.65:
				prop(bay, "antique_ceramic_vase_01", c + Vector3(rng.randf_range(-0.2, 0.2), 0.0, 0.3), rng.randf() * TAU, rng.randf_range(0.9, 1.3))
			elif roll < 0.8:
				prop(bay, "brass_goblets", c + Vector3(0, 0.0, 0.3), rng.randf() * TAU, 0.8)
			elif roll < 0.92:
				prop(bay, "marble_bust_01", c + Vector3(0, 0.0, 0.28), PI + rng.randf_range(-0.4, 0.4), 1.1)


## Il portone d'ingresso, con due scudi appesi e una testa di leone sopra.
static func _crypt_door(bay: Node3D, block: Material, dark: Material) -> void:
	_niche(bay, block, dark)
	prop(bay, "large_castle_door", Vector3(0, 0, 0.08), 0.0, 0.85)
	prop(bay, "lion_head", Vector3(0, 3.35, 0.06), 0.0, 1.3)
	for sx in [-1.0, 1.0]:
		var sh := prop(bay, "kite_shield", Vector3(sx * 2.15, 1.55, 0.05), 0.0, 0.8)
		if sh:
			sh.rotation.z = sx * 0.08


## Un cancello di ferro su un passaggio buio: dietro, solo un barlume rosso lontano.
static func _crypt_gate(bay: Node3D, dark: Material) -> void:
	var void_mat := StandardMaterial3D.new()
	void_mat.albedo_color = Color.BLACK
	void_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var glow := Gradient.new()                   # il buio dietro le sbarre arrossa verso il basso: le sbarre si stagliano
	glow.set_color(0, Color(0.0, 0.0, 0.0))
	glow.set_color(1, Color(0.32, 0.05, 0.02))
	var gt := GradientTexture2D.new()
	gt.gradient = glow
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	void_mat.albedo_texture = gt
	Geo.add(bay, Geo.box(Vector3(2.6, 2.7, 0.03)), void_mat, Vector3(0, 1.35, 0.03))
	var parts: Array = []
	parts.append([Geo.box(Vector3(0.35, 3.0, 0.4)), Transform3D(Basis(), Vector3(-1.45, 1.5, 0.2))])
	parts.append([Geo.box(Vector3(0.35, 3.0, 0.4)), Transform3D(Basis(), Vector3(1.45, 1.5, 0.2))])
	parts.append([Geo.box(Vector3(3.3, 0.4, 0.42)), Transform3D(Basis(), Vector3(0, 3.1, 0.2))])
	_add(bay, _merge(parts), dark)
	prop(bay, "large_iron_gate", Vector3(0, 0, 0.32), 0.0, 0.88)
	var ember := OmniLight3D.new()
	ember.light_color = Color(0.9, 0.15, 0.05)
	ember.light_energy = 1.2
	ember.omni_range = 2.6
	ember.light_specular = 0.3
	ember.position = Vector3(0, 0.5, 0.15)
	bay.add_child(ember)


static func _frozen_lake(host: Node3D, rng: RandomNumberGenerator) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.06
	var shore := rng.randf_range(10.0, 12.0)
	var ground := func(x: float, z: float) -> float:
		var r := Vector2(x, z).length() + noise.get_noise_2d(x * 0.5, z * 0.5) * 2.0
		return -0.25 + smoothstep(shore - 1.0, shore + 3.0, r) * (1.2 + noise.get_noise_2d(x, z) * 0.8) + smoothstep(shore + 6.0, 30.0, r) * 3.0
	var snow := pbr("snow_02", 2.5, Color(0.85, 0.88, 0.95))
	_terrain_fn(host, snow, ground)
	_plane(host, Mats.make("ghiaccio"), 0.0, 2.0 * (shore + 4.0))
	# montagne tutto attorno, coperte di neve (roccia scansionata con materiale di neve)
	var mountain_snow := pbr("snow_02", 6.0, Color(0.85, 0.88, 0.95))
	for k in 9:
		var a := TAU * k / 9.0 + rng.randf_range(-0.15, 0.15)
		var d := rng.randf_range(34.0, 44.0)
		var n := prop(host, "mountainside", Vector3(sin(a) * d, -2.0, cos(a) * d), a + PI + rng.randf_range(-0.4, 0.4), rng.randf_range(2.6, 3.6))
		if n:
			for mi in n.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_override = mountain_snow
	# pareti di roccia sulla riva, mezze innevate
	for k in 5:
		var p: Vector3 = _strat(rng, k, 5, rng.randf() * TAU, shore + 4.0, shore + 7.0, [])
		p.y = ground.call(p.x, p.z) - 0.6
		var n := prop(host, "rock_face_01", p, atan2(-p.x, -p.z) + rng.randf_range(-0.5, 0.5), rng.randf_range(0.6, 0.9))
	# pini neri sulle rive e tronchi spogli
	var trees := {"pino_alto": [], "pino_basso": []}
	for k in 150:
		var p: Vector3 = _strat(rng, k, 150, 0.3, shore + 2.0, 32.0, [])
		p.y = ground.call(p.x, p.z) - 0.25
		trees["pino_alto" if rng.randf() < 0.6 else "pino_basso"].append(_tf(p, rng, 0.85, 1.35))
	for kind in trees:
		_multi(host, kind, trees[kind], true)
	for k in 8:
		var p: Vector3 = _strat(rng, k, 8, 0.9, shore + 0.5, shore + 3.0, [])
		p.y = ground.call(p.x, p.z) - 0.2
		prop(host, "dead_quiver_trunk", p, rng.randf() * TAU, rng.randf_range(2.4, 3.4))
	# massi sotto la neve sulla riva e qualche sasso intrappolato nel ghiaccio
	var snowy_rock := pbr("snow_02", 1.0, Color(0.8, 0.83, 0.9))
	for k in 10:
		var p: Vector3 = _strat(rng, k, 10, 0.2, shore - 0.5, shore + 2.5, [])
		p.y = ground.call(p.x, p.z) - 0.25
		var n := prop(host, "boulder_01", p, rng.randf() * TAU, rng.randf_range(0.6, 1.1))
		if n and rng.randf() < 0.6:
			for mi in n.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_overlay = _snow_overlay()
	# --- oggetti dedicati del lago (16/10/2026)
	# una nave olandese rimasta intrappolata nel ghiaccio, inclinata e mezzo affondata, coperta di neve
	var sa := rng.randf() * TAU
	var ship := prop(host, "dutch_ship_medium", Vector3(sin(sa), 0, cos(sa)) * (shore - 0.5) + Vector3(0, -0.35, 0), sa + rng.randf_range(-0.2, 0.2), 0.62)
	if ship:
		ship.rotate_object_local(Vector3.RIGHT, deg_to_rad(rng.randf_range(10.0, 15.0)))      # piegata sul fianco
		ship.rotate_object_local(Vector3.FORWARD, deg_to_rad(rng.randf_range(-5.0, 5.0)))   # prua un po' sotto
		for mi in ship.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = _snow_overlay()
	# scogliere alte dietro le rive, con la neve sulle sporgenze
	for k in 4:
		var a := sa + PI * 0.5 + TAU * k / 4.0 + rng.randf_range(-0.3, 0.3)
		var d := rng.randf_range(27.0, 31.0)
		var cl := prop(host, "coastal_cliff_04", Vector3(sin(a) * d, ground.call(sin(a) * d, cos(a) * d) - 2.5, cos(a) * d), a + PI, rng.randf_range(0.55, 0.7))
		if cl:
			for mi in cl.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_overlay = _snow_overlay()
	# rocce scure sulla riva, con la neve sopra
	for k in 7:
		var p: Vector3 = _strat(rng, k, 7, rng.randf() * TAU, shore + 0.5, shore + 4.0, [Vector3(sin(sa), 0, cos(sa)) * (shore - 0.5)])
		p.y = ground.call(p.x, p.z) - 0.4
		var rf := prop(host, "rock_face_02", p, rng.randf() * TAU, rng.randf_range(0.6, 1.1))
		if rf:
			for mi in rf.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_overlay = _snow_overlay()
	# alberi morti innevati sulla riva
	for k in 5:
		var p: Vector3 = _strat(rng, k, 5, rng.randf() * TAU, shore + 0.5, shore + 3.5, [])
		p.y = ground.call(p.x, p.z) - 0.1
		var dt := prop(host, "dead_tree_trunk_02", p, rng.randf() * TAU, rng.randf_range(0.8, 1.2))
		if dt:
			for mi in dt.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_overlay = _snow_overlay()
	# creste di ghiaccio: lastre spezzate che spuntano dal lago dove il ghiaccio si è accavallato
	var shard_mat := StandardMaterial3D.new()
	shard_mat.albedo_color = Color(0.68, 0.8, 0.9, 0.88)
	shard_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	shard_mat.roughness = 0.22
	shard_mat.metallic_specular = 0.9
	shard_mat.rim_enabled = true
	shard_mat.rim = 0.6
	shard_mat.emission_enabled = true
	shard_mat.emission = Color(0.12, 0.2, 0.3)
	var shards: Array = []
	for ridge in 6:
		var a0 := rng.randf() * TAU
		var r0 := rng.randf_range(5.5, shore - 1.5)
		var along := Vector3(cos(a0), 0, -sin(a0)).rotated(Vector3.UP, rng.randf_range(-0.5, 0.5))
		var start := Vector3(sin(a0), 0, cos(a0)) * r0
		var count := rng.randi_range(5, 9)
		for i in count:
			var p := start + along * (i - count * 0.5) * rng.randf_range(0.35, 0.55) + along.cross(Vector3.UP) * rng.randf_range(-0.35, 0.35)
			if Vector2(p.x, p.z).length() < SAFE_R + 0.8 or Vector2(p.x, p.z).length() > shore:
				continue
			var size := Vector3(rng.randf_range(0.4, 1.0), rng.randf_range(0.2, 0.7), rng.randf_range(0.12, 0.26))
			var b := Basis(Vector3.UP, atan2(along.x, along.z) + PI * 0.5 + rng.randf_range(-0.4, 0.4))
			b = b.rotated(b.x, rng.randf_range(-0.9, 0.9)).rotated(b.z, rng.randf_range(-0.5, 0.5)).rotated(Vector3.UP, rng.randf_range(-0.6, 0.6))
			shards.append([Geo.box(size), Transform3D(b, p + Vector3(0, size.y * 0.2, 0))])
	if not shards.is_empty():
		var smi := _add(host, _merge(shards), shard_mat)
		smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		smi.material_overlay = _snow_overlay()
	snowfall(host)
	_loop_sound(host, "lago", -6.0)            # il ghiaccio che geme e scricchiola
	_ice_cracks(host, shore)


## Velo di neve appoggiato sopra un oggetto (solo sulle facce rivolte in alto).
static var _snow_ov: ShaderMaterial


static func _snow_overlay() -> ShaderMaterial:
	if _snow_ov == null:
		var sh := Shader.new()
		sh.code = """shader_type spatial;
render_mode blend_mix, depth_draw_never;
varying vec3 wn;
void vertex() { wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	float up = smoothstep(0.45, 0.8, wn.y);
	ALBEDO = vec3(0.84, 0.88, 0.95);
	ROUGHNESS = 0.8;
	ALPHA = up;
}"""
		_snow_ov = ShaderMaterial.new()
		_snow_ov.shader = sh
	return _snow_ov


## Banchi di nebbia: volumi di nebbia bassa che scivolano piano e cambiano densità.
static func _fog_banks(host: Node3D, rng: RandomNumberGenerator, col: Color, n: int) -> void:
	for k in n:
		var fv := FogVolume.new()
		fv.size = Vector3(rng.randf_range(6.0, 11.0), rng.randf_range(1.2, 2.2), rng.randf_range(6.0, 11.0))
		fv.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		var fm := FogMaterial.new()
		fm.density = rng.randf_range(0.35, 0.7)
		fm.albedo = col
		fm.edge_fade = 0.8
		fv.material = fm
		var start := _ring_point(rng, 6.0, 16.0) + Vector3(0, 0.4, 0)
		fv.position = start
		host.add_child(fv)
		var tw := fv.create_tween().set_loops()
		var to := start + Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5))
		var dur := rng.randf_range(14.0, 26.0)
		tw.tween_property(fv, "position", to, dur).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(fm, "density", fm.density * 0.4, dur * 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(fv, "position", start, dur).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(fm, "density", fm.density, dur * 0.5).set_trans(Tween.TRANS_SINE)


# ------------------------------------------------------------------ vita dei luoghi

## Corvi: alcuni posati sulle lapidi più vicine e sul tetto del mausoleo, altri in volo in cerchio sopra
## il cimitero.
static func _crows(host: Node3D, rng: RandomNumberGenerator, perches: Array, roof: Vector3) -> void:
	var near := perches.filter(func(pp: Array) -> bool:
		var q: Vector3 = pp[0]
		return Vector2(q.x, q.z).length() < 7.5)
	near.shuffle()
	for i in mini(6, near.size()):
		var c := Corvo.new().build(false, rng)
		host.add_child(c)
		c.position = near[i][0]
		c.rotation.y = rng.randf() * TAU
		c.scale = Vector3.ONE * rng.randf_range(1.3, 1.45)          # corvi imperiali, grandi
		if "--dove-corvi" in OS.get_cmdline_user_args():
			print("CORVO ", c.position)
	for sx in [-1.0, 0.6]:
		var c := Corvo.new().build(false, rng)
		host.add_child(c)
		c.position = roof + Vector3(sx * 1.6 + rng.randf_range(-0.2, 0.2), 0, 0)
		c.rotation.y = rng.randf_range(-0.6, 0.6)
		c.scale = Vector3.ONE * 1.4
	for k in 4:
		var c := Corvo.new().build(true, rng)
		c.radius = rng.randf_range(5.5, 10.0)
		c.height = rng.randf_range(4.5, 7.5)
		c.scale = Vector3.ONE * 1.4
		c.speed = rng.randf_range(0.1, 0.16) * (1.0 if k % 2 == 0 else -1.0)
		host.add_child(c)


## Foresta: foglie secche e aghi che cadono piano, girando su se stessi, portati dal vento.
static func _falling_leaves(host: Node3D) -> void:
	var p := GPUParticles3D.new()
	p.amount = 160
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.visibility_aabb = AABB(Vector3(-10, -8, -10), Vector3(20, 10, 20))
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(7, 0.5, 7)          # vicino al cerchio, dove il fuoco le illumina
	m.direction = Vector3(0.3, -1, 0.1)
	m.spread = 25.0
	m.initial_velocity_min = 0.4
	m.initial_velocity_max = 0.8
	m.gravity = Vector3(0.15, -0.9, 0.06)          # cadono davvero (più del freno dell'aria)
	m.damping_min = 0.05
	m.damping_max = 0.15
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.35          # ondeggiano scendendo, senza restare sospese
	m.turbulence_noise_scale = 2.0
	m.turbulence_influence_min = 0.05
	m.turbulence_influence_max = 0.15
	m.angle_min = -180.0
	m.angle_max = 180.0
	m.angular_velocity_min = -160.0
	m.angular_velocity_max = 160.0
	m.scale_min = 0.6
	m.scale_max = 1.3
	p.process_material = m
	# foglia secca: una forma a goccia allungata disegnata qui, marrone con la nervatura più scura
	var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 32:
			var v := float(y) / 63.0
			var half := 0.42 * sin(PI * clampf(v * 1.05, 0.0, 1.0))
			var dx := absf((float(x) + 0.5) / 32.0 - 0.5)
			var a := 1.0 if dx < half else 0.0
			var vein := 0.75 if dx < 0.03 else 1.0
			img.set_pixel(x, y, Color(0.62 * vein, 0.36 * vein, 0.14 * vein, a))
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.13)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.9
	mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER    # vicino alla telecamera sparisce
	mat.distance_fade_min_distance = 0.8
	mat.distance_fade_max_distance = 2.0
	q.material = mat
	p.draw_pass_1 = q
	p.position = Vector3(0, 6.5, 0)
	host.add_child(p)


## Cripta: polvere finissima che scende piano dall'apertura della volta e brilla nel raggio di luna.
static func _dust(host: Node3D, top_y: float) -> void:
	var p := GPUParticles3D.new()
	p.amount = 140
	p.lifetime = 16.0
	p.preprocess = 16.0
	p.visibility_aabb = AABB(Vector3(-3, -top_y - 1, -3), Vector3(6, top_y + 2, 6))
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = OCULUS_R * 1.4
	m.direction = Vector3(0, -1, 0)
	m.spread = 10.0
	m.initial_velocity_min = 0.15
	m.initial_velocity_max = 0.35
	m.gravity = Vector3(0, -0.03, 0)
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.15
	m.scale_min = 0.5
	m.scale_max = 1.2
	var g := Gradient.new()
	g.set_color(0, Color(0.7, 0.8, 1.0, 0.0))
	g.add_point(0.15, Color(0.7, 0.8, 1.0, 0.55))
	g.add_point(0.8, Color(0.7, 0.8, 1.0, 0.4))
	g.set_color(g.get_point_count() - 1, Color(0.7, 0.8, 1.0, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(0.012, 0.012)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = mat
	p.draw_pass_1 = q
	p.position = Vector3(0, top_y - 0.3, 0)
	host.add_child(p)


## Lago: ogni tanto il ghiaccio si crepa in un punto: schiocco nello spazio e uno sbuffo di neve.
static func _ice_cracks(host: Node3D, shore: float) -> void:
	var sounds: Array[AudioStream] = []
	for k in 3:
		var path := "res://audio/crepa_%d.wav" % (k + 1)
		if ResourceLoader.exists(path):
			sounds.append(load(path))
	var t := Timer.new()
	t.wait_time = 7.0
	t.autostart = true
	host.add_child(t)
	t.timeout.connect(func() -> void:
		t.wait_time = randf_range(6.0, 15.0)
		var a := randf() * TAU
		var d := randf_range(4.5, shore - 1.0)
		var at := Vector3(sin(a) * d, 0.02, cos(a) * d)
		if not sounds.is_empty():
			var pl := AudioStreamPlayer3D.new()
			pl.stream = sounds[randi() % sounds.size()]
			pl.bus = "Amb"
			pl.unit_size = 6.0
			pl.volume_db = -2.0
			pl.pitch_scale = randf_range(0.85, 1.15)
			host.add_child(pl)
			pl.position = at
			pl.play()
			pl.finished.connect(pl.queue_free)
		var puff := GPUParticles3D.new()
		puff.one_shot = true
		puff.amount = 24
		puff.lifetime = 1.6
		puff.explosiveness = 0.9
		var m := ParticleProcessMaterial.new()
		m.direction = Vector3(0, 1, 0)
		m.spread = 70.0
		m.initial_velocity_min = 0.3
		m.initial_velocity_max = 0.9
		m.gravity = Vector3(0, -0.6, 0)
		m.scale_min = 0.6
		m.scale_max = 1.4
		var g := Gradient.new()
		g.set_color(0, Color(0.9, 0.95, 1.0, 0.7))
		g.set_color(g.get_point_count() - 1, Color(0.9, 0.95, 1.0, 0.0))
		var gt := GradientTexture1D.new()
		gt.gradient = g
		m.color_ramp = gt
		puff.process_material = m
		var q := QuadMesh.new()
		q.size = Vector2(0.05, 0.05)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		q.material = mat
		puff.draw_pass_1 = q
		host.add_child(puff)
		puff.position = at
		puff.emitting = true
		puff.finished.connect(puff.queue_free))
