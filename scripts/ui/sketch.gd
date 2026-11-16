class_name Sketch
extends RefCounted
# 手绘笔触：固定种子的抖动折线（不会每帧闪烁）+ 双重描边模拟蜡笔/墨线
static func round_rect(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cs := [r.position + Vector2(rad, rad), Vector2(r.end.x - rad, r.position.y + rad), r.end - Vector2(rad, rad), Vector2(r.position.x + rad, r.end.y - rad)]
	for i in 4:
		for k in 6:
			var a := PI + i * PI / 2.0 + k * (PI / 2.0) / 5.0
			pts.append(cs[i] + Vector2(cos(a), sin(a)) * rad)
	return pts

static func circle(c: Vector2, rad: float, seg: int = 64) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg: pts.append(c + Vector2(cos(TAU * i / seg), sin(TAU * i / seg)) * rad)
	return pts

static func rough(pts: PackedVector2Array, amp: float, seed: int, closed: bool = true) -> PackedVector2Array:
	amp *= ThemeManager.jitter()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var out := PackedVector2Array()
	var n_pts := pts.size()
	for i in n_pts:
		if not closed and i == n_pts - 1: break
		var a := pts[i]
		var b := pts[(i + 1) % n_pts]
		var n := maxi(1, int(a.distance_to(b) / 22.0))
		for k in n: out.append(a.lerp(b, float(k) / n) + Vector2(rng.randf_range(-amp, amp), rng.randf_range(-amp, amp)))
	out.append(out[0] if closed else pts[n_pts - 1])
	return out

static func stroke(c: CanvasItem, pts: PackedVector2Array, col: Color, w: float, seed: int, closed: bool = true) -> void:
	c.draw_polyline(rough(pts, 1.3, seed, closed), col, w, true)
	if ThemeManager.jitter() > 0.5: c.draw_polyline(rough(pts, 1.8, seed + 977, closed), Color(col, col.a * 0.5), maxf(w * 0.55, 1.0), true)

static func line(c: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float, seed: int) -> void:
	stroke(c, PackedVector2Array([a, b]), col, w, seed, false)

static func star(c: CanvasItem, p: Vector2, r: float, col: Color, seed: int) -> void:  # 手画的小十字星
	line(c, p + Vector2(-r, 0), p + Vector2(r, 0), col, 1.6, seed)
	line(c, p + Vector2(0, -r), p + Vector2(0, r), col, 1.6, seed + 3)
	line(c, p + Vector2(-r, -r) * 0.5, p + Vector2(r, r) * 0.5, Color(col, col.a * 0.6), 1.0, seed + 5)
	line(c, p + Vector2(r, -r) * 0.5, p + Vector2(-r, r) * 0.5, Color(col, col.a * 0.6), 1.0, seed + 7)
