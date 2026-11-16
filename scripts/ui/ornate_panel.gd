class_name OrnatePanel
extends PanelContainer
# 切角黄铜框面板：渐变底 + 双线描边 + 四角菱形铆钉 + 投影
var bg: Color = Astral.NIGHT
var accent: Color = Astral.GOLD_DIM

func _init() -> void:
	var e := StyleBoxEmpty.new()
	e.set_content_margin_all(16)
	add_theme_stylebox_override("panel", e)

func _draw() -> void:
	var c := 11.0
	var r := Rect2(Vector2.ZERO, size)
	var outer := Astral.chamfer(r, c)
	var shadow := PackedVector2Array()
	for p in outer: shadow.append(p + Vector2(3, 5))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
	var top := bg.lightened(0.1)
	var bot := bg.darkened(0.3)
	top.a = bg.a
	bot.a = bg.a
	draw_polygon(outer, PackedColorArray([top, top, top, bot, bot, bot, bot, top]))
	draw_polyline(outer + PackedVector2Array([outer[0]]), accent, 2.0, true)
	var inner := Astral.chamfer(r.grow(-5.0), c - 3.0)
	draw_polyline(inner + PackedVector2Array([inner[0]]), Color(accent, 0.45), 1.0, true)
	draw_line(Vector2(c, 1.5), Vector2(size.x - c, 1.5), Color(1, 1, 1, 0.14), 1.0)
	for p in [Vector2(c * 0.5, c * 0.5), Vector2(size.x - c * 0.5, c * 0.5), Vector2(size.x - c * 0.5, size.y - c * 0.5), Vector2(c * 0.5, size.y - c * 0.5)]:
		Astral.diamond(self, p, 3.0, Astral.GOLD)
