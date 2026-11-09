shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Legno scuro vissuto: assi, venature, graffi, cerchi di bicchieri, cera colata, macchie scure.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 wood_dark : source_color = vec3(0.11, 0.06, 0.035);
uniform vec3 wood_light : source_color = vec3(0.27, 0.15, 0.08);
uniform float plank_width = 0.17;
uniform float grain_scale = 1.0;
uniform bool planks = true;
uniform float wear = 1.0;
uniform float stains = 1.0;
uniform float gloss = 0.5;

varying vec3 lpos;
varying vec3 lnrm;

void vertex() {
	lpos = VERTEX;
	lnrm = NORMAL;
}

float grain(vec3 p, float id) {
	vec2 q = vec2(p.x * 1.2, p.z * 26.0 + p.y * 26.0) * grain_scale;
	float warp = fbm2(vec2(p.x * 2.0, p.z * 3.0 + id * 5.0)) * 6.0;
	float rings = sin(q.y + warp + id * 11.0) * 0.5 + 0.5;
	rings = pow(rings, 3.0);
	float fibers = vnoise2(vec2(p.x * 3.0, (p.z + p.y) * 380.0) * grain_scale + id);
	return clamp(rings * 0.65 + fibers * 0.35, 0.0, 1.0);
}

void fragment() {
	vec3 p = lpos;
	float row = planks ? floor(p.z / plank_width) : 0.0;
	float id = hash21(vec2(row, 4.2));
	float g = grain(p, id);
	vec3 col = mix(wood_dark, wood_light, g * (0.7 + 0.6 * id));
	col *= 0.8 + 0.35 * fbm2(vec2(p.x * 0.8, p.z * 2.0) + id * 9.0);

	float gapmask = 0.0;
	if (planks) {
		float fz = fract(p.z / plank_width) * plank_width;
		float d = min(fz, plank_width - fz);
		gapmask = 1.0 - smoothstep(0.0012, 0.004, d);
	}
	// graffi e colpi di mannaia
	float scratch = 0.0;
	for (int i = 0; i < 3; i++) {
		float a = float(i) * 2.1 + 0.4;
		vec2 dir = vec2(cos(a), sin(a));
		vec2 rp = vec2(dot(p.xz, dir), dot(p.xz, vec2(-dir.y, dir.x)));
		float s = vnoise2(vec2(rp.x * 3.0, rp.y * 420.0) + float(i) * 13.0);
		scratch += smoothstep(0.93, 0.99, s) * step(0.45, vnoise2(rp * 6.0 + float(i)));
	}
	scratch = clamp(scratch, 0.0, 1.0) * wear;
	col = mix(col, col * 1.9 + vec3(0.05, 0.03, 0.01), scratch * 0.5);

	// macchie: vino, cera, cerchi di bicchieri
	float st = smoothstep(0.62, 0.75, fbm2(p.xz * 2.2 + 4.0)) * stains;
	col = mix(col, col * vec3(0.45, 0.25, 0.22), st * 0.8);
	vec2 cc = p.xz * 3.0;
	vec3 vr = voronoi2(cc + 1.3);
	float ring = smoothstep(0.02, 0.0, abs(vr.x - 0.33)) * step(0.82, vr.z) * stains;
	col = mix(col, col * 0.5, ring * 0.7);
	float wax = smoothstep(0.08, 0.04, voronoi2(p.xz * 9.0 + 7.0).x) * step(0.9, voronoi2(p.xz * 9.0 + 7.0).z) * stains;
	col = mix(col, col * 1.4 + vec3(0.06, 0.05, 0.03), wax * 0.35);
	col = mix(col, vec3(0.01), gapmask);

	vec3 n = normalize(lnrm);
	float e = 0.0008;
	float g0 = grain(p, id);
	float gx = grain(p + vec3(e, 0.0, 0.0), id);
	float gz = grain(p + vec3(0.0, 0.0, e), id);
	vec3 grad = vec3(gx - g0, 0.0, gz - g0) / e * 0.00035;
	grad -= dot(grad, n) * n;
	vec3 nb = normalize(n - grad);
	NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(nb, 0.0)).xyz);

	ALBEDO = col;
	float polish = mix(0.75, 0.32, gloss) + 0.15 * vnoise2(p.xz * 5.0);
	ROUGHNESS = clamp(mix(polish, 0.9, gapmask + scratch * 0.4 + wax * 0.3), 0.05, 1.0);
	SPECULAR = 0.45;
	AO = 1.0 - gapmask * 0.7;
}
