class_name Mats
extends RefCounted
## Fabbrica di materiali: tutti i materiali del gioco nascono qui.

static var _shaders := {}


static func shader(name: String) -> Shader:
	if not _shaders.has(name):
		_shaders[name] = load("res://shaders/%s.gdshader" % name)
	return _shaders[name]


static func make(name: String, params: Dictionary = {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader(name)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


static func brick(uv := false) -> ShaderMaterial:
	return make("brick", {"use_uv": uv})


static func floor_stone() -> ShaderMaterial:
	return make("stone_floor")


static func wood(dark := Color(0.11, 0.06, 0.035), light := Color(0.27, 0.15, 0.08),
		planks := true, gloss := 0.5, stains := 1.0) -> ShaderMaterial:
	return make("wood", {"wood_dark": dark, "wood_light": light, "planks": planks,
			"gloss": gloss, "stains": stains})


static func leather(c: Color, worn := Color(-1, 0, 0), shine := 0.5) -> ShaderMaterial:
	if worn.r < 0.0:
		worn = c.lightened(0.35)
	return make("leather", {"base": c, "worn": worn, "shine": shine})


static func cloth(c: Color, c2 := Color(-1, 0, 0), pattern := 0, sheen := 0.7,
		pat_col := Color(0.4, 0.3, 0.1), drape := 0.0) -> ShaderMaterial:
	if c2.r < 0.0:
		c2 = c.darkened(0.55)
	return make("cloth", {"base": c, "base2": c2, "pattern": pattern, "sheen": sheen,
			"pat_col": pat_col, "drape": drape})


## Stessa stoffa con le pieghe che muovono la sagoma.
static func draped(m: ShaderMaterial, amount: float) -> ShaderMaterial:
	var d := m.duplicate() as ShaderMaterial
	d.set_shader_parameter("drape", amount)
	return d


static func iron() -> ShaderMaterial:
	return make("metal", {"base": Color(0.16, 0.16, 0.17), "rust_amount": 0.35, "rough": 0.55})


static func brass() -> ShaderMaterial:
	return make("metal", {"base": Color(0.72, 0.52, 0.24), "rust": Color(0.12, 0.2, 0.14),
			"rust_amount": 0.2, "rough": 0.32, "hammer": 0.4})


static func steel() -> ShaderMaterial:
	return make("metal", {"base": Color(0.62, 0.62, 0.64), "rust_amount": 0.22, "rough": 0.28,
			"hammer": 0.2})


static func gold_coin() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.63, 0.25)
	m.metallic = 1.0
	m.roughness = 0.28
	return m


static func wax(top_y: float) -> ShaderMaterial:
	return make("wax", {"top_y": top_y})


static func flame(seed_v: float) -> ShaderMaterial:
	return make("flame", {"seed": seed_v})


static func glass(c := Color(0.02, 0.07, 0.03)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.06
	m.metallic = 0.0
	m.metallic_specular = 0.9
	m.rim_enabled = true
	m.rim = 0.3
	return m


static var _pbr := {}


## Ferro vecchio arrugginito, con texture fotografiche complete (Poly Haven rusty_metal_03, CC0): colore, rilievi,
## ruvidità. Proiezione dai tre assi: va bene su anelli, cinture, borchie senza mappe UV curate.
static func rust_iron(scale := 4.0) -> StandardMaterial3D:
	var key := "ferro%s" % scale
	if not _pbr.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_texture = load("res://assets/materiali/rusty_metal_03_diff_1k.jpg")
		m.albedo_color = Color(0.42, 0.36, 0.33)            # il diffuso è chiaro: ferro scuro, ruggine nei punti
		m.normal_enabled = true
		m.normal_texture = load("res://assets/materiali/rusty_metal_03_nor_gl_1k.jpg")
		m.normal_scale = 1.2
		m.roughness_texture = load("res://assets/materiali/rusty_metal_03_rough_1k.jpg")
		m.roughness = 1.0
		m.metallic = 0.7
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * scale
		m.uv1_world_triplanar = false
		_pbr[key] = m
	return _pbr[key]


## Cuoio scuro consumato (Poly Haven fabric_leather_01, CC0), per le cinture.
static func worn_leather() -> StandardMaterial3D:
	if not _pbr.has("cuoio"):
		var m := StandardMaterial3D.new()
		m.albedo_texture = load("res://assets/materiali/fabric_leather_01_diff_1k.jpg")
		m.albedo_color = Color(0.45, 0.36, 0.3)
		m.normal_enabled = true
		m.normal_texture = load("res://assets/materiali/fabric_leather_01_nor_gl_1k.jpg")
		m.roughness_texture = load("res://assets/materiali/fabric_leather_01_rough_1k.jpg")
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * 3.0
		_pbr["cuoio"] = m
	return _pbr["cuoio"]


static func matte(c: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


static func emissive(c: Color, energy := 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.BLACK
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


static func ghost() -> ShaderMaterial:
	return make("ghost")
