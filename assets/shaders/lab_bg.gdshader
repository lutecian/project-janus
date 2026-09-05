shader_type canvas_item;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 uv = UV * vec2(1.33, 1.0);
	float t = TIME * 0.02;
	float v = noise(uv * 3.0 + vec2(t, -t * 0.7)) * 0.6
		+ noise(uv * 6.0 - vec2(t * 0.5, t)) * 0.4;
	vec3 deep = vec3(0.015, 0.03, 0.06);
	vec3 glow = vec3(0.05, 0.16, 0.19);
	vec3 col = mix(deep, glow, v * 0.55);
	COLOR = vec4(col, 1.0);
}
