shader_type spatial;
// I cerchi rituali luminosi (immagini cotte da assets_src/atmosfera/cuoci_cerchi.py): una maschera bianca che diventa
// luce arancione, gira piano e pulsa come un respiro. Usato per il cerchio a terra e per quelli sospesi in aria.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform sampler2D mask : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 glow_color : source_color = vec4(1.0, 0.32, 0.06, 1.0);
uniform float energy = 1.0;            // moltiplicatore (eventi: lampi del cerchio)
uniform float brightness = 6.0;        // luce di base, sopra 1 per il bagliore
uniform float spin = -0.0242;          // radianti al secondo (-25 gradi in 18 secondi)
uniform float pulse_period = 2.0;      // il respiro
uniform float pulse_amount = 0.3;
uniform float phase = 0.0;

void fragment() {
	vec2 c = UV - 0.5;
	float a = TIME * spin + phase;
	mat2 r = mat2(vec2(cos(a), -sin(a)), vec2(sin(a), cos(a)));
	vec2 uv = r * c + 0.5;
	vec4 t = texture(mask, uv);
	float m = max(t.a * dot(t.rgb, vec3(0.333)), 0.0);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) m = 0.0;
	float breath = 1.0 - pulse_amount + pulse_amount * (0.5 + 0.5 * sin(TIME * 6.2831 / pulse_period + phase));
	// alone morbido attorno ai segni: un campione più sfocato della stessa immagine
	vec4 hl = textureLod(mask, uv, 4.0);
	float halo = hl.a * dot(hl.rgb, vec3(0.333)) * 0.35;
	ALBEDO = glow_color.rgb * (m + halo) * brightness * breath * energy;
}
