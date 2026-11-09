shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Lastre di pietra consumate, con pozzanghere che riflettono le candele.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 stone_a : source_color = vec3(0.26, 0.24, 0.22);
uniform vec3 stone_b : source_color = vec3(0.34, 0.31, 0.27);
uniform vec3 gap_col : source_color = vec3(0.06, 0.05, 0.045);
uniform vec2 slab = vec2(0.62, 0.46);
uniform float puddles = 0.6;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float slab_h(vec2 p, out vec2 id, out float crack) {
	vec2 w = p + (vec2(fbm2_3(p * 1.3), fbm2_3(p * 1.3 + 9.0)) - 0.5) * 0.09;
	vec2 q = w / slab;
	float row = floor(q.y);
	q.x += hash21(vec2(row, 1.7)) * 0.9;
	id = vec2(floor(q.x), row);
	vec2 f = fract(q) * slab;
	vec2 e = min(f, slab - f);
	float d = min(e.x, e.y);
	float h = smoothstep(0.004, 0.03, d + (vnoise2(p * 30.0) - 0.5) * 0.012);
	// crepe dentro la lastra
	vec3 vo = voronoi2(w * 3.0 + id * 7.0);
	crack = (1.0 - smoothstep(0.0, 0.015, vo.y)) * step(0.6, hash21(id + 3.0));
	h -= crack * 0.5;
	// lastre leggermente inclinate e consumate
	h += (hash21(id) - 0.5) * 0.15 * (f.x / slab.x - 0.5);
	h *= 0.85 + 0.15 * fbm2_3(p * 14.0);
	return h;
}

void fragment() {
	vec2 p = wpos.xz;
	vec2 id;
	float crack;
	float h = slab_h(p, id, crack);
	float e = 0.002;
	vec2 i2;
	float c2;
	float hx = slab_h(p + vec2(e, 0.0), i2, c2);
	float hy = slab_h(p + vec2(0.0, e), i2, c2);

	float wet = smoothstep(puddles - 0.08, puddles, fbm2(p * 0.45 + 3.0)) * smoothstep(0.1, 0.5, 1.0 - h + 0.6);
	vec2 g = vec2(hx - h, hy - h) / e * 0.01 * (1.0 - wet * 0.9);

	vec3 col = mix(stone_a, stone_b, hash21(id));
	col *= 0.7 + 0.5 * fbm2(p * 4.0 + id * 2.0);
	col = mix(col, col * vec3(0.9, 0.85, 0.75), vnoise2(p * 18.0) * 0.4);
	float gap = 1.0 - smoothstep(0.1, 0.5, h);
	col = mix(col, gap_col, gap * 0.9);
	col = mix(col, gap_col, crack * 0.7);
	// sporco e polvere vicino ai muri
	float dust = smoothstep(3.2, 4.4, max(abs(p.x), abs(p.y + 0.5)));
	col = mix(col, vec3(0.2, 0.18, 0.15), dust * 0.5);
	col *= mix(1.0, 0.45, wet);

	vec3 nw = normalize(vec3(-g.x, 1.0, -g.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	ALBEDO = col;
	ROUGHNESS = mix(mix(0.78, 0.95, gap), 0.06, wet);
	SPECULAR = mix(0.4, 0.6, wet);
	AO = mix(0.4, 1.0, smoothstep(0.0, 0.5, h));
}
