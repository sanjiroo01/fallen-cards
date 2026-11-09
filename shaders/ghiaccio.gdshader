shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Ghiaccio di un lago: azzurro scuro in profondità, chiaro dove è spesso, crepe bianche a ragnatela,
// spolverate di neve, abbastanza liscio da riflettere il falò.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 deep : source_color = vec3(0.05, 0.1, 0.14);
uniform vec3 pale : source_color = vec3(0.45, 0.58, 0.66);
uniform vec3 snow : source_color = vec3(0.78, 0.82, 0.86);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float thick = fbm2(p * 0.25);
	vec3 col = mix(deep, pale, smoothstep(0.3, 0.8, thick));
	// crepe: bordi delle celle di Voronoi a due scale
	vec2 q = p + vec2(fbm2(p * 0.35), fbm2(p * 0.35 + 4.0)) * 3.0;     // crepe storte, non a griglia
	vec3 v1 = voronoi2(q * 0.55);
	vec3 v2 = voronoi2(q * 1.9 + 7.0);
	float crack = (1.0 - smoothstep(0.0, 0.035, v1.y)) + (1.0 - smoothstep(0.0, 0.025, v2.y)) * 0.5;
	crack *= smoothstep(0.35, 0.65, fbm2(p * 0.5 + 11.0));       // le crepe ci sono solo in alcune zone
	col = mix(col, pale * 1.3, clamp(crack, 0.0, 1.0) * 0.45);
	// neve portata dal vento
	float dust = smoothstep(0.5, 0.8, fbm2(p * 0.6 + vec2(3.0, 9.0)) + (fbm2(p * 4.0) - 0.5) * 0.3);
	col = mix(col, snow, dust);
	ALBEDO = col;
	ROUGHNESS = mix(0.08, 0.85, dust) + crack * 0.2;
	SPECULAR = 0.55;
	vec3 nw = normalize(vec3((vnoise2(p * 3.0) - 0.5) * 0.04, 1.0, (vnoise2(p * 3.0 + 5.0) - 0.5) * 0.04));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
}
