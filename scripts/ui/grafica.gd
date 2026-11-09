class_name Grafica
extends RefCounted
## Qualità grafica scelta dal giocatore (Media, Alta, Ultra), salvata in user://grafica.cfg.
## Media è il gioco com'era prima; Alta (la partenza) aggiunge la luce che rimbalza, ombre morbide che
## sfumano con la distanza, texture nitide di sbieco e bordi più lisci; Ultra spinge tutto più in alto.

const CFG := "user://grafica.cfg"
const NOMI := ["Media", "Alta", "Ultra"]
const MEDIA := 0
const ALTA := 1
const ULTRA := 2

static var livello := ALTA
static var _caricato := false


static func carica() -> void:
	if _caricato:
		return
	_caricato = true
	var cf := ConfigFile.new()
	if cf.load(CFG) == OK:
		livello = clampi(int(cf.get_value("grafica", "livello", ALTA)), MEDIA, ULTRA)


static func scegli(l: int, vp: Viewport) -> void:
	livello = clampi(l, MEDIA, ULTRA)
	var cf := ConfigFile.new()
	cf.set_value("grafica", "livello", livello)
	cf.save(CFG)
	applica(vp)


## Impostazioni dello schermo (valgono per tutto il gioco).
static func applica(vp: Viewport) -> void:
	carica()
	var rs := RenderingServer
	vp.msaa_3d = [Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_4X][livello]
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA
	vp.mesh_lod_threshold = [1.0, 0.75, 0.5][livello]          # più dettaglio nei modelli lontani
	vp.positional_shadow_atlas_size = [4096, 8192, 8192][livello]
	if "anisotropic_filtering_level" in vp:
		vp.set("anisotropic_filtering_level", [Viewport.ANISOTROPY_4X, Viewport.ANISOTROPY_16X, Viewport.ANISOTROPY_16X][livello])
	rs.directional_shadow_atlas_set_size([4096, 4096, 8192][livello], true)
	var soft: int = [RenderingServer.SHADOW_QUALITY_SOFT_HIGH, RenderingServer.SHADOW_QUALITY_SOFT_HIGH, RenderingServer.SHADOW_QUALITY_SOFT_ULTRA][livello]
	rs.directional_soft_shadow_filter_set_quality(soft)
	rs.positional_soft_shadow_filter_set_quality(soft)
	rs.environment_set_ssao_quality([RenderingServer.ENV_SSAO_QUALITY_MEDIUM, RenderingServer.ENV_SSAO_QUALITY_HIGH,
		RenderingServer.ENV_SSAO_QUALITY_ULTRA][livello], livello == MEDIA, 0.5, 2, 50.0, 300.0)
	rs.environment_set_ssil_quality([RenderingServer.ENV_SSIL_QUALITY_LOW, RenderingServer.ENV_SSIL_QUALITY_MEDIUM,
		RenderingServer.ENV_SSIL_QUALITY_HIGH][livello], livello != ULTRA, 0.5, 4, 50.0, 300.0)
	rs.environment_set_volumetric_fog_volume_size([128, 160, 192][livello], [128, 128, 160][livello])
	rs.environment_glow_set_use_bicubic_upscale(livello != MEDIA)
	rs.environment_set_ssr_roughness_quality([RenderingServer.ENV_SSR_ROUGHNESS_QUALITY_LOW,
		RenderingServer.ENV_SSR_ROUGHNESS_QUALITY_MEDIUM, RenderingServer.ENV_SSR_ROUGHNESS_QUALITY_HIGH][livello])


## Impostazioni di un luogo (le chiama l'arena quando costruisce l'ambiente).
static func ambiente(env: Environment) -> void:
	carica()
	env.ssil_enabled = livello != MEDIA          # la luce del fuoco rimbalza sulle pietre vicine
	env.ssil_intensity = 0.9
	env.ssil_radius = 4.0
	env.ssil_normal_rejection = 1.0
	if env.ssr_enabled:
		env.ssr_max_steps = [48, 64, 96][livello]


## Luci principali: con Alta e Ultra le ombre si ammorbidiscono allontanandosi dall'oggetto (come quelle vere).
static func luce(l: Light3D, grandezza: float) -> void:
	carica()
	l.light_size = 0.0 if livello == MEDIA else grandezza
