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
	var scr := Vector2(DisplayServer.screen_get_size())
	var win := Vector2(DisplayServer.window_get_size())
	var sa := Rect2(DisplayServer.get_display_safe_area())
	if scr.x <= 0 or win.x <= 0 or sa.size.x <= 0: return out
	var k := get_viewport().get_visible_rect().size / win
	out["left"] = maxf(CORNER_MIN, sa.position.x * k.x)
	out["top"] = maxf(CORNER_MIN, sa.position.y * k.y)
	out["right"] = maxf(CORNER_MIN, (scr.x - sa.end.x) * k.x)
	out["bottom"] = maxf(CORNER_MIN, (scr.y - sa.end.y) * k.y)
	return out

func effective() -> Dictionary:
	return values.duplicate() if manual else system_insets()

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
