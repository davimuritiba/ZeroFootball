shader_type spatial;
render_mode cull_back;

uniform vec4 base_color : source_color = vec4(0.32, 0.32, 0.34, 1.0);
uniform float noise_scale : hint_range(1.0, 40.0, 0.5) = 12.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = noise(world_pos.xz * noise_scale);
	float n2 = noise(world_pos.xz * noise_scale * 3.7);
	vec3 col = base_color.rgb * (0.88 + 0.24 * n) + vec3(n2 * 0.03);
	ALBEDO = col;
	ROUGHNESS = 0.88 + n2 * 0.08;
	SPECULAR = 0.12;
}
