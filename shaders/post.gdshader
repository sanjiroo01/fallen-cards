shader_type canvas_item;
// Pellicola: nitidezza, gradazione colore (ombre fredde, luci calde), luci forti che sfumano
// invece di bruciare, grana, vignettatura e una lieve aberrazione solo agli angoli.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette = 0.5;
uniform float grain = 0.035;
uniform float aberration = 0.0007;
uniform float darkness = 0.0;
uniform float flash = 0.0;
uniform vec3 flash_col : source_color = vec3(0.6, 0.02, 0.02);
uniform float sharpen = 0.35;
uniform float grade = 1.0;                                      // 0 = colori come escono dal motore
uniform vec3 shadow_tint : source_color = vec3(0.86, 0.95, 1.06);   // le ombre virano al blu della notte
uniform vec3 high_tint : source_color = vec3(1.05, 0.99, 0.9);      // le luci al giallo delle candele
uniform float shoulder = 0.86;                                  // da qui in su le luci si comprimono

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float luma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);
	// aberrazione: nulla al centro, appena percettibile agli angoli
	vec2 off = c * r2 * r2 * aberration * 16.0;
	vec3 col;
	col.r = texture(screen_tex, uv + off).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - off).b;
	// nitidezza: contrasto locale a croce, solo sulla luminanza (niente aloni colorati)
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 nb = texture(screen_tex, uv + vec2(px.x, 0.0)).rgb + texture(screen_tex, uv - vec2(px.x, 0.0)).rgb
			+ texture(screen_tex, uv + vec2(0.0, px.y)).rgb + texture(screen_tex, uv - vec2(0.0, px.y)).rgb;
	float detail = luma(col) - luma(nb) * 0.25;
	col += clamp(detail, -0.08, 0.08) * sharpen;
	col = max(col, vec3(0.0));
	// gradazione: viraggio diviso fra ombre e luci, con un filo di curva a S
	float l = luma(col);
	vec3 graded = col * mix(shadow_tint, high_tint, smoothstep(0.02, 0.5, l));
	graded = mix(graded, graded * graded * (3.0 - 2.0 * graded), 0.18);
	// spalla morbida: le fiamme vicine e le carte sotto le candele non diventano bianco piatto
	float gl = luma(graded);
	if (gl > shoulder) {
		float k = shoulder + (1.0 - shoulder) * (1.0 - exp(-(gl - shoulder) / (1.0 - shoulder)));
		graded *= k / gl;
	}
	col = mix(col, graded, grade);
	float v = 1.0 - smoothstep(0.15, 0.85, r2 * 2.0) * vignette;
	col *= v;
	float g = h(uv * 1000.0 + fract(TIME * 7.13)) - 0.5;
	col += g * grain * (0.4 + 0.6 * (1.0 - luma(col)));
	col = mix(col, vec3(0.0), darkness);
	col = mix(col, flash_col, flash * (0.4 + 0.6 * r2 * 2.0));
	COLOR = vec4(col, 1.0);
}
