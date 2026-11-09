shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Legno carbonizzato e braci: superficie nera e opaca con crepe che brillano d'arancio e pulsano piano,
// come quando il vento soffia sul fuoco.

#include "res://shaders/noise.gdshaderinc"

uniform float heat = 1.0;           // quanto è viva la brace (letto di braci > ceppi)

varying vec3 lpos;

void vertex() {
	lpos = VERTEX;
}

void fragment() {
	vec3 p = lpos * 9.0;
	float cracks = vnoise3(p) * 0.6 + vnoise3(p * 2.7) * 0.4;
	float glow = smoothstep(0.68, 0.74, cracks) * (1.0 - smoothstep(0.74, 0.84, cracks)) + smoothstep(0.8, 0.9, cracks) * 0.4;
	float pulse = 0.65 + 0.35 * sin(TIME * 1.7 + vnoise3(lpos * 3.0 + TIME * 0.3) * 6.0);
	ALBEDO = mix(vec3(0.025, 0.02, 0.018), vec3(0.12, 0.05, 0.02), glow);
	ROUGHNESS = 0.95;
	EMISSION = mix(vec3(0.9, 0.18, 0.02), vec3(1.0, 0.55, 0.12), glow) * glow * pulse * 3.0 * heat;
}
