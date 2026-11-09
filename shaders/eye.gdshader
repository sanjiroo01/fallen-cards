shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Occhio: sclera con i capillari, iride a fibre raggiate con le cripte, il collaretto e l'anello
// scuro sul bordo, pupilla, cornea bagnata.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 iris : source_color = vec3(0.25, 0.16, 0.08);
uniform vec3 iris2 : source_color = vec3(0.45, 0.33, 0.16);
uniform float iris_size = 0.33;
uniform float ghost = 0.0;

void fragment() {
	// la sfera ha il polo davanti
	float a = UV.y * 3.14159;           // angolo dal polo anteriore
	float r = a / iris_size;            // 1 = bordo dell'iride
	float ang = UV.x * 6.28318;
	// sclera: bianco caldo, un po' rosata verso gli angoli, i capillari sottili
	vec3 sclera = vec3(0.86, 0.82, 0.78) * (0.95 + 0.05 * vnoise2(UV * vec2(60.0, 30.0)));
	float side = smoothstep(1.4, 2.6, r) * (0.4 + 0.6 * pow(abs(cos(ang)), 2.0));
	sclera = mix(sclera, vec3(0.8, 0.55, 0.5), side * 0.35);
	float vein = 0.0;
	for (int k = 0; k < 3; k++) {
		float fk = float(k);
		float wob = vnoise2(vec2(ang * (7.0 + fk * 3.0), r * 2.0 + fk * 5.0));
		float line = abs(fract(ang * (5.0 + fk * 2.0) / 6.28318 + wob * 0.35 + fk * 0.31) - 0.5);
		vein = max(vein, (1.0 - smoothstep(0.0, 0.012, line)) * smoothstep(1.6, 2.8, r) * (0.5 + 0.5 * wob));
	}
	sclera = mix(sclera, vec3(0.7, 0.22, 0.2), vein * 0.45);
	// iride: fibre raggiate a due scale, cripte scure, collaretto chiaro vicino alla pupilla
	float fib1 = vnoise2(vec2(ang * 60.0, r * 2.5));
	float fib2 = vnoise2(vec2(ang * 160.0, r * 6.0 + 3.0));
	float fib = fib1 * 0.6 + fib2 * 0.4;
	vec3 ic = mix(iris * 0.8, iris2, smoothstep(0.25, 0.85, fib));
	float collar = smoothstep(0.38, 0.5, r) * (1.0 - smoothstep(0.5, 0.66, r + 0.06 * vnoise2(vec2(ang * 12.0, 1.0))));
	ic = mix(ic, iris2 * 1.25 + vec3(0.05, 0.04, 0.0), collar * 0.55);
	float crypt = smoothstep(0.62, 0.8, vnoise2(vec2(ang * 9.0, r * 5.0 + 7.0))) * smoothstep(0.5, 0.65, r) * (1.0 - smoothstep(0.85, 0.95, r));
	ic *= 1.0 - crypt * 0.55;
	ic *= 0.75 + 0.35 * smoothstep(0.3, 0.6, r);
	vec3 col = sclera;
	col = mix(ic, col, smoothstep(0.96, 1.06, r));
	// anello limbare: scuro e sfumato sul bordo
	col = mix(col, ic * 0.25, smoothstep(0.78, 0.98, r) * (1.0 - smoothstep(0.98, 1.12, r)) * 0.85);
	// pupilla, con il bordo appena frastagliato
	float pr = 0.33 + 0.012 * vnoise2(vec2(ang * 20.0, 0.0));
	col = mix(vec3(0.008), col, smoothstep(pr - 0.015, pr + 0.025, r));
	ALBEDO = col;
	ROUGHNESS = 0.03;
	SPECULAR = 0.85;
	CLEARCOAT = 1.0;
	CLEARCOAT_ROUGHNESS = 0.02;
	EMISSION = vec3(0.4, 0.7, 0.85) * ghost * 1.5;
}
