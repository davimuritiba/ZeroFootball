shader_type spatial;
render_mode cull_back;

uniform vec4 color_a : source_color = vec4(0.14, 0.16, 0.20, 1.0);
uniform vec4 color_b : source_color = vec4(0.20, 0.22, 0.28, 1.0);
uniform float seat_pitch : hint_range(0.2, 2.0, 0.05) = 0.55;

void fragment() {
	float stripe = step(0.5, fract(UV.x * (1.0 / seat_pitch)));
	ALBEDO = mix(color_a.rgb, color_b.rgb, stripe);
	ROUGHNESS = 0.72;
	SPECULAR = 0.22;
}
