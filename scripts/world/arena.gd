class_name Arena
extends Node3D
## Il luogo della partita: cerchio rituale, scenario (foresta o castello), luci, nebbia, il Custode,
## i quattro posti e gli effetti dei colpi. Forme semplici: è il prototipo.

const R := 2.4                    # raggio del cerchio dei campioni
var n_seats := 4                   # posti attorno al tavolo (4-8), a distanza uguale; 0 = il tuo, verso la telecamera

var scenario := 0
var env: Environment
var camera: Camera3D
var seats: Array[Figura] = []
var custode: Node3D
var _custode_eyes: StandardMaterial3D
var _circle_mat: ShaderMaterial
var _cam_base := Transform3D()   # dove sta la telecamera adesso (senza scossone)
var _cam_home := Transform3D()   # l'inquadratura di gioco
var _cam_goal := Transform3D()   # dove sta andando
var _cam_speed := 4.0
var _trauma := 0.0               # scossone: cresce coi colpi, decade da solo
var _t := 0.0


func build(scenario_id: int, seed_value := -1) -> Arena:
	scenario = scenario_id
	orbit_max = 7.4 if scenario == 2 else 22.0
	_environment()
	Scenari.build(self, scenario, seed_value if seed_value >= 0 else randi())
	# ogni luogo ha la sua musica (se il file manca, resta quella di sempre)
	var tune: String = ["musica_foresta", "musica_cimitero", "musica_cripta", "musica_lago"][clampi(scenario, 0, 3)]
	Sfx.place_music(tune if ResourceLoader.exists("res://audio/%s.wav" % tune) else "music_drone")
	_circle()
	_custode()
	_lights()
	_atmosphere()
	camera = Camera3D.new()
	camera.fov = 52.0
	add_child(camera)
	camera.transform = Visuale.transform(R)          # l'inquadratura scelta dal giocatore
	_cam_base = camera.transform
	_cam_home = camera.transform
	_cam_goal = camera.transform
	camera.current = true
	return self


## Cambia inquadratura (scelta in Audio e schermo o col tasto V): la telecamera ci scivola piano.
func set_view() -> void:
	_cam_home = Visuale.transform(R)
	_cam_goal = _cam_home


func seat_pos(i: int) -> Vector3:
	var a := TAU * i / n_seats
	return Vector3(sin(a), 0, cos(a)) * R


## Quanti posti ci sono al tavolo (prima di place): gli anelli delle catene si rifanno per i posti nuovi.
func set_seats(count: int) -> void:
	if count == n_seats:
		return
	n_seats = count
	for c in _chairs.values():
		(c as Node3D).queue_free()
	_chairs.clear()
	for i in _table_rings:
		for h in _table_rings[i]:
			(h as Node3D).get_parent().queue_free()
	_table_rings.clear()


## Mette il campione al posto i (seduto sulla sua sedia di pietra).
func place(i: int, cls: int, name_text: String, font: Font) -> Figura:
	_chair(i)
	var f := Figura.new()
	add_child(f)
	f.position = seat_pos(i)
	f.look_at(Vector3.ZERO, Vector3.UP)
	f.build(cls, name_text, font)
	if seats.size() <= i:
		seats.resize(i + 1)
	seats[i] = f
	return f



## Le sedie di pietra (la stessa del mago, assets_src/personaggi/mago_nero/carte_sedia/sedia_pietra.py): una per
## posto, rivolta verso l'altare, col bordo della seduta 6 cm davanti al punto del posto.
var _chairs := {}
const CHAIR_FRONT := 0.06


func _chair(i: int) -> void:
	if _chairs.has(i):
		return
	var dir := seat_pos(i).normalized()
	var c := Scenari.prop(self, "sedia_pietra", seat_pos(i) - dir * CHAIR_FRONT, 0.0, 1.0)
	if c == null:
		return
	c.look_at(c.position + dir, Vector3.UP)        # -Z verso fuori: la sedia (che guarda +Z) guarda l'altare
	for mi in c.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_chairs[i] = c

## Modalità esplorazione: la telecamera gira attorno al cerchio (mouse per girare, rotella per la distanza).
var orbit := false
var orbit_yaw := 0.0
var orbit_pitch := 0.42
var orbit_dist := 9.0
var orbit_idle := 0.0
var follow_altar := false          # solo per le prove (--segui-altare)


func orbit_drag(dx: float, dy: float) -> void:
	orbit_yaw -= dx * 0.006
	orbit_pitch = clampf(orbit_pitch + dy * 0.004, 0.05, 1.3)
	orbit_idle = 0.0


## Distanza massima della telecamera libera (nella cripta resta dentro i muri).
var orbit_max := 22.0


## Nella cripta la telecamera resta sempre dentro la sala: sotto la volta (mai fuori dall'apertura in alto)
## e lontana da sarcofagi, statue e macerie lungo i muri. Accorcia la distanza finché il punto è libero.
func _crypt_reach(dir: Vector3, want: float) -> float:
	var d := want
	while d > 2.5:
		var p := dir * d + Vector3(0, 0.6, 0)
		var flat := Vector2(p.x, p.z).length()
		var room := 5.9 if p.y < 1.7 else 6.9          # in basso ci sono sarcofagi, piedistalli, macerie
		if p.y > Scenari.CRYPT_WALL_H:                  # sotto la volta, con mezzo metro di margine
			var s := clampf((p.y + 0.5 - Scenari.CRYPT_WALL_H) / (Scenari.CRYPT_TOP - Scenari.CRYPT_WALL_H), 0.0, 1.0)
			room = minf(room, Scenari.CRYPT_R * sqrt(1.0 - s * s) - 0.6)
		if flat <= room:
			return d
		d -= 0.05
	return 2.5


func orbit_zoom(f: float) -> void:
	orbit_dist = clampf(orbit_dist * f, 2.5, orbit_max)
	orbit_idle = 0.0


func _process(delta: float) -> void:
	_t += delta
	_altar_float()
	_chains_step(delta)
	if orbit:
		orbit_idle += delta
		if orbit_idle > 2.5:
			orbit_yaw += delta * 0.07          # se nessuno tocca, gira da sola, piano
		var dir := Vector3(sin(orbit_yaw) * cos(orbit_pitch), sin(orbit_pitch), cos(orbit_yaw) * cos(orbit_pitch))
		var pos := dir * orbit_dist
		if scenario == 2:
			pos = dir * _crypt_reach(dir, orbit_dist)
		if follow_altar and _altar_root:          # prova: la telecamera sale e scende con l'altare
			camera.transform = Transform3D(Basis(), pos + Vector3(0, 0.6, 0)).looking_at(Vector3(0, 0.7, 0), Vector3.UP)
			camera.transform = _altar_root.transform * Transform3D(Basis(), Vector3(0, -ALTAR_LIFT, 0)) * camera.transform
			return
		camera.transform = Transform3D(Basis(), pos + Vector3(0, 0.6, 0)).looking_at(Vector3(0, 0.7, 0), Vector3.UP)
		return
	# la telecamera scivola verso la sua meta e respira appena (mai ferma come una foto)
	_cam_base = _cam_base.interpolate_with(_cam_goal, 1.0 - exp(-_cam_speed * delta))
	var breath := Vector3(sin(_t * 0.37) * 0.03, sin(_t * 0.51) * 0.02, 0.0)
	_trauma = maxf(_trauma - delta * 1.4, 0.0)
	var k := _trauma * _trauma
	var o := Vector3(sin(_t * 41.0) * 0.09, sin(_t * 53.0 + 1.3) * 0.06, 0.0) * k
	camera.transform = _cam_base.translated_local(breath + o)
	camera.rotate_object_local(Vector3.FORWARD, sin(_t * 37.0) * 0.03 * k)
	for f in seats:
		if f:
			f.face_fan(camera.global_position)


## Scossone (si somma, poi decade da solo): 0.3 colpo, 0.6 contrattacco, 1 morte.
static var shake_on := true


func shake(amount := 1.0) -> void:
	if not shake_on:
		return
	_trauma = clampf(_trauma + amount * 0.6, 0.0, 1.0)


## Inquadratura da vicino di uno scontro fra due punti (attaccante e bersaglio).
func focus_pair(a: Vector3, b: Vector3, speed := 3.5) -> void:
	var m := (a + b) * 0.5
	var d := b - a
	d.y = 0.0
	var sep := maxf(d.length(), 0.5)
	var side := d.normalized().cross(Vector3.UP)
	var dist := clampf(sep * 0.95, 2.4, 4.6)
	# dei due lati si sceglie quello più lontano dagli altri campioni (nessuno davanti all'obiettivo),
	# a parità quello verso la telecamera di gioco
	var best := Vector3.ZERO
	var best_v := -1e9
	for sgn in [1.0, -1.0]:
		var cand: Vector3 = m + side * sgn * dist + Vector3(0, 1.9, 0)
		var clear := 1e9
		for f in seats:
			if f:
				var fp := f.global_position
				var seg := _dist_to_segment(fp, cand, m)
				clear = minf(clear, seg)
		var v := clear + (0.3 if cand.z > m.z else 0.0)
		if v > best_v:
			best_v = v
			best = cand
	var pos := best
	_cam_goal = Transform3D(Basis(), pos).looking_at(m + Vector3(0, 1.05, 0), Vector3.UP)
	_close_up(true)
	_cam_speed = speed


## Inquadratura su un solo campione (morte).
func focus_one(p: Vector3, speed := 3.0) -> void:
	var out := p.normalized() if p.length() > 0.1 else Vector3.BACK
	var pos := p * 0.35 + Vector3(0, 2.0, 0) + Vector3(0, 0, 1.6)
	if out.z > 0.5:   # il tuo posto: guardato di tre quarti, non da dentro la telecamera
		pos = p + Vector3(1.8, 2.0, -2.0)
	_cam_goal = Transform3D(Basis(), pos).looking_at(p + Vector3(0, 1.0, 0), Vector3.UP)
	_close_up(true)
	_cam_speed = speed


## Torna all'inquadratura di gioco.
func focus_home(speed := 2.5) -> void:
	_cam_goal = _cam_home
	_close_up(false)
	_cam_speed = speed


## Numero del danno che sale e svanisce sopra un campione.
func damage_number(at: Vector3, text: String, c: Color) -> void:
	var l := Label3D.new()
	l.font = Stile.font_num()
	l.font_size = 110
	l.pixel_size = 0.0026
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.outline_size = 12
	l.outline_modulate = Color(0.08, 0.0, 0.0, 0.95)
	l.modulate = c
	l.text = text.replace("-", "−")     # meno tipografico, più largo del trattino
	add_child(l)
	l.global_position = at
	l.scale = Vector3.ONE * 0.4
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * 1.15, 0.15).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(l, "global_position", at + Vector3(0, 0.9, 0), 1.2).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


