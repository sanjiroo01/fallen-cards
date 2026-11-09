shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Mattoni antichi: fughe, mattoni scheggiati, fuliggine in alto, umidità in basso.

#include "res://shaders/noise.gdshaderinc"

uniform bool use_uv = false;
uniform vec2 brick_size = vec2(0.27, 0.085);
uniform float mortar = 0.012;
uniform vec3 brick_a : source_color = vec3(0.33, 0.14, 0.085);
uniform vec3 brick_b : source_color = vec3(0.45, 0.23, 0.14);
uniform vec3 brick_c : source_color = vec3(0.29, 0.22, 0.19);
uniform vec3 mortar_col : source_color = vec3(0.36, 0.33, 0.29);
uniform float soot_start = 1.9;
uniform float damp_height = 0.55;
uniform float relief = 0.012;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float brick_h(vec2 p, out vec2 id, out vec2 local) {
	vec2 q = p / brick_size;
	float row = floor(q.y);
	q.x += mod(row, 2.0) * 0.5 + hash21(vec2(row, 3.0)) * 0.13;
	id = vec2(floor(q.x), row);
	vec2 f = fract(q) * brick_size;
	local = f / brick_size;
	vec2 e = min(f, brick_size - f);
	float d = min(e.x, e.y);
	float chip = (vnoise2(p * 41.0) - 0.5) * 0.009 + (vnoise2(p * 9.0 + id) - 0.5) * 0.006;
	float h = smoothstep(mortar * 0.5, mortar * 0.5 + 0.014, d + chip);
	float surf = fbm2_3(p * 26.0 + id * 3.1);
	h *= 0.8 + 0.2 * surf;
	return h;
}

void fragment() {
	vec3 n = normalize(wnrm);
	vec2 p;
	vec3 T;
	vec3 B;
	vec3 an = abs(n);
	if (use_uv) {
		p = UV;
		T = vec3(1.0, 0.0, 0.0);
		B = vec3(0.0, 1.0, 0.0);
	} else if (an.y > an.x && an.y > an.z) {
		p = wpos.xz;
		T = vec3(1.0, 0.0, 0.0);
		B = vec3(0.0, 0.0, 1.0);
	} else if (an.x > an.z) {
		p = wpos.zy;
		T = vec3(0.0, 0.0, 1.0);
		B = vec3(0.0, 1.0, 0.0);
	} else {
		p = wpos.xy;
		T = vec3(1.0, 0.0, 0.0);
		B = vec3(0.0, 1.0, 0.0);
	}
	vec2 id;
	vec2 loc;
	float h = brick_h(p, id, loc);
	float e = 0.0015;
	vec2 i2;
	vec2 l2;
	float hx = brick_h(p + vec2(e, 0.0), i2, l2);
	float hy = brick_h(p + vec2(0.0, e), i2, l2);
	vec2 g = vec2(hx - h, hy - h) / e * relief;

	float r = hash21(id);
	vec3 col = r < 0.45 ? mix(brick_a, brick_b, hash21(id + 7.0)) : (r < 0.85 ? mix(brick_b, brick_a, 0.5) : brick_c);
	col *= 0.75 + 0.4 * fbm2(p * 7.0 + id);
	// macchie e bruciature sul singolo mattone
	col *= mix(1.0, 0.55, smoothstep(0.55, 0.9, vnoise2(loc * vec2(2.0, 1.0) + id * 5.3)));
	float mortar_mask = 1.0 - smoothstep(0.05, 0.35, h);
	vec3 mcol = mortar_col * (0.7 + 0.5 * vnoise2(p * 60.0));
	col = mix(col, mcol, mortar_mask);

	// fuliggine delle candele in alto
	float soot = smoothstep(soot_start - 0.6, soot_start + 1.2, wpos.y + (fbm2(p * 1.5) - 0.5) * 0.9);
	col = mix(col, col * 0.18, soot * 0.85);
	// umidità e salnitro vicino al pavimento
	float wet_line = damp_height + (fbm2(p * 2.2) - 0.5) * 0.5;
	float damp = 1.0 - smoothstep(wet_line - 0.25, wet_line, wpos.y);
	float salt = smoothstep(0.1, 0.0, abs(wpos.y - wet_line)) * smoothstep(0.45, 0.8, fbm2(p * 5.0));
	col = mix(col, col * 0.45, damp * 0.8);
	col = mix(col, vec3(0.55, 0.53, 0.48), salt * 0.45);

	vec3 nw = normalize(n - g.x * T - g.y * B);
	if (use_uv) {
		NORMAL_MAP = normalize(vec3(-g.x, -g.y, 1.0)) * 0.5 + 0.5;
	} else {
		NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	}
	ALBEDO = col;
	ROUGHNESS = mix(mix(0.82, 0.95, mortar_mask), 0.42, damp * 0.9);
	SPECULAR = 0.35;
	AO = mix(0.35, 1.0, smoothstep(0.0, 0.6, h));
	AO_LIGHT_AFFECT = 0.4;
}
