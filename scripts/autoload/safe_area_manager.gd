extends Node
# 安全区：系统值(刘海/灵动岛/圆角) + 用户手动调整。UI 根容器读取 effective() 真正改变可用布局。
signal changed
const PATH := "user://safe_area.json"
const CORNER_MIN := 12.0
const SIDES := ["left", "right", "top", "bottom"]
var manual := false
var values := {"left": 0.0, "right": 0.0, "top": 0.0, "bottom": 0.0}

func _ready() -> void:
	var d := SaveManager.read_json(PATH)
	manual = bool(d.get("manual", false))
	var v: Dictionary = d.get("values", {})
	for k in SIDES: values[k] = float(v.get(k, 0.0))
	get_tree().root.size_changed.connect(func(): changed.emit())  # 左右横屏切换时刷新

func system_insets() -> Dictionary:
	var out := {"left": CORNER_MIN, "right": CORNER_MIN, "top": CORNER_MIN, "bottom": CORNER_MIN}
	var vp := get_viewport().get_visible_rect().size
	var scr := Vector2(DisplayServer.screen_get_size())
	var sa := Rect2(DisplayServer.get_display_safe_area())
	if scr.x <= 0 or scr.y <= 0 or sa.size.x <= 0 or sa.size.y <= 0: return out
	var k := vp / scr  # 屏幕像素 -> 视口单位
	var l := sa.position.x * k.x
	var r := (scr.x - sa.end.x) * k.x
	var t := sa.position.y * k.y
	var b := (scr.y - sa.end.y) * k.y
	# 合理性校验：某些设备/横屏方向下系统返回的右(或左)边距会异常巨大，
	# 真实的刘海/灵动岛边距不会超过屏幕宽度的 9%。异常侧改用对侧的值（刘海机左右对称）。
	var max_x := vp.x * 0.09
	var max_y := vp.y * 0.12
	var lv := l <= max_x
	var rv := r <= max_x
	if lv and not rv: r = l
	elif rv and not lv: l = r
	elif not lv and not rv:
		l = vp.x * 0.05 if OS.get_name() == "iOS" else 0.0
		r = l
	if t > max_y: t = 0.0
	if b > max_y: b = 0.0
	out["left"] = maxf(CORNER_MIN, l)
	out["right"] = maxf(CORNER_MIN, r)
	out["top"] = maxf(CORNER_MIN, t)
	out["bottom"] = maxf(CORNER_MIN, b)
	return out

func effective() -> Dictionary:
	var e: Dictionary = values.duplicate() if manual else system_insets()
	var vp := get_viewport().get_visible_rect().size
	e["left"] = clampf(e["left"], 0.0, vp.x * 0.25)  # 兜底：任何情况下都不允许吞掉半个屏幕
	e["right"] = clampf(e["right"], 0.0, vp.x * 0.25)
	e["top"] = clampf(e["top"], 0.0, vp.y * 0.25)
	e["bottom"] = clampf(e["bottom"], 0.0, vp.y * 0.25)
	return e

func usable_rect() -> Rect2:
	var e := effective()
	var vp := get_viewport().get_visible_rect().size
	return Rect2(e["left"], e["top"], vp.x - e["left"] - e["right"], vp.y - e["top"] - e["bottom"])

func set_inset(side: String, v: float) -> void:
	if not manual:
		values = system_insets()
		manual = true
	values[side] = clampf(v, 0.0, 160.0)
	save()
	changed.emit()

func reset_defaults() -> void:
	manual = false
	for k in SIDES: values[k] = 0.0
	save()
	changed.emit()

func save() -> void: SaveManager.write_json(PATH, {"manual": manual, "values": values})
