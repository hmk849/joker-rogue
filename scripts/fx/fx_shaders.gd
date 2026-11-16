class_name FxShaders
extends RefCounted
# 全部 Shader 以代码形式内置，不依赖外部资源。
const BG := """
shader_type canvas_item;
uniform float speed = 1.0;
uniform int detail = 3;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
vec3 pal(float x) {
	vec3 c0 = vec3(0.05, 0.06, 0.14); vec3 c1 = vec3(0.10, 0.16, 0.30); vec3 c2 = vec3(0.12, 0.30, 0.36);
	vec3 c3 = vec3(0.30, 0.16, 0.34); vec3 c4 = vec3(0.42, 0.22, 0.20);
	x = clamp(x, 0.0, 1.0) * 4.0;
	if (x < 1.0) return mix(c0, c1, x);
	if (x < 2.0) return mix(c1, c2, x - 1.0);
	if (x < 3.0) return mix(c2, c3, x - 2.0);
	return mix(c3, c4, x - 3.0);
}
void fragment() {
	vec2 uv = (UV - 0.5) * vec2(1.78, 1.0) * 2.0;
	float t = TIME * speed * 0.35;
	vec2 p = uv;
	for (int i = 0; i < 6; i++) {
		if (i >= detail + 2) break;
		p += 0.55 * vec2(sin(p.y * 1.6 + t + float(i) * 1.3), cos(p.x * 1.4 - t * 0.8 + float(i)));
	}
	float v = 0.5 + 0.5 * sin(length(p) * 1.8 - t * 1.2 + atan(p.y, p.x));
	v += (vnoise(p * 6.0) - 0.5) * 0.05;
	float f = fract(v * 6.0);
	float lv = floor(v * 6.0) / 6.0;
	vec3 col = pal(lv + f * 0.12);
	col = mix(col, vec3(0.93, 0.9, 0.78), smoothstep(0.05, 0.0, min(f, 1.0 - f)) * 0.16);
	col += (hash(floor(FRAGCOORD.xy * 0.5)) - 0.5) * 0.035;
	col += (vnoise(vec2(UV.x * 260.0, UV.y * 5.0)) - 0.5) * 0.03;
	vec2 gp = (uv * 0.5 + 0.5) * vec2(36.0, 20.0);
	float h = hash(floor(gp));
	vec2 fp = fract(gp) - 0.5;
	float mark = step(0.93, h) * smoothstep(0.035, 0.0, min(abs(fp.x), abs(fp.y))) * step(max(abs(fp.x), abs(fp.y)), 0.2);
	col += vec3(0.95, 0.9, 0.75) * mark * (0.6 + 0.4 * sin(t * 5.0 + h * 40.0)) * 0.7;
	col *= 1.0 - 0.38 * dot(uv * 0.5, uv * 0.5);
	COLOR = vec4(col, 1.0);
}
"""
const POST := """
shader_type canvas_item;
uniform sampler2D scr : hint_screen_texture, filter_linear;
uniform int color_mode = 0;
uniform float contrast = 1.0;
uniform float vignette = 0.0;
uniform float scan = 0.0;
void fragment() {
	vec3 c = texture(scr, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	if (color_mode == 1) c = mix(vec3(l), c, 1.35);
	else if (color_mode == 2) c = mix(vec3(l), c, 0.8) * 0.95 + 0.04;
	else if (color_mode == 3) { c = mix(vec3(l), c, 0.9); c *= vec3(1.0, 0.94, 0.8); }
	c = (c - 0.5) * contrast + 0.5;
	vec2 q = SCREEN_UV - 0.5;
	c *= 1.0 - vignette * dot(q, q) * 1.6;
	c *= 1.0 - scan * (0.5 + 0.5 * sin(SCREEN_UV.y * 900.0));
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""
const SHEEN := """
shader_type canvas_item;
uniform int mode = 1;
varying vec2 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float band = sin((lp.x + lp.y) * 0.06 - TIME * 2.5);
	float s = smoothstep(0.55, 1.0, band);
	vec3 tint = vec3(0.5, 0.8, 1.0);
	if (mode == 2) tint = vec3(1.0, 0.45, 0.85);
	if (mode == 3) tint = 0.5 + 0.5 * cos(vec3(0.0, 2.1, 4.2) + (lp.x + lp.y) * 0.05 + TIME * 2.0);
	float k = step(0.25, dot(COLOR.rgb, vec3(0.333)));
	float base = (mode == 3) ? 0.2 : 0.12;
	COLOR.rgb = mix(COLOR.rgb, tint, base * k) + tint * s * 0.3 * COLOR.a * k;
}
"""
static var _c := {}
static func shader(name: String) -> Shader:
	if not _c.has(name):
		var s := Shader.new()
		s.code = {"bg": BG, "post": POST, "sheen": SHEEN}[name]
		_c[name] = s
	return _c[name]
