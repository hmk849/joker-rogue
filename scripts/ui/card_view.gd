class_name CardView
extends Control
# 程序化绘制的扑克牌：立体阴影、花色图形、点数排布、增强/版本/蜡封、牌背、翻转。
const W := 100.0
const H := 140.0
const SUIT_COL := [Color(0.1, 0.12, 0.3), Color(0.78, 0.13, 0.27), Color(0.1, 0.12, 0.3), Color(0.78, 0.13, 0.27)]
const NAMES := {11: "J", 12: "Q", 13: "K", 14: "A"}
const P4 := [[.3, .2], [.7, .2], [.3, .8], [.7, .8]]
const P6 := [[.3, .2], [.7, .2], [.3, .5], [.7, .5], [.3, .8], [.7, .8]]
const P8 := [[.3, .17], [.7, .17], [.3, .39], [.7, .39], [.3, .61], [.7, .61], [.3, .83], [.7, .83]]
var card: Dictionary = {}
var face_up := true
var selected := false
var tw: Tween
var deal_delay := 0.0

static func make(c: Dictionary, s: float) -> CardView:
	var v := CardView.new()
	v.card = c
	v.size = Vector2(W, H) * s
	v.pivot_offset = v.size / 2.0
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.update_material()
	return v

func update_material() -> void:
	var m: int = {"foil": 1, "holo": 2, "poly": 3}.get(String(card.get("ed", "")), 0)
	if m == 0:
		material = null
		return
	var sm := ShaderMaterial.new()
	sm.shader = FxShaders.shader("sheen")
	sm.set_shader_parameter("mode", m)
	material = sm

func flip(face: bool) -> void:
	AudioManager.play("flip", randf_range(0.9, 1.1))
	var d := AnimationManager.duration(0.25)
	if d <= 0.0:
		face_up = face
		queue_redraw()
		return
	var t := create_tween()
	t.tween_property(self, "scale:x", 0.0, d * 0.5)
	t.tween_callback(func():
		face_up = face
		queue_redraw())
	t.tween_property(self, "scale:x", 1.0, d * 0.5)

func _pips(n: int) -> Array:
	match n:
		2: return [[.5, .2], [.5, .8]]
		3: return [[.5, .2], [.5, .5], [.5, .8]]
		4: return P4
		5: return P4 + [[.5, .5]]
		6: return P6
		7: return P6 + [[.5, .35]]
		8: return P6 + [[.5, .35], [.5, .65]]
		9: return P8 + [[.5, .5]]
	return P8 + [[.5, .28], [.5, .72]]

func _draw() -> void:
	var k := size.x / W
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	draw_style_box(UIStyle.box(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 0, 12), Rect2(3, 7, W, H))
	if face_up: _face(k)
	else: _back()

func _back() -> void:
	match ThemeManager.style():
		"wood": _back_wood()
		"velvet": _back_velvet()
		_: _back_sketch()

# 咸风酒馆：深海蓝牌背 + 黄铜边 + 绳圈船锚 + 海浪
func _back_wood() -> void:
	draw_style_box(UIStyle.box(Color(0.09, 0.16, 0.28), Astral.GOLD, 3, 10), Rect2(0, 0, W, H))
	draw_style_box(UIStyle.box(Color(0.12, 0.21, 0.36), Astral.GOLD_DIM, 1, 6), Rect2(8, 8, W - 16, H - 16))
	var c := Vector2(W / 2, H / 2 - 6)
	draw_arc(c, 32.0, 0.0, TAU, 40, Astral.CHALK, 3.0, true)
	for i in 24:
		var d := Vector2(cos(TAU * i / 24.0), sin(TAU * i / 24.0))
		draw_line(c + d * 29.0, c + d * 35.0, Color(Astral.CHALK, 0.6), 1.2)
	draw_arc(c + Vector2(0, -22), 5.0, 0.0, TAU, 12, Astral.GOLD, 2.2)
	draw_line(c + Vector2(0, -17), c + Vector2(0, 20), Astral.GOLD, 2.6)
	draw_line(c + Vector2(-9, -9), c + Vector2(9, -9), Astral.GOLD, 2.6)
	draw_arc(c + Vector2(0, 8), 14.0, 0.15 * PI, 0.85 * PI, 14, Astral.GOLD, 2.6, true)
	for k in 3:
		var pts := PackedVector2Array()
		for i in 13: pts.append(Vector2(14 + i * (W - 28) / 12.0, H - 22 - k * 6 + sin(i * 1.3 + k) * 2.5))
		draw_polyline(pts, Color(Astral.CHALK, 0.55 - k * 0.12), 1.4)

