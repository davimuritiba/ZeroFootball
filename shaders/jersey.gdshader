shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform vec4 base_color : source_color = vec4(0.8, 0.08, 0.12, 1.0);
uniform float weave_scale : hint_range(20.0, 200.0, 1.0) = 90.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz * weave_scale;
	float weave = hash(floor(uv)) * 0.55 + hash(uv) * 0.45;
	vec3 col = base_color.rgb * (0.90 + weave * 0.14);

	vec3 tangent_normal = normalize(vec3(
		(hash(uv + vec2(0.07, 0.0)) - 0.5) * 0.35,
		1.0,
		(hash(uv + vec2(0.0, 0.07)) - 0.5) * 0.35
	));

	ALBEDO = col;
	ROUGHNESS = 0.68 + weave * 0.18;
	SPECULAR = 0.18;
	NORMAL = tangent_normal;
}