## Scintille che schizzano dal punto colpito.
func sparks(at: Vector3, c: Color, amount := 28, speed := 3.5) -> void:
	var p := GPUParticles3D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.7
	p.explosiveness = 1.0
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, 1, 0)
	m.spread = 180.0
	m.initial_velocity_min = speed * 0.4
	m.initial_velocity_max = speed
	m.gravity = Vector3(0, -6, 0)
	m.scale_min = 0.5
	m.scale_max = 1.2
	var g := Gradient.new()
	g.set_color(0, Color(c.r * 2.0, c.g * 2.0, c.b * 2.0, 1.0))
	g.set_color(1, Color(c.r, c.g * 0.3, c.b * 0.2, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m
	p.draw_pass_1 = _spark_mesh()
	add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


static var _spark_q: QuadMesh


func _spark_mesh() -> QuadMesh:
	if _spark_q == null:
		_spark_q = QuadMesh.new()
		_spark_q.size = Vector2(0.035, 0.035)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.vertex_color_use_as_albedo = true
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 32
		gt.height = 32
		sm.albedo_texture = gt
		_spark_q.material = sm
	return _spark_q


## Fumo ai piedi dell'altare: sbuffi morbidi che nascono attorno alla base, strisciano sul terreno allargandosi e
## svaniscono. Prendono la luce del fuoco (non sono luminosi da soli) e sfumano dove toccano il suolo.
func _altar_smoke() -> void:
	var p := GPUParticles3D.new()
	p.amount = 110
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.randomness = 0.5
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = 0.95
	m.emission_ring_inner_radius = 0.6
	m.emission_ring_height = 0.05
	m.direction = Vector3(0, 1, 0)
	m.spread = 20.0
	m.initial_velocity_min = 0.02
	m.initial_velocity_max = 0.06
	m.radial_velocity_min = 0.12           # si allarga verso l'esterno, basso sul terreno
	m.radial_velocity_max = 0.3
	m.gravity = Vector3(0, -0.01, 0)
	m.damping_min = 0.02
	m.damping_max = 0.05
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.25
	m.turbulence_noise_scale = 3.0
	m.angle_min = 0.0
	m.angle_max = 360.0
	m.angular_velocity_min = -12.0
	m.angular_velocity_max = 12.0
	m.scale_min = 0.7
	m.scale_max = 1.2
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.45))
	sc.add_point(Vector2(1.0, 1.6))
	var sct := CurveTexture.new()
	sct.curve = sc
	m.scale_curve = sct
	var g := Gradient.new()
	g.set_color(0, Color(0.78, 0.75, 0.72, 0.0))
	g.add_point(0.2, Color(0.78, 0.75, 0.72, 0.7))
	g.add_point(0.65, Color(0.7, 0.68, 0.66, 0.45))
	g.set_color(g.get_point_count() - 1, Color(0.5, 0.5, 0.5, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(1.5, 0.95)
	var sm := StandardMaterial3D.new()
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.vertex_color_use_as_albedo = true
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.albedo_texture = _smoke_puff()
	sm.roughness = 1.0
	sm.proximity_fade_enabled = true       # niente taglio netto dove il fumo tocca il terreno
	sm.proximity_fade_distance = 0.35
	sm.disable_receive_shadows = true
	q.material = sm
	p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.position = Vector3(0, 0.12, 0)
	p.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 3, 8))
	add_child(p)


## Uno sbuffo di fumo: macchia morbida con il bordo irregolare (rumore), fatta una volta sola.
static var _puff: Texture2D


static func _smoke_puff() -> Texture2D:
	if _puff:
		return _puff
	var s := 96
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 5
	n.frequency = 0.06
	n.fractal_octaves = 4
	for y in s:
		for x in s:
			var d := Vector2(x - s * 0.5, y - s * 0.5).length() / (s * 0.5)
			var cloud := n.get_noise_2d(x, y) * 0.5 + 0.5
			var a := clampf(1.0 - d * (1.15 - 0.45 * cloud), 0.0, 1.0)
			a = a * a * (0.6 + 0.4 * cloud)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_puff = ImageTexture.create_from_image(img)
	return _puff