# 暗河赌厅：酒红丝绒 + 鎏金菱格 + 威尼斯面具
func _back_velvet() -> void:
	draw_style_box(UIStyle.box(Color(0.26, 0.05, 0.1), Astral.GOLD, 3, 8), Rect2(0, 0, W, H))
	draw_style_box(UIStyle.box(Color(0.32, 0.08, 0.13), Color(Astral.GOLD, 0.5), 1, 5), Rect2(8, 8, W - 16, H - 16))
	for i in 8:
		draw_line(Vector2(8 + i * 14.0, 8), Vector2(W - 8, H - 8 - i * 14.0), Color(Astral.GOLD, 0.12), 1.0)
		draw_line(Vector2(8, 8 + i * 14.0), Vector2(W - 8 - i * 14.0, H - 8), Color(Astral.GOLD, 0.12), 1.0)
	var c := Vector2(W / 2, H / 2 + 2)
	var mask := PackedVector2Array()
	for p in [[-0.85, -0.1], [-0.55, -0.5], [0.0, -0.38], [0.55, -0.5], [0.85, -0.1], [0.6, 0.3], [0.18, 0.38], [0.0, 0.95], [-0.18, 0.38], [-0.6, 0.3]]: mask.append(c + Vector2(p[0], p[1]) * 30.0)
	draw_colored_polygon(mask, Color(0.92, 0.78, 0.4))
	for s in [-1.0, 1.0]:
		var eye := PackedVector2Array()
		for i in 12: eye.append(c + Vector2(s * 11.0 + cos(TAU * i / 12.0) * 7.0, -5.0 + sin(TAU * i / 12.0) * 4.0))
		draw_colored_polygon(eye, Color(0.18, 0.03, 0.06))
		draw_arc(c + Vector2(s * 26.0, -30.0), 12.0, PI * 1.1, PI * 1.9, 8, Astral.GOLD, 1.6)
	var mc := mask.duplicate()
	mc.append(mask[0])
	draw_polyline(mc, Color(0.45, 0.3, 0.1), 1.6)
	for p in [Vector2(16, 16), Vector2(W - 16, 16), Vector2(16, H - 16), Vector2(W - 16, H - 16)]: Astral.diamond(self, p, 3.0, Astral.GOLD)

func _back_sketch() -> void:
	draw_style_box(UIStyle.box(Astral.TEAL.darkened(0.55), Color(0, 0, 0, 0), 0, 10), Rect2(0, 0, W, H))
	Sketch.stroke(self, Sketch.round_rect(Rect2(1.5, 1.5, W - 3, H - 3), 10.0), Color(0.95, 0.92, 0.82), 2.6, 3)
	Sketch.stroke(self, Sketch.round_rect(Rect2(9, 9, W - 18, H - 18), 6.0), Color(0.95, 0.92, 0.82, 0.55), 1.4, 8)
	var c := Vector2(W / 2, H / 2)
	Sketch.stroke(self, Sketch.circle(c, 30.0, 32), Color(Astral.GOLD, 0.9), 2.0, 12)
	Sketch.stroke(self, Sketch.circle(c, 22.0, 28), Color(Astral.GOLD, 0.5), 1.2, 15)
	Sketch.star(self, c, 14.0, Astral.GOLD, 20)
	for p in [Vector2(20, 22), Vector2(W - 20, 22), Vector2(20, H - 22), Vector2(W - 20, H - 22)]: Sketch.star(self, p, 4.0, Color(0.95, 0.92, 0.82, 0.8), int(p.x + p.y))

