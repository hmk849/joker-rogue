class_name Astral
extends RefCounted
# 「星盘炼金」视觉规范：午夜靛蓝 + 黄铜鎏金线 + 象牙羊皮纸；
# 标志元素：星盘刻度环、切角黄铜框、菱形铆钉、四角星。全部由代码绘制。
const INK := Color(0.03, 0.04, 0.1)
const NIGHT := Color(0.07, 0.09, 0.2)
const INDIGO := Color(0.13, 0.15, 0.34)
const GOLD := Color(0.95, 0.8, 0.4)
const GOLD_DIM := Color(0.62, 0.5, 0.26)
const IVORY := Color(0.96, 0.93, 0.84)
const PARCHMENT := Color(0.97, 0.94, 0.86)
const TEAL := Color(0.27, 0.72, 0.78)
const CRIMSON := Color(0.8, 0.22, 0.32)
const VIOLET := Color(0.52, 0.34, 0.82)
static var _star: ImageTexture

static func star_texture() -> ImageTexture:  # 四角星粒子贴图（程序化生成）
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

static func chamfer(r: Rect2, c: float) -> PackedVector2Array:  # 切角矩形
	var a := r.position
	var b := r.end
	return PackedVector2Array([Vector2(a.x + c, a.y), Vector2(b.x - c, a.y), Vector2(b.x, a.y + c), Vector2(b.x, b.y - c),
		Vector2(b.x - c, b.y), Vector2(a.x + c, b.y), Vector2(a.x, b.y - c), Vector2(a.x, a.y + c)])

static func divider(w: float = 200.0) -> Control:  # 带中央菱形的分隔线
	var d := Control.new()
	d.custom_minimum_size = Vector2(w, 16)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.draw.connect(func():
		var y := d.size.y / 2.0
		var m := d.size.x / 2.0
		d.draw_line(Vector2(4, y), Vector2(m - 12, y), GOLD_DIM, 1.5)
		d.draw_line(Vector2(m + 12, y), Vector2(d.size.x - 4, y), GOLD_DIM, 1.5)
		diamond(d, Vector2(m, y), 5.0, GOLD)
		diamond(d, Vector2(m - 12, y), 2.0, GOLD_DIM)
		diamond(d, Vector2(m + 12, y), 2.0, GOLD_DIM))
	return d

static func button_deco(b: Button) -> void:  # 黄铜按钮：高光带 + 两侧铆钉
	if b.disabled: return
	b.draw_rect(Rect2(3, 3, b.size.x - 6, b.size.y * 0.36), Color(1, 1, 1, 0.07))
	diamond(b, Vector2(9, b.size.y / 2.0), 2.5, GOLD)
	diamond(b, Vector2(b.size.x - 9, b.size.y / 2.0), 2.5, GOLD)

static func draw_sigil(c: CanvasItem, center: Vector2, radius: float) -> void:  # 出牌区的星盘法阵
	c.draw_arc(center, radius, 0.0, TAU, 96, Color(GOLD_DIM, 0.35), 2.0, true)
	c.draw_arc(center, radius * 0.93, 0.0, TAU, 96, Color(GOLD_DIM, 0.2), 1.0, true)
	for i in 36:
		var a := TAU * i / 36.0
		var d := Vector2(cos(a), sin(a))
		var l := 0.07 if i % 3 == 0 else 0.035
		c.draw_line(center + d * radius * (0.93 - l), center + d * radius * 0.93, Color(GOLD_DIM, 0.3), 1.0)
	for i in 4:
		var a := TAU * i / 4.0
		diamond(c, center + Vector2(cos(a), sin(a)) * radius, 4.0, Color(GOLD, 0.5))
