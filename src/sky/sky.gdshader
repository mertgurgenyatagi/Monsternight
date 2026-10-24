shader_type canvas_item;
// The sky's gradient, cut into bands of paper with wavy hand-cut edges. Each band overlaps
// the one below it and casts a soft shadow on it.

uniform vec4 top_color : source_color = vec4(0.09, 0.06, 0.2, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.42, 0.16, 0.36, 1.0);
uniform float bands = 7.0;
uniform float shadow = 0.22;

float edge(float i, float x) {
	return i / bands + 0.012 * sin(x * 8.0 + i * 2.3) + 0.005 * sin(x * 21.0 + i * 5.1);
}

void fragment() {
	float band = 0.0;
	for (float i = 1.0; i < bands; i += 1.0) {
		if (UV.y > edge(i, UV.x)) {
			band = i;
		}
	}
	vec3 color = mix(top_color.rgb, bottom_color.rgb, band / (bands - 1.0));
	float below = UV.y - edge(band, UV.x);
	float dark = band > 0.0 ? shadow * (1.0 - smoothstep(0.0, 0.02, below)) : 0.0;
	COLOR = vec4(color * (1.0 - dark), 1.0);
}
