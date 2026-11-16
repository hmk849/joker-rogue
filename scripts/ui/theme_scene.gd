class_name ThemeScene
extends Control
# 主题背景：Shader 铺底 + 代码绘制的动态道具
#   harbor（咸风酒馆·主界面）风暴码头：摇晃的帆船、拍岸浪花、系缆桩与缆绳、提灯、海鸥
#   tavern（咸风酒馆·局内）酒馆内景：三盏摇晃的提灯、木桶、飘起的火星
#   vault （暗河赌厅·主界面）威尼斯地下拱廊：烛光吊灯、墙上面具、滑行的贡多拉
#   table （暗河赌厅·局内）赌桌：筹码堆、烛台、缭绕的烟雾
var kind := "harbor"
var mat: ShaderMaterial
var props: Control
var motes: Array = []
var _t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var base := ColorRect.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = FxShaders.shader(kind)
	base.material = mat
	add_child(base)
	props = Control.new()
	props.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	props.mouse_filter = Control.MOUSE_FILTER_IGNORE
	props.draw.connect(_draw_props)
	add_child(props)
	_spawn()
	_apply_speed()
	SettingsManager.changed.connect(func(k: String):
		if k in ["bg_effects", "quality", "animations"]:
			_spawn()
			_apply_speed())

func _anim() -> bool: return bool(SettingsManager.get_value("bg_effects")) and bool(SettingsManager.get_value("animations"))
func _apply_speed() -> void: mat.set_shader_parameter("speed", 1.0 if _anim() else 0.0)

