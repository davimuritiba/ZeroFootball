shader_type spatial;
render_mode cull_back;

uniform vec4 color_light : source_color = vec4(0.24, 0.64, 0.24, 1.0);
uniform vec4 color_dark  : source_color = vec4(0.13, 0.46, 0.14, 1.0);
uniform float stripe_count : hint_range(4.0, 16.0, 1.0) = 7.0;
uniform float blade_detail : hint_range(20.0, 400.0, 1.0) = 220.0;
uniform float wear_amount : hint_range(0.0, 1.0, 0.01) = 0.18;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Mowing stripes running lengthwise across the field
	float stripe = mod(floor(UV.y * stripe_count), 2.0);
	vec3 base = mix(color_dark.rgb, color_light.rgb, stripe);

	// Fine blade-level variation (high frequency noise)
	float blades = noise(UV * blade_detail);
	base *= 0.88 + 0.24 * blades;

	// Broad patchy variation (low frequency) for uneven turf
	float patch = noise(UV * 14.0);
	base = mix(base, base * 0.82, patch * wear_amount);

	// Slightly worn, lighter centre circle area
	float dist_center = length(world_pos.xz);
	float worn = smoothstep(6.0, 0.0, dist_center) * wear_amount;
	base = mix(base, base * 1.12 + vec3(0.04, 0.05, 0.03), worn);

	ALBEDO = base;
	ROUGHNESS = 0.78 + 0.18 * blades;
	// Anisotropic-ish sheen: stripes catch light differently
	SPECULAR = 0.10 + 0.06 * stripe;
}
