shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Ferro battuto, ottone e acciaio: patina, ruggine, rilievi del martello.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 base : source_color = vec3(0.3, 0.3, 0.32);
uniform vec3 rust : source_color = vec3(0.22, 0.09, 0.04);
uniform float rust_amount = 0.3;
uniform float rough = 0.45;
uniform float hammer = 0.6;
uniform float edge_shine = 0.0;

varying vec3 lpos;
varying vec3 lnrm;

void vertex() {
	lpos = VERTEX;
	lnrm = NORMAL;
}

void fragment() {
	vec3 n = normalize(lnrm);
	vec3 nb = bump_world(lpos, n, 60.0, 0.25 * hammer);
	NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(nb, 0.0)).xyz);
	float r = smoothstep(1.0 - rust_amount, 1.0 - rust_amount + 0.2, fbm3(lpos * 22.0));
	float spot = vnoise3(lpos * 140.0);
	ALBEDO = mix(base * (0.8 + 0.3 * spot), rust * (0.7 + 0.5 * spot), r);
	METALLIC = mix(1.0, 0.1, r);
	ROUGHNESS = clamp(mix(rough + 0.15 * spot, 0.9, r), 0.05, 1.0);
	SPECULAR = 0.5;
}
