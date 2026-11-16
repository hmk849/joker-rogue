class_name Astral
extends RefCounted
# 视觉规范「夜之手账」：深蓝牛皮纸底、奶白粉笔线、彩铅/水彩色块、手画小星星。全部由代码绘制。
const INK := Color(0.05, 0.05, 0.1)
const NIGHT := Color(0.09, 0.12, 0.22)
const INDIGO := Color(0.15, 0.18, 0.36)
const GOLD := Color(0.98, 0.82, 0.42)
const GOLD_DIM := Color(0.74, 0.64, 0.44)
const IVORY := Color(0.97, 0.94, 0.86)
const PARCHMENT := Color(0.97, 0.93, 0.83)
const CHALK := Color(0.95, 0.92, 0.82)
const TEAL := Color(0.3, 0.74, 0.74)
const CRIMSON := Color(0.88, 0.34, 0.36)
const VIOLET := Color(0.56, 0.4, 0.84)
static var _star: ImageTexture

static func star_texture() -> ImageTexture:
	if _star: return _star
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var d := pow(absf(x - 7.5) / 7.5, 0.6667) + pow(absf(y - 7.5) / 7.5, 0.6667)
			img.set_pixel(x, y, Color(1, 1, 1, clampf((1.0 - d) * 3.0, 0.0, 1.0)))
	_star = ImageTexture.create_from_image(img)
	return _star

static func diamond(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)]), col)

static func divider(w: float = 200.0) -> Control:  # 手画波浪分隔线 + 中央小星
	var d := Control.new()
	d.custom_minimum_size = Vector2(w, 16)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.draw.connect(func():
		var y := d.size.y / 2.0
		var m := d.size.x / 2.0
		Sketch.line(d, Vector2(4, y), Vector2(m - 14, y), Color(CHALK, 0.6), 1.6, 11)
		Sketch.line(d, Vector2(m + 14, y), Vector2(d.size.x - 4, y), Color(CHALK, 0.6), 1.6, 23)
		Sketch.star(d, Vector2(m, y), 6.0, GOLD, 5))
	return d

static func button_deco(b: Button) -> void:  # 按钮：粉笔勾边 + 手画高光
	var seed := int(b.size.x * 3.0 + b.size.y)
	var a := 0.35 if b.disabled else 0.95
	Sketch.stroke(b, Sketch.round_rect(Rect2(2, 2, b.size.x - 4, b.size.y - 4), 10.0), Color(CHALK, a), 2.2, seed)
	if not b.disabled: Sketch.line(b, Vector2(14, 9), Vector2(b.size.x * 0.4, 9), Color(1, 1, 1, 0.25), 2.0, seed + 9)

static func draw_sigil(c: CanvasItem, center: Vector2, radius: float) -> void:  # 出牌区：粉笔画的星盘圈
	Sketch.stroke(c, Sketch.circle(center, radius), Color(CHALK, 0.4), 2.0, 41)
	Sketch.stroke(c, Sketch.circle(center, radius * 0.92), Color(CHALK, 0.22), 1.2, 53)
	for i in 36:
		var a := TAU * i / 36.0
		var d := Vector2(cos(a), sin(a))
		var l := 0.03 + 0.05 * fposmod(sin(i * 12.9898) * 43758.5, 1.0)
		Sketch.line(c, center + d * radius * (0.92 - l), center + d * radius * 0.92, Color(CHALK, 0.3), 1.2, 60 + i)
	for i in 4:
		var a := TAU * i / 4.0
		Sketch.star(c, center + Vector2(cos(a), sin(a)) * radius, 5.0, Color(GOLD, 0.75), 80 + i)
