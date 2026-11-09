shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Cera: traslucida, si illumina vicino alla fiamma.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 base : source_color = vec3(0.86, 0.78, 0.62);
uniform float top_y = 0.2;
uniform float lit = 1.0;

varying vec3 lpos;
varying vec3 lnrm;

void vertex() {
	lpos = VERTEX;
	lnrm = NORMAL;
}

void fragment() {
	vec3 n = normalize(lnrm);
	vec3 nb = bump_world(lpos, n, 120.0, 0.18);
	NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(nb, 0.0)).xyz);
	float dirt = fbm3(lpos * 40.0);
	// la cera vicino alla fiamma riceve già tanta luce: l'albedo resta sotto il bianco pieno
	ALBEDO = base * (0.68 + 0.2 * dirt);
	ROUGHNESS = 0.42;
	SSS_STRENGTH = 0.7;
	BACKLIGHT = vec3(0.9, 0.55, 0.25) * 0.45;
	// solo l'orlo sotto la fiamma si accende, in arancio, e sfuma presto verso il basso
	float glow = smoothstep(top_y - 0.03, top_y, lpos.y) * lit;
	EMISSION = vec3(1.0, 0.42, 0.1) * glow * glow * 0.55;
}