## Particelle continue (braci, cenere): emissione in una scatola, salgono piano.
func _drift(at: Vector3, box: Vector3, c: Color, amount: int, life: float, up: float, size: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = box
	m.direction = Vector3(0, 1, 0)
	m.spread = 25.0
	m.initial_velocity_min = up * 0.5
	m.initial_velocity_max = up
	m.gravity = Vector3(0.05, 0.0, 0.0)
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.6
	m.turbulence_noise_scale = 2.0
	m.scale_min = size * 0.5
	m.scale_max = size
	var g := Gradient.new()
	g.set_color(0, Color(c, 0.0))
	g.add_point(0.2, c)
	g.set_color(g.get_point_count() - 1, Color(c, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m
	p.draw_pass_1 = _spark_mesh()
	p.position = at
	p.visibility_aabb = AABB(-box - Vector3(2, 2, 2), box * 2.0 + Vector3(4, 8, 4))
	add_child(p)
	return p


## Atmosfera: luce dall'alto con i raggi nella nebbia, foschia a terra, braci dall'altare, cenere nell'aria.
func _atmosphere() -> void:
	var beam := SpotLight3D.new()
	beam.light_color = Color(0.72, 0.8, 1.0)
	beam.light_energy = 3.2
	beam.spot_range = 14.0
	beam.spot_angle = 26.0
	beam.spot_attenuation = 0.6
	beam.shadow_enabled = true
	beam.light_volumetric_fog_energy = 2.2
	beam.position = Vector3(0.6, 9.0, 0.8) if scenario != 2 else Vector3(0.15, 9.5, 0.2)
	add_child(beam)
	beam.look_at(Vector3.ZERO, Vector3.FORWARD)
	# la nebbia sta solo ai piedi dell'altare (richiesta dell'utente, 21/10): uno strato basso attorno alla base
	# e il fumo che striscia sul terreno (_altar_smoke)
	var fog := FogVolume.new()
	fog.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	fog.size = Vector3(5.0, 0.8, 5.0)
	fog.position = Vector3(0, 0.1, 0)
	var fm := FogMaterial.new()
	fm.density = [0.22, 0.26, 0.12, 0.14][clampi(scenario, 0, 3)]
	fm.albedo = [Color(0.55, 0.65, 0.6), Color(0.6, 0.62, 0.72), Color(0.6, 0.55, 0.48), Color(0.85, 0.9, 1.0)][clampi(scenario, 0, 3)]
	fm.height_falloff = 1.6
	fm.edge_fade = 0.4
	fog.material = fm
	add_child(fog)
	_altar_smoke()
	_drift(Vector3(0, 0.6, 0), Vector3(0.25, 0.05, 0.25), Color(1.0, 0.45, 0.12), 46, 3.5, 0.7, 1.0)
	_drift(Vector3(0, 2.0, 0), Vector3(6, 2, 6), Color(0.4, 0.4, 0.38, 0.6), 110, 9.0, 0.08, 0.45)


# ------------------------------------------------------------------ effetti dei colpi

## Proiettile luminoso da a verso b (freccia, maledizione, fiammata, fendente).
func shoot(from: Vector3, to: Vector3, c: Color, dur := 0.35, big := 1.0) -> void:
	var n := Node3D.new()
	add_child(n)
	n.global_position = from
	var mat := Mats.emissive(c, 6.0)
	Geo.add(n, Geo.sphere(0.07 * big, 12, 6), mat, Vector3.ZERO, Vector3.ZERO, false)
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 2.5 * big
	l.omni_range = 2.5
	n.add_child(l)
	# scia: braci che restano indietro
	var trail := _drift(Vector3.ZERO, Vector3(0.02, 0.02, 0.02), c, 40, 0.4, 0.05, 1.3 * big)
	trail.local_coords = false
	remove_child(trail)
	n.add_child(trail)
	var tw := create_tween()
	tw.tween_property(n, "global_position", to, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	_burst(to, c, big)
	sparks(to, c, int(18 * big), 3.0)
	n.queue_free()


func _burst(at: Vector3, c: Color, big := 1.0) -> void:
	var n := Node3D.new()
	add_child(n)
	n.global_position = at
	var mat := Mats.emissive(c, 5.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var s := Geo.add(n, Geo.sphere(0.25 * big, 16, 8), mat, Vector3.ZERO, Vector3.ZERO, false)
	var tw := create_tween()
	tw.tween_property(s, "scale", Vector3.ONE * 2.2, 0.3)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.parallel().tween_property(mat, "emission_energy_multiplier", 0.0, 0.3)
	tw.tween_callback(n.queue_free)


## Il drago del domatore si alza e soffia fuoco su tutti i bersagli.
func dragon_fire(tamer: Figura, targets: Array[Vector3]) -> void:
	if tamer.dragon == null:
		return
	var d := tamer.dragon
	var home := d.position
	var tw := create_tween()
	tw.tween_property(d, "position", home + Vector3(0.4, 0.9, -0.6), 0.45).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(d, "scale", Vector3.ONE * 3.0, 0.45)
	await tw.finished
	shake(0.8)
	for t in targets:
		shoot(d.global_position, t, Color(1.0, 0.45, 0.1), 0.45, 1.8)
	await get_tree().create_timer(0.5).timeout
	var back := create_tween()
	back.tween_property(d, "position", home, 0.5)
	back.parallel().tween_property(d, "scale", Vector3.ONE, 0.5)


## Il Custode parla: gli occhi si accendono.
func custode_speak() -> void:
	if _custode_eyes == null:
		return
	var tw := create_tween()
	tw.tween_property(_custode_eyes, "emission_energy_multiplier", 14.0, 0.15)
	tw.tween_property(_custode_eyes, "emission_energy_multiplier", 4.0, 1.2)


func circle_pulse(c: Color) -> void:
	var old: Color = _circle_mat.get_shader_parameter("glow_color")
	_circle_mat.set_shader_parameter("glow_color", c)
	var tw := create_tween()
	tw.tween_method(func(e: float) -> void: _circle_mat.set_shader_parameter("energy", e), 1.0, 3.5, 0.15)
	tw.tween_method(func(e: float) -> void: _circle_mat.set_shader_parameter("energy", e), 3.5, 1.0, 0.9)
	tw.tween_callback(func() -> void: _circle_mat.set_shader_parameter("glow_color", old))


# ------------------------------------------------------------------ costruzione

func _environment() -> void:
	env = Environment.new()
	# cielo notturno vero (Poly Haven, CC0): sfondo nella nebbia, luce diffusa e riflessi
	var sky_mat := PanoramaSkyMaterial.new()
	sky_mat.panorama = load("res://assets/scenari/cielo/kloppenheim_02_puresky_2k.hdr")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.background_energy_multiplier = 0.15     # fondo molto scuro
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.ambient_light_energy = 0.18
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.15
	env.ssao_enabled = true
	env.ssao_radius = 0.8
	env.ssao_intensity = 1.4
	env.glow_enabled = true
	env.glow_intensity = 0.95
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.038        # quanto basta per i raggi del controluce: il luogo resta visibile
	env.volumetric_fog_albedo = [Color(0.62, 0.72, 0.7), Color(0.6, 0.64, 0.75), Color(0.62, 0.56, 0.5), Color(0.8, 0.86, 0.95)][clampi(scenario, 0, 3)]
	# riflessi sul bagnato: cimitero sotto la pioggia, pietra levigata della cripta, ghiaccio del lago
	env.ssr_enabled = scenario >= 1
	env.ssr_max_steps = 48
	env.volumetric_fog_anisotropy = 0.6
	env.volumetric_fog_length = 24.0
	# foschia di profondità: oltre i 25 metri le cose sfumano nel colore della notte (niente orizzonte vuoto)
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = [Color(0.05, 0.07, 0.09), Color(0.06, 0.07, 0.09), Color(0.04, 0.035, 0.03), Color(0.12, 0.15, 0.2)][clampi(scenario, 0, 3)]
	env.fog_light_energy = 1.0
	env.fog_depth_begin = 22.0
	env.fog_depth_end = 75.0
	env.fog_depth_curve = 1.4
	env.fog_sky_affect = 0.85
	if scenario == 3:          # il lago è aperto: la foschia comincia più lontano, si vedono le montagne
		env.fog_depth_begin = 34.0
		env.fog_depth_end = 110.0
	if scenario == 2:          # la cripta è chiusa: dal cielo arriva solo poca luce, il resto lo fanno le torce
		env.ambient_light_energy = 0.05
		env.ssao_intensity = 2.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.9
	Grafica.ambiente(env)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _circle() -> void:
	# la firma visiva (ISTRUZIONI_ATMOSFERA.txt, fase 1): il cerchio rituale luminoso a terra, arancione, con anelli,
	# stella a sette punte e lettere greche; gira piano e pulsa come un respiro (shaders/sigillo.gdshader)
	_circle_mat = _sigil_mat("res://assets/cerchi/cerchio_terra.png", 4.0, 0.0)
	var pm := PlaneMesh.new()
	pm.size = Vector2(5.6, 5.6)
	Geo.add(self, pm, _circle_mat, Vector3(0, 0.025, 0), Vector3.ZERO, false)
	_signature()
	_altar_root = Node3D.new()
	_altar_root.position = Vector3(0, ALTAR_LIFT, 0)
	add_child(_altar_root)
	_altar()
	_fire(Vector3(0, ALTAR_TOP + 0.08, 0))
	_altar_tether()
	# 22/10 (richiesta dell'utente): l'altare non vola più, sta a terra in mezzo al tavolo di pietra; le catene della
	# terra sotto l'altare sospeso non servono più (il codice resta, spento)
	_ground_on = false
	for nd in _ground_nodes:
		(nd as Node3D).visible = false
	_lift = 0.0
	_lift_goal = 0.0
	_table()
	# il cerchio manda un riflesso rosso basso sull'altare e sul terreno
	for k in 4:
		var ang := TAU * k / 4.0 + PI / 4.0
		var gl := OmniLight3D.new()
		gl.light_color = Color(1.0, 0.34, 0.08)
		gl.light_energy = 0.7
		gl.omni_range = 2.2
		gl.light_specular = 0.0          # niente puntini lucidi sul ghiaccio e sull acqua
		gl.position = Vector3(sin(ang) * 1.6, 0.25, cos(ang) * 1.6)
		add_child(gl)


const ALTAR_TOP := 1.06            # altezza del piano dell'altare sopra la sua base, dove sta il braciere
const ALTAR_LIFT := 0.5            # l'altare galleggia sopra il cerchio: lo tengono giù le catene
var _altar_root: Node3D            # l'altare, il fuoco e le fiamme raccolte: si muovono insieme
var _lift := ALTAR_LIFT            # altezza dell'altare adesso; nelle Catene parte da terra e sale con le candele
var _lift_goal := ALTAR_LIFT
var _ground_nodes: Array[Node] = [] # catene, pali e zolle che tengono l'altare a terra (nascosti in partita)
var _ground_on := true


## L'altare: tre gradini dal bordo arrotondato, zoccolo modanato, colonna a otto facce con colonnine tortili
## agli spigoli e riquadri incisi di rune che pulsano come brace, capitello con dentelli, catene di ferro
## appese fra le colonnine, colature di cera scura, e il braciere di pietra col falò.
func _altar() -> void:
	var stone := _on_object(Scenari.pbr("mossy_rock", 1.0) if scenario == 0 else Scenari.pbr("castle_wall_varriation", 1.0, Color(0.6, 0.6, 0.6)))
	var dark := _on_object(Scenari.pbr("castle_wall_varriation", 1.0, Color(0.5, 0.47, 0.45)))
	var oct := Vector3(0, 22.5, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	# gradini con lo spigolo arrotondato (consumati da chi ci è salito)
	var y := 0.0
	var steps := [[1.0, 0.13], [0.86, 0.13], [0.72, 0.12]]
	for i in steps.size():
		var a: float = steps[i][0]
		var h: float = steps[i][1]
		var inner: float = steps[i + 1][0] - 0.02 if i + 1 < steps.size() else 0.5
		Geo.add(_altar_root, _oct_lathe(PackedVector2Array([Vector2(a + 0.02, y), Vector2(a + 0.02, y + h * 0.15),
			Vector2(a, y + h * 0.3), Vector2(a, y + h - 0.035), Vector2(a - 0.008, y + h - 0.012),
			Vector2(a - 0.03, y + h), Vector2(inner, y + h)])), stone)
		y += h
	# zoccolo modanato: toro, gola, listello
	var base := y
	Geo.add(_altar_root, _oct_lathe(PackedVector2Array([Vector2(0.62, y), Vector2(0.63, y + 0.02), Vector2(0.615, y + 0.04),
		Vector2(0.575, y + 0.05), Vector2(0.545, y + 0.065), Vector2(0.53, y + 0.085), Vector2(0.53, y + 0.1),
		Vector2(0.49, y + 0.1)])), dark)
	y += 0.1
	var col_h := ALTAR_TOP - 0.16 - y
	Geo.add(_altar_root, Geo.cyl(0.5, 0.5, col_h, 8), stone, Vector3(0, y + col_h * 0.5, 0), oct)
	var apothem := 0.5 * cos(PI / 8.0)
	_rune_mat = StandardMaterial3D.new()
	_rune_mat.albedo_color = Color(0.08, 0.02, 0.01)
	_rune_mat.emission_enabled = true
	_rune_mat.emission = Color(0.9, 0.2, 0.06)
	_rune_mat.emission_energy_multiplier = 1.4
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.1, 0.09, 0.085)
	iron.metallic = 0.85
	iron.roughness = 0.45
	var twists: Array = []
	for k in 8:
		var a := TAU * k / 8.0
		var nrm := Vector3(sin(a), 0, cos(a))
		# colonnina tortile sullo spigolo: due fusti che si avvolgono, con base e capitello
		var ce := TAU * (k + 0.5) / 8.0
		var corner := Vector3(sin(ce), 0, cos(ce)) * 0.53
		for strand in 2:
			var ph := PI * strand
			twists.append([Geo.tube(func(t: float) -> Vector3:
					var w := ph + t * TAU * 3.0
					return corner + Vector3(cos(w) * 0.018, y + 0.04 + t * (col_h - 0.08), sin(w) * 0.018),
				func(_t: float) -> float: return 0.026, 6, 40), Transform3D()])
		twists.append([Geo.cyl(0.062, 0.07, 0.045, 10), Transform3D(Basis(), corner + Vector3(0, y + 0.022, 0))])
		twists.append([Geo.cyl(0.07, 0.058, 0.045, 10), Transform3D(Basis(), corner + Vector3(0, y + col_h - 0.022, 0))])
		# riquadro incassato con cornice e una runa che brilla
		var face := Node3D.new()
		_altar_root.add_child(face)
		face.position = nrm * (apothem + 0.004) + Vector3(0, y + col_h * 0.5, 0)
		face.rotation.y = a
		var pw := 0.26
		var ph_ := col_h * 0.66
		for fr in [[Vector3(0, ph_ * 0.5, 0), Vector3(pw + 0.05, 0.025, 0.02)], [Vector3(0, -ph_ * 0.5, 0), Vector3(pw + 0.05, 0.025, 0.02)],
				[Vector3(pw * 0.5, 0, 0), Vector3(0.025, ph_, 0.02)], [Vector3(-pw * 0.5, 0, 0), Vector3(0.025, ph_, 0.02)]]:
			Geo.add(face, Geo.box(fr[1]), dark, fr[0])
		Geo.add(face, Geo.box(Vector3(pw, ph_, 0.004)), dark, Vector3(0, 0, -0.002))
		var pts: Array[Vector2] = []
		for i in 9:
			pts.append(Vector2((i % 3 - 1) * 0.07, (i / 3 - 1) * 0.11))
		for st in rng.randi_range(3, 4):
			var p0 := pts[rng.randi() % 9]
			var p1 := pts[rng.randi() % 9]
			if p0 == p1:
				continue
			var stroke := Node3D.new()
			face.add_child(stroke)
			Geo.orient_between(stroke, Vector3(p0.x, p0.y, 0.004), Vector3(p1.x, p1.y, 0.004))
			Geo.add(stroke, Geo.box(Vector3(0.016, p0.distance_to(p1) + 0.016, 0.006)), _rune_mat, Vector3.ZERO, Vector3.ZERO, false)
		# le rune rischiarano di rosso la pietra scolpita attorno (una luce piccola ogni due facce)
		if k % 2 == 0:
			var gl := OmniLight3D.new()
			gl.light_color = Color(1.0, 0.22, 0.07)
			gl.light_energy = 0.5
			gl.omni_range = 0.85
			gl.light_specular = 0.1
			gl.position = nrm * (apothem + 0.28) + Vector3(0, y + col_h * 0.5, 0)
			_altar_root.add_child(gl)
			_rune_lights.append(gl)
	_add_merged(twists, dark)
	y += col_h
	# capitello: gola, dentelli sotto la lastra, lastra smussata con un listello
	Geo.add(_altar_root, _oct_lathe(PackedVector2Array([Vector2(0.47, y), Vector2(0.5, y + 0.01), Vector2(0.54, y + 0.03),
		Vector2(0.585, y + 0.05), Vector2(0.6, y + 0.06), Vector2(0.6, y + 0.07), Vector2(0.45, y + 0.07)])), dark)
	var dent: Array = []
	for k in 8:
		var a := TAU * k / 8.0
		var nrm := Vector3(sin(a), 0, cos(a))
		var side := Vector3(cos(a), 0, -sin(a))
		for j in 7:
			var off := (j - 3) * 0.055
			dent.append([Geo.box(Vector3(0.03, 0.03, 0.035)), Transform3D(Basis(Vector3.UP, a), nrm * 0.585 + side * off + Vector3(0, y + 0.085, 0))])
	_add_merged(dent, dark)
	Geo.add(_altar_root, _oct_lathe(PackedVector2Array([Vector2(0.45, y + 0.1), Vector2(0.67, y + 0.1), Vector2(0.68, y + 0.115),
		Vector2(0.68, y + 0.135), Vector2(0.665, y + 0.15), Vector2(0.64, y + 0.155), Vector2(0.64, ALTAR_TOP),
		Vector2(0.3, ALTAR_TOP)])), stone)
	# colature di cera scura dal bordo del piano, giù lungo la colonna
	var wax := StandardMaterial3D.new()
	wax.albedo_color = Color(0.22, 0.03, 0.025)
	wax.roughness = 0.25
	wax.clearcoat_enabled = true
	var drips: Array = []
	for k in 5:
		var a := TAU * rng.randi_range(0, 7) / 8.0 + rng.randf_range(-0.25, 0.25)
		var r_edge := 0.68 / cos(absf(wrapf(a, -PI / 8.0, PI / 8.0)))
		for j in rng.randi_range(2, 4):
			var aa := a + rng.randf_range(-0.12, 0.12)
			var n2 := Vector3(sin(aa), 0, cos(aa))
			var len := rng.randf_range(0.03, 0.09)
			drips.append([Geo.capsule(0.009, len), Transform3D(Basis(), n2 * (r_edge * 0.995) + Vector3(0, ALTAR_TOP - 0.03 - len * 0.4, 0))])
	_add_merged(drips, wax)
	Scenari.prop(_altar_root, "stone_fire_pit", Vector3(0, ALTAR_TOP - 0.01, 0), 0.4, 0.62)
	var fl := FlickerLight.new()
	fl.light_color = Color(1.0, 0.45, 0.18)
	fl.base_energy = 1.6
	fl.omni_range = 7.0
	fl.shadow_enabled = true
	fl.position = Vector3(0, ALTAR_TOP + 0.6, 0)
	Grafica.luce(fl, 0.3)
	_altar_root.add_child(fl)
	# le rune pulsano piano, come brace che respira
	var tw := create_tween().set_loops()
	tw.tween_method(_rune_pulse, 0.0, 1.0, 2.2).set_trans(Tween.TRANS_SINE)
	tw.tween_method(_rune_pulse, 1.0, 0.0, 2.2).set_trans(Tween.TRANS_SINE)


var _rune_mat: StandardMaterial3D


## Le pietre dei luoghi sono proiettate dal mondo (niente giunte fra un sasso e l'altro); l'altare però si
## muove: la sua pietra va proiettata dall'oggetto, altrimenti i mattoni scivolerebbero sopra di lui.
func _on_object(m: StandardMaterial3D) -> StandardMaterial3D:
	var d := m.duplicate() as StandardMaterial3D
	d.uv1_world_triplanar = false
	return d
var _rune_lights: Array[OmniLight3D] = []


func _rune_pulse(v: float) -> void:
	_rune_mat.emission_energy_multiplier = lerpf(1.0, 2.3, v)
	for l in _rune_lights:
		l.light_energy = lerpf(0.3, 0.75, v)


## Più pezzi in una sola mesh (meno oggetti da disegnare).
func _add_merged(parts: Array, mat: Material) -> void:
	if parts.is_empty():
		return
	var mi := MeshInstance3D.new()
	mi.mesh = Scenari._merge(parts)
	mi.material_override = mat
	_altar_root.add_child(mi)


## Tornio a otto facce: il profilo (apotema, altezza) gira attorno all'asse con facce piane, ma resta morbido
## lungo il profilo (le modanature sembrano scolpite, non a gradini). Gli spigoli guardano come la colonna.
func _oct_lathe(prof: PackedVector2Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := prof.size()
	var k_corner := 1.0 / cos(PI / 8.0)
	# normale del profilo in ogni punto (media dei due tratti vicini, ma gli spigoli vivi restano vivi)
	var seg_n: Array[Vector2] = []
	for i in n - 1:
		var d := prof[i + 1] - prof[i]
		seg_n.append(Vector2(d.y, -d.x).normalized())
	for side in 8:
		var a := TAU * side / 8.0
		var nrm := Vector3(sin(a), 0, cos(a))
		var c0 := Vector3(sin(a - PI / 8.0), 0, cos(a - PI / 8.0)) * k_corner
		var c1 := Vector3(sin(a + PI / 8.0), 0, cos(a + PI / 8.0)) * k_corner
		for i in n - 1:
			var p0 := prof[i]
			var p1 := prof[i + 1]
			var na := seg_n[i]
			var nb := seg_n[i]
			if i > 0 and seg_n[i - 1].dot(seg_n[i]) > 0.7:
				na = (seg_n[i - 1] + seg_n[i]).normalized()
			if i + 1 < n - 1 and seg_n[i + 1].dot(seg_n[i]) > 0.7:
				nb = (seg_n[i + 1] + seg_n[i]).normalized()
			var v00 := c0 * p0.x + Vector3(0, p0.y, 0)
			var v01 := c1 * p0.x + Vector3(0, p0.y, 0)
			var v10 := c0 * p1.x + Vector3(0, p1.y, 0)
			var v11 := c1 * p1.x + Vector3(0, p1.y, 0)
			var n0 := (nrm * na.x + Vector3.UP * na.y).normalized()
			var n1 := (nrm * nb.x + Vector3.UP * nb.y).normalized()
			for v in [[v00, n0], [v10, n1], [v11, n1], [v00, n0], [v11, n1], [v01, n0]]:
				var pv: Vector3 = v[0]
				st.set_normal(v[1])
				st.set_uv(Vector2(pv.x + pv.z, pv.y))
				st.add_vertex(pv)
	st.generate_tangents()
	return st.commit()


const THRONE_POS := Vector3(0, 0, -5.15)
var throne: Node3D


func _custode() -> void:
	# il Custode del Cerchio (modello costruito in Blender da stoffe CC0 di Poly Haven): fluttua alle spalle
	# del cerchio, guarda i campioni; gli occhi brillano nel buio del cappuccio e si accendono quando parla
	# il trono di pietra nera del Custode (Meshy, approvato il 21/10; alleggerito con assets_src/trono): dietro
	# l'altare, sul bordo del cerchio, rivolto verso i campioni. Il Custode ci sta seduto (per alzarsi gli servira' lo
	# scheletro, fase 3 di ISTRUZIONI_ATMOSFERA.txt)
	throne = Scenari.prop(self, "trono", THRONE_POS, 0.0, 1.0)
	# il cerchio illumina il trono dal basso e dal davanti: pietra nera, ma si leggono gradini, guglie e catene
	var tl := SpotLight3D.new()
	tl.light_color = Color(1.0, 0.42, 0.14)
	tl.light_energy = 6.0
	tl.spot_range = 9.0
	tl.spot_angle = 34.0
	tl.shadow_enabled = true
	tl.light_volumetric_fog_energy = 0.3
	tl.position = THRONE_POS + Vector3(0, 0.6, 4.2)
	add_child(tl)
	tl.look_at(THRONE_POS + Vector3(0, 2.3, 0), Vector3.UP)
	# 2/11/2026: SEDUTO sul trono (assets_src/custode/custode_seduto.py piega il modello alle anche e alle ginocchia;
	# il modello e' gia' nelle coordinate del trono). Resta seduto: niente piu' fluttuare.
	custode = Node3D.new()
	custode.position = THRONE_POS
	add_child(custode)
	var body := Scenari.prop(custode, "custode_seduto", Vector3.ZERO, 0.0, 1.0)
	_custode_eyes = Mats.emissive(Color(1.0, 0.2, 0.1), 4.0)
	if body:
		for mi in body.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.name.to_lower().begins_with("occhi"):
				m.material_override = _custode_eyes
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.25, 0.15)
	l.light_energy = 0.5
	l.omni_range = 1.6
	l.light_specular = 0.0
	l.position = Vector3(0, 3.7, 0.15)               # davanti agli occhi, dentro il cappuccio
	custode.add_child(l)
	# respira piano, quasi immobile
	var tw := custode.create_tween().set_loops()
	tw.tween_property(custode, "scale", Vector3(1.0, 1.006, 1.004), 3.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(custode, "scale", Vector3.ONE, 3.4).set_trans(Tween.TRANS_SINE)


func _sigil_mat(path: String, brightness: float, phase: float, spin := -0.0242) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/sigillo.gdshader")
	m.set_shader_parameter("mask", load(path))
	m.set_shader_parameter("brightness", brightness)
	m.set_shader_parameter("phase", phase)
	m.set_shader_parameter("spin", spin)
	m.set_shader_parameter("glow_color", Color(1.0, 0.32, 0.06))
	return m


## Il resto della firma visiva, uguale in tutti i luoghi: tre cerchi sospesi dietro il Custode che girano e galleggiano,
## una forte luce arancione alle sue spalle che fa raggi nella nebbia e sagome scure, la luce del cerchio dal basso e
## polvere luminosa sospesa.
func _signature() -> void:
	var rings := [["res://assets/cerchi/cerchio_aria_9.png", Vector3(0, 3.6, -9.4), 4.6, 0.0, 0.7, 0.0],
		["res://assets/cerchi/cerchio_aria_5.png", Vector3(-4.2, 2.6, -8.4), 2.6, 1.3, -1.05, 0.35],
		["res://assets/cerchi/cerchio_aria_8.png", Vector3(4.2, 2.6, -8.4), 2.6, 2.6, 0.95, -0.35]]
	for rg in rings:
		var q := QuadMesh.new()
		q.size = Vector2(rg[2], rg[2])
		var holder := Node3D.new()
		holder.position = rg[1]
		holder.rotation.y = rg[5]                         # girati appena verso il centro
		add_child(holder)
		var mi := Geo.add(holder, q, _sigil_mat(rg[0], 3.2, rg[3], deg_to_rad(rg[4] * 40.0) / 18.0), Vector3.ZERO, Vector3.ZERO, false)
		var y0: float = rg[1].y
		var tw := holder.create_tween().set_loops()
		tw.tween_property(holder, "position:y", y0 + 0.18, 4.5 + rg[3]).set_trans(Tween.TRANS_SINE)
		tw.tween_property(holder, "position:y", y0, 4.5 + rg[3]).set_trans(Tween.TRANS_SINE)
		mi.name = "CerchioSospeso"
	# controluce arancione dietro il Custode: raggi nella nebbia e sagome scure
	var back := SpotLight3D.new()
	back.light_color = Color(1.0, 0.45, 0.15)
	back.light_energy = 7.0
	back.spot_range = 22.0
	back.spot_angle = 38.0
	back.spot_attenuation = 0.8
	back.shadow_enabled = true
	back.light_volumetric_fog_energy = 2.2
	back.light_specular = 0.3
	back.position = Vector3(0, 5.0, -12.5)
	add_child(back)
	back.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	# la luce del cerchio, dal basso
	var under := OmniLight3D.new()
	under.light_color = Color(1.0, 0.38, 0.1)
	under.light_energy = 1.0
	under.omni_range = 4.5
	under.light_specular = 0.1
	under.position = Vector3(0, 0.35, 0)
	add_child(under)
	# polvere luminosa sospesa, che sale lenta
	var dust := _drift(Vector3(0, 2.2, -1.0), Vector3(6.5, 2.2, 6.0), Color(1.0, 0.55, 0.25), 260, 14.0, 0.03, 0.6)
	dust.name = "Polvere"


func _lights() -> void:
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 0.32          # fredda e debole, di lato: la luce forte è il controluce arancione
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-24, 200, 0)   # controluce: la luna è dietro il Custode, le sagome si staccano dalla nebbia
	moon.light_volumetric_fog_energy = 1.6
	if Grafica.livello != Grafica.MEDIA:
		moon.light_angular_distance = 0.6      # ombre della luna che sfumano con la distanza
	moon.visible = scenario != 2      # nella cripta la luna entra solo dall'apertura della volta
	add_child(moon)


func labels(on: bool) -> void:
	for f in seats:
		if f:
			f.labels(on)


# ------------------------------------------------------------------ carte dei Presagi

var _omen_cards: Array[Node3D] = []


func _card(font: Font) -> Node3D:
	var c := Node3D.new()
	add_child(c)
	var back := Mats.matte(Color(0.22, 0.03, 0.03), 0.6)
	back.emission_enabled = true
	back.emission = Color(0.35, 0.04, 0.02)
	back.emission_energy_multiplier = 0.4
	Geo.add(c, Geo.box(Vector3(0.5, 0.75, 0.012)), back, Vector3.ZERO, Vector3.ZERO, false)
	# occhio dorato sul dorso
	var gold := Mats.emissive(Color(1.0, 0.7, 0.25), 1.5)
	var eye := Geo.add(c, Geo.torus(0.07, 0.085, 24, 4), gold, Vector3(0, 0, -0.008), Vector3(90, 0, 0), false)
	eye.scale = Vector3(1.6, 1, 1)
	# fronte color pergamena (sul lato +Z)
	var front := Mats.matte(Color(0.75, 0.66, 0.5), 0.9)
	front.emission_enabled = true
	front.emission = Color(0.8, 0.68, 0.48)
	front.emission_energy_multiplier = 0.55
	var q := QuadMesh.new()
	q.size = Vector2(0.46, 0.71)
	Geo.add(c, q, front, Vector3(0, 0, 0.0065), Vector3.ZERO, false)
	return c


## Le carte cadono nel cerchio, il Custode ne estrae una e la gira verso di te.
func draw_omen(title: String, text: String, spd: float, on_flip: Callable) -> void:
	drop_omen()
	var font: Font = Stile.font_title()
	var body: Font = Stile.font_body()
	var n := 5
	for k in n:
		var c := _card(font)
		var a := TAU * k / n + 0.3
		c.position = Vector3(sin(a) * 0.4, 3.2 + k * 0.25, cos(a) * 0.4)
		c.rotation = Vector3(randf_range(-1, 1), randf() * TAU, randf_range(-1, 1))
		var dst := Vector3(sin(a) * 0.75, 0.03 + k * 0.004, cos(a) * 0.75)
		var tw := create_tween()
		tw.tween_interval(k * 0.09 * spd)
		tw.tween_property(c, "position", dst, 0.45 * spd).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(c, "rotation", Vector3(-PI * 0.5, a + PI, 0), 0.45 * spd)
		_omen_cards.append(c)
	await get_tree().create_timer((0.45 + n * 0.09 + 0.35) * spd).timeout
	# la carta scelta si alza davanti alla telecamera, ancora coperta
	var pick: Node3D = _omen_cards[randi() % n]
	var t1 := Label3D.new()
	t1.font = font
	t1.font_size = 56
	t1.pixel_size = 0.0011
	t1.modulate = Color(0.45, 0.05, 0.03)
	t1.text = title.to_upper()
	t1.width = 380
	t1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t1.position = Vector3(0, 0.22, 0.008)
	t1.outline_size = 0
	pick.add_child(t1)
	var t2 := Label3D.new()
	t2.font = body
	t2.font_size = 36
	t2.pixel_size = 0.0011
	t2.modulate = Color(0.12, 0.08, 0.05)
	t2.text = text
	t2.width = 370
	t2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t2.position = Vector3(0, -0.08, 0.008)
	t2.outline_size = 0
	pick.add_child(t2)
	var cam := camera.global_position
	var up := Vector3(0, 2.45, 1.75)
	var face := Transform3D.IDENTITY.translated(up).looking_at(cam, Vector3.UP)
	var back_basis := face.basis   # -Z verso di te: si vede il dorso
	var tw2 := create_tween()
	tw2.tween_property(pick, "position", up, 0.6 * spd).set_trans(Tween.TRANS_BACK)
	tw2.parallel().tween_property(pick, "quaternion", back_basis.get_rotation_quaternion(), 0.6 * spd)
	tw2.parallel().tween_property(pick, "scale", Vector3.ONE * 1.6, 0.6 * spd)
	await tw2.finished
	# girata
	custode_speak()
	on_flip.call()
	var front_q := face.basis.rotated(face.basis.y.normalized(), PI).get_rotation_quaternion()   # +Z verso di te: il fronte
	var tw3 := create_tween()
	tw3.tween_property(pick, "quaternion", front_q, 0.4 * spd).set_trans(Tween.TRANS_SINE)
	await tw3.finished
	circle_pulse(Color(1.0, 0.25, 0.1))


## Le carte svaniscono.
func drop_omen() -> void:
	for c in _omen_cards:
		if is_instance_valid(c):
			var tw := create_tween()
			tw.tween_property(c, "scale", Vector3.ONE * 0.01, 0.35)
			tw.tween_callback(c.queue_free)
	_omen_cards.clear()


# ------------------------------------------------------------------ altare

var _altar_flames: Array[MeshInstance3D] = []
var _altar_lbl: Label3D


func altar_pos() -> Vector3:
	return _altar_root.transform * Vector3(0, ALTAR_TOP + 0.3, 0)


## Mostra le fiamme raccolte sull'altare (una fiammella per ogni candela spenta).
func set_altar(n: float) -> void:
	var k := int(round(maxf(n, 0.0)))
	if _altar_lbl == null:
		_altar_lbl = Label3D.new()
		_altar_lbl.font = Stile.font_head()
		_altar_lbl.font_size = 60
		_altar_lbl.pixel_size = 0.0016
		_altar_lbl.outline_modulate = Color(0, 0, 0, 0.9)
		_altar_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_altar_lbl.no_depth_test = true
		_altar_lbl.outline_size = 12
		_altar_lbl.modulate = Color(1.0, 0.75, 0.4)
		_altar_lbl.position = Vector3(0, ALTAR_TOP + 1.75, 0.2)
		_altar_root.add_child(_altar_lbl)
	while _altar_flames.size() < k:
		var i := _altar_flames.size()
		var a := i * 0.52 + 0.2
		var r := 0.36 + 0.03 * (i % 2)
		var f := Geo.add(_altar_root, Geo.cyl(0.0, 0.035, 0.12, 8), Mats.emissive(Color(1.0, 0.55, 0.15), 5.0),
			Vector3(sin(a) * r, ALTAR_TOP + 0.24 + 0.01 * (i / 12), cos(a) * r), Vector3.ZERO, false)
		f.scale = Vector3.ONE * 0.01
		create_tween().tween_property(f, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
		_altar_flames.append(f)
	while _altar_flames.size() > k:
		var f: MeshInstance3D = _altar_flames.pop_back()
		var tw := create_tween()
		tw.tween_property(f, "scale", Vector3.ONE * 0.01, 0.25)
		tw.tween_callback(f.queue_free)
	# sull'altare vuoto non si scrive nulla: la scritta passava sopra il fuoco
	_altar_lbl.text = ("%d sull'altare" % k) if k > 0 else ""


## Una carta giocata compare sopra il campione e svanisce.
func flash_card(fig: Figura, title: String) -> void:
	var k := Carta.NOMI.find(title)
	var c := card3d(maxi(k, 0))
	c.global_position = fig.global_position + Vector3(0, 3.2, 0)
	_face_camera(c, true)
	c.scale = Vector3.ONE * 0.1
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(1.6)
	tw.tween_property(c, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(c.queue_free)


# ------------------------------------------------------------------ candele sull'altare (Catene dell'altare)

var _altar_candles: Array[Candle] = []


## Dodici candele in cerchio sul piano dell'altare: sono l'orologio della manche e si spengono una alla volta.
func altar_candles(n: int) -> void:
	for c in _altar_candles:
		c.queue_free()
	_altar_candles.clear()
	for i in n:
		var c := Candle.new()
		c.height = 0.13 + 0.05 * float((i * 5) % 7) / 6.0
		c.has_light = i % 4 == 0            # poche luci vere: bastano per far brillare la pietra attorno
		c.shadows = false
		c.energy = 0.5
		c.light_range = 1.6
		c.build()
		c.scale = Vector3.ONE * 1.5
		var a := TAU * (i + 0.5) / n
		c.position = Vector3(sin(a) * 0.55, ALTAR_TOP, cos(a) * 0.55)
		_altar_root.add_child(c)
		_altar_candles.append(c)


## Accese le prime `lit` candele; le altre si spengono (con il fumo) nell'ordine del giro.
func altar_candles_lit(lit: int, animated := true) -> void:
	for i in _altar_candles.size():
		var on := i < lit
		var c := _altar_candles[i]
		if c.lit == on:
			continue
		if not animated:
			c.set_lit_instant(on)
		elif on:
			c.relight()
		else:
			c.blow_out(0.15 * (i - lit))


# ------------------------------------------------------------------ carte 3D: mescolata e distribuzione

var _table_cards: Array[Node3D] = []
var _secret_card: Node3D
var _secret_spin: Tween
var _pivot: Node3D


## Una carta 3D con la faccia (Carta.texture) su +Z e il dorso su -Z.
func card3d(kind: int) -> Node3D:
	var c := Node3D.new()
	add_child(c)
	for side in [1, -1]:
		var q := QuadMesh.new()
		q.size = Vector2(0.36, 0.54)
		var m := StandardMaterial3D.new()
		var tex := Carta.texture(kind if side == 1 else -1)
		m.albedo_texture = tex
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.emission_enabled = true
		m.emission_texture = tex
		m.emission_energy_multiplier = 0.55        # si legge anche lontano dal fuoco
		m.roughness = 0.8
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(0, 0, 0.002 * side)
		if side == -1:
			mi.rotation.y = PI
		c.add_child(mi)
	return c


## Orienta la carta verso la telecamera: con la faccia (front) o con il dorso.
func _face_camera(c: Node3D, front: bool) -> void:
	var t := Transform3D.IDENTITY.translated(c.global_position).looking_at(camera.global_position, Vector3.UP)
	var b := t.basis
	if front:
		b = b.rotated(b.y.normalized(), PI)
	c.global_basis = b.orthonormalized() * Basis.from_scale(c.scale if c.scale.x > 0.001 else Vector3.ONE)


## Le carte giocate nel turno, coperte, si posano sul tavolo di pietra e scivolano in giro attorno all'altare, veloci,
## poi rallentano (22/10: si gioca sul tavolo); la carta segreta (il dono del Guardiano), se c'è, resta al centro del
## fuoco. Restituisce le carte, in ordine.
func shuffle_cards(n: int, secret: bool, spd := 1.0) -> Array[Node3D]:
	clear_cards()
	var pivot := Node3D.new()
	add_child(pivot)
	_pivot = pivot
	pivot.global_position = Vector3(0, TABLE_TOP + 0.004, 0)
	for k in n:
		var c := card3d(0)
		c.reparent(pivot, false)
		var a := TAU * k / maxf(n, 1)
		# coperta, distesa sul piano: la faccia (+Z) guarda la pietra, il lato lungo lungo il giro
		c.basis = Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, PI * 0.5)
		c.position = Vector3(sin(a), 0, cos(a)) * CARD_R + Vector3(0, 0.25, 0)
		c.scale = Vector3.ONE * 0.05
		var tw0 := create_tween()
		tw0.tween_property(c, "scale", Vector3.ONE, 0.25 * spd).set_delay(0.05 * k * spd)
		tw0.parallel().tween_property(c, "position:y", 0.0, 0.3 * spd).set_delay(0.05 * k * spd).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_table_cards.append(c)
	if secret:
		_secret_card = card3d(0)
		_secret_card.global_position = _altar_root.transform * Vector3(0, ALTAR_TOP + 0.35, 0)
		_secret_card.scale = Vector3.ONE * 0.05
		create_tween().tween_property(_secret_card, "scale", Vector3.ONE * 0.8, 0.4 * spd)
		_secret_spin = _secret_card.create_tween().set_loops()
		_secret_spin.tween_property(_secret_card, "rotation:y", TAU, 2.4).as_relative()
	# il giro veloce attorno al fuoco, che rallenta
	var tw := create_tween()
	tw.tween_property(pivot, "rotation:y", TAU * 2.5, 1.3 * spd).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	return _table_cards.duplicate()


## Una carta coperta scivola sul tavolo fino al posto del campione, si gira a faccia in su e mostra `kind`; poi si
## solleva appena e si volta verso la telecamera, perché si legga anche dall'altra parte del tavolo. Restituisce dove
## sta la carta (da lì parte il colpo).
func deal_card(c: Node3D, fig: Figura, kind: int, spd := 1.0) -> Vector3:
	if not is_instance_valid(c):
		c = card3d(kind)
	var gp := c.global_position
	var gb := c.global_basis
	c.reparent(self)
	c.global_position = gp
	c.global_basis = gb
	var dir := Vector3(fig.global_position.x, 0, fig.global_position.z).normalized()
	var spot := dir * CARD_R + Vector3(0, TABLE_TOP + 0.004, 0)
	var a := atan2(dir.x, dir.z)
	var down := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, PI * 0.5)       # coperta
	var up := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -PI * 0.5)        # scoperta, dritta per chi sta al posto
	var tw := create_tween()
	tw.tween_property(c, "global_position", spot, 0.4 * spd).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(c, "quaternion", down.get_rotation_quaternion(), 0.4 * spd)
	await tw.finished
	_set_face(c, kind)
	# si gira come una carta vera: si alza su un lato e ricade a faccia in su
	var tw1 := create_tween()
	tw1.tween_property(c, "global_position", spot + Vector3(0, 0.12, 0), 0.15 * spd).set_trans(Tween.TRANS_SINE)
	tw1.parallel().tween_property(c, "quaternion", up.get_rotation_quaternion(), 0.3 * spd).set_trans(Tween.TRANS_SINE)
	tw1.tween_property(c, "global_position", spot, 0.15 * spd).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw1.finished
	await get_tree().create_timer(0.15 * spd).timeout
	if not is_instance_valid(c):
		return spot
	# e si mostra: sollevata sopra il suo posto, girata verso chi guarda
	var show := spot + Vector3(0, 0.55, 0)
	var start := c.quaternion
	c.global_position = show
	_face_camera(c, true)
	var end := c.quaternion
	c.global_position = spot
	c.quaternion = start
	var tw2 := create_tween()
	tw2.tween_property(c, "global_position", show, 0.3 * spd).set_trans(Tween.TRANS_SINE)
	tw2.parallel().tween_property(c, "quaternion", end, 0.3 * spd).set_trans(Tween.TRANS_SINE)
	tw2.parallel().tween_property(c, "scale", Vector3.ONE * 1.25, 0.3 * spd)
	await tw2.finished
	return show


## La carta segreta, al centro del fuoco, si gira per ultima.
func reveal_secret(spd := 1.0) -> Vector3:
	if not is_instance_valid(_secret_card):
		_secret_card = card3d(Carta.DONO)
		_secret_card.global_position = _altar_root.transform * Vector3(0, ALTAR_TOP + 0.35, 0)
	var c := _secret_card
	if _secret_spin:
		_secret_spin.kill()
	_set_face(c, Carta.DONO)
	var dst := _altar_root.transform * Vector3(0, ALTAR_TOP + 1.1, 0)
	var tw := create_tween()
	tw.tween_property(c, "global_position", dst, 0.35 * spd)
	tw.parallel().tween_property(c, "scale", Vector3.ONE * 1.25, 0.35 * spd)
	await tw.finished
	_face_camera(c, true)
	_burst(dst, Color(1.0, 0.35, 0.1), 0.8)
	return dst


func _set_face(c: Node3D, kind: int) -> void:
	var front := c.get_child(0) as MeshInstance3D
	var m := front.material_override as StandardMaterial3D
	m.albedo_texture = Carta.texture(kind)
	m.emission_texture = m.albedo_texture


## Le foto dei campioni per la schermata del voto: una macchina fotografica davanti a ognuno, dal lato
## dell'altare, con più luce solo per lo scatto. Le scritte sopra i campioni si nascondono mentre si scatta.
## Restituisce posto -> texture (foto ferma).
func portraits() -> Dictionary:
	clear_portraits()
	for f in seats:
		if f:
			f.labels(false)
	var out := {}
	for i in seats.size():
		var fig := seats[i]
		if fig == null or not fig.visible:
			continue
		var vp := SubViewport.new()
		vp.size = Vector2i(360, 440)
		vp.world_3d = get_world_3d()
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		var cam := Camera3D.new()
		cam.fov = 34.0
		var e: Environment = env.duplicate() if env else Environment.new()
		e.tonemap_exposure *= 2.6
		e.ambient_light_energy = maxf(e.ambient_light_energy, 0.6) * 1.6
		cam.environment = e
		vp.add_child(cam)
		add_child(vp)
		var target := fig.chest() + Vector3(0, 0.1, 0)
		var inward := Vector3(-target.x, 0, -target.z).normalized()
		cam.global_position = target + inward * 2.3 + Vector3(0, 0.25, 0)
		cam.look_at(target, Vector3.UP)
		_portrait_vps.append(vp)
		out[i] = vp.get_texture()
	# due giri del gioco bastano perché le macchine scattino (senza finestra, nelle prove, non si disegna nulla)
	for k in 3:
		await get_tree().process_frame
	# la foto diventa un'immagine fissa: la schermata del voto non dipende più dalle macchine fotografiche
	if DisplayServer.get_name() != "headless":
		for i in out:
			var img: Image = (out[i] as Texture2D).get_image()
			if img and not img.is_empty():
				out[i] = ImageTexture.create_from_image(img)
	clear_portraits()
	for f in seats:
		if f:
			f.labels(true)
	return out


var _portrait_vps: Array[SubViewport] = []


func clear_portraits() -> void:
	for vp in _portrait_vps:
		if is_instance_valid(vp):
			vp.queue_free()
	_portrait_vps.clear()


## Le carte del turno svaniscono.
func clear_cards() -> void:
	for c in _table_cards + ([_secret_card] if is_instance_valid(_secret_card) else []):
		if is_instance_valid(c):
			var tw := create_tween()
			tw.tween_property(c, "scale", Vector3.ONE * 0.01, 0.3)
			tw.tween_callback(c.queue_free)
	_table_cards.clear()
	_secret_card = null
	if is_instance_valid(_pivot):
		_pivot.queue_free()


func _close_up(on: bool) -> void:
	labels(not on)
	if _altar_lbl:
		_altar_lbl.visible = not on


## Distanza in pianta di un punto dal segmento a-b (per capire se un campione copre l'inquadratura).
static func _dist_to_segment(p: Vector3, a: Vector3, b: Vector3) -> float:
	var p2 := Vector2(p.x, p.z)
	var a2 := Vector2(a.x, a.z)
	var b2 := Vector2(b.x, b.z)
	var ab := b2 - a2
	var t := clampf((p2 - a2).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p2.distance_to(a2 + ab * t)


## Lingua di fiamma: quadrato allungato con una sfumatura a goccia (base larga, punta stretta), additiva.
func _flame_quad() -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(0.22, 0.5)
	var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 32:
			var v := 1.0 - float(y) / 63.0          # 0 in basso, 1 in alto
			var half := 0.5 * (1.0 - v * v) + 0.04  # più stretta in alto
			var dx := absf((float(x) + 0.5) / 32.0 - 0.5) / half
			var a := clampf(1.0 - dx * dx, 0.0, 1.0) * clampf(1.0 - v * 0.9, 0.0, 1.0) * smoothstep(0.0, 0.12, v + 0.05)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var tex := ImageTexture.create_from_image(img)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.vertex_color_use_as_albedo = true
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.albedo_texture = tex
	q.material = sm
	return q


## Fuoco vivo: lingue di fiamma (particelle additive che salgono e si stringono) e fumo scuro sopra.
func _fire(at: Vector3) -> void:
	var flame := GPUParticles3D.new()
	flame.amount = 90
	flame.lifetime = 0.9
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.24
	m.direction = Vector3(0, 1, 0)
	m.spread = 12.0
	m.initial_velocity_min = 0.5
	m.initial_velocity_max = 1.1
	m.gravity = Vector3(0, 0.6, 0)
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 0.9
	m.scale_min = 0.7
	m.scale_max = 1.2
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.6))
	sc.add_point(Vector2(0.25, 1.0))
	sc.add_point(Vector2(1, 0.0))
	var sct := CurveTexture.new()
	sct.curve = sc
	m.scale_curve = sct
	var g := Gradient.new()
	g.set_color(0, Color(2.2, 1.3, 0.45, 0.9))
	g.add_point(0.35, Color(2.0, 0.7, 0.12, 0.8))
	g.add_point(0.7, Color(1.1, 0.22, 0.04, 0.45))
	g.set_color(g.get_point_count() - 1, Color(0.2, 0.02, 0.0, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	flame.process_material = m
	flame.draw_pass_1 = _flame_quad()
	flame.free()          # le vecchie fiamme a particelle: sostituite dalle lingue disegnate qui sotto
	# un vero falò: ceppi carbonizzati incrociati, letto di braci, tante fiammelle irregolari sopra
	var ember := ShaderMaterial.new()
	ember.shader = load("res://shaders/brace.gdshader")
	ember.set_shader_parameter("heat", 0.7)
	var bed := ember.duplicate() as ShaderMaterial
	bed.set_shader_parameter("heat", 1.3)
	Geo.add(_altar_root, Geo.cyl(0.3, 0.33, 0.06, 16), bed, at + Vector3(0, -0.06, 0), Vector3.ZERO, false)
	for k in 6:
		var a := TAU * k / 6.0 + randf_range(-0.2, 0.2)
		var log_node := Node3D.new()
		_altar_root.add_child(log_node)
		var foot := at + Vector3(sin(a) * 0.3, -0.04, cos(a) * 0.3)
		var tip := at + Vector3(sin(a + 0.4) * 0.05, randf_range(0.22, 0.32), cos(a + 0.4) * 0.05)
		Geo.orient_between(log_node, foot, tip)
		Geo.add(log_node, Geo.cyl(randf_range(0.035, 0.05), randf_range(0.05, 0.065), foot.distance_to(tip), 8), ember)
	# la fiamma: un volume di luce (shader fuoco_volume), pieno da ogni lato
	var vol := ShaderMaterial.new()
	vol.shader = load("res://shaders/fuoco_volume.gdshader")
	vol.set_shader_parameter("size", Vector3(0.9, 1.7, 0.9))
	vol.set_shader_parameter("radius", 0.36)
	vol.set_shader_parameter("seed", randf() * 10.0)
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 1.7, 0.9)
	var fire_box := MeshInstance3D.new()
	fire_box.mesh = box
	fire_box.material_override = vol
	fire_box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fire_box.position = at + Vector3(0, 0.85 - 0.04, 0)        # la scatola è centrata: base appena sotto le braci
	_altar_root.add_child(fire_box)
	# faville che salgono dal fuoco, girano nell'aria calda e si spengono
	var sp := GPUParticles3D.new()
	sp.amount = 45
	sp.lifetime = 2.4
	sp.preprocess = 2.4
	sp.visibility_aabb = AABB(Vector3(-1.5, -0.5, -1.5), Vector3(3, 5, 3))
	var spm := ParticleProcessMaterial.new()
	spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spm.emission_sphere_radius = 0.22
	spm.direction = Vector3(0, 1, 0)
	spm.spread = 18.0
	spm.initial_velocity_min = 0.8
	spm.initial_velocity_max = 2.0
	spm.gravity = Vector3(0, 0.25, 0)
	spm.turbulence_enabled = true
	spm.turbulence_noise_strength = 1.4
	spm.turbulence_noise_scale = 1.2
	spm.scale_min = 0.15
	spm.scale_max = 0.45
	var sg2 := Gradient.new()
	sg2.set_color(0, Color(3.0, 1.6, 0.5, 1.0))
	sg2.add_point(0.5, Color(2.2, 0.6, 0.1, 0.9))
	sg2.set_color(sg2.get_point_count() - 1, Color(0.8, 0.1, 0.02, 0.0))
	var sgt2 := GradientTexture1D.new()
	sgt2.gradient = sg2
	spm.color_ramp = sgt2
	sp.process_material = spm
	sp.draw_pass_1 = _spark_mesh()
	sp.position = at + Vector3(0, 0.15, 0)
	_altar_root.add_child(sp)
	# l'aria sopra il fuoco trema per il calore (lo sfondo dietro si deforma appena)
	var haze := ShaderMaterial.new()
	haze.shader = load("res://shaders/calore.gdshader")
	var hq := QuadMesh.new()
	hq.size = Vector2(1.3, 2.2)
	hq.center_offset = Vector3(0, 1.1, 0)
	var hmi := MeshInstance3D.new()
	hmi.mesh = hq
	hmi.material_override = haze
	hmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hmi.position = at + Vector3(0, 0.5, 0)
	_altar_root.add_child(hmi)
	var smoke := GPUParticles3D.new()
	smoke.amount = 24
	smoke.lifetime = 4.0
	var sm := ParticleProcessMaterial.new()
	sm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	sm.emission_sphere_radius = 0.15
	sm.direction = Vector3(0, 1, 0)
	sm.spread = 15.0
	sm.initial_velocity_min = 0.3
	sm.initial_velocity_max = 0.6
	sm.gravity = Vector3(0.05, 0.1, 0)
	sm.turbulence_enabled = true
	sm.scale_min = 12.0
	sm.scale_max = 20.0
	var sg := Gradient.new()
	sg.set_color(0, Color(0.1, 0.08, 0.07, 0.0))
	sg.add_point(0.2, Color(0.1, 0.08, 0.07, 0.35))
	sg.set_color(sg.get_point_count() - 1, Color(0.1, 0.1, 0.1, 0.0))
	var sgt := GradientTexture1D.new()
	sgt.gradient = sg
	sm.color_ramp = sgt
	smoke.process_material = sm
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.035)
	var mat := (_spark_mesh().material as StandardMaterial3D).duplicate() as StandardMaterial3D
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	q.material = mat
	smoke.draw_pass_1 = q
	smoke.position = at + Vector3(0, 0.5, 0)
	_altar_root.add_child(smoke)


# ------------------------------------------------------------------ altare sospeso e catene

const CHAIN_LINK := 0.058          # passo fra un anello e l'altro
var _chains: Array = []            # [ancora a terra, attacco sull'altare (locale), MultiMesh]
var _under_glow: OmniLight3D


## Sotto l'altare un blocco di roccia e terra strappato dal suolo, con radici che pendono; quattro catene
## dagli spigoli in alto ai pali di ferro piantati nel terreno, fra i posti dei campioni.
func _altar_tether() -> void:
	var rock := _on_object(Scenari.pbr("dark_rock", 0.8, Color(0.55, 0.5, 0.46)))
	var chunk := Geo.add(_altar_root, Geo.lathe(PackedVector2Array([Vector2(0.98, 0.0), Vector2(0.9, -0.08),
		Vector2(0.7, -0.17), Vector2(0.45, -0.25), Vector2(0.2, -0.31), Vector2(0.0, -0.33)]), 11, 0.16), rock)
	chunk.rotation.y = 0.3
	var roots: Array = []
	var rr := RandomNumberGenerator.new()
	rr.seed = 7
	for k in 7:
		var a := rr.randf() * TAU
		var r0 := rr.randf_range(0.25, 0.7)
		var start := Vector3(sin(a) * r0, -0.33 * (1.0 - r0) - 0.02, cos(a) * r0)
		var drop := rr.randf_range(0.12, 0.3)
		var bend := Vector3(rr.randf_range(-0.08, 0.08), 0, rr.randf_range(-0.08, 0.08))
		roots.append([Geo.tube(func(t: float) -> Vector3: return start + bend * t * t + Vector3(0, -drop * t, 0),
			func(t: float) -> float: return 0.018 * (1.0 - t) + 0.003, 5, 10), Transform3D()])
	_add_merged(roots, _on_object(Scenari.pbr("pine_bark", 0.3, Color(0.3, 0.24, 0.2))))
	# bagliore rosso sotto: il cerchio si vede attraverso il vuoto
	_under_glow = OmniLight3D.new()
	_under_glow.light_color = Color(1.0, 0.25, 0.08)
	_under_glow.light_energy = 0.6
	_under_glow.omni_range = 1.8
	_under_glow.light_specular = 0.0
	_under_glow.position = Vector3(0, 0.12, 0)
	add_child(_under_glow)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.12, 0.105, 0.1)
	iron.metallic = 0.85
	iron.roughness = 0.42
	var dirt := Scenari.pbr("dark_rock", 0.6, Color(0.4, 0.36, 0.32))
	var link := Geo.torus(0.012, 0.027, 12, 6)
	var corner_r := 0.68 / cos(PI / 8.0) - 0.03
	var first_ground := get_child_count()
	for k in 4:
		var ce := TAU * (2 * k + 1.5) / 8.0           # spigoli fra i posti dei campioni
		var dir := Vector3(sin(ce), 0, cos(ce))
		var anchor := dir * 1.85 + Vector3(0, 0.13, 0)
		# palo di ferro piantato a terra, con l'anello e una zolla smossa attorno
		Geo.add(self, Geo.cyl(0.022, 0.034, 0.34, 8), iron, dir * 1.85 + Vector3(0, 0.05, 0), Vector3(rad_to_deg(-dir.z * 0.2), 0, rad_to_deg(dir.x * 0.2)))
		var ring := Geo.add(self, Geo.torus(0.022, 0.04, 14, 6), iron, anchor)
		ring.look_at_from_position(anchor, anchor + dir, Vector3.UP)
		var clod := Geo.add(self, Geo.sphere(0.16, 12, 6), dirt, dir * 1.85 + Vector3(0, -0.02, 0))
		clod.scale = Vector3(1.0, 0.25, 1.0)
		var attach := dir * corner_r + Vector3(0, ALTAR_TOP - 0.05, 0)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = link
		var length := (_altar_root.transform * attach).distance_to(anchor)
		mm.instance_count = int(length / CHAIN_LINK) + 2
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = iron
		add_child(mmi)
		_chains.append([anchor, attach, mm])
	for idx in range(first_ground, get_child_count()):
		_ground_nodes.append(get_child(idx))
	_altar_float()


## Le Catene in partita: niente catene a terra, l'altare appoggiato al suolo, gli anelli delle catene sul tavolo.
func game_mode() -> void:
	_ground_on = false
	for n in _ground_nodes:
		(n as Node3D).visible = false
	_build_table_rings()
	altar_reset()


## L'altare torna a terra (inizio manche).
func altar_reset() -> void:
	_lift_goal = 0.0
	_lift = 0.0


## I tre movimenti dell'altare (decisi dall'utente il 22/10): fermo a terra nei primi turni (0), poi si alza una
## volta (1: le catene si tendono), poi una seconda (2: trascina i campioni quasi al centro); il terzo è altar_fly.
## Dal 22/10 sera l'altare non vola più (richiesta dell'utente): le Catene non chiamano più questi movimenti.
const ALTAR_STEPS := [0.0, 1.2, 1.85]


func altar_step(n: int) -> void:
	_lift_goal = ALTAR_STEPS[clampi(n, 0, ALTAR_STEPS.size() - 1)]


## Compatibilità: 0..1 diventa il gradino più vicino.
func altar_rise(p: float) -> void:
	altar_step(int(floor(clampf(p, 0.0, 1.0) * 2.0 + 0.001)))


## Il campione `i` brucia al suo posto (22/10): fiamma vera attorno al corpo (lo stesso volume di fuoco dell'altare),
## faville, una luce che sfarfalla; poi la fiamma cala e resta la brace. Lui si accascia contro il tavolo.
func burn_seat(i: int) -> void:
	var fig: Figura = seats[i] if i < seats.size() else null
	if fig == null:
		return
	fig.burn_in_place()
	var base := fig.global_position + (Vector3.ZERO - fig.global_position).normalized() * 0.12
	var vol := ShaderMaterial.new()
	vol.shader = load("res://shaders/fuoco_volume.gdshader")
	vol.set_shader_parameter("size", Vector3(1.5, 2.8, 1.5))
	vol.set_shader_parameter("radius", 0.6)        # più largo del corpo: le fiamme lo avvolgono, non restano dentro
	vol.set_shader_parameter("seed", randf() * 10.0)
	vol.set_shader_parameter("intensity", 0.0)
	var box := BoxMesh.new()
	box.size = Vector3(1.5, 2.8, 1.5)
	var fire := MeshInstance3D.new()
	fire.mesh = box
	fire.material_override = vol
	fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fire)
	fire.global_position = base + Vector3(0, 1.4 - 0.05, 0)
	var light := FlickerLight.new()
	light.light_color = Color(1.0, 0.42, 0.12)
	light.base_energy = 0.0
	light.omni_range = 4.0
	light.shadow_enabled = true
	add_child(light)
	light.global_position = base + Vector3(0, 1.1, 0)
	var embers := _drift(base + Vector3(0, 0.9, 0), Vector3(0.25, 0.5, 0.25), Color(1.0, 0.5, 0.15), 40, 1.6, 1.4, 0.03)
	sparks(fig.chest(), Color(1.0, 0.45, 0.1), 50, 2.5)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		vol.set_shader_parameter("intensity", v)
		light.base_energy = 2.4 * v, 0.0, 1.0, 0.8)
	tw.tween_interval(3.2)
	tw.tween_method(func(v: float) -> void:
		vol.set_shader_parameter("intensity", v)
		light.base_energy = 2.4 * v, 1.0, 0.0, 2.5)
	tw.tween_callback(func() -> void:
		embers.emitting = false
		fire.queue_free()
		light.queue_free())
	tw.tween_interval(2.0)
	tw.tween_callback(embers.queue_free)


