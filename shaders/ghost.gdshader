shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;
// Spettro: solo il contorno, freddo, che ondeggia.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 tint : source_color = vec3(0.35, 0.65, 0.8);
uniform float strength = 1.0;

varying vec3 lpos;

void vertex() {
	lpos = VERTEX;
	VERTEX += NORMAL * (vnoise3(VERTEX * 6.0 + vec3(0.0, TIME * 0.6, 0.0)) - 0.5) * 0.02;
}

void fragment() {
	float fres = pow(clamp(1.0 - abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.2);
	float flow = fbm3(lpos * 5.0 + vec3(0.0, -TIME * 0.35, 0.0));
	ALBEDO = tint * (fres * 1.4 + flow * 0.12) * strength;
}
