shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
// Fiammella: un piano rivolto alla telecamera su cui scorre del rumore verso l'alto. Tante fiammelle
// sovrapposte fanno il falò. La forma (larga in basso, a punta in alto) è bucata e piegata dal rumore,
// così le lingue si staccano e tremano. Il colore segue il "calore": giallo solo alla base e nel cuore,
// arancio nel corpo, rosso scuro sulle punte che svaniscono.

#include "res://shaders/noise.gdshaderinc"

uniform float seed = 0.0;
uniform float speed = 2.0;
uniform float strength = 1.0;

void vertex() {
	// sempre rivolta alla telecamera, ma dritta (ruota solo attorno all'asse verticale)
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], MODEL_MATRIX[1], vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, MODEL_MATRIX[1].xyz)), 0.0), MODEL_MATRIX[3]);
}

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;                       // 0 in basso, 1 in alto
	float t = TIME * speed + seed * 13.0;
	// il rumore sale e si allunga: grande e lento + piccolo e veloce
	float n1 = fbm2(vec2(uv.x * 2.5 + seed, uv.y * 1.6 - t));
	float n2 = fbm2(vec2(uv.x * 6.0 - seed * 2.0, uv.y * 4.5 - t * 1.8));
	float n = n1 * 0.6 + n2 * 0.4;
	// la fiamma ondeggia di lato, di più in alto
	float x = (uv.x - 0.5) * 2.0;
	x += (n1 - 0.5) * 1.1 * uv.y + sin(t * 0.7 + seed) * 0.12 * uv.y;
	float width = mix(0.8, 0.0, pow(uv.y, 0.7));
	float shape = 1.0 - smoothstep(width * 0.35, width, abs(x));
	shape *= smoothstep(0.0, 0.12, uv.y);             // base morbida, nascosta tra i ceppi
	// calore: alto al centro in basso, scende verso l'alto, il rumore lo spezza in lingue
	float heat = shape * (1.15 - uv.y * 1.25) + (n - 0.5) * 0.9;
	heat = clamp(heat, 0.0, 1.0);
	float f = smoothstep(0.08, 0.45, heat);
	vec3 deep = vec3(0.45, 0.04, 0.01);
	vec3 orange = vec3(1.0, 0.33, 0.04);
	vec3 yellow = vec3(1.0, 0.72, 0.28);
	vec3 col = mix(deep, orange, smoothstep(0.15, 0.55, heat));
	col = mix(col, yellow, smoothstep(0.62, 0.95, heat) * (1.0 - uv.y));
	ALBEDO = col * f * 1.4 * strength;
	ALPHA = f;
}