## Fine manche: l'altare vola via in alto e porta con sé chi è ancora legato.
func altar_fly() -> void:
	_lift_goal = 12.0


## Le catene dell'altare (docs/catene_altare.md, fase 0 di ISTRUZIONI_ATMOSFERA.txt): ogni campione è legato da tante
## catene quante ne ha. Ogni catena ha una LUNGHEZZA FISSA, decisa quando nasce: una fila di punti a passo costante
## (un anello fra due punti) che la gravità fa pendere o appoggiare a terra. I punti si possono avvicinare (la catena
## si affloscia) ma mai allontanare oltre il passo: la catena non si allunga mai. Quando è tesa, è il campione a essere
## trascinato verso l'altare. Un capo è l'anello della cintura (Figura.belt_anchor), l'altro un anello di ferro
## fissato all'altare (_ring_anchor: è il solo punto da cambiare per agganciarle al trono).
const LINK_P := 0.068              # passo fra un anello e il successivo (come nella prova d'atmosfera: 7 cm)
const CHAIN_LEN := 1.3             # lunghezza di ogni catena, in metri (dal 22/10 vanno al tavolo, a ~0,7 m: pendono e toccano terra)
const MAX_STRANDS := 9
const MAX_DRAG := 0.85             # di quanto al massimo un campione può essere trascinato verso l'altare
const GROUND_Y := 0.025
var _tethers := {}                 # posto -> Array di catene agganciate (Dictionary, vedi _new_strand)
var _loose: Array = []             # pezzi di catena spezzata che cadono e poi spariscono
var _altar_rings := {}             # posto -> Array[Node3D]: i punti d'aggancio sugli anelli dell'altare
var _link_mesh: TorusMesh