func _spawn() -> void:
	motes.clear()
	var n: int = [8, 16, 28, 40][clampi(int(SettingsManager.get_value("quality")), 0, 3)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in n:
		var v := Vector2(rng.randf_range(-0.008, 0.008), -rng.randf_range(0.01, 0.05))
		if kind == "harbor": v = Vector2(rng.randf_range(0.12, 0.3), rng.randf_range(-0.01, 0.03))
		motes.append({"p": Vector2(rng.randf(), rng.randf()), "v": v, "s": rng.randf_range(1.5, 3.5), "ph": rng.randf() * TAU})

func _process(dt: float) -> void:
	if not _anim(): return
	_t += dt
	for m in motes:
		var p: Vector2 = m["p"] + m["v"] * dt
		p.x = fposmod(p.x, 1.0)
		p.y = fposmod(p.y, 1.0)
		m["p"] = p
	props.queue_redraw()

func _draw_props() -> void:
	var c: Control = props
	match kind:
		"harbor": _harbor(c)
		"tavern": _tavern(c)
		"vault": _vault(c)
		_: _table(c)
	var col := {"harbor": Color(0.85, 0.92, 1.0), "tavern": Color(1.0, 0.6, 0.25), "vault": Color(1.0, 0.82, 0.45), "table": Color(0.9, 0.9, 0.85)}[kind] as Color
	for m in motes: c.draw_circle(Vector2(m["p"].x * c.size.x, m["p"].y * c.size.y), m["s"], Color(col, 0.2 + 0.25 * (0.5 + 0.5 * sin(_t * 2.0 + float(m["ph"])))))

func _ellp(ctr: Vector2, rx: float, ry: float) -> PackedVector2Array: return ItemArt._ell(ctr, rx, ry, 0.0, 20)

func _harbor(c: Control) -> void:
	var s := c.size
	var hz := s.y * 0.5
	var sc := s.y / 700.0
	var bob := sin(_t * 1.3) * 7.0 * sc
	var rot := 0.06 * sin(_t * 0.9) + 0.02 * sin(_t * 2.1)
	c.draw_set_transform(Vector2(s.x * 0.58, hz + 24.0 * sc + bob), rot, Vector2(sc, sc))
	var dark := Color(0.12, 0.07, 0.04)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-130, -6), Vector2(140, -6), Vector2(105, 42), Vector2(-95, 42)]), dark)
	c.draw_line(Vector2(-130, -6), Vector2(-165, -32), dark, 6.0)
	c.draw_line(Vector2(-35, -6), Vector2(-35, -175), dark, 5.0)
	c.draw_line(Vector2(45, -6), Vector2(45, -145), dark, 5.0)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-35, -170), Vector2(-105, -50), Vector2(-35, -38)]), Color(0.78, 0.74, 0.62, 0.9))
	c.draw_colored_polygon(PackedVector2Array([Vector2(45, -140), Vector2(105, -40), Vector2(45, -28)]), Color(0.7, 0.66, 0.55, 0.9))
	c.draw_circle(Vector2(118, 6), 24.0, Color(1.0, 0.7, 0.3, 0.12))
	c.draw_circle(Vector2(118, 6), 8.0, Color(1.0, 0.78, 0.35, 0.95))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var top := s.y * 0.82
	c.draw_colored_polygon(PackedVector2Array([Vector2(0, top), Vector2(s.x, top), Vector2(s.x, s.y), Vector2(0, s.y)]), Color(0.17, 0.1, 0.06))
	for i in 25:
		var xb := s.x * i / 24.0
		c.draw_line(Vector2(s.x * 0.5 + (xb - s.x * 0.5) * 0.6, top), Vector2(xb, s.y), Color(0.05, 0.03, 0.02, 0.8), 2.0)
	for k in range(1, 5): c.draw_line(Vector2(0, top + (s.y - top) * pow(k / 5.0, 1.6)), Vector2(s.x, top + (s.y - top) * pow(k / 5.0, 1.6)), Color(0.05, 0.03, 0.02, 0.7), 2.0)
	c.draw_line(Vector2(0, top), Vector2(s.x, top), Color(0.4, 0.28, 0.16), 4.0)
	for px in [s.x * 0.1, s.x * 0.9]:
		c.draw_rect(Rect2(px - 10, top - s.y * 0.2, 20, s.y * 0.22), Color(0.14, 0.08, 0.05))
		c.draw_circle(Vector2(px, top - s.y * 0.2), 12.0, Color(0.18, 0.1, 0.06))
	var rope := PackedVector2Array()
	for i in 21:
		var u := i / 20.0
		rope.append(Vector2(lerpf(s.x * 0.1, s.x * 0.9, u), top - s.y * 0.2 + sin(u * PI) * s.y * 0.09 + sin(_t * 1.2 + u * 6.0) * 3.0))
	c.draw_polyline(rope, Color(0.6, 0.5, 0.32), 4.0)
	var fl := 0.85 + 0.15 * sin(_t * 10.0)
	c.draw_circle(Vector2(s.x * 0.1, top - s.y * 0.24), 44.0, Color(1, 0.75, 0.35, 0.1 * fl))
	c.draw_circle(Vector2(s.x * 0.1, top - s.y * 0.24), 10.0, Color(1, 0.82, 0.45, 0.95))
	for i in 6:
		var h := 0.5 + 0.5 * sin(_t * 1.6 + i * 1.7)
		c.draw_arc(Vector2(s.x * (i + 0.5) / 6.0, top + 4.0), 40.0 + 30.0 * h, PI * 1.1, PI * 1.9, 12, Color(0.9, 0.95, 1.0, 0.35 * h), 3.0)
	for i in 3:
		var gx := fposmod(_t * (0.03 + 0.01 * i) + i * 0.37, 1.2) * s.x - 0.1 * s.x
		var gy := s.y * (0.14 + 0.07 * i) + sin(_t * 0.8 + i) * 14.0
		var wing := 0.35 + 0.3 * sin(_t * 7.0 + i * 2.0)
		c.draw_polyline(PackedVector2Array([Vector2(gx - 16, gy + wing * 18), Vector2(gx, gy), Vector2(gx + 16, gy + wing * 18)]), Color(0.9, 0.92, 0.95, 0.85), 2.4)

