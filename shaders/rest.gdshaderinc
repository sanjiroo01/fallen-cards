// Posizione a riposo del vertice (prima della pelle): UV2 = (x, z), colore r,g = y a 16 bit.
vec3 rest_pos(vec2 uv2, vec4 col) {
	float y = (round(col.r * 255.0) * 256.0 + round(col.g * 255.0)) / 65535.0 * 3.0 - 0.5;
	return vec3(uv2.x, y, uv2.y);
}
