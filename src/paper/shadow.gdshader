shader_type canvas_item;
// The shared soft shadow: the piece's own shape, blurred and darkened.
// The blur is measured in screen pixels, so it's the same whatever the piece's scale.

uniform float softness = 6.0; // in screen pixels
uniform float strength = 0.4;
uniform vec3 tint : source_color = vec3(0.07, 0.02, 0.09);

const int TAPS = 16;

void fragment() {
	vec2 uv_per_pixel = fwidth(UV);
	float texels_per_pixel = length(uv_per_pixel / TEXTURE_PIXEL_SIZE);
	float lod = max(log2(texels_per_pixel * softness / 4.0), 0.0);
	float alpha = 0.0;
	for (int i = 0; i < TAPS; i++) {
		float radius = sqrt((float(i) + 0.5) / float(TAPS)) * softness;
		float angle = float(i) * 2.39996; // the golden angle spreads the taps evenly over a disk
		alpha += textureLod(TEXTURE, UV + vec2(cos(angle), sin(angle)) * radius * uv_per_pixel, lod).a;
	}
	COLOR = vec4(tint, alpha / float(TAPS) * strength);
}
