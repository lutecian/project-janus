shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(0.2, 0.84, 1.0, 1.0);
uniform vec4 color_b : source_color = vec4(0.02, 0.05, 0.1, 1.0);
uniform float pattern = 0.0;
uniform float scale_uv = 3.0;
uniform float speed = 0.35;

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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV - 0.5;
	float r = length(uv) * 2.0;
	float mask = smoothstep(1.0, 0.82, r);
	float t = TIME * speed;
	float v;
	if (pattern < 0.5) {
		v = fbm(uv * scale_uv + vec2(t * 0.3, -t * 0.2));
	} else if (pattern < 1.5) {
		v = fbm(uv * scale_uv * 1.5 + vec2(0.0, t * 0.15));
		v = pow(v, 2.0) * 1.6;
	} else {
		float ang = atan(uv.y, uv.x);
		v = fbm(vec2(ang * 2.0 + t * 0.4, r * scale_uv - t * 0.3));
		v *= smoothstep(0.9, 0.3, abs(r - 0.55));
	}
	vec3 col = mix(color_b.rgb, color_a.rgb, clamp(v, 0.0, 1.0));
	col += color_a.rgb * pow(clamp(v, 0.0, 1.0), 3.0) * 0.8;
	COLOR = vec4(col * mask, mask);
}
