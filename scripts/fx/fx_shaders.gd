class_name FxShaders
extends RefCounted
# 全部 Shader 以代码形式内置，不依赖外部资源。
const BG := """
shader_type canvas_item;
uniform float speed = 1.0;
uniform int detail = 3;
uniform vec4 c1 : source_color = vec4(0.05, 0.08, 0.13, 1.0);
uniform vec4 c2 : source_color = vec4(0.11, 0.2, 0.32, 1.0);
uniform vec4 c3 : source_color = vec4(0.27, 0.12, 0.3, 1.0);
void fragment() {
	vec2 p = (UV - 0.5) * vec2(3.2, 1.8) * 1.4;
	float t = TIME * speed * 0.22;
	for (int i = 0; i < 6; i++) {
		if (i >= detail) break;
		p += vec2(sin(p.y * 1.3 + t + float(i)), cos(p.x * 1.1 - t * 1.2 + float(i) * 1.7)) * 0.6;
	}
	float v = 0.5 + 0.5 * sin(p.x + p.y + t);
	float w = 0.5 + 0.5 * cos(p.x * 0.7 - p.y);
	vec3 col = mix(c1.rgb, c2.rgb, v);
	col = mix(col, c3.rgb, w * 0.45);
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
