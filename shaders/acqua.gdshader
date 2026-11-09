shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Acqua ferma e scura della palude: quasi nera, liscia come uno specchio (riflette fuoco e lanterne),
// increspata appena da due onde lente, con chiazze di lenticchie d'acqua e foglie.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 deep : source_color = vec3(0.02, 0.03, 0.026);
uniform vec3 scum : source_color = vec3(0.07, 0.09, 0.035);
uniform float scum_amount = 0.35;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float t = TIME * 0.05;
	// increspature: gradiente di due rumori che scorrono in direzioni diverse
	float e = 0.05;
	float h0 = fbm2(p * 1.3 + vec2(t, t * 0.6)) + fbm2(p * 2.1 - vec2(t * 0.7, t));
	float hx = fbm2((p + vec2(e, 0.0)) * 1.3 + vec2(t, t * 0.6)) + fbm2((p + vec2(e, 0.0)) * 2.1 - vec2(t * 0.7, t));
	float hz = fbm2((p + vec2(0.0, e)) * 1.3 + vec2(t, t * 0.6)) + fbm2((p + vec2(0.0, e)) * 2.1 - vec2(t * 0.7, t));
	vec3 nw = normalize(vec3(-(hx - h0) / e * 0.025, 1.0, -(hz - h0) / e * 0.025));
	// chiazze galleggianti
	float s = smoothstep(0.55, 0.75, fbm2(p * 0.4 + 3.0)) * scum_amount;
	ALBEDO = mix(deep, scum, s);
	ROUGHNESS = mix(0.015, 0.8, s);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	EMISSION = vec3(0.03, 0.045, 0.05) * fres * (1.0 - s);
	SPECULAR = 1.0;
	NORMAL = normalize((VIEW_MATRIX * vec4(mix(nw, vec3(0.0, 1.0, 0.0), s), 0.0)).xyz);
}
