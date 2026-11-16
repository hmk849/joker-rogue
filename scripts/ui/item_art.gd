class_name ItemArt
extends RefCounted
# 小丑牌 / 塔罗 / 星球 / 幻灵 / 卡包 / 优惠券 的程序化手绘插画（粉笔线 + 色块），无外部素材
const PLANET_COL := {"pluto": Color(0.78, 0.68, 0.62), "mercury": Color(0.72, 0.72, 0.76), "venus": Color(0.96, 0.8, 0.42),
	"earth": Color(0.3, 0.55, 0.92), "mars": Color(0.86, 0.36, 0.26), "jupiter": Color(0.92, 0.66, 0.42),
	"saturn": Color(0.92, 0.82, 0.52), "uranus": Color(0.5, 0.86, 0.9), "neptune": Color(0.3, 0.42, 0.92)}
const HAT_COL := [Color(0.88, 0.34, 0.36), Color(0.3, 0.74, 0.74), Color(0.56, 0.4, 0.84), Color(0.92, 0.62, 0.22)]
const EMB := {"greedy": "s3", "lusty": "s1", "wrathful": "s0", "gluttonous": "s2", "scary": "eye", "banner": "flag", "half": "moon",
	"mystic": "burst", "fib": "burst", "scholar": "book", "photo": "cam", "supernova": "burst", "blue": "cards", "bull": "horns",
	"golden": "coin", "cavendish": "moon", "baron": "crown", "moon": "moon", "triboulet": "crown", "chicot": "eye",
	"jolly": "cards", "sly": "cards", "zany": "cards", "wily": "cards", "mad": "cards", "clever": "cards"}

static func draw(c: CanvasItem, kind: String, id: String, r: Rect2, bg: Color) -> void:
	var ctr := r.get_center()
	var u := minf(r.size.x, r.size.y) * 0.5
	var sd := id.hash() % 997
	match kind:
		"planet": _planet(c, id, ctr, u, sd)
		"tarot": _tarot(c, id, ctr, u, bg, sd)
		"spectral": _spectral(c, id, ctr, u, bg, sd)
		"joker": _joker(c, id, ctr, u, sd)
		"pack": _pack(c, id, ctr, u, sd)
		_: _voucher(c, ctr, u, sd)

# ---------- 小工具 ----------
static func _pl(c: CanvasItem, ctr: Vector2, u: float, arr: Array, fill: Color, line: Color, sd: int, closed: bool = true) -> void:
	var p := PackedVector2Array()
	for q in arr: p.append(ctr + Vector2(q[0], q[1]) * u)
	if fill.a > 0.0 and closed: c.draw_colored_polygon(p, fill)
	if line.a > 0.0: Sketch.stroke(c, p, line, 1.8, sd, closed)

static func _ci(c: CanvasItem, ctr: Vector2, rad: float, fill: Color, line: Color, sd: int) -> void:
	if fill.a > 0.0: c.draw_circle(ctr, rad, fill)
	if line.a > 0.0: Sketch.stroke(c, Sketch.circle(ctr, rad, 24), line, 1.8, sd)

static func _ln(c: CanvasItem, a: Vector2, b: Vector2, col: Color, sd: int) -> void:
	Sketch.line(c, a, b, col, 2.0, sd)

static func _ell(ctr: Vector2, rx: float, ry: float, rot: float, seg: int = 36) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in seg: p.append(ctr + Vector2(cos(TAU * i / seg) * rx, sin(TAU * i / seg) * ry).rotated(rot))
	return p

static func _star5(c: CanvasItem, ctr: Vector2, R: float, fill: Color, line: Color, sd: int) -> void:
	var arr := []
	for i in 10:
		var rr := 1.0 if i % 2 == 0 else 0.42
		var a := -PI / 2.0 + i * PI / 5.0
		arr.append([cos(a) * rr * R, sin(a) * rr * R])
	_pl(c, ctr, 1.0, arr, fill, line, sd)

