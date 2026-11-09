shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;
// Pelle e cuoio: grana fine, lucida dove è consumata.

#include "res://shaders/noise.gdshaderinc"
#include "res://shaders/rest.gdshaderinc"

uniform vec3 base : source_color = vec3(0.08, 0.04, 0.03);
uniform vec3 worn : source_color = vec3(0.2, 0.11, 0.07);
uniform float grain_scale = 900.0;
uniform float grain_strength = 0.35;
uniform float shine = 0.5;
uniform float wet_look = 0.0;
uniform float ghost = 0.0;
uniform bool use_rest = false;
uniform float seams = 0.0;

varying vec3 lpos;
varying vec3 lnrm;

void vertex() {
	lpos = use_rest ? rest_pos(UV2, COLOR) : VERTEX;
	lnrm = NORMAL;
}

void fragment() {
	vec3 n = normalize(lnrm);
	if (!FRONT_FACING) {
		n = -n;
	}
	// la grana sfuma quando un pixel copre più granelli: da lontano non sfrigola
	float px = length(fwidth(lpos)) * grain_scale;
	float aa = 1.0 / (1.0 + px * px * 4.0);
	vec3 nb = bump_world(lpos, n, grain_scale, grain_strength * aa);
	// ondulazione larga appena accennata: più forte, sotto la luce radente, disegnava muscoli
	nb = bump_world(lpos + 3.1, nb, grain_scale * 0.12, grain_strength * 0.1);
	NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(nb, 0.0)).xyz);
	// usura: chiazze piccole e tenui (grandi e chiare, sotto la candela, sembravano bozzi)
	float w = smoothstep(0.5, 0.85, fbm3(lpos * 60.0));
	vec3 col = mix(base, worn, w * 0.4);
	col *= 0.85 + 0.3 * vnoise3(lpos * 180.0);
	// grinze del cuoio: corte e spezzate in ogni direzione (a strisce sembravano costole)
	float crease = smoothstep(0.66, 0.82, vnoise3(lpos * 140.0)) * smoothstep(0.4, 0.7, vnoise3(lpos * 23.0 + 7.0));
	col *= 1.0 - crease * 0.18;
	ALBEDO = col;
	ROUGHNESS = clamp(mix(0.62, 0.3, shine) - w * 0.05 - wet_look * 0.3 + crease * 0.1, 0.08, 1.0);
	SPECULAR = 0.5;
	RIM = 0.25;
	RIM_TINT = 0.6;
	EMISSION = vec3(0.35, 0.6, 0.75) * ghost * pow(clamp(1.0 - abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0) * 2.0;
}
