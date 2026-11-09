shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
// Fiamma di candela: rivolta sempre verso la camera, ma dritta in verticale.

#include "res://shaders/noise.gdshaderinc"

uniform float intensity = 5.0;
uniform float seed = 0.0;
uniform float sway = 0.0;

void vertex() {
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 to_cam = normalize(INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz);
	vec3 right = normalize(cross(up, to_cam));
	vec3 fwd = cross(right, up);
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	mat4 bb = mat4(vec4(right * sx, 0.0), vec4(up * sy, 0.0), vec4(fwd, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * bb;
}

void fragment() {
	vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y); // y: 0 base, 1 punta
	float t = TIME * 3.0 + seed * 10.0;
	float n = vnoise2(vec2(p.y * 3.0 - t * 1.3, seed * 7.0));
	float bend = (n - 0.5) * 0.45 * p.y * p.y + sway * p.y * p.y;
	float x = p.x - bend;
	float y = p.y;
	// sagoma a goccia
	float w = 0.62 * pow(clamp(1.0 - y, 0.0, 1.0), 0.75) * smoothstep(-0.02, 0.22, y);
	float shape = 1.0 - smoothstep(w * 0.25, w, abs(x));
	shape *= smoothstep(1.0, 0.7, y + (n - 0.5) * 0.25);
	float core = (1.0 - smoothstep(w * 0.05, w * 0.55, abs(x))) * smoothstep(0.08, 0.3, y) * smoothstep(0.75, 0.35, y);
	float blue = smoothstep(0.28, 0.0, y) * (1.0 - smoothstep(0.0, w * 1.3, abs(x)));
	vec3 col = vec3(1.0, 0.36, 0.06) * shape;
	col += vec3(1.0, 0.72, 0.32) * core * 1.4;
	col += vec3(0.15, 0.25, 0.9) * blue * 0.8;
	float flick = 0.85 + 0.15 * vnoise2(vec2(t * 2.5, seed));
	ALBEDO = col * intensity * flick;
}
