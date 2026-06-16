shader_type spatial;
render_mode cull_back;

uniform vec4 base_color : source_color = vec4(0.18, 0.19, 0.22, 1.0);

varying vec3 world_pos;

void fragment() {
	float lines = abs(sin(world_pos.x * 2.5)) * 0.04;
	vec3 col = base_color.rgb - vec3(lines);
	ALBEDO = col;
	METALLIC = 0.55;
	ROUGHNESS = 0.38;
	SPECULAR = 0.5;
}
