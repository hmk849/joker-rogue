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
const COMMON := """
uniform float speed = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * vnoise(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; }
	return v;
}
"""
# 风暴码头：翻滚的乌云、闪电、旋转的灯塔光束、起伏的海浪与浪沫、斜雨
const HARBOR := """
void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	float hz = 0.5 + 0.012 * sin(uv.x * 6.0 + t * 0.9);
	vec3 col;
	if (uv.y < hz) {
		float k = uv.y / hz;
		col = mix(vec3(0.03, 0.05, 0.09), vec3(0.26, 0.32, 0.38), k * k);
		float cl = fbm(vec2(uv.x * 2.5 - t * 0.03, uv.y * 5.0));
		col = mix(col, vec3(0.12, 0.15, 0.2), smoothstep(0.35, 0.8, cl) * 0.8);
		float cl2 = fbm(vec2(uv.x * 4.0 - t * 0.06 + 9.0, uv.y * 9.0));
		col += vec3(0.06, 0.07, 0.09) * smoothstep(0.5, 0.9, cl2);
		float flash = step(0.8, hash(vec2(floor(t * 0.5), 3.0))) * exp(-fract(t * 0.5) * 7.0);
		col += vec3(0.55, 0.65, 0.9) * flash * (1.0 - k * 0.5);
		vec2 lp = vec2(0.86, 0.3);
		vec2 dv = uv - lp;
		dv.x *= 1.78;
		float beam = pow(max(cos(atan(dv.y, dv.x) - t * 0.7), 0.0), 40.0) * smoothstep(1.2, 0.0, length(dv));
		col += vec3(1.0, 0.9, 0.6) * beam * 0.35;
		float tower = step(abs(uv.x - lp.x), 0.012 + (uv.y - lp.y) * 0.02) * step(lp.y, uv.y);
		col = mix(col, vec3(0.04, 0.04, 0.06), tower);
		col += vec3(1.0, 0.85, 0.5) * smoothstep(0.02, 0.0, length(dv)) * 1.2;
	} else {
		float d = (uv.y - hz) / (1.0 - hz);
		col = mix(vec3(0.05, 0.15, 0.22), vec3(0.01, 0.05, 0.09), d);
		float freq = 8.0 + d * 26.0;
		float w = sin(uv.x * freq + t * (1.2 + d * 1.5) + d * 12.0) + 0.6 * sin(uv.x * freq * 1.7 - t * 1.6 + d * 5.0);
		float crest = smoothstep(0.95, 1.5, w + (vnoise(vec2(uv.x * 30.0 + t, d * 30.0)) - 0.5) * 0.8);
		col += vec3(0.75, 0.85, 0.9) * crest * (0.25 + d * 0.5);
		col += vec3(0.05, 0.1, 0.14) * (w * 0.5 + 0.5) * d;
	}
	float rain = step(0.988, hash(floor(vec2(uv.x * 140.0 + uv.y * 45.0, uv.y * 70.0 + t * 38.0)))) * 0.25;
	col += vec3(0.6, 0.7, 0.8) * rain;
	col *= 1.0 - 0.9 * dot(uv - 0.5, uv - 0.5);
	COLOR = vec4(col, 1.0);
}
"""
# 酒馆内景：竖木板墙、三盏摇晃的提灯、壁炉余光、窗外的风暴与闪电
const TAVERN := """
void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	float pw = 0.07;
	float pid = floor(uv.x / pw);
	float px = fract(uv.x / pw);
	float tone = hash(vec2(pid, 1.0));
	vec3 wood = mix(vec3(0.16, 0.09, 0.05), vec3(0.28, 0.16, 0.08), tone);
	wood *= 0.75 + 0.5 * vnoise(vec2(uv.x * 40.0 + pid * 7.0, uv.y * 4.0 + tone * 20.0));
	wood *= 1.0 - 0.6 * smoothstep(0.06, 0.0, px) - 0.4 * smoothstep(0.94, 1.0, px);
	vec3 light = vec3(0.0);
	for (int i = 0; i < 3; i++) {
		vec2 lp = vec2(0.2 + 0.3 * float(i) + 0.012 * sin(t * 0.8 + float(i) * 2.0), 0.14);
		float fl = 0.85 + 0.15 * sin(t * 11.0 + float(i) * 5.0);
		vec2 dd = (uv - lp) * vec2(1.78, 1.0);
		light += vec3(1.0, 0.62, 0.25) * fl * exp(-dot(dd, dd) * 5.0) * 0.9;
	}
	vec2 fp = (uv - vec2(0.95, 0.85)) * vec2(1.78, 1.0);
	light += vec3(1.0, 0.4, 0.1) * exp(-dot(fp, fp) * 3.0) * (0.8 + 0.2 * sin(t * 9.0)) * 0.7;
	vec3 col = wood * (0.18 + light);
	vec2 wmin = vec2(0.04, 0.1);
	vec2 wsz = vec2(0.16, 0.36);
	vec2 wuv = (uv - wmin) / wsz;
	float inner = step(0.0, wuv.x) * step(wuv.x, 1.0) * step(0.0, wuv.y) * step(wuv.y, 1.0);
	float outer = step(-0.07, wuv.x) * step(wuv.x, 1.07) * step(-0.03, wuv.y) * step(wuv.y, 1.03);
	col = mix(col, vec3(0.07, 0.04, 0.025), outer - inner);
	vec3 sky = mix(vec3(0.04, 0.06, 0.1), vec3(0.2, 0.26, 0.32), wuv.y);
	if (wuv.y > 0.62) sky = mix(vec3(0.03, 0.1, 0.16), vec3(0.01, 0.04, 0.07), (wuv.y - 0.62) * 2.6) + vec3(0.6, 0.75, 0.85) * smoothstep(0.8, 1.0, sin(wuv.x * 36.0 + t * 2.0 + wuv.y * 14.0)) * 0.3;
	sky += vec3(0.55, 0.65, 0.9) * step(0.8, hash(vec2(floor(t * 0.5), 3.0))) * exp(-fract(t * 0.5) * 7.0);
	float mull = max(step(abs(wuv.x - 0.5), 0.02), step(abs(wuv.y - 0.5), 0.015));
	col = mix(col, mix(sky, vec3(0.07, 0.04, 0.025), mull), inner);
	col *= 1.0 - 0.7 * dot(uv - 0.5, uv - 0.5);
	COLOR = vec4(col, 1.0);
}
"""
# 威尼斯地下赌城：砖石拱廊、吊灯暖光、地下运河倒影与薄雾
const VAULT := """
void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	float wy = 0.74;
	vec2 sp = vec2(uv.x * 14.0, uv.y * 8.0);
	sp.x += mod(floor(sp.y), 2.0) * 0.5;
	vec2 bf = fract(sp);
	float mortar = max(step(bf.x, 0.05), step(bf.y, 0.08));
	float sn = vnoise(floor(sp) * 3.1 + 4.0);
	vec3 stone = mix(vec3(0.17, 0.14, 0.13), vec3(0.3, 0.26, 0.22), sn) * (0.8 + 0.4 * vnoise(uv * 60.0));
	stone = mix(stone, stone * 0.4, mortar);
	float ax = fract(uv.x * 3.0) - 0.5;
	float ay = uv.y - 0.34;
	float ring = length(vec2(ax, ay * 0.85));
	float inside = clamp(step(abs(ax), 0.3) * step(0.0, ay) + step(ring, 0.3) * step(ay, 0.0), 0.0, 1.0) * step(uv.y, wy);
	vec3 deep = mix(vec3(0.05, 0.03, 0.05), vec3(0.16, 0.09, 0.06), smoothstep(0.0, 0.5, vnoise(vec2(uv.x * 6.0, uv.y * 4.0 - t * 0.05))));
	float bk = hash(floor(vec2(uv.x * 40.0, uv.y * 20.0)));
	deep += vec3(1.0, 0.7, 0.3) * step(0.985, bk) * (0.5 + 0.5 * sin(t * 4.0 + bk * 50.0)) * 0.8;
	vec3 col = mix(stone, deep, inside);
	float edge = smoothstep(0.02, 0.0, abs(ring - 0.3)) * step(ay, 0.0) + smoothstep(0.015, 0.0, abs(abs(ax) - 0.3)) * step(0.0, ay) * step(uv.y, wy);
	col += vec3(0.7, 0.5, 0.2) * edge * 0.6;
	for (int i = 0; i < 3; i++) {
		vec2 lp = vec2((float(i) + 0.5) / 3.0, 0.1);
		float fl = 0.85 + 0.15 * sin(t * 9.0 + float(i) * 3.0);
		vec2 dd = (uv - lp) * vec2(1.78, 1.0);
		col += vec3(1.0, 0.65, 0.3) * exp(-dot(dd, dd) * 6.0) * fl * 0.5;
	}
	if (uv.y > wy) {
		float d = (uv.y - wy) / (1.0 - wy);
		vec3 wc = mix(vec3(0.03, 0.08, 0.1), vec3(0.01, 0.03, 0.05), d);
		float rip = sin(uv.x * 80.0 + sin(uv.y * 30.0 + t) * 3.0 + t * 1.5) * 0.5 + 0.5;
		wc += vec3(0.5, 0.35, 0.2) * smoothstep(0.8, 1.0, rip) * 0.12 * (1.0 - d);
		for (int i = 0; i < 3; i++) {
			float dx = (uv.x - (float(i) + 0.5) / 3.0) * 6.0;
			wc += vec3(1.0, 0.6, 0.25) * exp(-dx * dx) * 0.22 * (1.0 - d) * (0.7 + 0.3 * sin(uv.y * 90.0 + t * 3.0));
		}
		col = wc;
	}
	col += vec3(0.1, 0.12, 0.14) * smoothstep(0.3, 0.0, abs(uv.y - wy)) * 0.5 * (0.6 + 0.4 * vnoise(vec2(uv.x * 5.0 + t * 0.1, uv.y * 8.0)));
	col *= 1.0 - 0.7 * dot(uv - 0.5, uv - 0.5);
	COLOR = vec4(col, 1.0);
}
"""
# 赌桌：绿毛毡、聚光灯、鎏金椭圆线、外圈皮革桌沿
const TABLE := """
void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	vec2 p = (uv - 0.5) * vec2(1.78, 1.0);
	float e = length(p / vec2(0.82, 0.46));
	vec3 felt = vec3(0.04, 0.24, 0.17);
	felt *= 0.82 + 0.35 * vnoise(uv * vec2(400.0, 260.0));
	felt *= 0.9 + 0.2 * vnoise(uv * 6.0);
	felt += vec3(0.04, 0.14, 0.09) * exp(-dot(p, p) * 3.0);
	float ringl = smoothstep(0.012, 0.0, abs(e - 0.9)) + smoothstep(0.008, 0.0, abs(e - 0.86)) * 0.5;
	felt += vec3(0.8, 0.65, 0.3) * ringl * 0.7;
	vec2 g = abs(fract(p * 6.0 + 0.5) - 0.5);
	felt += vec3(0.02, 0.05, 0.04) * smoothstep(0.03, 0.0, abs(g.x + g.y - 0.5));
	vec3 rail = mix(vec3(0.16, 0.07, 0.04), vec3(0.3, 0.15, 0.08), vnoise(uv * vec2(30.0, 6.0)));
	rail *= 0.8 + 0.4 * smoothstep(1.0, 1.1, e);
	vec3 col = mix(felt, rail, smoothstep(1.0, 1.02, e));
	col += vec3(0.1, 0.1, 0.08) * (vnoise(vec2(p.x * 3.0 + t * 0.05, p.y * 3.0 - t * 0.08)) - 0.4) * 0.3;
	col *= 1.0 - 0.5 * dot(p, p);
	COLOR = vec4(col, 1.0);
}
"""
static var _c := {}
static func shader(name: String) -> Shader:
	if not _c.has(name):
		var s := Shader.new()
		var head := "shader_type canvas_item;\n" + COMMON
		s.code = {"bg": BG, "post": POST, "sheen": SHEEN, "harbor": head + HARBOR, "tavern": head + TAVERN, "vault": head + VAULT, "table": head + TABLE}[name]
		_c[name] = s
	return _c[name]