static func _suit(c: CanvasItem, p: Vector2, r: float, s: int, col: Color) -> void:
	match s:
		0:
			c.draw_circle(p + Vector2(-.5, .2) * r, r * .55, col)
			c.draw_circle(p + Vector2(.5, .2) * r, r * .55, col)
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-1, .15) * r, p + Vector2(1, .15) * r, p + Vector2(0, -1) * r]), col)
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-.12, .3) * r, p + Vector2(.12, .3) * r, p + Vector2(.35, 1) * r, p + Vector2(-.35, 1) * r]), col)
		1:
			c.draw_circle(p + Vector2(-.5, -.3) * r, r * .55, col)
			c.draw_circle(p + Vector2(.5, -.3) * r, r * .55, col)
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-1, -.05) * r, p + Vector2(1, -.05) * r, p + Vector2(0, 1) * r]), col)
		2:
			for d in [Vector2(0, -.5), Vector2(-.55, .2), Vector2(.55, .2)]: c.draw_circle(p + d * r, r * .45, col)
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-.12, .3) * r, p + Vector2(.12, .3) * r, p + Vector2(.35, 1) * r, p + Vector2(-.35, 1) * r]), col)
		_:
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -1) * r, p + Vector2(.7, 0) * r, p + Vector2(0, 1) * r, p + Vector2(-.7, 0) * r]), col)

# ---------- 星球 ----------
static func _planet(c: CanvasItem, id: String, ctr: Vector2, u: float, sd: int) -> void:
	var col: Color = PLANET_COL.get(id, Color.WHITE)
	var ringed := id == "saturn" or id == "uranus"
	var rad := u * (0.58 if ringed else 0.7)
	c.draw_circle(ctr, rad, col)
	c.draw_arc(ctr, rad * 0.84, -0.3, 1.7, 16, Color(0, 0, 0, 0.25), rad * 0.3, true)
	if id == "jupiter" or id == "saturn":
		for k in [-0.45, -0.12, 0.25]:
			var y: float = rad * k
			var hw := sqrt(maxf(rad * rad - y * y, 0.0)) * 0.92
			Sketch.line(c, ctr + Vector2(-hw, y), ctr + Vector2(hw, y), Color(0.55, 0.3, 0.2, 0.55), 2.0, sd + int(k * 10))
	elif id == "earth":
		c.draw_circle(ctr + Vector2(-rad * 0.3, -rad * 0.15), rad * 0.28, Color(0.35, 0.75, 0.4))
		c.draw_circle(ctr + Vector2(rad * 0.28, rad * 0.32), rad * 0.22, Color(0.35, 0.75, 0.4))
	elif id == "mars":
		c.draw_circle(ctr + Vector2(0, -rad * 0.84), rad * 0.17, Astral.CHALK)
	Sketch.stroke(c, Sketch.circle(ctr, rad, 28), Astral.CHALK, 2.0, sd)
	if ringed: Sketch.stroke(c, _ell(ctr, u * 0.98, u * 0.26, -0.35, 40), Color(Astral.GOLD, 0.9), 2.0, sd + 3)
	Sketch.star(c, ctr + Vector2(-u * 0.85, -u * 0.7), u * 0.1, Color(Astral.GOLD, 0.8), sd + 5)
	Sketch.star(c, ctr + Vector2(u * 0.85, u * 0.62), u * 0.08, Color(Astral.CHALK, 0.8), sd + 6)

