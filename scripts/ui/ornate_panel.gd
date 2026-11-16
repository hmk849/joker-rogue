class_name OrnatePanel
extends PanelContainer
# 手绘面板：圆角色块 + 偏移彩铅晕色 + 双重粉笔描边 + 四角手画小星
var bg: Color = Astral.NIGHT
var accent: Color = Astral.GOLD_DIM
var plain := false  # 简洁模式：只留外框，用于栏内的小方框
var _sb := StyleBoxEmpty.new()

func _init() -> void:
	_sb.set_content_margin_all(16)
	add_theme_stylebox_override("panel", _sb)

func set_pad(p: float) -> void: _sb.set_content_margin_all(p)

func _draw() -> void:
	match ThemeManager.style():
		"wood": _draw_wood()
		"velvet": _draw_velvet()
		_: _draw_sketch()

func _closed(p: PackedVector2Array) -> PackedVector2Array:
	var c := p.duplicate()
	c.append(p[0])
	return c

# 木板拼成的告示牌：横向木纹、板缝、黄铜内线、铁钉
func _draw_wood() -> void:
	var r := Rect2(Vector2(2, 2), size - Vector2(4, 4))
	var pts := Sketch.round_rect(r, 8.0)
	var sh := PackedVector2Array()
	for p in pts: sh.append(p + Vector2(3, 5))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.4))
	draw_colored_polygon(pts, bg)
	var ph := 22.0 if plain else 30.0
	var sd := int(size.x * 3.0 + size.y)
	for i in int(r.size.y / ph) + 1:
		var y := r.position.y + i * ph
		if y + 3.0 > r.end.y: break
		var h := minf(ph - 1.0, r.end.y - y - 2.0)
		var tone := 0.05 * sin(i * 12.9898 + sd)
		draw_rect(Rect2(r.position.x + 3, y + 1.0, r.size.x - 6, h), bg.lightened(0.05 + tone) if i % 2 == 0 else bg.darkened(0.05 - tone))
		draw_line(Vector2(r.position.x + 3, y), Vector2(r.end.x - 3, y), Color(0, 0, 0, 0.4), 1.5)
		for k in 2:
			var gx := r.position.x + 12.0 + fposmod(sin((i * 2 + k + sd) * 78.233) * 43758.5, 1.0) * maxf(r.size.x - 80.0, 10.0)
			var gy := y + ph * (0.35 + 0.3 * k)
			draw_line(Vector2(gx, gy), Vector2(gx + 30.0, gy + 1.0), Color(0, 0, 0, 0.13), 1.0)
	var bc: Color = Astral.INK if not plain else accent.lerp(Astral.INK, 0.35)
	draw_polyline(_closed(pts), bc, 3.0, true)
	draw_polyline(_closed(Sketch.round_rect(r.grow(-4.0), 6.0)), Color(Astral.GOLD_DIM, 0.7), 1.5, true)
	if plain: return
	for p in [r.position + Vector2(11, 11), Vector2(r.end.x - 11, r.position.y + 11), r.end - Vector2(11, 11), Vector2(r.position.x + 11, r.end.y - 11)]:
		draw_circle(p, 4.0, Astral.INK)
		draw_circle(p + Vector2(-1, -1), 2.0, Astral.GOLD_DIM)

func _diag(r: Rect2, off: float, slope: float) -> void:  # 绗缝菱格的一条斜线（裁剪在面板内）
	var w := r.size.x
	var ta := (r.position.y - off) / (slope * w)
	var tb := (r.end.y - off) / (slope * w)
	var lo := maxf(0.0, minf(ta, tb))
	var hi := minf(1.0, maxf(ta, tb))
	if lo >= hi: return
	draw_line(Vector2(r.position.x + lo * w, off + slope * lo * w), Vector2(r.position.x + hi * w, off + slope * hi * w), Color(Astral.GOLD, 0.07), 1.0)

# 酒红丝绒：渐变底、绗缝菱格、双层鎏金边、卷草角花
func _draw_velvet() -> void:
	var r := Rect2(Vector2(2, 2), size - Vector2(4, 4))
	var pts := Sketch.round_rect(r, 7.0)
	var sh := PackedVector2Array()
	for p in pts: sh.append(p + Vector2(3, 5))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.4))
	var cols := PackedColorArray()
	var top := bg.lightened(0.08)
	var bot := bg.darkened(0.3)
	for p in pts: cols.append(top.lerp(bot, clampf((p.y - r.position.y) / maxf(r.size.y, 1.0), 0.0, 1.0)))
	draw_polygon(pts, cols)
	var step := 26.0
	for i in int((r.size.x + r.size.y) / step) + 2:
		_diag(r, r.position.y - r.size.x + i * step, 1.0)
		_diag(r, r.position.y + i * step, -1.0)
	draw_polyline(_closed(pts), Astral.GOLD if not plain else accent, 2.5, true)
	if plain: return
	draw_polyline(_closed(Sketch.round_rect(r.grow(-6.0), 4.0)), Color(Astral.GOLD, 0.45), 1.0, true)
	var cs := [r.position + Vector2(16, 16), Vector2(r.end.x - 16, r.position.y + 16), r.end - Vector2(16, 16), Vector2(r.position.x + 16, r.end.y - 16)]
	for i in 4:
		var a0 := PI + i * PI / 2.0
		draw_arc(cs[i], 8.0, a0, a0 + PI * 1.5, 12, Color(Astral.GOLD, 0.85), 1.6, true)
		Astral.diamond(self, cs[i], 2.6, Astral.GOLD)
	Astral.diamond(self, Vector2(size.x / 2.0, 3.0), 3.5, Astral.GOLD)
	Astral.diamond(self, Vector2(size.x / 2.0, size.y - 3.0), 3.5, Astral.GOLD)

func _draw_sketch() -> void:
	var r := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	var pts := Sketch.round_rect(r, 10.0 if plain else 14.0)
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
	if plain: return
	Sketch.stroke(self, Sketch.round_rect(r.grow(-7.0), 9.0), Color(oc, 0.28), 1.2, seed + 31)
	for p in [r.position + Vector2(11, 11), Vector2(r.end.x - 11, r.position.y + 11), r.end - Vector2(11, 11), Vector2(r.position.x + 11, r.end.y - 11)]:
		Sketch.star(self, p, 4.5, Astral.GOLD, seed + int(p.x))
