class_name BgDoodles
extends Control
# 背景里缓缓漂浮、旋转、呼吸的粉笔涂鸦：花色、星星、螺旋、扑克牌、小丑帽……（预生成折线，逐帧只做变换）
var items: Array = []
var shapes := {}
var _t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shapes()
	_spawn()
	SettingsManager.changed.connect(func(k: String):
		if k in ["quality", "bg_effects", "animations"]:
			_spawn()
			queue_redraw())

func _jit(pts: PackedVector2Array, rng: RandomNumberGenerator, a: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts: out.append(p + Vector2(rng.randf_range(-a, a), rng.randf_range(-a, a)))
	return out

func _circ(c: Vector2, r: float, n: int = 20) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1: out.append(c + Vector2(cos(TAU * i / n), sin(TAU * i / n)) * r)
	return out

func _build_shapes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var heart := PackedVector2Array()
	var spade := PackedVector2Array()
	for i in 41:
		var t := TAU * i / 40.0
		var p := Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) / 17.0
		heart.append(p)
		spade.append(Vector2(p.x, -p.y))
	shapes["heart"] = [_jit(heart, rng, 0.02)]
	shapes["spade"] = [_jit(spade, rng, 0.02), PackedVector2Array([Vector2(0, 0.5), Vector2(-0.22, 1.0), Vector2(0.22, 1.0), Vector2(0, 0.5)])]
	shapes["diamond"] = [_jit(PackedVector2Array([Vector2(0, -1), Vector2(0.65, 0), Vector2(0, 1), Vector2(-0.65, 0), Vector2(0, -1)]), rng, 0.03)]
	shapes["club"] = [_circ(Vector2(0, -0.5), 0.42), _circ(Vector2(-0.5, 0.2), 0.42), _circ(Vector2(0.5, 0.2), 0.42), PackedVector2Array([Vector2(0, 0.2), Vector2(-0.2, 1.0), Vector2(0.2, 1.0), Vector2(0, 0.2)])]
	shapes["star"] = [PackedVector2Array([Vector2(-1, 0), Vector2(1, 0)]), PackedVector2Array([Vector2(0, -1), Vector2(0, 1)]), PackedVector2Array([Vector2(-0.5, -0.5), Vector2(0.5, 0.5)]), PackedVector2Array([Vector2(0.5, -0.5), Vector2(-0.5, 0.5)])]
	var sp := PackedVector2Array()
	for i in 60: sp.append(Vector2(cos(i * 0.32), sin(i * 0.32)) * (i / 60.0))
	shapes["spiral"] = [_jit(sp, rng, 0.015)]
	var cd := Sketch.round_rect(Rect2(-0.5, -0.7, 1.0, 1.4), 0.12)
	cd.append(cd[0])
	shapes["card"] = [_jit(cd, rng, 0.015), _circ(Vector2(0, 0), 0.22, 12)]
	shapes["hat"] = [_jit(PackedVector2Array([Vector2(-0.8, 0.6), Vector2(-0.9, -0.4), Vector2(-0.35, 0.1), Vector2(0, -0.8), Vector2(0.35, 0.1), Vector2(0.9, -0.4), Vector2(0.8, 0.6), Vector2(-0.8, 0.6)]), rng, 0.02), _circ(Vector2(-0.9, -0.4), 0.1, 8), _circ(Vector2(0, -0.8), 0.1, 8), _circ(Vector2(0.9, -0.4), 0.1, 8)]

func _spawn() -> void:
	items.clear()
	var n: int = [6, 12, 20, 30][clampi(int(SettingsManager.get_value("quality")), 0, 3)]
	var kinds := shapes.keys()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var cols := [Astral.CHALK, Astral.TEAL.lightened(0.2), Astral.CRIMSON.lightened(0.2), Astral.GOLD]
	for i in n:
		items.append({"k": kinds[i % kinds.size()], "p": Vector2(rng.randf(), rng.randf()),
			"v": Vector2(rng.randf_range(-0.012, 0.012), rng.randf_range(-0.035, -0.008)), "r": rng.randf() * TAU,
			"w": rng.randf_range(-0.4, 0.4), "s": rng.randf_range(22.0, 70.0), "ph": rng.randf() * TAU, "c": cols[rng.randi() % 4]})

func _process(dt: float) -> void:
	if not bool(SettingsManager.get_value("bg_effects")) or not bool(SettingsManager.get_value("animations")): return
	_t += dt
	for it in items:
		var p: Vector2 = it["p"] + it["v"] * dt
		if p.y < -0.12: p.y = 1.12
		if p.x < -0.12: p.x = 1.12
		if p.x > 1.12: p.x = -0.12
		it["p"] = p
		it["r"] = float(it["r"]) + float(it["w"]) * dt
	queue_redraw()

func _draw() -> void:
	for it in items:
		var pulse := 1.0 + 0.07 * sin(_t * 1.5 + float(it["ph"]))
		var s: float = float(it["s"]) * pulse
		draw_set_transform(Vector2(it["p"].x * size.x, it["p"].y * size.y), it["r"], Vector2(s, s))
		var col: Color = it["c"]
		draw_circle(Vector2.ZERO, 0.75, Color(col, 0.05))  # 水彩晕色
		for pl in shapes[it["k"]]: draw_polyline(pl, Color(col, 0.26), 2.0 / s, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
