shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
// Aria calda sopra il fuoco: un piano rivolto alla telecamera che non si vede, ma sposta appena quello che
// c'è dietro, con un tremolio che sale. Più forte poco sopra le fiamme, sparisce ai bordi e in alto.

#include "res://shaders/noise.gdshaderinc"

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float strength = 0.006;

void vertex() {
	// rivolto alla telecamera, ma dritto
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], MODEL_MATRIX[1], vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, MODEL_MATRIX[1].xyz)), 0.0), MODEL_MATRIX[3]);
}

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;
	float edge = smoothstep(0.5, 0.15, abs(uv.x - 0.5)) * smoothstep(0.0, 0.25, uv.y) * smoothstep(1.0, 0.55, uv.y);
	vec2 n = vec2(vnoise2(vec2(uv.x * 7.0, uv.y * 5.0 - TIME * 2.2)), vnoise2(vec2(uv.x * 7.0 + 13.0, uv.y * 5.0 - TIME * 2.6))) - 0.5;
	vec2 off = n * strength * edge;
	ALBEDO = textureLod(screen, SCREEN_UV + off, 0.0).rgb;
	ALPHA = edge;
}