# ---------- 塔罗 ----------
static func _tarot(c: CanvasItem, id: String, ctr: Vector2, u: float, bg: Color, sd: int) -> void:
	var G := Astral.GOLD
	var C := Astral.CHALK
	var K := Astral.INK
	match id:
		"sun":
			for i in 12:
				var d := Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0))
				_ln(c, ctr + d * u * 0.58, ctr + d * u * 0.95, G, sd + i)
			_ci(c, ctr, u * 0.46, G, C, sd)
			c.draw_circle(ctr + Vector2(-u * 0.15, -u * 0.08), u * 0.05, K)
			c.draw_circle(ctr + Vector2(u * 0.15, -u * 0.08), u * 0.05, K)
			c.draw_arc(ctr + Vector2(0, u * 0.05), u * 0.2, 0.3, PI - 0.3, 10, K, 2.0)
		"moon", "priestess":
			c.draw_circle(ctr + Vector2(0, -u * 0.05 if id == "moon" else -u * 0.2), u * (0.72 if id == "moon" else 0.5), C)
			c.draw_circle(ctr + Vector2(u * 0.3, -u * (0.15 if id == "moon" else 0.28)), u * (0.64 if id == "moon" else 0.44), bg)
			Sketch.star(c, ctr + Vector2(u * 0.55, -u * 0.5), u * 0.17, G, sd)
			if id == "priestess":
				_pl(c, ctr, u, [[-0.9, 0.85], [-0.9, -0.1], [-0.65, -0.1], [-0.65, 0.85]], C, K, sd)
				_pl(c, ctr, u, [[0.65, 0.85], [0.65, -0.1], [0.9, -0.1], [0.9, 0.85]], K.lightened(0.2), C, sd + 1)
		"star": _star5(c, ctr, u * 0.88, G, C, sd)
		"world":
			_ci(c, ctr, u * 0.7, Astral.TEAL.darkened(0.2), C, sd)
			Sketch.stroke(c, _ell(ctr, u * 0.3, u * 0.7, 0.0), Color(C, 0.8), 1.4, sd + 1)
			_ln(c, ctr + Vector2(-u * 0.7, 0), ctr + Vector2(u * 0.7, 0), Color(C, 0.8), sd + 2)
			for i in 12: c.draw_circle(ctr + Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0)) * u * 0.92, u * 0.07, Color(0.4, 0.8, 0.45))
		"tower":
			_pl(c, ctr, u, [[-0.3, 0.85], [-0.3, -0.35], [-0.4, -0.35], [-0.4, -0.6], [-0.22, -0.6], [-0.22, -0.45], [-0.08, -0.45], [-0.08, -0.6], [0.08, -0.6], [0.08, -0.45], [0.22, -0.45], [0.22, -0.6], [0.4, -0.6], [0.4, -0.35], [0.3, -0.35], [0.3, 0.85]], Color(0.62, 0.62, 0.74), C, sd)
			_ci(c, ctr + Vector2(0, u * 0.1), u * 0.09, K, Color(0, 0, 0, 0), sd)
			_pl(c, ctr, u, [[0.12, -0.98], [-0.08, -0.55], [0.1, -0.55], [-0.15, -0.05]], Color(0, 0, 0, 0), G, sd + 3, false)
		"wheel":
			_ci(c, ctr, u * 0.72, Color(0, 0, 0, 0), G, sd)
			for i in 8:
				var d := Vector2(cos(TAU * i / 8.0), sin(TAU * i / 8.0))
				_ln(c, ctr + d * u * 0.12, ctr + d * u * 0.72, C, sd + i)
			_ci(c, ctr, u * 0.14, G, C, sd + 9)
		"hiero":
			_ln(c, ctr + Vector2(0, -u * 0.9), ctr + Vector2(0, u * 0.9), G, sd)
			for k in 3: _ln(c, ctr + Vector2(-u * (0.3 + 0.15 * k), -u * 0.65 + u * 0.3 * k), ctr + Vector2(u * (0.3 + 0.15 * k), -u * 0.65 + u * 0.3 * k), G, sd + k + 1)
		"empress", "emperor":
			_pl(c, ctr, u, [[-0.7, 0.4], [-0.7, -0.3], [-0.35, 0.0], [0.0, -0.55], [0.35, 0.0], [0.7, -0.3], [0.7, 0.4]], G, C, sd)
			_ln(c, ctr + Vector2(-u * 0.7, u * 0.18), ctr + Vector2(u * 0.7, u * 0.18), C, sd + 2)
			for p in [Vector2(-0.7, -0.3), Vector2(0, -0.55), Vector2(0.7, -0.3)]: _ci(c, ctr + p * u, u * 0.09, Astral.CRIMSON, C, sd + 3)
			if id == "emperor": _ln(c, ctr + Vector2(u * 0.85, -u * 0.8), ctr + Vector2(u * 0.85, u * 0.85), G, sd + 4)
		"justice":
			_ln(c, ctr + Vector2(0, -u * 0.8), ctr + Vector2(0, u * 0.78), C, sd)
			_ln(c, ctr + Vector2(-u * 0.75, -u * 0.5), ctr + Vector2(u * 0.75, -u * 0.5), G, sd + 1)
			for sx in [-1.0, 1.0]:
				_ln(c, ctr + Vector2(sx * u * 0.75, -u * 0.5), ctr + Vector2(sx * u * 0.75, -u * 0.1), C, sd + 2)
				_pl(c, ctr, u, [[sx * 0.95, -0.1], [sx * 0.55, -0.1], [sx * 0.75, 0.2]], G, C, sd + 3)
		"strength":
			var arr := []
			for i in 40:
				var t := TAU * i / 40.0
				arr.append([cos(t) / (1.0 + sin(t) * sin(t)) * 0.9, sin(t) * cos(t) / (1.0 + sin(t) * sin(t)) * 0.9])
			_pl(c, ctr, u, arr, Color(0, 0, 0, 0), G, sd)
			_ci(c, ctr + Vector2(0, -u * 0.62), u * 0.17, Color(0, 0, 0, 0), C, sd + 1)
		"death":
			_ci(c, ctr + Vector2(0, -u * 0.12), u * 0.55, C, K, sd)
			_pl(c, ctr, u, [[-0.3, 0.36], [0.3, 0.36], [0.26, 0.75], [-0.26, 0.75]], C, K, sd + 1)
			for s in [-1.0, 1.0]: c.draw_circle(ctr + Vector2(s * u * 0.22, -u * 0.17), u * 0.14, K)
			_pl(c, ctr, u, [[-0.07, 0.05], [0.07, 0.05], [0.0, 0.2]], K, Color(0, 0, 0, 0), sd + 2)
			for k in 3: _ln(c, ctr + Vector2(u * (-0.12 + 0.12 * k), u * 0.4), ctr + Vector2(u * (-0.12 + 0.12 * k), u * 0.72), K, sd + k)
		"hanged":
			_ln(c, ctr + Vector2(0, -u * 0.95), ctr + Vector2(0, -u * 0.35), C, sd)
			_ln(c, ctr + Vector2(0, -u * 0.35), ctr + Vector2(0, u * 0.25), G, sd + 1)
			_ln(c, ctr + Vector2(0, -u * 0.1), ctr + Vector2(-u * 0.4, u * 0.2), G, sd + 2)
			_ln(c, ctr + Vector2(0, -u * 0.1), ctr + Vector2(u * 0.4, u * 0.2), G, sd + 3)
			_ci(c, ctr + Vector2(0, u * 0.45), u * 0.2, Color(0.98, 0.86, 0.72), C, sd + 4)
		"hermit":
			c.draw_arc(ctr + Vector2(0, -u * 0.45), u * 0.25, PI, TAU, 12, C, 2.0)
			_pl(c, ctr, u, [[-0.3, -0.35], [0.3, -0.35], [0.4, 0.6], [-0.4, 0.6]], K.lightened(0.15), G, sd)
			_ci(c, ctr + Vector2(0, u * 0.12), u * 0.17, G, C, sd + 1)
		"temper":
			_pl(c, ctr, u, [[-0.78, -0.45], [-0.25, -0.45], [-0.35, 0.05], [-0.68, 0.05]], Color(C, 0.55), C, sd)
			_pl(c, ctr, u, [[0.25, 0.4], [0.78, 0.4], [0.68, 0.85], [0.35, 0.85]], Color(C, 0.55), C, sd + 1)
			var w := []
			for i in 12: w.append([lerpf(-0.4, 0.5, i / 11.0), lerpf(0.05, 0.4, i / 11.0) + sin(i * 1.2) * 0.07])
			_pl(c, ctr, u, w, Color(0, 0, 0, 0), Astral.TEAL.lightened(0.2), sd + 2, false)
		"judgement":
			_pl(c, ctr, u, [[-0.85, 0.15], [-0.85, -0.05], [0.2, -0.45], [0.2, 0.55]], G, C, sd)
			for i in 5:
				var a := -0.5 + i * 0.25
				_ln(c, ctr + Vector2(u * 0.3, u * 0.05), ctr + Vector2(u * 0.3, u * 0.05) + Vector2(cos(a), sin(a)) * u * 0.6, Color(G, 0.8), sd + i)
			Sketch.stroke(c, _ell(ctr + Vector2(-u * 0.2, -u * 0.75), u * 0.35, u * 0.1, 0.0), G, 1.6, sd + 7)
		"chariot":
			_pl(c, ctr, u, [[-0.6, -0.3], [0.6, -0.3], [0.5, 0.3], [-0.5, 0.3]], Astral.VIOLET.lightened(0.2), C, sd)
			for s in [-1.0, 1.0]:
				_ci(c, ctr + Vector2(s * u * 0.42, u * 0.5), u * 0.22, K, C, sd + 1)
				_ln(c, ctr + Vector2(s * u * 0.42 - u * 0.22, u * 0.5), ctr + Vector2(s * u * 0.42 + u * 0.22, u * 0.5), C, sd + 2)
			_star5(c, ctr + Vector2(0, -u * 0.65), u * 0.24, G, C, sd + 3)
		"magician":
			_ln(c, ctr + Vector2(-u * 0.7, u * 0.8), ctr + Vector2(u * 0.5, -u * 0.55), C, sd)
			_star5(c, ctr + Vector2(u * 0.58, -u * 0.65), u * 0.25, G, C, sd + 1)
			var lem := []
			for i in 30:
				var t := TAU * i / 30.0
				lem.append([-0.45 + cos(t) / (1.0 + sin(t) * sin(t)) * 0.3, -0.45 + sin(t) * cos(t) / (1.0 + sin(t) * sin(t)) * 0.3])
			_pl(c, ctr, u, lem, Color(0, 0, 0, 0), G, sd + 2)
		_:
			_star5(c, ctr, u * 0.85, G, C, sd)