func _tavern(c: Control) -> void:
	var s := c.size
	for i in 3:
		var x0 := (0.2 + 0.3 * i) * s.x
		var ln := s.y * 0.14
		var a := 0.1 * sin(_t * 0.8 + i * 2.0)
		var p := Vector2(x0 + sin(a) * ln, cos(a) * ln)
		var fl := 0.8 + 0.2 * sin(_t * 11.0 + i * 5.0)
		c.draw_line(Vector2(x0, 0), p, Color(0.07, 0.04, 0.03, 0.9), 2.0)
		c.draw_circle(p, 70.0, Color(1, 0.65, 0.25, 0.06 * fl))
		c.draw_circle(p, 38.0, Color(1, 0.7, 0.3, 0.12 * fl))
		c.draw_rect(Rect2(p + Vector2(-9, 0), Vector2(18, 24)), Color(1, 0.82, 0.42, 0.95))
		c.draw_rect(Rect2(p + Vector2(-9, 0), Vector2(18, 24)), Color(0.1, 0.06, 0.03), false, 2.0)
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-12, 0), p + Vector2(12, 0), p + Vector2(0, -12)]), Color(0.1, 0.06, 0.03))
	for bx in [s.x * 0.03, s.x * 0.97]:
		var by := s.y * 0.9
		c.draw_style_box(UIStyle.box(Color(0.3, 0.17, 0.09), Color(0.07, 0.04, 0.03), 3, 16), Rect2(bx - 34, by - 70, 68, 80))
		for y in [by - 50, by - 12]: c.draw_line(Vector2(bx - 34, y), Vector2(bx + 34, y), Color(0.1, 0.06, 0.04), 4.0)
		c.draw_colored_polygon(_ellp(Vector2(bx, by - 70), 30.0, 8.0), Color(0.4, 0.24, 0.12))

func _mask(c: Control, p: Vector2, r: float) -> void:
	var m := PackedVector2Array()
	for q in [[-0.85, -0.1], [-0.55, -0.5], [0.0, -0.38], [0.55, -0.5], [0.85, -0.1], [0.6, 0.3], [0.18, 0.38], [0.0, 0.95], [-0.18, 0.38], [-0.6, 0.3]]: m.append(p + Vector2(q[0], q[1]) * r)
	c.draw_colored_polygon(m, Color(0.9, 0.78, 0.45, 0.92))
	for sg in [-1.0, 1.0]:
		c.draw_circle(p + Vector2(sg * 0.35 * r, -0.1 * r), 0.2 * r, Color(0.1, 0.03, 0.05))
		c.draw_line(p + Vector2(sg * 0.85 * r, -0.1 * r), p + Vector2(sg * 1.3 * r, -0.55 * r), Astral.GOLD, 2.0)

