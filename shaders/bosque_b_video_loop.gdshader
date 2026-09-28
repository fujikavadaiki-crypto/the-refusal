shader_type canvas_item;
render_mode unshaded;

// Every phase is an integer harmonic of the ten-second loop.
uniform float loop_phase : hint_range(0.0, 1.0) = 0.0;

float region(vec2 p, vec4 bounds, float edge) {
	return smoothstep(bounds.x - edge, bounds.x + edge, p.x)
		* (1.0 - smoothstep(bounds.y - edge, bounds.y + edge, p.x))
		* smoothstep(bounds.z - edge, bounds.z + edge, p.y)
		* (1.0 - smoothstep(bounds.w - edge, bounds.w + edge, p.y));
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec2 p = UV * vec2(1900.0, 633.0);
	float tau = 6.28318530718;
	float luminance = dot(original.rgb, vec3(0.2126, 0.7152, 0.0722));

	// Light travels down inside the painted waterfalls. The edges, rock and
	// approved composition stay at their original pixels.
	float upper = region(p, vec4(1602.0, 1647.0, 364.0, 474.0), 2.5);
	float fall = region(p, vec4(1599.0, 1699.0, 476.0, 607.0), 2.0);
	float painted_water = smoothstep(0.17, 0.39, luminance);
	float strand = sin(p.y * 0.34 - loop_phase * tau * 5.0 + p.x * 0.13);
	float strand_fine = sin(p.y * 0.79 - loop_phase * tau * 8.0 + p.x * 0.27);
	float cascade = max(0.0, strand * 0.66 + strand_fine * 0.34);
	vec3 water_light = vec3(0.110, 0.128, 0.124) * cascade * painted_water * (upper * 0.65 + fall);

	// Small horizontal reflections move in the painted water below the ledge.
	float lower = region(p, vec4(0.0, 1900.0, 601.0, 633.0), 3.0);
	float ripple = max(0.0, sin(p.x * 0.075 - loop_phase * tau * 4.0 + p.y * 0.18));
	float ripple_fine = max(0.0, sin(p.x * 0.16 - loop_phase * tau * 7.0 - p.y * 0.29));
	float water_luma = smoothstep(0.10, 0.29, luminance);
	vec3 reflection = vec3(0.036, 0.043, 0.041)
		* (ripple * 0.7 + ripple_fine * 0.3) * lower * water_luma;

	COLOR = vec4(min(original.rgb + water_light + reflection, vec3(1.0)), original.a);
}
