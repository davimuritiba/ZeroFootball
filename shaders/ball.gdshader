shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform vec4 color_white  : source_color = vec4(0.95, 0.95, 0.95, 1.0);
uniform vec4 color_black  : source_color = vec4(0.05, 0.05, 0.05, 1.0);
uniform float pentagon_size : hint_range(0.05, 0.55, 0.01) = 0.30;

varying vec3 obj_normal;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void vertex() {
	obj_normal = NORMAL;
}

void fragment() {
	vec3 n = normalize(obj_normal);

	float s = 0.5257;
	float l = 0.8507;

	bool on_black =
		dot(n, vec3( 0.0,  s,  l)) > (1.0 - pentagon_size) ||
		dot(n, vec3( 0.0, -s,  l)) > (1.0 - pentagon_size) ||
		dot(n, vec3( 0.0,  s, -l)) > (1.0 - pentagon_size) ||
		dot(n, vec3( 0.0, -s, -l)) > (1.0 - pentagon_size) ||
		dot(n, vec3( s,  l,  0.0)) > (1.0 - pentagon_size) ||
		dot(n, vec3(-s,  l,  0.0)) > (1.0 - pentagon_size) ||
		dot(n, vec3( s, -l,  0.0)) > (1.0 - pentagon_size) ||
		dot(n, vec3(-s, -l,  0.0)) > (1.0 - pentagon_size) ||
		dot(n, vec3( l,  0.0,  s)) > (1.0 - pentagon_size) ||
		dot(n, vec3(-l,  0.0,  s)) > (1.0 - pentagon_size) ||
		dot(n, vec3( l,  0.0, -s)) > (1.0 - pentagon_size) ||
		dot(n, vec3(-l,  0.0, -s)) > (1.0 - pentagon_size);

	vec3 base = on_black ? color_black.rgb : color_white.rgb;
	float grain = hash(n * 12.0) * 0.5 + hash(n * 40.0) * 0.5;
	base *= 0.94 + grain * 0.10;

	ALBEDO = base;
	ROUGHNESS = on_black ? 0.38 + grain * 0.12 : 0.18 + grain * 0.08;
	SPECULAR = on_black ? 0.35 : 0.72;
	METALLIC = 0.0;
}
