shader_type spatial;

uniform vec4 color_white  : source_color = vec4(0.95, 0.95, 0.95, 1.0);
uniform vec4 color_black  : source_color = vec4(0.05, 0.05, 0.05, 1.0);
uniform float pentagon_size : hint_range(0.05, 0.55, 0.01) = 0.30;

// Pass object-space normal from vertex to fragment
varying vec3 obj_normal;

void vertex() {
	obj_normal = NORMAL;
}

void fragment() {
	vec3 n = normalize(obj_normal);

	// 12 pre-normalised icosahedron vertex directions
	// (each is ±1/mag, ±φ/mag, 0) with φ=1.618, mag≈1.902
	float s = 0.5257;   // 1  / mag
	float l = 0.8507;   // phi / mag

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

	ALBEDO    = on_black ? color_black.rgb : color_white.rgb;
	ROUGHNESS = 0.22;
	SPECULAR  = 0.65;
	METALLIC  = 0.0;
}
