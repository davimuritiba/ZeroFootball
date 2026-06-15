shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_lambert, specular_disabled;

uniform vec4 net_color : source_color = vec4(0.92, 0.93, 0.95, 1.0);
uniform float grid_density : hint_range(10.0, 80.0, 1.0) = 46.0;
uniform float thread : hint_range(0.01, 0.2, 0.005) = 0.055;

void fragment() {
	vec2 g = fract(UV * grid_density);
	// distance to nearest grid line on each axis
	float lx = min(g.x, 1.0 - g.x);
	float ly = min(g.y, 1.0 - g.y);
	float line = 1.0 - smoothstep(0.0, thread, min(lx, ly));

	ALBEDO = net_color.rgb;
	ALPHA = line * 0.6;
}
