shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Sottobosco: terra umida, chiazze di muschio, foglie marce e sassolini. Tutto procedurale, in coordinate
// del mondo, così il terreno non si ripete.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 dirt : source_color = vec3(0.075, 0.06, 0.045);
uniform vec3 moss : source_color = vec3(0.07, 0.1, 0.045);
uniform vec3 leaves : source_color = vec3(0.16, 0.08, 0.035);
uniform float wet = 0.5;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = wpos.xz;
	float big = fbm2(p * 0.18);
	float mid = fbm2(p * 0.9 + 3.0);
	float fine = vnoise2(p * 9.0);
	float m = smoothstep(0.45, 0.7, big + (mid - 0.5) * 0.4);
	vec3 col = mix(dirt, moss, m);
	// foglie: macchie piccole e irregolari
	vec3 v = voronoi2(p * 3.2);
	float leaf = smoothstep(0.32, 0.1, v.x) * step(0.55, hash21(floor(p * 3.2) + v.yz));
	col = mix(col, leaves * (0.7 + 0.6 * fine), leaf * (1.0 - m * 0.7));
	// sassolini
	vec3 s = voronoi2(p * 7.0 + 11.0);
	float stone = smoothstep(0.12, 0.04, s.x) * step(0.8, hash21(floor(p * 7.0 + 11.0) + s.yz));
	col = mix(col, vec3(0.16, 0.15, 0.14), stone);
	col *= 0.8 + 0.4 * fine;
	float puddle = smoothstep(0.62, 0.7, fbm2(p * 0.35 + 7.0)) * wet;
	ALBEDO = col * (1.0 - puddle * 0.5);
	ROUGHNESS = mix(0.95, 0.15, puddle) - leaf * 0.1;
	vec3 nw = bump_world(wpos, wnrm, 9.0, 0.35 * (1.0 - puddle));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
}
