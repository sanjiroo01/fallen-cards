class_name Candle
extends Node3D
## Candela con cera traslucida, fiamma viva, luce che trema e fumo quando si spegne.

var height := 0.16
var radius := 0.017
var has_light := true
var shadows := true
var energy := 1.1
var light_range := 3.5
var light_color := Color(1.0, 0.6, 0.28)
var wax_color := Color(0.8, 0.7, 0.52)     # cera d'api vecchia, avorio caldo (non bianco)
var lit := true

var _flame: MeshInstance3D
var _flame_mat: ShaderMaterial
var _wax_mat: ShaderMaterial
var _light: OmniLight3D
var _smoke: GPUParticles3D
var _noise := FastNoiseLite.new()
var _t := 0.0
var _factor := 1.0          # 1 accesa, 0 spenta (animato)
var _sway := 0.0
var _flame_base := Vector3.ONE

static var _smoke_tex: Texture2D


func build() -> Candle:
	_t = randf() * 100.0
	_noise.seed = randi()
	_noise.frequency = 1.0
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var h := height
	var r := radius
	var prof := PackedVector2Array([
		Vector2(r * 1.06, 0.0), Vector2(r * 1.03, h * 0.35), Vector2(r * 1.0, h * 0.8),
		Vector2(r * 0.98, h - 0.003), Vector2(r * 0.9, h), Vector2(r * 0.72, h - 0.002),
		Vector2(r * 0.3, h - 0.007), Vector2(0.0, h - 0.008)])
	_wax_mat = Mats.wax(h)
	_wax_mat.set_shader_parameter("base", wax_color)
	Geo.add(self, Geo.lathe(prof, 28, 0.025), _wax_mat)
	# colature di cera
	var drips := 2 + randi() % 3
	for i in drips:
		var a := randf() * TAU
		var len := randf_range(0.02, h * 0.55)
		var dr := randf_range(0.0035, 0.0055)
		var d := Geo.add(self, Geo.capsule(dr, len), _wax_mat,
				Vector3(cos(a) * r * 0.98, h - len * 0.5 + 0.002, sin(a) * r * 0.98))
		d.rotation.y = -a
	# stoppino
	var wick := Geo.add(self, Geo.cyl(0.0008, 0.0012, 0.013, 6), Mats.matte(Color(0.02, 0.015, 0.01)),
			Vector3(0, h - 0.002, 0), Vector3(0, 0, randf_range(-12, 12)))
	wick.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# fiamma
	var q := QuadMesh.new()
	q.size = Vector2(0.024, 0.058)
	_flame_mat = Mats.flame(randf())
	_flame = Geo.add(self, q, _flame_mat, Vector3(0, h + 0.026, 0), Vector3.ZERO, false)
	_flame.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	if has_light:
		_light = OmniLight3D.new()
		_light.position = Vector3(0, h + 0.04, 0)
		_light.light_color = light_color
		_light.light_energy = energy
		_light.omni_range = light_range
		_light.omni_attenuation = 1.3
		_light.shadow_enabled = shadows
		_light.light_size = 0.02
		_light.shadow_bias = 0.03
		_light.shadow_normal_bias = 1.2
		_light.light_volumetric_fog_energy = 1.4
		add_child(_light)
	_build_smoke(h)
	return self


func _build_smoke(h: float) -> void:
	if _smoke_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.9))
		g.set_color(1, Color(1, 1, 1, 0.0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 64
		gt.height = 64
		_smoke_tex = gt
	_smoke = GPUParticles3D.new()
	_smoke.position = Vector3(0, h + 0.01, 0)
	_smoke.amount = 14
	_smoke.lifetime = 2.6
	_smoke.one_shot = true
	_smoke.explosiveness = 0.35
	_smoke.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 0.04
	pm.initial_velocity_max = 0.09
	pm.gravity = Vector3(0.01, 0.035, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.3))
	sc.add_point(Vector2(1, 2.5))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	var cr := Gradient.new()
	cr.set_color(0, Color(0.55, 0.52, 0.5, 0.35))
	cr.set_color(1, Color(0.4, 0.4, 0.4, 0.0))
	var crt := GradientTexture1D.new()
	crt.gradient = cr
	pm.color_ramp = crt
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.4
	pm.turbulence_noise_scale = 3.0
	_smoke.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.03, 0.03)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _smoke_tex
	m.albedo_color = Color(0.3, 0.3, 0.3, 1)
	q.material = m
	_smoke.draw_pass_1 = q
	add_child(_smoke)


func _process(delta: float) -> void:
	if _flame == null:
		return
	_t += delta
	var n1 := _noise.get_noise_1d(_t * 7.0)
	var n2 := _noise.get_noise_1d(_t * 13.0 + 50.0)
	var n3 := _noise.get_noise_1d(_t * 5.0 + 90.0)
	var f := _factor
	var flick := 1.0 + 0.1 * n1 + 0.06 * n2
	_flame.scale = Vector3(1.0 + 0.08 * n2, (1.0 + 0.16 * n1) * f, 1.0) * maxf(f, 0.001)
	_flame.visible = f > 0.01
	_flame_mat.set_shader_parameter("sway", _sway + n3 * 0.08)
	_wax_mat.set_shader_parameter("lit", f)
	if _light:
		_light.light_energy = energy * flick * f
		_light.position = Vector3(n2 * 0.004 + _sway * 0.01, height + 0.04 + n1 * 0.003, n3 * 0.004)
		_light.visible = f > 0.005


## Colpo di vento: la fiamma si piega, poi si spegne con un filo di fumo.
func blow_out(delay := 0.0) -> void:
	lit = false
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "_sway", 0.7, 0.18).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(self, "_factor", 0.55, 0.18)
	tw.tween_property(self, "_factor", 0.0, 0.12)
	tw.tween_callback(func() -> void:
		_sway = 0.0
		if _smoke:
			_smoke.restart()
			_smoke.emitting = true)


func relight(delay := 0.0) -> void:
	lit = true
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "_factor", 1.35, 0.12).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "_factor", 1.0, 0.35)


func set_lit_instant(on: bool) -> void:
	lit = on
	_factor = 1.0 if on else 0.0