func tether(i: int, on: bool) -> void:
	if on:
		if chain_count(i) == 0:
			set_chains(i, 1)
	else:
		set_chains(i, 0)


func chain_count(i: int) -> int:
	return (_tethers.get(i, []) as Array).size()


## Il tavolo dove si giocano le carte (22/10, richiesta dell'utente): un anello di pietra attorno all'altare, alto come
## un tavolo da stare in piedi. Sotto, un basamento di blocchi squadrati con lo zoccolo; sopra, una lastra di pietra
## spessa con lo spigolo consumato. Gli anelli delle catene sono bullonati al basamento, davanti a ogni posto.
const TABLE_IN := 1.24             # raggio interno della lastra (l'altare coi gradini arriva a ~1,1 m)
const TABLE_OUT := 1.95            # raggio esterno della lastra
const TABLE_TOP := 0.75            # altezza del piano: da stare seduti (seduta a 42 cm, 2/11/2026)
const SLAB := 0.13                 # spessore della lastra
const PED_OUT := 1.74              # raggio esterno del basamento (la lastra sporge di 21 cm: lì sotto stanno le catene)
const PLINTH_OUT := 1.81           # zoccolo del basamento
const CARD_R := 1.62               # dove si posano le carte, davanti a ogni posto
var _table_root: Node3D


