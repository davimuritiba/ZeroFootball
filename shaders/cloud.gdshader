shader_type spatial;
render_mode cull_disabled, unshaded, fog_disabled;

uniform vec4 cloud_color : source_color = vec4(0.95, 0.97, 1.0, 0.85);
uniform float softness : hint_range(0.1, 1.0, 0.05) = 0.55;

varying vec3 local_vert;

void vertex() {
	local_vert = VERTEX;
}

void fragment() {
	float d = length(local_vert.xz);
	float alpha = smoothstep(1.0, softness, d) * cloud_color.a;
	ALBEDO = cloud_color.rgb;
	ALPHA = alpha;
}
