shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;
// Stoffe: velluto, seta, lana, lino. Pieghe, riflesso sui bordi, motivi.
// La posizione a riposo arriva in UV2 e nei colori (vedi rest.gdshaderinc), così il disegno non scivola.

#include "res://shaders/noise.gdshaderinc"
#include "res://shaders/rest.gdshaderinc"

uniform vec3 base : source_color = vec3(0.12, 0.02, 0.03);
uniform vec3 base2 : source_color = vec3(0.05, 0.01, 0.015);
uniform int pattern = 0; // 0 liscio, 1 rombi, 2 damascato, 3 righe, 4 pizzo, 5 toppe di Arlecchino (Seicento)
uniform vec3 pat_col : source_color = vec3(0.4, 0.3, 0.1);
uniform float fold_scale = 9.0;
uniform float fold_strength = 0.6;
uniform float sheen = 0.7;
uniform float rough = 0.88;
uniform float ghost = 0.0;
uniform float pattern_scale = 1.0;
uniform float drape = 0.0;
uniform bool use_rest = true;
uniform float wear = 0.3;

varying vec3 lpos;
varying vec3 lnrm;

float folds(vec3 p) {
	return fbm3_2(vec3(p.x * fold_scale, p.y * fold_scale * 0.35, p.z * fold_scale));
}

void vertex() {
	lpos = use_rest ? rest_pos(UV2, COLOR) : VERTEX;
	lnrm = NORMAL;
	if (drape > 0.0) {
		float rad = length(VERTEX.xz);
		vec2 dir = rad > 0.0001 ? VERTEX.xz / rad : vec2(1.0, 0.0);
		float fold = fbm3_2(vec3(dir.x * 2.2, VERTEX.y * 1.4, dir.y * 2.2) + vec3(3.0));
		VERTEX += NORMAL * (fold - 0.5) * drape * smoothstep(0.0, 0.04, rad);
	}
}