func _table() -> void:
	_table_root = Node3D.new()
	_table_root.name = "Tavolo"
	add_child(_table_root)
	var slab_m := Scenari.pbr("monastery_stone_floor", 1.4, Color(0.62, 0.58, 0.55))
	var block_m := Scenari.pbr("medieval_blocks_05", 1.1, Color(0.36, 0.34, 0.33))      # più scuro: la pietra chiara usciva dal buio
	var t := TABLE_TOP
	var b := t - SLAB
	# la lastra: profilo chiuso, girato in senso antiorario (fuori in su, sopra verso dentro, dentro in giù)
	Geo.add(_table_root, Geo.lathe(PackedVector2Array([
		Vector2(TABLE_OUT - 0.03, b), Vector2(TABLE_OUT - 0.006, b + 0.008), Vector2(TABLE_OUT, b + 0.03),
		Vector2(TABLE_OUT, t - 0.035), Vector2(TABLE_OUT - 0.008, t - 0.012), Vector2(TABLE_OUT - 0.032, t),
		Vector2(TABLE_IN + 0.03, t), Vector2(TABLE_IN + 0.006, t - 0.01), Vector2(TABLE_IN, t - 0.035),
		Vector2(TABLE_IN, b + 0.02), Vector2(TABLE_IN + 0.02, b), Vector2(TABLE_OUT - 0.03, b)]), 96, 0.004), slab_m)
	# il basamento: zoccolo a terra, fusto, cornice sotto la lastra
	Geo.add(_table_root, Geo.lathe(PackedVector2Array([
		Vector2(PLINTH_OUT, 0.0), Vector2(PLINTH_OUT, 0.075), Vector2(PLINTH_OUT - 0.02, 0.1), Vector2(PED_OUT + 0.012, 0.115),
		Vector2(PED_OUT, 0.13), Vector2(PED_OUT, b - 0.05), Vector2(PED_OUT + 0.03, b - 0.03), Vector2(PED_OUT + 0.04, b),
		Vector2(1.36, b), Vector2(1.36, 0.13), Vector2(1.31, 0.1), Vector2(1.3, 0.0), Vector2(PLINTH_OUT, 0.0)]), 96), block_m)



