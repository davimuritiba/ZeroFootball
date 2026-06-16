shader_type spatial;
render_mode cull_disabled;

uniform vec4 base_color : source_color = vec4(0.9, 0.1, 0.1, 1.0);
uniform float scan_speed : hint_range(0.0, 6.0, 0.1) = 1.8;
uniform float glow : hint_range(0.5, 4.0, 0.1) = 2.2;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float scan = sin(world_pos.x * 8.0 + TIME * scan_speed) * 0.5 + 0.5;
	float band = smoothstep(0.35, 0.65, fract(UV.y * 6.0 + TIME * 0.3));
	vec3 col = base_color.rgb * (0.75 + 0.25 * scan) + vec3(band * 0.15);
	ALBEDO = col;
	EMISSION = col * glow;
	ROUGHNESS = 0.35;
}