# ---------- 幻灵 ----------
static func _spectral(c: CanvasItem, id: String, ctr: Vector2, u: float, bg: Color, sd: int) -> void:
	var G := Astral.GOLD
	var C := Astral.CHALK
	var K := Astral.INK
	match id:
		"talisman", "deja", "trance", "medium":
			var col: Color = {"talisman": Color(1, 0.8, 0.2), "deja": Color(0.9, 0.2, 0.2), "trance": Color(0.3, 0.5, 1.0), "medium": Color(0.7, 0.3, 0.9)}[id]
			_pl(c, ctr, u, [[-0.25, 0.5], [-0.5, 0.98], [-0.1, 0.8]], col.darkened(0.2), C, sd)
			_pl(c, ctr, u, [[0.25, 0.5], [0.5, 0.98], [0.1, 0.8]], col.darkened(0.2), C, sd + 1)
			var arr := []
			for i in 24:
				var rr := 0.74 + (0.09 if i % 2 == 0 else 0.0)
				arr.append([cos(TAU * i / 24.0) * rr, sin(TAU * i / 24.0) * rr - 0.1])
			_pl(c, ctr, u, arr, col, C, sd + 2)
			_star5(c, ctr + Vector2(0, -u * 0.1), u * 0.38, Color(1, 1, 1, 0.35), C, sd + 3)
		"aura":
			var top := []
			var bot := []
			for i in 17:
				var x := lerpf(-0.92, 0.92, i / 16.0)
				top.append([x, -0.5 * sin(PI * i / 16.0)])
			for i in 17:
				var x := lerpf(0.92, -0.92, i / 16.0)
				bot.append([x, 0.5 * sin(PI * i / 16.0)])
			_pl(c, ctr, u, top + bot, C, K, sd)
			_ci(c, ctr, u * 0.3, Astral.TEAL, K, sd + 1)
			c.draw_circle(ctr, u * 0.13, K)
			for i in 5: _ln(c, ctr + Vector2(lerpf(-u * 0.6, u * 0.6, i / 4.0), -u * 0.62), ctr + Vector2(lerpf(-u * 0.8, u * 0.8, i / 4.0), -u * 0.9), Color(G, 0.8), sd + i)
		"familiar", "wraith", "soul":
			var arr := []
			for i in 11: arr.append([cos(PI + PI * i / 10.0) * 0.55, -0.15 + sin(PI + PI * i / 10.0) * 0.55])
			arr += [[0.55, 0.7], [0.35, 0.5], [0.18, 0.7], [0.0, 0.5], [-0.18, 0.7], [-0.35, 0.5], [-0.55, 0.7]]
			if id == "soul": _ci(c, ctr, u * 0.92, Color(G, 0.12), Color(G, 0.8), sd + 9)
			_pl(c, ctr, u, arr, Color(C, 0.92), K if id != "soul" else G, sd)
			for s in [-1.0, 1.0]: c.draw_circle(ctr + Vector2(s * u * 0.2, -u * 0.2), u * 0.08, K)
			c.draw_circle(ctr + Vector2(0, u * 0.05), u * 0.07, K)
		"grim": _tarot(c, "death", ctr, u, bg, sd)
		"incant":
			_pl(c, ctr, u, [[-0.65, 0.7], [-0.65, -0.7], [0.65, -0.7], [0.65, 0.7]], Astral.VIOLET.darkened(0.1), C, sd)
			_ln(c, ctr + Vector2(-u * 0.5, -u * 0.7), ctr + Vector2(-u * 0.5, u * 0.7), Color(C, 0.6), sd + 1)
			_star5(c, ctr + Vector2(u * 0.08, 0), u * 0.3, G, C, sd + 2)
		"immolate":
			_pl(c, ctr, u, [[0, -0.95], [0.3, -0.45], [0.55, 0.05], [0.45, 0.6], [0, 0.85], [-0.45, 0.6], [-0.55, 0.05], [-0.28, -0.4]], Color(1, 0.5, 0.15), C, sd)
			_pl(c, ctr, u, [[0, -0.3], [0.22, 0.1], [0.15, 0.5], [0, 0.62], [-0.15, 0.5], [-0.22, 0.1]], Color(1, 0.88, 0.35), Color(0, 0, 0, 0), sd + 1)
		"blackhole":
			for i in 4: Sketch.stroke(c, _ell(ctr, u * (0.95 - 0.18 * i), u * (0.38 - 0.07 * i), -0.4 + i * 0.5), C if i % 2 == 0 else Astral.VIOLET.lightened(0.2), 1.8, sd + i)
			c.draw_circle(ctr, u * 0.2, K)
		"ankh":
			Sketch.stroke(c, _ell(ctr + Vector2(0, -u * 0.5), u * 0.26, u * 0.36, 0.0), G, 2.2, sd)
			_ln(c, ctr + Vector2(0, -u * 0.14), ctr + Vector2(0, u * 0.9), G, sd + 1)
			_ln(c, ctr + Vector2(-u * 0.42, u * 0.08), ctr + Vector2(u * 0.42, u * 0.08), G, sd + 2)
		"hex":
			_ci(c, ctr, u * 0.88, Color(0, 0, 0, 0), Color(C, 0.8), sd)
			var pts := []
			for i in 5:
				var a := -PI / 2.0 + (i * 2 % 5) * TAU / 5.0
				pts.append([cos(a) * 0.88, sin(a) * 0.88])
			_pl(c, ctr, u, pts, Color(0, 0, 0, 0), Astral.CRIMSON.lightened(0.2), sd + 1)
		_:
			_star5(c, ctr, u * 0.85, G, C, sd)

