shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Ciocche di capelli: UV.x attorno alla ciocca, UV.y = numero della ciocca + lungo.
// Fili sottili che corrono lungo la ciocca, ogni ciocca col suo tono, riflesso allungato lungo i fili.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 base : source_color = vec3(0.09, 0.05, 0.025);
uniform vec3 tip : source_color = vec3(0.22, 0.13, 0.06);
uniform float ghost = 0.0;

void fragment() {
	float id = floor(UV.y);
	float t = fract(UV.y);
	float a = UV.x * 6.28318;
	vec2 ring = vec2(cos(a), sin(a));
	float tone = hash21(vec2(id, 1.7));
	// i fili: rumore fitto attorno alla ciocca, quasi costante lungo
	float f1 = vnoise2(ring * 9.0 + vec2(t * 2.5, id * 3.7));
	float f2 = vnoise2(ring * 26.0 + vec2(t * 5.0 + id, 0.0));
	float f3 = vnoise2(ring * 60.0 + vec2(t * 9.0, id * 1.3));
	float s = f1 * 0.45 + f2 * 0.35 + f3 * 0.2;
	vec3 col = mix(base, tip, clamp(tone * 0.55 + s * 0.6 - 0.15, 0.0, 1.0));
	col *= 0.62 + 0.55 * s;
	// ai lati della ciocca (dove si appoggia sulle altre) più scuro
	col *= 0.7 + 0.3 * smoothstep(-0.6, 0.6, ring.y);
	ALBEDO = col;
	ROUGHNESS = 0.42 + 0.25 * (1.0 - f2);
	SPECULAR = 0.4;
	float e = 0.02;
	float sx = f2 - vnoise2(vec2(cos(a + e), sin(a + e)) * 26.0 + vec2(t * 5.0 + id, 0.0));
	float sx3 = f3 - vnoise2(vec2(cos(a + e), sin(a + e)) * 60.0 + vec2(t * 9.0, id * 1.3));
	NORMAL_MAP = normalize(vec3((sx * 3.0 + sx3 * 1.5), 0.0, 1.0)) * 0.5 + 0.5;
	RIM = 0.25;
	RIM_TINT = 0.6;
	EMISSION = vec3(0.35, 0.6, 0.75) * ghost * pow(clamp(1.0 - abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0) * 2.0;
}