void fragment() {
	vec3 p = lpos;
	float f0 = folds(p);
	vec3 col = mix(base2, base, smoothstep(0.2, 0.8, f0));
	float alpha = 1.0;
	if (pattern == 1) {
		// rombi: nello spazio UV del corpo
		vec2 q = UV * vec2(26.0, 20.0) * pattern_scale;
		vec2 r = vec2(q.x + q.y, q.x - q.y) * 0.5;
		vec2 cid = floor(r);
		vec2 d = abs(fract(r) - 0.5);
		float cell = mod(cid.x + cid.y * 2.0, 4.0);
		vec3 c1 = vec3(0.42, 0.045, 0.035);
		vec3 c2 = vec3(0.05, 0.2, 0.1);
		vec3 c3 = vec3(0.5, 0.36, 0.08);
		vec3 c4 = vec3(0.07, 0.1, 0.28);
		vec3 dc = cell < 0.5 ? c1 : (cell < 1.5 ? c2 : (cell < 2.5 ? c3 : c4));
		dc *= 0.85 + 0.25 * vnoise2(cid * 3.1);
		col = dc * (0.6 + 0.5 * smoothstep(0.2, 0.8, f0));
		float line = smoothstep(0.455, 0.49, max(d.x, d.y));
		col = mix(col, vec3(0.012), line * 0.9);
	} else if (pattern == 2) {
		// damascato: fiori ricamati, lucidi
		vec3 q = p * 22.0 * pattern_scale;
		vec3 vo = vec3(voronoi2(q.xy + q.z * 0.3));
		float petal = abs(sin(atan(q.y - floor(q.y) - 0.5, q.x - floor(q.x) - 0.5) * 4.0)) * 0.22 + 0.12;
		vec2 cq = fract(vec2(q.x + q.z * 0.5, q.y)) - 0.5;
		float dam = 1.0 - smoothstep(petal - 0.03, petal, length(cq));
		float vine = 1.0 - smoothstep(0.0, 0.035, abs(cq.y - 0.12 * sin(cq.x * 12.566)));
		float m = clamp(dam + vine * 0.5, 0.0, 1.0);
		col = mix(col, pat_col * (0.55 + 0.4 * f0), m * 0.55);
		SPECULAR = 0.5;
	} else if (pattern == 3) {
		float st = step(0.5, fract((p.x + p.z) * 30.0 * pattern_scale));
		col = mix(col, pat_col, st * 0.6);
	} else if (pattern == 4) {
		// pizzo: disegno a fiori in rilievo, i vuoti sono ombra (niente trafori che sfarfallano)
		vec3 q = p * 70.0 * pattern_scale;
		vec3 vo = voronoi2(q.xy + q.z * 0.7);
		vec3 vo2 = voronoi2(q.yz * 1.3 + 5.0);
		float hole = smoothstep(0.2, 0.34, vo.x) * smoothstep(0.02, 0.08, vo.y);
		float hole2 = smoothstep(0.28, 0.4, vo2.x) * smoothstep(0.03, 0.09, vo2.y);
		float h = max(hole, hole2 * 0.8);
		float thread = 1.0 - smoothstep(0.0, 0.025, vo.y);
		col = base * (0.95 + 0.1 * vnoise3(q * 3.0));
		col = mix(col, base * 0.25, h * 0.75);
		col = mix(col, base * 1.15, thread * 0.5);
		alpha = 1.0;
	}
	if (pattern == 5) {
		// tela chiara piena di toppe cucite a caso, come il vestito di un servo povero del Seicento
		vec2 q = vec2(p.x + p.z * 0.6, p.y + p.z * 0.3) * 13.0 * pattern_scale;
		vec2 warp = vec2(vnoise2(q * 0.7), vnoise2(q * 0.7 + 9.0)) - 0.5;
		vec3 vo = voronoi2(q + warp * 0.8);
		float id = vo.z;
		vec3 cloth = mix(base2, base, smoothstep(0.2, 0.8, f0));
		vec3 pc = cloth;
		if (id < 0.18) pc = vec3(0.36, 0.06, 0.04);
		else if (id < 0.32) pc = vec3(0.1, 0.22, 0.09);
		else if (id < 0.44) pc = vec3(0.09, 0.12, 0.26);
		else if (id < 0.54) pc = vec3(0.48, 0.35, 0.09);
		else if (id < 0.6) pc = vec3(0.22, 0.13, 0.07);
		pc *= 0.75 + 0.35 * smoothstep(0.2, 0.8, f0);
		pc *= 0.88 + 0.2 * vnoise2(q * 9.0 + id * 40.0);
		col = pc;
		// cuciture: punti scuri lungo i bordi delle toppe
		float seam = 1.0 - smoothstep(0.015, 0.04, vo.y);
		float stitch = step(0.5, fract((q.x + q.y) * 7.0));
		col = mix(col, col * 0.35, seam * (0.55 + 0.45 * stitch));
	}
	// usura sui rilievi
	col = mix(col, col * 1.25 + vec3(0.01), wear * smoothstep(0.6, 0.85, fbm3(p * 25.0)) * 0.4);
	vec3 n = normalize(lnrm);
	if (!FRONT_FACING) {
		n = -n;
	}
	float e = 0.01;
	vec3 g = vec3(folds(p + vec3(e, 0.0, 0.0)) - f0, folds(p + vec3(0.0, e, 0.0)) - f0, folds(p + vec3(0.0, 0.0, e)) - f0) / e;
	g -= dot(g, n) * n;
	vec3 nb = normalize(n - g * 0.02 * fold_strength);
	nb = bump_world(p, nb, 700.0, 0.1);
	NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(nb, 0.0)).xyz);
	ALBEDO = col;
	ROUGHNESS = rough;
	RIM = sheen;
	RIM_TINT = 0.55;
	float fres = pow(clamp(1.0 - abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.5);
	EMISSION = vec3(0.3, 0.55, 0.7) * ghost * fres * 2.5;
}
