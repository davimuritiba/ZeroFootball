shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform vec4 paint_color : source_color = vec4(0.95, 0.95, 0.95, 1.0);

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float wear = hash(world_pos.xz * 18.0) * 0.5 + hash(world_pos.xz * 4.0) * 0.5;
	vec3 col = paint_color.rgb * (0.94 + wear * 0.06);
	col = mix(col, col * vec3(0.92, 0.94, 0.90), wear * 0.25);

	ALBEDO = col;
	ROUGHNESS = 0.62 + wear * 0.12;
	SPECULAR = 0.08;
}
