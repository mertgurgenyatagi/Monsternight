shader_type canvas_item;
// A paper strip tiled along a location. It fades in at its left end and out at its right, so
// neighbouring locations blend into each other, and fog and water can drift sideways.

uniform float width = 1000.0; // the strip's length, in its own unscaled pixels
uniform float fade_in = 0.0;
uniform float fade_out = 0.0;
uniform float drift = 0.0; // texels per second, positive to the right

varying float x;
varying vec4 tint;

void vertex() {
	x = VERTEX.x;
	tint = COLOR;
}

void fragment() {
	vec4 paper = texture(TEXTURE, UV - vec2(drift * TIME * TEXTURE_PIXEL_SIZE.x, 0.0));
	float alpha = 1.0;
	if (fade_in > 0.0) {
		alpha *= smoothstep(0.0, fade_in, x);
	}
	if (fade_out > 0.0) {
		alpha *= 1.0 - smoothstep(width - fade_out, width, x);
	}
	COLOR = paper * tint * vec4(1.0, 1.0, 1.0, alpha);
}
