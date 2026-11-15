extends Control
# 安全区调节页：四方向滑块 + 数值输入 + 实时预览 + 恢复默认 + 保存
signal closed
const SIDES := [["left", "左"], ["right", "右"], ["top", "上"], ["bottom", "下"]]
var sliders := {}
var spins := {}
var _sync := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var safe := preload("res://scripts/ui/safe_area_container.gd").new()
	add_child(safe)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	safe.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "安全区调节（红色=不可用区域）"
	box.add_child(title)
	for s in SIDES:
		var row := HBoxContainer.new()
		box.add_child(row)
		var lb := Label.new()
		lb.text = s[1]
		lb.custom_minimum_size.x = 30
		row.add_child(lb)
		var sl := HSlider.new()
		sl.max_value = 160
		sl.step = 1
		sl.custom_minimum_size = Vector2(320, 30)
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sp := SpinBox.new()
		sp.max_value = 160
		sp.step = 1
		row.add_child(sl)
		row.add_child(sp)
		sliders[s[0]] = sl
		spins[s[0]] = sp
		sl.value_changed.connect(_on_value.bind(s[0]))
		sp.value_changed.connect(_on_value.bind(s[0]))
	var bar := HBoxContainer.new()
	box.add_child(bar)
	var reset := Button.new()
	reset.text = "恢复默认"
	reset.pressed.connect(SafeAreaManager.reset_defaults)
	var ok := Button.new()
	ok.text = "保存并返回"
	ok.pressed.connect(func():
		SafeAreaManager.save()
		closed.emit())
	bar.add_child(reset)
	bar.add_child(ok)
	SafeAreaManager.changed.connect(_refresh)
	_refresh()

func _on_value(v: float, side: String) -> void:
	if not _sync: SafeAreaManager.set_inset(side, v)

func _refresh() -> void:
	_sync = true
	var e := SafeAreaManager.effective()
	for k in sliders:
		sliders[k].value = e[k]
		spins[k].value = e[k]
	_sync = false
	queue_redraw()

func _draw() -> void:
	var r := SafeAreaManager.usable_rect()
	var red := Color(1, 0.15, 0.15, 0.35)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(0, 0, size.x, r.position.y), red)
	draw_rect(Rect2(0, r.end.y, size.x, size.y - r.end.y), red)
	draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), red)
	draw_rect(Rect2(r.end.x, r.position.y, size.x - r.end.x, r.size.y), red)
	draw_rect(r, Color(0.3, 1, 0.4), false, 3.0)
