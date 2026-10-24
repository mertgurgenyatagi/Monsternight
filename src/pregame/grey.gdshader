shader_type canvas_item;
// Greys a taken monster out and darkens it. `amount` 0 is full color, 1 is fully greyed.

uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float grey = dot(c.rgb, vec3(0.3, 0.59, 0.11)) * 0.55;
	COLOR = vec4(mix(c.rgb, vec3(grey), amount), c.a);
}