# ---------- 小丑牌：小丑脸 + 专属徽记 ----------
static func _joker(c: CanvasItem, id: String, ctr: Vector2, u: float, sd: int) -> void:
	var rar := "common"
	if JokerManager.DEFS.has(id): rar = JokerManager.DEFS[id][1]
	var hc: Color = HAT_COL[id.hash() % 4]
	var fc := ctr + Vector2(-u * 0.1, u * 0.12)
	var k := u * 0.8
	if rar == "legendary":
		for i in 12:
			var d := Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0))
			_ln(c, ctr + d * u * 0.9, ctr + d * u * 1.05, Astral.GOLD, sd + i)
	_pl(c, fc, k, [[-0.55, -0.1], [-0.82, -0.75], [-0.25, -0.42], [0.0, -0.98], [0.25, -0.42], [0.82, -0.75], [0.55, -0.1]], hc, Astral.CHALK, sd)
	for p in [Vector2(-0.82, -0.75), Vector2(0.0, -0.98), Vector2(0.82, -0.75)]: _ci(c, fc + p * k, k * 0.12, Astral.GOLD, Astral.CHALK, sd + 1)
	_ci(c, fc + Vector2(0, k * 0.26), k * 0.52, Color(0.98, 0.86, 0.72), Astral.INK, sd + 2)
	_ln(c, fc + Vector2(-k * 0.56, -k * 0.08), fc + Vector2(k * 0.56, -k * 0.08), Astral.GOLD, sd + 3)
	for s in [-1.0, 1.0]:
		c.draw_circle(fc + Vector2(s * k * 0.19, k * 0.16), k * 0.06, Astral.INK)
		c.draw_circle(fc + Vector2(s * k * 0.32, k * 0.36), k * 0.09, Color(1, 0.55, 0.55, 0.5))
	match id.hash() % 3:
		0: c.draw_arc(fc + Vector2(0, k * 0.3), k * 0.2, 0.25, PI - 0.25, 10, Astral.INK, 2.0)
		1: c.draw_colored_polygon(PackedVector2Array([fc + Vector2(-k * 0.2, k * 0.36), fc + Vector2(k * 0.2, k * 0.36), fc + Vector2(0, k * 0.55)]), Astral.CRIMSON)
		_: c.draw_arc(fc + Vector2(k * 0.04, k * 0.34), k * 0.16, 0.2, PI - 0.6, 8, Astral.INK, 2.0)
	_emb(c, EMB.get(id, "star"), ctr + Vector2(u * 0.68, u * 0.58), u * 0.3, sd)