## Gli anelli delle catene sul basamento del tavolo: per ogni posto una fila davanti al campione, ognuno con la sua
## piastra e due bulloni. Le catene si agganciano al fondo dell'anello (_ring_anchor).
var _table_rings := {}             # posto -> Array[Node3D]: i punti d'aggancio sugli anelli del tavolo
const RING_Y := 0.42


func _build_table_rings() -> void:
	if not _table_rings.is_empty():
		return
	var iron := Mats.rust_iron(8.0)
	var ring_mesh := Geo.torus(0.016, 0.028, 16, 6)
	for i in n_seats:
		var flat := seat_pos(i)
		var n := Vector3(flat.x, 0, flat.z).normalized()
		var side := Vector3.UP.cross(n).normalized()
		var list: Array[Node3D] = []
		for k in Figura.BELT_ORDER.size():
			var off := float(Figura.BELT_ORDER[k]) * 0.05
			# sulla pietra curva: la piastra si appoggia al basamento, non resta sospesa sulla corda
			var depth := PED_OUT - sqrt(PED_OUT * PED_OUT - off * off)
			var at := n * (PED_OUT - depth + 0.005) + side * off + Vector3(0, RING_Y, 0)
			var grp := Node3D.new()
			grp.name = "Anello%d_%d" % [i, k]
			_table_root.add_child(grp)
			var plate := Geo.add(grp, Geo.box(Vector3(0.034, 0.04, 0.012)), iron, at)
			plate.look_at_from_position(at, at + n, Vector3.UP)
			for s in [-1.0, 1.0]:
				Geo.add(plate, Geo.sphere(0.006, 8, 4), iron, Vector3(0, 0.012 * s, -0.007), Vector3.ZERO, false)
			var ring := Geo.add(grp, ring_mesh, iron, at + n * 0.014 + Vector3(0, -0.026, 0))
			ring.basis = Basis(n, side, Vector3.UP)
			var hook := Node3D.new()
			hook.position = at + n * 0.016 + Vector3(0, -0.05, 0)
			grp.add_child(hook)
			list.append(hook)
		_table_rings[i] = list


## Gli anelli di ferro sull'altare: per ogni posto una fila sul lato rivolto verso quel campione, bullonati allo
## zoccolo, con la piastra. Le catene si agganciano al fondo dell'anello. (Fino al 22/10; ora le catene vanno al tavolo.)
func _build_altar_rings() -> void:
	if not _altar_rings.is_empty():
		return
	var iron := Mats.rust_iron(8.0)
	var ring_mesh := Geo.torus(0.014, 0.024, 16, 6)
	var apothem := 0.5 * cos(PI / 8.0)        # la colonna dell'altare: le facce guardano verso i posti
	for i in seats.size():
		var flat := seat_pos(i)
		var n := Vector3(flat.x, 0, flat.z).normalized()
		var side := Vector3.UP.cross(n).normalized()
		var list: Array[Node3D] = []
		for k in Figura.BELT_ORDER.size():
			# una fila di anelli sulla faccia della colonna, sotto il riquadro delle rune, sopra lo zoccolo
			var off := float(Figura.BELT_ORDER[k]) * 0.04
			var at := n * (apothem + 0.006) + side * off + Vector3(0, 0.53, 0)
			var plate := Geo.add(_altar_root, Geo.box(Vector3(0.03, 0.034, 0.01)), iron, at)
			plate.look_at_from_position(at, at + n, Vector3.UP)
			Geo.add(plate, Geo.sphere(0.009, 8, 4), iron, Vector3(0, 0, -0.008), Vector3.ZERO, false)
			var ring := Geo.add(_altar_root, ring_mesh, iron, at + n * 0.012 + Vector3(0, -0.022, 0))
			ring.basis = Basis(n, side, Vector3.UP)
			var hook := Node3D.new()
			hook.position = at + n * 0.014 + Vector3(0, -0.042, 0)
			_altar_root.add_child(hook)
			list.append(hook)
		_altar_rings[i] = list


