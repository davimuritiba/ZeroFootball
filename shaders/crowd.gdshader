shader_type spatial;
render_mode cull_back, diffuse_lambert;

// Per-instance colour drives albedo; per-instance custom data (.x) holds a
// random phase so each spectator bobs/cheers out of sync with the others.

uniform float bob_amp   : hint_range(0.0, 0.3, 0.005) = 0.08;
uniform float bob_speed : hint_range(0.0, 8.0, 0.1) = 2.6;
uniform float sway_amp  : hint_range(0.0, 0.2, 0.005) = 0.03;

void vertex() {
	float phase = INSTANCE_CUSTOM.x * 6.28318;
	float t = TIME * bob_speed + phase;
	// upward-biased bob (people half-rising to cheer)
	float bob = (sin(t) * 0.5 + 0.5);
	VERTEX.y += bob * bob_amp;
	// subtle side sway
	VERTEX.x += sin(t * 0.5) * sway_amp;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.86;
	SPECULAR = 0.18;
}