static func _emb(c: CanvasItem, kind: String, p: Vector2, s: float, sd: int) -> void:
	var G := Astral.GOLD
	var C := Astral.CHALK
	c.draw_circle(p, s * 1.25, Color(0, 0, 0, 0.35))
	match kind:
		"s0": _suit(c, p, s * 0.8, 0, Color(0.85, 0.88, 1.0))
		"s1": _suit(c, p, s * 0.8, 1, Astral.CRIMSON.lightened(0.15))
		"s2": _suit(c, p, s * 0.8, 2, Color(0.85, 0.88, 1.0))
		"s3": _suit(c, p, s * 0.8, 3, Astral.CRIMSON.lightened(0.15))
		"coin":
			_ci(c, p, s, G, C, sd)
			_star5(c, p, s * 0.55, Color(0.8, 0.6, 0.15), Color(0, 0, 0, 0), sd)
		"crown": _pl(c, p, s, [[-0.9, 0.6], [-0.9, -0.5], [-0.4, 0.0], [0.0, -0.8], [0.4, 0.0], [0.9, -0.5], [0.9, 0.6]], G, C, sd)
		"moon":
			c.draw_circle(p, s, C)
			c.draw_circle(p + Vector2(s * 0.4, -s * 0.15), s * 0.85, Color(0.12, 0.1, 0.2))
		"eye":
			_pl(c, p, s, [[-1, 0], [-0.5, -0.5], [0, -0.6], [0.5, -0.5], [1, 0], [0.5, 0.5], [0, 0.6], [-0.5, 0.5]], C, Astral.INK, sd)
			c.draw_circle(p, s * 0.3, Astral.TEAL)
			c.draw_circle(p, s * 0.13, Astral.INK)
		"cards":
			for i in 3: _pl(c, p + Vector2((i - 1) * s * 0.4, 0), s, [[-0.45, -0.8], [0.45, -0.8], [0.45, 0.8], [-0.45, 0.8]], Color(0.97, 0.93, 0.83), Astral.INK, sd + i)
		"burst":
			for i in 8:
				var d := Vector2(cos(TAU * i / 8.0), sin(TAU * i / 8.0))
				Sketch.line(c, p + d * s * 0.3, p + d * s * (1.0 if i % 2 == 0 else 0.7), G, 2.0, sd + i)
			c.draw_circle(p, s * 0.28, G)
		"flag":
			_ln(c, p + Vector2(-s * 0.6, s), p + Vector2(-s * 0.6, -s), C, sd)
			_pl(c, p, s, [[-0.6, -1.0], [0.9, -0.6], [-0.6, -0.1]], Astral.CRIMSON, C, sd + 1)
		"horns":
			c.draw_arc(p + Vector2(-s * 0.5, 0), s * 0.6, PI * 0.9, PI * 1.9, 10, C, 3.0)
			c.draw_arc(p + Vector2(s * 0.5, 0), s * 0.6, PI * 1.1, PI * 2.1, 10, C, 3.0)
		"cam":
			_pl(c, p, s, [[-1, -0.5], [1, -0.5], [1, 0.7], [-1, 0.7]], Color(0.4, 0.4, 0.5), C, sd)
			_ci(c, p + Vector2(0, s * 0.1), s * 0.38, Astral.INK, C, sd + 1)
		"book":
			_pl(c, p, s, [[-0.8, -0.8], [0.8, -0.8], [0.8, 0.8], [-0.8, 0.8]], Astral.VIOLET, C, sd)
			_ln(c, p + Vector2(-s * 0.5, -s * 0.8), p + Vector2(-s * 0.5, s * 0.8), C, sd + 1)
		_: _star5(c, p, s, G, C, sd)