func _face(k: float) -> void:
	var e := String(card.get("enh", ""))
	var ed := String(card.get("ed", ""))
	var bg: Color = {"bonus": Color(0.8, 0.9, 1.0), "mult": Color(1, 0.84, 0.84), "glass": Color(0.85, 0.96, 1.0), "stone": Color(0.62, 0.62, 0.66), "steel": Color(0.76, 0.81, 0.86), "lucky": Color(0.86, 0.95, 0.8)}.get(e, Astral.PARCHMENT)
	var edge := Astral.GOLD if selected else Color(0.45, 0.36, 0.18)
	draw_style_box(UIStyle.box(bg, Color(0, 0, 0, 0), 0, 10), Rect2(0, 0, W, H))
	var sd := int(card["rank"]) * 13 + int(card["suit"])
	Sketch.stroke(self, Sketch.round_rect(Rect2(1.5, 1.5, W - 3, H - 3), 10.0), Astral.GOLD if selected else Color(0.14, 0.11, 0.16), 3.4 if selected else 2.4, sd)
	Sketch.stroke(self, Sketch.round_rect(Rect2(6, 6, W - 12, H - 12), 6.0), Color(0.45, 0.33, 0.2, 0.5), 1.1, sd + 5)
	var s: int = card["suit"]
	var r: int = card["rank"]
	var col: Color = SUIT_COL[s]
	if e == "stone":
		for i in 5: draw_line(Vector2(12, 24 + i * 22.0), Vector2(W - 12, 40 + i * 18.0), Color(0.45, 0.45, 0.5), 2.0)
	else:
		var rn: String = NAMES.get(r, str(r))
		_corner(rn, col, s)
		draw_set_transform(Vector2(W, H) * k, PI, Vector2(k, k))
		_corner(rn, col, s)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
		if r == 14:
			_suit(Vector2(W / 2, H / 2), 26.0, s, col)
		elif r > 10:
			draw_style_box(UIStyle.box(Color(col, 0.07), col, 2, 8), Rect2(26, 26, W - 52, H - 52))
			draw_string(ThemeDB.fallback_font, Vector2(0, H * 0.5 + 19), rn, HORIZONTAL_ALIGNMENT_CENTER, W, 54, col)
			_suit(Vector2(W / 2, H * 0.8), 8.0, s, col)
		else:
			for p in _pips(r): _suit(Vector2(lerpf(28.0, W - 28.0, p[0]), lerpf(32.0, H - 32.0, p[1])), 9.5, s, col)
	if BlindManager.is_debuffed(card):
		draw_rect(Rect2(2, 2, W - 4, H - 4), Color(0.08, 0.08, 0.1, 0.6))
		draw_line(Vector2(14, 14), Vector2(W - 14, H - 14), Color(0.9, 0.2, 0.2), 4.0)
		draw_line(Vector2(W - 14, 14), Vector2(14, H - 14), Color(0.9, 0.2, 0.2), 4.0)
	var seal := String(card.get("seal", ""))
	if seal != "":
		draw_circle(Vector2(W / 2, H - 9), 5.0, {"gold": Color(1, 0.8, 0.2), "red": Color(0.9, 0.2, 0.2), "blue": Color(0.3, 0.5, 1), "purple": Color(0.7, 0.3, 0.9)}.get(seal, Color.WHITE))

func _corner(rn: String, col: Color, s: int) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(8, 28), rn, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, col)
	_suit(Vector2(17, 45), 8.0, s, col)

func _suit(c: Vector2, r: float, s: int, col: Color) -> void:
	var stem := PackedVector2Array([c + Vector2(-.12, .3) * r, c + Vector2(.12, .3) * r, c + Vector2(.35, 1.0) * r, c + Vector2(-.35, 1.0) * r])
	match s:
		0:
			draw_circle(c + Vector2(-.5, .2) * r, r * .55, col)
			draw_circle(c + Vector2(.5, .2) * r, r * .55, col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-1.0, .15) * r, c + Vector2(1.0, .15) * r, c + Vector2(0, -1.0) * r]), col)
			draw_colored_polygon(stem, col)
		1:
			draw_circle(c + Vector2(-.5, -.3) * r, r * .55, col)
			draw_circle(c + Vector2(.5, -.3) * r, r * .55, col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-1.0, -.05) * r, c + Vector2(1.0, -.05) * r, c + Vector2(0, 1.0) * r]), col)
		2:
			draw_circle(c + Vector2(0, -.5) * r, r * .45, col)
			draw_circle(c + Vector2(-.55, .2) * r, r * .45, col)
			draw_circle(c + Vector2(.55, .2) * r, r * .45, col)
			draw_circle(c + Vector2(0, .1) * r, r * .3, col)
			draw_colored_polygon(stem, col)
		_:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -1.0) * r, c + Vector2(.7, 0) * r, c + Vector2(0, 1.0) * r, c + Vector2(-.7, 0) * r]), col)