## Il capo della catena k del posto i dalla parte del tavolo (anello sul basamento davanti al campione).
func _ring_anchor(i: int, k: int) -> Vector3:
	var list: Array = _table_rings.get(i, [])
	if list.is_empty():
		return seat_pos(i).normalized() * (PED_OUT + 0.02) + Vector3(0, RING_Y - 0.05, 0)
	return (list[clampi(k, 0, list.size() - 1)] as Node3D).global_position


## Porta a `n` le catene del campione `i`. Una nuova cade dall'anello dell'altare e un attimo dopo si aggancia alla
## cintura con un lampo e un colpo di ferro; quelle in più si spezzano (un anello si apre con scintille) e i due pezzi
## cadono a terra.
func set_chains(i: int, n: int) -> void:
	n = clampi(n, 0, MAX_STRANDS)
	if not _tethers.has(i):
		_tethers[i] = []
	_build_table_rings()
	var list: Array = _tethers[i]
	while list.size() < n:
		list.append(_new_strand(i, list.size()))
	while list.size() > n:
		_break(list.pop_back())


## Toglie tutte le catene subito, senza effetti (inizio manche).
func clear_chains() -> void:
	for i in _tethers:
		for s in _tethers[i]:
			(s["node"] as Node).queue_free()
	_tethers.clear()
	for s in _loose:
		(s["node"] as Node).queue_free()
	_loose.clear()
	for f in seats:
		if f:
			f.drag = 0.0


func _new_strand(i: int, k: int) -> Dictionary:
	if _link_mesh == null:
		_link_mesh = Geo.torus(0.0135, 0.031, 14, 6)
	var count := int(round(CHAIN_LEN / LINK_P))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _link_mesh
	mm.instance_count = count
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = Mats.rust_iron(10.0)
	add_child(mmi)
	# nasce appesa all'anello dell'altare, raccolta in basso: cade e si stende
	var top := _ring_anchor(i, k)
	var pts := PackedVector3Array()
	for j in count + 1:
		var t := float(count - j)                # j = 0 sarà il capo della cintura
		pts.append(Vector3(top.x, maxf(top.y - t * LINK_P * 0.5, GROUND_Y), top.z) + seat_pos(i).normalized() * 0.01 * t)
	var s := {"seat": i, "k": k, "pts": pts, "old": pts.duplicate(), "mm": mm, "node": mmi,
		"belt": false, "ring": true, "wait": 0.3, "life": -1.0}
	return s


## Una catena che si spezza: si apre un anello verso il centro, scintille, e i due pezzi cadono liberi.
func _break(s: Dictionary) -> void:
	var pts: PackedVector3Array = s["pts"]
	var cut := int(pts.size() * 0.45)
	sparks(pts[cut], Color(1.0, 0.75, 0.35), 26, 2.6)
	Sfx.play("chop", -9.0, 1.7)
	# il pezzo dalla cintura e quello dall'altare diventano due catene libere
	for half in [[0, cut], [cut + 1, pts.size() - 1]]:
		var a: int = half[0]
		var b: int = half[1]
		if b - a < 1:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _link_mesh
		mm.instance_count = b - a
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = (s["node"] as MultiMeshInstance3D).material_override
		add_child(mmi)
		var piece := pts.slice(a, b + 1)
		var old: PackedVector3Array = (s["old"] as PackedVector3Array).slice(a, b + 1)
		_loose.append({"seat": s["seat"], "k": s["k"], "pts": piece, "old": old, "mm": mm, "node": mmi,
			"belt": false, "ring": false, "wait": 0.0, "life": 3.5})
	(s["node"] as Node).queue_free()


## Un passo di simulazione per tutte le catene, e il trascinamento dei campioni.
func _chains_step(delta: float) -> void:
	var dt := clampf(delta, 0.0, 1.0 / 30.0)
	for i in _tethers:
		var fig: Figura = seats[i] if i < seats.size() else null
		if fig == null:
			continue
		var excess := -INF
		if fig.carried:
			# portato via: resta sotto l'altare, appeso alle catene, e sparisce quando è in alto
			fig.position.y = maxf(_lift - 1.7, 0.0)
			if fig.position.y > 6.0:
				fig.visible = false
		for s in _tethers[i]:
			var belt_p := fig.belt_anchor(s["k"])
			if not fig.visible:
				s["belt"] = false
			var ring_p := _ring_anchor(i, s["k"])
			if s["wait"] > 0.0:
				s["wait"] -= dt
				if s["wait"] <= 0.0:
					s["belt"] = true             # si aggancia alla cintura: lampo e colpo di ferro
					sparks(belt_p, Color(1.0, 0.85, 0.5), 18, 1.8)
					Sfx.play("chop", -10.0, 1.9)
			_simulate(s, belt_p, ring_p, dt)
			if s["belt"]:
				excess = maxf(excess, belt_p.distance_to(ring_p) - LINK_P * ((s["pts"] as PackedVector3Array).size() - 1) * 0.985)
			_draw_chain(s)
		# catena tesa: il campione viene trascinato quanto basta perché non si allunghi; se la catena si allenta, torna
		if excess > -INF:
			fig.drag = clampf(fig.drag + (excess if excess > 0.0 else excess * 0.2), 0.0, MAX_DRAG)
		else:
			fig.drag = maxf(fig.drag - dt * 0.5, 0.0)
	for f in seats:
		if f and not _tethers.has(seats.find(f)):
			f.drag = maxf(f.drag - dt * 0.5, 0.0)
	for s in _loose.duplicate():
		s["life"] -= dt
		_simulate(s, Vector3.ZERO, Vector3.ZERO, dt)
		_draw_chain(s)
		if s["life"] < 1.0:                          # i pezzi a terra affondano nel buio e spariscono
			(s["node"] as Node3D).position.y = -0.06 * (1.0 - maxf(s["life"], 0.0))
		if s["life"] <= 0.0:
			(s["node"] as Node).queue_free()
			_loose.erase(s)


## Verlet: ogni punto prosegue col suo slancio più la gravità; poi più passate rimettono i vicini al passo (mai più
## lontani), tengono fermi i capi agganciati e non lasciano scendere nulla sotto il terreno.
func _simulate(s: Dictionary, a: Vector3, b: Vector3, dt: float) -> void:
	var pts: PackedVector3Array = s["pts"]
	var old: PackedVector3Array = s["old"]
	var n := pts.size()
	var g := Vector3(0, -9.8, 0) * dt * dt
	for j in n:
		var p := pts[j]
		var v := (p - old[j]) * 0.97
		old[j] = p
		var q := p + v + g
		if q.y < GROUND_Y:
			q.y = GROUND_Y
			q.x = lerpf(q.x, p.x, 0.6)            # attrito sul terreno
			q.z = lerpf(q.z, p.z, 0.6)
		pts[j] = q
	var pin_a: bool = s["belt"]
	var pin_b: bool = s["ring"]
	for it in 20:
		if pin_a:
			pts[0] = a
		if pin_b:
			pts[n - 1] = b
		for j in n - 1:
			var d := pts[j + 1] - pts[j]
			var l := d.length()
			if l > LINK_P and l > 0.0:
				var corr := d * ((l - LINK_P) / l)
				var fa := 0.0 if (j == 0 and pin_a) else 0.5
				var fb := 0.0 if (j + 1 == n - 1 and pin_b) else 0.5
				if fa + fb > 0.0:
					var k := 1.0 / (fa + fb)
					pts[j] += corr * fa * k
					pts[j + 1] -= corr * fb * k
		for j in n:
			if pts[j].y < GROUND_Y:
				pts[j].y = GROUND_Y
			pts[j] = _off_table(pts[j])
	if pin_a:
		pts[0] = a
	if pin_b:
		pts[n - 1] = b
	s["pts"] = pts
	s["old"] = old


## Un punto di catena non entra nella pietra del tavolo: fuori dal basamento (e dal suo zoccolo) e, sotto la lastra
## che sporge, mai dentro lo spessore della lastra. Il raggio dell'anello è compreso.
func _off_table(p: Vector3) -> Vector3:
	if _table_root == null:
		return p
	var r := Vector2(p.x, p.z).length()
	if r < 0.01 or r > TABLE_OUT + 0.05:
		return p
	var lim := -1.0
	if p.y < 0.13:
		lim = PLINTH_OUT + 0.03
	elif p.y < TABLE_TOP - SLAB:
		lim = PED_OUT + 0.03
	elif p.y < TABLE_TOP + 0.03:
		lim = TABLE_OUT + 0.03
	if lim > 0.0 and r < lim and r > TABLE_IN - 0.1:
		var k := lim / r
		p.x *= k
		p.z *= k
	return p


## Un anello fra ogni coppia di punti, girato di 90 gradi rispetto al vicino, lungo il tratto.
func _draw_chain(s: Dictionary) -> void:
	var pts: PackedVector3Array = s["pts"]
	var mm: MultiMesh = s["mm"]
	var last := Vector3.FORWARD
	for j in mini(pts.size() - 1, mm.instance_count):
		var d := pts[j + 1] - pts[j]
		if d.length_squared() > 1e-8:
			last = d.normalized()
		var up := Vector3.UP if absf(last.y) < 0.95 else Vector3.RIGHT
		var basis := Basis.looking_at(last, up)
		if j % 2 == 1:
			basis = basis.rotated(last, PI * 0.5)
		mm.set_instance_transform(j, Transform3D(basis * Basis.from_scale(Vector3(1.0, 1.0, 1.7)), (pts[j] + pts[j + 1]) * 0.5))


## L'altare galleggia e ondeggia appena; le catene lo seguono, più tese quando sale.
func _altar_float() -> void:
	if _altar_root == null:
		return
	var rise := 0.035 * sin(_t * 0.9) + 0.012 * sin(_t * 2.3 + 0.7)
	_lift = lerpf(_lift, _lift_goal, 0.025)
	if _lift < 0.05:
		rise *= _lift / 0.05                     # appoggiato a terra non ondeggia
	_altar_root.position = Vector3(0, _lift + rise, 0)
	var sway := 0.014 * clampf(_lift / 0.05, 0.0, 1.0)     # la pietra appoggiata a terra non dondola
	_altar_root.rotation = Vector3(sway * sin(_t * 0.7), _altar_root.rotation.y, sway * sin(_t * 0.83 + 1.0))
	if _under_glow:
		_under_glow.light_energy = 0.45 + 0.25 * (0.5 + 0.5 * sin(_t * 1.4))
	if not _ground_on:
		return
	for c in _chains:
		var a: Vector3 = c[0]
		var b: Vector3 = _altar_root.transform * (c[1] as Vector3)
		var mm: MultiMesh = c[2]
		var sag := clampf(0.07 - rise * 1.2, 0.02, 0.12)      # quando l'altare sale la catena si tende
		var n := mm.instance_count
		var prev := a
		for i in n:
			var t := (i + 0.5) / n
			var p := a.lerp(b, t) + Vector3(0, -sag * 4.0 * t * (1.0 - t), 0)
			var t2 := minf(t + 0.02, 1.0)
			var q := a.lerp(b, t2) + Vector3(0, -sag * 4.0 * t2 * (1.0 - t2), 0)
			var along := (q - p).normalized() if t2 > t else (p - prev).normalized()
			var basis := Basis.looking_at(along, Vector3.UP)
			if i % 2 == 1:
				basis = basis.rotated(along, PI * 0.5)
			mm.set_instance_transform(i, Transform3D(basis * Basis.from_scale(Vector3(1.0, 1.0, 1.45)), p))
			prev = p