# ---------- 卡包 / 优惠券 ----------
static func _pack(c: CanvasItem, id: String, ctr: Vector2, u: float, sd: int) -> void:
	var col: Color = ShopManager.PACKS[id][3].lightened(0.15) if ShopManager.PACKS.has(id) else Astral.TEAL
	_pl(c, ctr, u, [[-0.62, -0.9], [0.62, -0.9], [0.62, 0.9], [-0.62, 0.9]], col, Astral.CHALK, sd)
	for i in 8:
		_ln(c, ctr + Vector2(lerpf(-u * 0.62, u * 0.62, i / 8.0), -u * 0.9), ctr + Vector2(lerpf(-u * 0.62, u * 0.62, (i + 0.5) / 8.0), -u * 0.76), Astral.CHALK, sd + i)
		_ln(c, ctr + Vector2(lerpf(-u * 0.62, u * 0.62, i / 8.0), u * 0.9), ctr + Vector2(lerpf(-u * 0.62, u * 0.62, (i + 0.5) / 8.0), u * 0.76), Astral.CHALK, sd + 20 + i)
	var bg := col.darkened(0.3)
	match id:
		"celestial": _planet(c, "saturn", ctr, u * 0.55, sd)
		"arcana": _tarot(c, "star", ctr, u * 0.55, bg, sd)
		"spectral": _spectral(c, "wraith", ctr, u * 0.5, bg, sd)
		_: _joker(c, "joker", ctr, u * 0.5, sd)

static func _voucher(c: CanvasItem, ctr: Vector2, u: float, sd: int) -> void:
	_pl(c, ctr, u, [[-0.95, -0.55], [0.95, -0.55], [0.95, -0.15], [0.8, 0.0], [0.95, 0.15], [0.95, 0.55], [-0.95, 0.55], [-0.95, 0.15], [-0.8, 0.0], [-0.95, -0.15]], Astral.GOLD.darkened(0.15), Astral.CHALK, sd)
	_star5(c, ctr, u * 0.32, Astral.CHALK, Astral.INK, sd + 1)
