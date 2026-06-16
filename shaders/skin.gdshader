shader_type spatial;
render_mode cull_back, diffuse_burley;

uniform vec4 skin_color : source_color = vec4(0.88, 0.70, 0.54, 1.0);

void fragment() {
	vec3 warm = skin_color.rgb * vec3(1.04, 0.98, 0.94);
	ALBEDO = warm;
	ROUGHNESS = 0.48;
	SPECULAR = 0.32;
	SSS_STRENGTH = 0.42;
}
