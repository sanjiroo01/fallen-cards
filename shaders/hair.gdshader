shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Capelli e barba: ciocche che scorrono in una direzione, riflessi lucidi.

#include "res://shaders/noise.gdshaderinc"
#include "res://shaders/rest.gdshaderinc"

uniform vec3 base : source_color = vec3(0.09, 0.05, 0.025);
uniform vec3 tip : source_color = vec3(0.22, 0.13, 0.06);
uniform vec3 flow = vec3(0.0, 1.0, 0.0);
uniform float strand = 1100.0;
uniform float ghost = 0.0;

varying vec3 rest;

void vertex() {
	rest = rest_pos(UV2, COLOR);
}

void fragment() {
	vec3 f = normalize(flow);
	vec3 a = normalize(cross(f, vec3(0.0, 0.0, 1.0) + f.zxy * 0.01));
	vec3 b = cross(f, a);
	vec3 q = vec3(dot(rest, a) * strand, dot(rest, b) * strand, dot(rest, f) * 12.0);
	// ciocche sottili e irregolari: due frequenze, nessuna riga regolare
	float s = vnoise3(q + vec3(vnoise3(rest * 60.0) * 3.0));
	float s2 = vnoise3(q * vec3(0.23, 0.23, 0.4) + 7.0);
	vec3 col = mix(base, tip, s2 * 0.4 + s * 0.2);
	col *= 0.92 + 0.12 * s;
	ALBEDO = col;
	ROUGHNESS = 0.32 + 0.3 * (1.0 - s);
	SPECULAR = 0.55;
	float e = 0.002;
	NORMAL_MAP = normalize(vec3((s - vnoise3(q + vec3(e * strand, 0.0, 0.0))) * 1.5, (s - vnoise3(q + vec3(0.0, e * strand, 0.0))) * 1.5, 1.0)) * 0.5 + 0.5;
	RIM = 0.4;
	RIM_TINT = 0.5;
	EMISSION = vec3(0.35, 0.6, 0.75) * ghost * pow(clamp(1.0 - abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0) * 2.0;
}
