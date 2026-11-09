shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
// Il cerchio rituale inciso nel terreno, disegnato su un piano trasparente: doppio anello esterno,
// fascia di rune tutte diverse, anello interno, stella a otto punte attorno all'altare.
// I solchi sono bruciati e scuri; dentro brilla una luce rossa che pulsa e scorre lenta attorno.

#include "res://shaders/noise.gdshaderinc"

uniform float size = 4.0;                       // lato del piano in metri
uniform vec3 glow_color : source_color = vec3(0.85, 0.12, 0.05);
uniform float energy = 1.0;

const float RUNES = 36.0;
const float R_OUT = 1.84;
const float R_OUT2 = 1.74;
const float R_RUNE = 1.585;
const float R_IN = 1.43;
const float R_CORE = 1.04;

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float line(float d, float w, float aa) {
	return 1.0 - smoothstep(w * 0.5, w * 0.5 + aa, d);
}

// una runa: tre o quattro tratti fra i punti di una griglia 3x3, scelti a caso per ogni cella
float rune(vec2 q, float id, float aa) {
	float m = 0.0;
	for (int s = 0; s < 4; s++) {
		float h0 = hash21(vec2(id, float(s) * 7.1));
		float h1 = hash21(vec2(id * 1.7 + 3.0, float(s) * 3.3));
		if (s == 3 && hash21(vec2(id, 99.0)) < 0.5) {
			break;
		}
		float i0 = floor(h0 * 9.0);
		float i1 = floor(h1 * 9.0);
		if (i0 == i1) {
			i1 = mod(i1 + 4.0, 9.0);
		}
		vec2 a = (vec2(mod(i0, 3.0), floor(i0 / 3.0)) - 1.0) * vec2(0.055, 0.06);
		vec2 b = (vec2(mod(i1, 3.0), floor(i1 / 3.0)) - 1.0) * vec2(0.055, 0.06);
		m = max(m, line(seg(q, a, b), 0.016, aa));
	}
	return m;
}

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float aa = fwidth(r) * 1.2;
	float m = 0.0;
	// anelli
	m = max(m, line(abs(r - R_OUT), 0.035, aa));
	m = max(m, line(abs(r - R_OUT2), 0.014, aa));
	m = max(m, line(abs(r - R_IN), 0.022, aa));
	m = max(m, line(abs(r - R_CORE), 0.03, aa));
	// rune nella fascia
	float cell = ang / TAU * RUNES;
	float id = floor(cell);
	float cw = TAU * R_RUNE / RUNES;
	vec2 q = vec2((fract(cell) - 0.5) * cw, r - R_RUNE);
	if (abs(q.y) < 0.11) {
		m = max(m, rune(q, mod(id, RUNES), aa));
	}
	// stella a otto punte {8/3} fra l'anello interno e quello attorno all'altare
	float star = 0.0;
	for (int k = 0; k < 8; k++) {
		float a0 = TAU * float(k) / 8.0 + 0.3927;
		float a1 = TAU * float(k + 3) / 8.0 + 0.3927;
		star = max(star, line(seg(p, vec2(cos(a0), sin(a0)) * R_IN, vec2(cos(a1), sin(a1)) * R_IN), 0.018, aa));
		// borchie sulle punte
		star = max(star, line(length(p - vec2(cos(a0), sin(a0)) * (R_IN + 0.0)), 0.07, aa));
	}
	m = max(m, star * step(R_CORE, r));
	// crepe bruciate che partono dall'anello esterno e si perdono nel terreno
	float crack = 0.0;
	if (r > R_OUT && r < R_OUT + 0.55) {
		vec3 vo = voronoi2(vec2(ang * 9.0, r * 7.0));
		float k = 1.0 - smoothstep(0.0, 0.035, vo.y);
		crack = k * smoothstep(R_OUT + 0.55, R_OUT + 0.02, r) * step(0.55, hash21(vec2(vo.z, 3.0)));
	}
	// consumato: qua e là il solco è più debole o interrotto
	float wear = 0.55 + 0.45 * smoothstep(0.25, 0.7, vnoise2(p * 6.0));
	m *= wear;
	// bordo del solco: una fascia più larga di terra bruciata attorno a ogni incisione
	float burn = clamp(m * 2.5, 0.0, 1.0);
	float scorch = smoothstep(R_OUT + 0.35, R_OUT - 0.15, r) * (0.25 + 0.35 * vnoise2(p * 2.5));
	// dentro i solchi la brace: macchie calde che si accendono e si spengono, scorrono lente attorno
	float t = TIME;
	float hot = vnoise2(vec2(ang * 6.0 - t * 0.35, r * 4.0)) * 0.6 + vnoise2(p * 9.0 + vec2(t * 0.6, -t * 0.4)) * 0.4;
	hot = smoothstep(0.25, 0.85, hot);
	float breath = 0.75 + 0.25 * sin(t * 1.1 + ang * 2.0);
	vec3 deep = vec3(0.55, 0.035, 0.01);           // brace: rosso cupo, arancio solo dove è più calda
	vec3 ember = mix(deep, vec3(1.0, 0.26, 0.03), smoothstep(0.55, 1.0, hot));
	vec3 burnt = vec3(0.012, 0.008, 0.006);
	ALBEDO = mix(burnt, vec3(0.06, 0.015, 0.008), m);
	ROUGHNESS = 0.95;
	EMISSION = ember * (m * (0.45 + hot * 0.9) + crack * 0.4 * hot) * breath * energy;
	ALPHA = clamp(max(max(burn, scorch * 0.8), crack * 0.9), 0.0, 1.0) * smoothstep(R_OUT + 0.6, R_OUT + 0.4, r);
}
