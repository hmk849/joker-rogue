class_name HandView
extends Control
# 手牌区：扇形排布、点击选牌(最多5张)、拖动排序（与 GameManager.hand 同步）、发牌动画。
signal selection_changed
var views: Array = []
var _drag: CardView = null
var _press: CardView = null
var _press_pos := Vector2.ZERO
var _dragging := false

func _ready() -> void:
	resized.connect(func(): layout(false))

func sync(cards: Array) -> void:
	var keep := []
	for v in views:
		if cards.any(func(c): return is_same(c, v.card)): keep.append(v)
		else: v.queue_free()
	views = keep
	var out := []
	var n_new := 0
	for c in cards:
		var found: CardView = null
		for x in views:
			if is_same(x.card, c):
				found = x
				break
		if found == null:
			found = CardView.make(c, UIManager.card_scale())
			add_child(found)
			found.position = Vector2(size.x, size.y)
			found.face_up = false
			found.deal_delay = AnimationManager.duration(0.06) * n_new
			n_new += 1
			var f := found
			get_tree().create_timer(f.deal_delay + 0.1).timeout.connect(func():
				if is_instance_valid(f): f.flip(true))
		found.update_material()
		found.queue_redraw()
		out.append(found)
	views = out
	layout(true)
	selection_changed.emit()

func detach(list: Array) -> void:  # 出牌/弃牌时把牌交给外部做动画
	for v in list:
		if v.tw: v.tw.kill()
		views.erase(v)
	if _drag in list: _drag = null
	layout(true)

func layout(animate: bool) -> void:
	var n := views.size()
	if n == 0: return
	var cw := CardView.W * UIManager.card_scale()
	var ch := CardView.H * UIManager.card_scale()
	var step := minf(cw + 10.0, (size.x - cw) / maxf(n - 1, 1))
	step = maxf(step, cw * 0.45)  # 极窄屏时牌会溢出两侧而不是彻底叠死
	var x0 := (size.x - (step * (n - 1) + cw)) * 0.5
	var mid := (n - 1) * 0.5
	for i in n:
		var v: CardView = views[i]
		if v == _drag: continue
		var off := (i - mid) / maxf(mid, 1.0)
		var pos := Vector2(x0 + step * i, size.y - ch - 8 + off * off * 14.0 - (28.0 if v.selected else 0.0))
		_move(v, pos, deg_to_rad(off * 4.0), animate)

func _move(v: CardView, pos: Vector2, rot: float, animate: bool) -> void:
	if v.tw: v.tw.kill()
	var d := AnimationManager.duration(0.2) if animate else 0.0
	if d <= 0.0:
		v.position = pos
		v.rotation = rot
		return
	v.tw = v.create_tween().set_parallel()
	v.tw.tween_property(v, "position", pos, d).set_delay(v.deal_delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	v.tw.tween_property(v, "rotation", rot, d).set_delay(v.deal_delay)
	v.deal_delay = 0.0

func selected_indices() -> Array:
	var out := []
	for i in views.size():
		if views[i].selected: out.append(i)
	return out

func clear_selection() -> void:
	for v in views:
		v.selected = false
		v.queue_redraw()
	layout(true)
	selection_changed.emit()

func _pick(pos: Vector2) -> CardView:
	for i in range(views.size() - 1, -1, -1):
		if Rect2(views[i].position, views[i].size).has_point(pos): return views[i]
	return null

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press = _pick(e.position)
			_press_pos = e.position
			_dragging = false
		else:
			_release()
	elif e is InputEventMouseMotion and _press != null:
		_motion(e.position)

func _motion(pos: Vector2) -> void:
	if not _dragging and bool(SettingsManager.get_value("drag_select")) and pos.distance_to(_press_pos) > 10.0 / maxf(float(SettingsManager.get_value("sensitivity")), 0.3):
		_dragging = true
		_drag = _press
		_drag.z_index = 10
		if _drag.tw: _drag.tw.kill()
	if not _dragging: return
	_drag.position = Vector2(pos.x - _drag.size.x / 2.0, clampf(pos.y - _drag.size.y / 2.0, -40.0, size.y - _drag.size.y))
	var i := views.find(_drag)
	var j := i
	while j > 0 and _drag.position.x < views[j - 1].position.x: j -= 1
	while j < views.size() - 1 and _drag.position.x > views[j + 1].position.x: j += 1
	if j != i:
		views.remove_at(i)
		views.insert(j, _drag)
		var c = GameManager.hand.pop_at(i)  # 同步手牌顺序
		GameManager.hand.insert(j, c)
		AudioManager.play("move")
		layout(true)

func _release() -> void:
	if _dragging:
		_drag.z_index = 0
		_drag = null
		layout(true)
	elif _press != null and bool(SettingsManager.get_value("tap_select")):
		if _press.selected or selected_indices().size() < 5:
			_press.selected = not _press.selected
			_press.queue_redraw()
			AudioManager.play("select")
			layout(true)
			selection_changed.emit()
	_press = null
	_dragging = false

func _draw() -> void:  # 手牌下方的黄铜导轨
	var y := size.y - 3.0
	draw_line(Vector2(40, y), Vector2(size.x - 40, y), Color(Astral.GOLD_DIM, 0.35), 2.0)
	Astral.diamond(self, Vector2(size.x / 2.0, y), 5.0, Color(Astral.GOLD, 0.7))
	Astral.diamond(self, Vector2(40, y), 3.0, Color(Astral.GOLD_DIM, 0.6))
	Astral.diamond(self, Vector2(size.x - 40, y), 3.0, Color(Astral.GOLD_DIM, 0.6))