func _vault(c: Control) -> void:
	var s := c.size
	for i in 3:
		var x := (i + 0.5) / 3.0 * s.x
		var y := s.y * 0.1
		c.draw_line(Vector2(x, 0), Vector2(x, y - 14.0), Color(Astral.GOLD_DIM, 0.8), 2.0)
		c.draw_arc(Vector2(x, y), 36.0, 0.0, TAU, 24, Astral.GOLD, 3.0)
		for k in 6:
			var cx := x + (k - 2.5) * 12.0
			var fl := 0.8 + 0.2 * sin(_t * 9.0 + k * 1.7 + i * 3.0)
			c.draw_rect(Rect2(cx - 2.5, y - 14.0, 5.0, 14.0), Color(0.95, 0.9, 0.78))
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx, y - 14.0 - 12.0 * fl), Vector2(cx + 3.0, y - 14.0), Vector2(cx - 3.0, y - 14.0)]), Color(1.0, 0.8, 0.35))
			c.draw_circle(Vector2(cx, y - 18.0), 10.0, Color(1, 0.7, 0.3, 0.1 * fl))
	for i in 4: _mask(c, Vector2(i / 3.0 * s.x, s.y * 0.43), s.y * 0.05)
	var sc := s.y / 700.0
	var gx := fposmod(_t * 0.025, 1.0) * (s.x + 400.0) - 200.0
	var gy := s.y * 0.82 + sin(_t * 1.1) * 3.0
	c.draw_set_transform(Vector2(gx, gy), 0.0, Vector2(sc, sc))
	var dk := Color(0.04, 0.03, 0.05)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-120, -24), Vector2(-90, 4), Vector2(90, 4), Vector2(130, -30), Vector2(110, -8), Vector2(-100, -8)]), dk)
	c.draw_line(Vector2(40, -8), Vector2(40, -72), dk, 7.0)
	c.draw_circle(Vector2(40, -82), 8.0, dk)
	c.draw_line(Vector2(48, -60), Vector2(86, 12), dk, 3.0)
	c.draw_set_transform(Vector2(gx, gy + 14.0 * sc), 0.0, Vector2(sc, -sc * 0.5))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-120, -24), Vector2(-90, 4), Vector2(90, 4), Vector2(130, -30), Vector2(110, -8), Vector2(-100, -8)]), Color(0, 0, 0, 0.3))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _stack(c: Control, p: Vector2, n: int, col: Color) -> void:
	for i in n:
		var y := p.y - i * 7.0
		c.draw_rect(Rect2(p.x - 26.0, y, 52.0, 7.0), col.darkened(0.35))
		c.draw_colored_polygon(_ellp(Vector2(p.x, y + 7.0), 26.0, 9.0), col.darkened(0.35))
		c.draw_colored_polygon(_ellp(Vector2(p.x, y), 26.0, 9.0), col)
		var ring := _ellp(Vector2(p.x, y), 18.0, 6.0)
		ring.append(ring[0])
		c.draw_polyline(ring, Color(1, 1, 1, 0.55), 1.5)
		for sg in [-1.0, 1.0]: c.draw_line(Vector2(p.x + sg * 24.0, y - 2.0), Vector2(p.x + sg * 26.0, y + 5.0), Color(1, 1, 1, 0.7), 2.0)

func _candle(c: Control, p: Vector2) -> void:
	var fl := 0.8 + 0.2 * sin(_t * 10.0 + p.x)
	c.draw_circle(p + Vector2(0, -8), 60.0, Color(1, 0.7, 0.3, 0.08 * fl))
	c.draw_rect(Rect2(p.x - 7.0, p.y, 14.0, 56.0), Color(0.95, 0.9, 0.78))
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -18.0 * fl), p + Vector2(5, 0), p + Vector2(-5, 0)]), Color(1.0, 0.82, 0.38))
	c.draw_rect(Rect2(p.x - 14.0, p.y + 56.0, 28.0, 6.0), Astral.GOLD)

func _table(c: Control) -> void:
	var s := c.size
	_stack(c, Vector2(s.x * 0.06, s.y * 0.92), 7, Color(0.8, 0.2, 0.2))
	_stack(c, Vector2(s.x * 0.105, s.y * 0.95), 5, Color(0.2, 0.35, 0.8))
	_stack(c, Vector2(s.x * 0.94, s.y * 0.92), 8, Color(0.12, 0.12, 0.14))
	_stack(c, Vector2(s.x * 0.895, s.y * 0.95), 4, Color(0.9, 0.75, 0.3))
	for cx in [s.x * 0.04, s.x * 0.96]: _candle(c, Vector2(cx, s.y * 0.1))
	for i in 3:
		var pts := PackedVector2Array()
		for k in 20:
			var u := k / 19.0
			pts.append(Vector2(s.x * (0.3 + 0.2 * i) + sin(u * 6.0 + _t * 0.6 + i * 2.0) * 30.0 * u, s.y * (0.5 - u * 0.5)))
		c.draw_polyline(pts, Color(1, 1, 1, 0.035), 14.0)
