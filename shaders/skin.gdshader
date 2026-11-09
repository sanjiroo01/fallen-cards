shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Pelle: tono di base, labbra e palpebre dalla mappa delle zone; sul viso le mappe in alta definizione
// (tools/skin_face.py): rossori, occhiaie, sopracciglia pelo per pelo, ciglia, barba rasa, pori, rughe.

#include "res://shaders/noise.gdshaderinc"
#include "res://shaders/rest.gdshaderinc"

uniform sampler2D regions : hint_default_black, filter_linear_mipmap;
uniform sampler2D face_col : hint_default_black, filter_linear_mipmap, repeat_disable;
uniform sampler2D face_nrm : hint_default_black, filter_linear_mipmap, repeat_disable;
uniform vec4 face_rect = vec4(0.0, 0.0, 0.0, 0.0);   // origine e lato del riquadro del viso nelle UV
uniform vec3 tone : source_color = vec3(0.78, 0.58, 0.47);
uniform vec3 lips : source_color = vec3(0.58, 0.27, 0.26);
uniform vec3 blush : source_color = vec3(0.8, 0.45, 0.4);
uniform vec3 brow_col : source_color = vec3(0.06, 0.035, 0.02);
uniform float lip_amount = 0.8;
uniform float age = 0.0;
uniform float beard = 0.0;
uniform float pale = 0.0;
uniform float ghost = 0.0;

varying vec3 rest;

// pori: fossette sparse su una griglia irregolare; torna la pendenza (per la normale) e la profondità
vec3 pores(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	vec2 grad = vec2(0.0);
	float depth = 0.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash22(n + g);
			float keep = step(0.35, hash21(n + g + 17.0));
			float sz = 0.16 + 0.12 * hash21(n + g + 3.0);
			vec2 d = f - (g + o);
			float e = exp(-dot(d, d) / (sz * sz)) * keep;
			depth += e;
			grad += 2.0 * d / (sz * sz) * e;
		}
	}
	return vec3(grad, depth);
}

void vertex() {
	rest = rest_pos(UV2, COLOR);
}

void fragment() {
	vec4 r = texture(regions, UV);
	vec3 c = tone;
	c = mix(c, c * vec3(1.04, 0.92, 0.9), r.r * 0.35);           // viso un po' più caldo
	c = mix(c, blush, smoothstep(0.2, 0.9, r.r) * 0.06);
	c = mix(c, c * vec3(0.84, 0.72, 0.74), smoothstep(0.1, 0.8, r.b) * 0.5); // palpebre
	c = mix(c, c * vec3(1.05, 0.88, 0.86), r.a * 0.4);            // orecchie e unghie
	float n = fbm2(UV * 180.0);
	float n2 = vnoise2(UV * 900.0);
	c *= 0.95 + 0.07 * n;
	// il viso in alta definizione
	vec2 fuv = (UV - face_rect.xy) / max(face_rect.zw, vec2(1e-5));
	float inf = (face_rect.z > 0.0 && fuv.x > 0.0 && fuv.y > 0.0 && fuv.x < 1.0 && fuv.y < 1.0) ? 1.0 : 0.0;
	vec4 fc = vec4(0.0, 0.5, 0.0, 0.0);
	vec4 fn = vec4(0.0, 0.5, 0.0, 0.5);
	vec2 wn = vec2(0.0);
	float lipm = smoothstep(0.1, 0.7, r.g);
	if (inf > 0.5) {
		fc = texture(face_col, fuv);
		fn = texture(face_nrm, fuv);
		vec2 px = 1.0 / vec2(textureSize(face_nrm, 0));
		vec4 nx = texture(face_nrm, fuv + vec2(px.x, 0.0));
		vec4 ny = texture(face_nrm, fuv + vec2(0.0, px.y));
		wn = vec2(fn.b - nx.b, fn.b - ny.b) * (1.2 + 3.0 * age);   // rughe
		wn += vec2(fn.g - nx.g, fn.g - ny.g) * 6.0;                 // righe delle labbra, grana
		lipm = fn.r;
	}
	// le labbra: colore pieno al centro, bordo appena più scuro
	vec3 lc = lips * (0.92 + 0.12 * smoothstep(0.5, 1.0, lipm));
	c = mix(c, lc, smoothstep(0.15, 0.6, lipm) * lip_amount);
	// rossori (sangue sotto la pelle) e chiaroscuri; le occhiaie tirano al viola
	c = mix(c, c * vec3(1.1, 0.78, 0.76), clamp(fc.r, 0.0, 1.0) * 0.7);
	float sh = fc.g - 0.5;
	c = mix(c, c * vec3(0.66, 0.56, 0.64), clamp(-sh * 2.0, 0.0, 1.0) * 0.7);
	c *= 1.0 + max(sh, 0.0) * 0.25;
	// barba rasa: ombra bluastra e i peli tagliati
	c = mix(c, c * vec3(0.42, 0.44, 0.5), clamp(fc.a * beard, 0.0, 1.0));
	// rughe: nei solchi un filo più scuro
	c *= 1.0 - fn.b * (0.1 + 0.14 * age);
	// sopracciglia e ciglia
	c = mix(c, brow_col, fc.b * 0.95);
	c = mix(c, vec3(dot(c, vec3(0.33))), pale);
	c *= 1.0 - age * 0.12 * smoothstep(0.5, 0.8, n);
	ALBEDO = c;
	// pori e grana: dalla mappa sul viso, dal rumore altrove
	vec2 e = vec2(0.0006, 0.0);
	float h0 = vnoise2(UV * 900.0);
	float hx = vnoise2((UV + e.xy) * 900.0);
	float hy = vnoise2((UV + e.yx) * 900.0);
	vec2 far_n = vec2((h0 - hx) * 1.2, (h0 - hy) * 1.2);
	// i pori: fitti sul naso e sulle guance, quasi niente sulle labbra
	vec3 pr = pores(UV * 2300.0);
	vec3 pr2 = pores(UV * 4100.0 + 7.0);
	float pa = (1.0 - lipm) * (0.55 + 0.6 * clamp(fc.r, 0.0, 1.0));
	vec2 near_n = wn + (pr.xy * 0.06 + pr2.xy * 0.03) * pa;
	c *= 1.0 - (pr.z * 0.06 + pr2.z * 0.03) * pa * inf;
	NORMAL_MAP = normalize(vec3(mix(far_n, near_n, inf), 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = mix(0.35, 0.8, inf);
	ROUGHNESS = clamp(mix(0.55, 0.5, smoothstep(0.2, 0.8, lipm)) + 0.06 * n2 + age * 0.1 - (fn.a - 0.5) * 0.4 + pr.z * 0.08 * inf
			+ fc.b * 0.15 + fc.a * beard * 0.1, 0.2, 1.0);
	SPECULAR = mix(0.42, 0.3, smoothstep(0.2, 0.8, lipm));
	SSS_STRENGTH = 0.55;
	BACKLIGHT = vec3(0.6, 0.25, 0.18) * 0.35;
	EMISSION = vec3(0.35, 0.6, 0.75) * ghost * pow(clamp(1.0 - abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.0) * 2.0;
}
