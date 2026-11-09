shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
// Fuoco in volume: dentro una scatola invisibile si percorre il raggio di vista a piccoli passi e si somma
// la luce di una fiamma fatta di rumore che sale. La forma è larga alla base e si stringe in alto, il rumore
// la piega e la spezza in lingue che si staccano; il colore segue la temperatura: bianco-giallo nel cuore
// basso, arancio nel corpo, rosso scuro sulle punte. Si ferma sugli oggetti davanti (ceppi, altare).

#include "res://shaders/noise.gdshaderinc"

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 size = vec3(0.9, 1.7, 0.9);       // la scatola (centrata); la fiamma nasce dal suo fondo
uniform float radius = 0.3;                    // raggio della fiamma alla base
uniform float speed = 1.6;                     // velocità con cui sale il rumore
uniform float intensity = 1.0;
uniform float seed = 0.0;

varying vec3 cam_local;

void vertex() {
	cam_local = (inverse(MODEL_MATRIX) * vec4(INV_VIEW_MATRIX[3].xyz, 1.0)).xyz;
}

// densità e temperatura della fiamma in un punto (coordinate della scatola)
vec2 flame(vec3 p) {
	float h = clamp(p.y / size.y, 0.0, 1.0);
	float t = TIME * speed + seed * 7.0;
	// rumore stirato in verticale (lingue lunghe e strette) che sale; un vortice lento lo fa girare
	vec3 q = vec3(p.x * 4.2, p.y * 2.2, p.z * 4.2);
	float sw = sin(t * 0.37 + p.y * 2.0) * 0.3;
	q.xz = mat2(vec2(cos(sw), sin(sw)), vec2(-sin(sw), cos(sw))) * q.xz;
	q.y -= t * 1.6;
	float n = fbm3(q + vec3(seed));
	float n2 = vnoise3(vec3(q.x * 2.3, q.y * 1.7 - t * 0.8, q.z * 2.3) + vec3(3.1, 0.0, 1.7));
	// la massa ondeggia appena di lato
	vec2 wob = vec2(vnoise3(vec3(p.y * 1.2 - t * 0.7, seed, 1.0)), vnoise3(vec3(p.y * 1.2 - t * 0.7, seed, 7.0))) - 0.5;
	vec2 xz = p.xz - wob * 0.18 * h;
	// sagoma di un falò: larga e piena in basso, si stringe sopra la metà
	float r = radius * (1.0 - smoothstep(0.05, 0.85, h) * 0.92) + 0.015;
	float d = length(xz) / r;
	// calore: pieno dentro la sagoma, il rumore lo spezza in lingue sempre di più salendo
	float n3 = vnoise3(vec3(q.x * 5.0, q.y * 3.5 - t * 1.5, q.z * 5.0));      // dettaglio fine: fili di fiamma
	float heat = (1.0 - d) * 1.35 + (n - 0.5) * (1.0 + h * 1.8) + (n2 - 0.5) * 0.7 + (n3 - 0.5) * (0.25 + h * 0.5);
	heat -= h * h * 0.9;
	heat *= smoothstep(0.0, 0.05, p.y);             // la base nasce fra i ceppi
	float dens = smoothstep(0.04, 0.22, heat);
	return vec2(dens, clamp(heat, 0.0, 1.4));
}

vec3 color_of(float temp) {
	// colore del fuoco secondo la temperatura (dal rosso scuro al bianco caldo)
	vec3 c = mix(vec3(0.3, 0.025, 0.004), vec3(0.95, 0.2, 0.02), smoothstep(0.0, 0.5, temp));
	c = mix(c, vec3(1.0, 0.5, 0.1), smoothstep(0.5, 0.95, temp));
	c = mix(c, vec3(1.0, 0.85, 0.55), smoothstep(1.0, 1.35, temp));     // bianco-giallo solo nel cuore
	return c * (0.45 + temp * 1.7);
}

void fragment() {
	vec3 ro = cam_local;
	vec3 hit = (inverse(MODEL_MATRIX) * (INV_VIEW_MATRIX * vec4(VERTEX, 1.0))).xyz;
	vec3 rd = normalize(hit - ro);
	// ingresso e uscita dalla scatola
	vec3 bmin = -size * 0.5;
	vec3 bmax = size * 0.5;
	vec3 t0 = (bmin - ro) / rd;
	vec3 t1 = (bmax - ro) / rd;
	vec3 tmn = min(t0, t1);
	vec3 tmx = max(t0, t1);
	float tn = max(max(max(tmn.x, tmn.y), tmn.z), 0.0);
	float tf = min(min(tmx.x, tmx.y), tmx.z);
	// fermati sugli oggetti opachi davanti (ceppi, braciere, altare)
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 ndc = vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec4 vpos = INV_PROJECTION_MATRIX * ndc;
	vpos.xyz /= vpos.w;
	vec3 opaque = (inverse(MODEL_MATRIX) * (INV_VIEW_MATRIX * vec4(vpos.xyz, 1.0))).xyz;
	tf = min(tf, dot(opaque - ro, rd));
	if (tf <= tn) {
		discard;
	}
	const int STEPS = 40;
	float dt = (tf - tn) / float(STEPS);
	float jitter = hash21(FRAGCOORD.xy + fract(TIME) * 61.0);   // niente righe a strati
	vec3 acc = vec3(0.0);
	float trans = 1.0;
	for (int i = 0; i < STEPS; i++) {
		vec3 p = ro + rd * (tn + (float(i) + jitter) * dt);
		vec2 f = flame(p + vec3(0.0, size.y * 0.5, 0.0));     // altezza misurata dal fondo
		if (f.x > 0.001) {
			float a = 1.0 - exp(-f.x * dt * 9.0);
			acc += color_of(f.y) * a * trans;
			trans *= 1.0 - a * 0.35;                    // la fiamma è un po' opaca: il cuore copre il retro
		}
	}
	ALBEDO = acc * intensity;
}
