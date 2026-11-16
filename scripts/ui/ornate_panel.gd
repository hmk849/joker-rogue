class_name OrnatePanel
extends PanelContainer
# 手绘面板：圆角色块 + 偏移彩铅晕色 + 双重粉笔描边 + 四角手画小星
var bg: Color = Astral.NIGHT
var accent: Color = Astral.GOLD_DIM

func _init() -> void:
	var e := StyleBoxEmpty.new()
	e.set_content_margin_all(16)
	add_theme_stylebox_override("panel", e)

func _draw() -> void:
	var r := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	var pts := Sketch.round_rect(r, 14.0)
	var sh := PackedVector2Array()
	for p in pts: sh.append(p + Vector2(3, 5))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.3))
	draw_colored_polygon(pts, bg.lightened(0.03))
	var wash := PackedVector2Array()  # 彩铅晕色：略微错位的色块，像印刷套色没对准
	for p in Sketch.round_rect(Rect2(r.position + Vector2(8, 8), r.grow(-5.0).size), 10.0): wash.append(p)
	draw_colored_polygon(wash, Color(accent, 0.07))
	var seed := int(size.x * 13.0 + size.y * 7.0)
	var oc := accent.lerp(Astral.CHALK, 0.6)
	Sketch.stroke(self, pts, Color(oc, 0.95), 2.4, seed)
	Sketch.stroke(self, Sketch.round_rect(r.grow(-7.0), 9.0), Color(oc, 0.28), 1.2, seed + 31)
	for p in [r.position + Vector2(11, 11), Vector2(r.end.x - 11, r.position.y + 11), r.end - Vector2(11, 11), Vector2(r.position.x + 11, r.end.y - 11)]:
		Sketch.star(self, p, 4.5, Astral.GOLD, seed + int(p.x))
