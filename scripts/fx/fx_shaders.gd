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
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 6; i++) { if (i >= detail + 1) break; v += a * vnoise(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; }
	return v;
}
void fragment() {
	vec2 uv = (UV - 0.5) * vec2(1.78, 1.0);
	float t = TIME * speed;
	vec3 col = mix(vec3(0.025, 0.035, 0.09), vec3(0.07, 0.055, 0.17), UV.y);
	float n = fbm(uv * 2.2 + vec2(t * 0.02, -t * 0.015));
	float n2 = fbm(uv * 3.5 - vec2(t * 0.03, 0.0) + 4.0);
	col += vec3(0.08, 0.24, 0.32) * smoothstep(0.35, 0.9, n) * 0.55;
	col += vec3(0.3, 0.12, 0.4) * smoothstep(0.4, 0.95, n2) * 0.4;
	vec2 gp = (uv + 0.5) * vec2(60.0, 34.0);
	float h = hash(floor(gp));
	float tw = 0.6 + 0.4 * sin(t * 2.0 + h * 40.0);
	col += vec3(1.0, 0.92, 0.7) * step(0.965, h) * smoothstep(0.35, 0.0, length(fract(gp) - 0.5)) * tw * 0.9;
	float r = length(uv);
	float ang = atan(uv.y, uv.x);
	float ring = smoothstep(0.004, 0.0, abs(r - 0.55)) + smoothstep(0.003, 0.0, abs(r - 0.5)) * 0.6 + smoothstep(0.003, 0.0, abs(r - 0.78)) * 0.5;
	float a = fract((ang + t * 0.03) * 24.0 / 6.2832);
	float tick = smoothstep(0.05, 0.0, min(a, 1.0 - a)) * step(0.55, r) * step(r, 0.59);
	col += vec3(0.95, 0.78, 0.4) * (ring * 0.2 + tick * 0.22);
	col *= 1.0 - 0.45 * dot(uv, uv);
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
