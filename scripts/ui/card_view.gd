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
	draw_style_box(UIStyle.box(Astral.INDIGO.darkened(0.35), Astral.GOLD, 3, 10), Rect2(0, 0, W, H))
	draw_style_box(UIStyle.box(Astral.INDIGO, Astral.GOLD_DIM, 1, 6), Rect2(8, 8, W - 16, H - 16))
	var c := Vector2(W / 2, H / 2)
	draw_arc(c, 34.0, 0.0, TAU, 48, Astral.GOLD, 2.0, true)
	draw_arc(c, 27.0, 0.0, TAU, 48, Astral.GOLD_DIM, 1.0, true)
	for i in 12:
		var d := Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0))
		draw_line(c + d * 34.0, c + d * 40.0, Astral.GOLD, 2.0)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -21), c + Vector2(5, -5), c + Vector2(21, 0), c + Vector2(5, 5), c + Vector2(0, 21), c + Vector2(-5, 5), c + Vector2(-21, 0), c + Vector2(-5, -5)]), Astral.GOLD)
	for p in [Vector2(17, 17), Vector2(W - 17, 17), Vector2(17, H - 17), Vector2(W - 17, H - 17)]: Astral.diamond(self, p, 3.0, Astral.GOLD)

func _face(k: float) -> void:
	var e := String(card.get("enh", ""))
	var ed := String(card.get("ed", ""))
	var bg: Color = {"bonus": Color(0.8, 0.9, 1.0), "mult": Color(1, 0.84, 0.84), "glass": Color(0.85, 0.96, 1.0), "stone": Color(0.62, 0.62, 0.66), "steel": Color(0.76, 0.81, 0.86), "lucky": Color(0.86, 0.95, 0.8)}.get(e, Astral.PARCHMENT)
	var edge := Astral.GOLD if selected else Color(0.45, 0.36, 0.18)
	draw_style_box(UIStyle.box(bg, edge, 4 if selected else 2, 10), Rect2(0, 0, W, H))
	draw_style_box(UIStyle.box(Color(0, 0, 0, 0), Color(0.62, 0.5, 0.26, 0.75), 1, 6), Rect2(5, 5, W - 10, H - 10))
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
