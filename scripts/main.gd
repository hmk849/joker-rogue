extends Control
# 正式横屏主界面：左(盲注/目标/得分) 中(出牌区+手牌) 右(牌型/筹码×倍率/金币/小丑牌栏)，顶部(底注/出牌/弃牌)。
const SafeBox := preload("res://scripts/ui/safe_area_container.gd")
const SafePage := preload("res://scripts/ui/safe_area_page.gd")
var L := {}
var cs := 1.0
var busy := false
var pending := false
var banner := ""
var shown_score := 0
var root_box: Control
var fx: Control
var play_area: Control
var hand_view: HandView
var play_btn: Button
var discard_btn: Button
var _t := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	cs = UIManager.card_scale()
	_setup_fx()
	_build()
	move_child(root_box, 1)
	move_child(fx, 2)
	GameManager.state_changed.connect(func():
		if busy: pending = true
		else: _refresh())
	GameManager.blind_cleared.connect(func(r): banner = "盲注通过！ +$%d" % r)
	if not GameManager.load_run(): _deck_select()

# ---------- 特效层：Shader 背景 / 色彩与高对比后处理 / 设置联动 ----------
var bg_mat: ShaderMaterial
var post_layer: CanvasLayer
var post_mat: ShaderMaterial
var _rebuild_timer: Timer
var _end_shown := false

func _setup_fx() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_mat = ShaderMaterial.new()
	bg_mat.shader = FxShaders.shader("bg")
	bg.material = bg_mat
	add_child(bg)
	post_layer = CanvasLayer.new()
	post_layer.layer = 100
	var pr := ColorRect.new()
	pr.set_anchors_preset(Control.PRESET_FULL_RECT)
	pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_mat = ShaderMaterial.new()
	post_mat.shader = FxShaders.shader("post")
	pr.material = post_mat
	post_layer.add_child(pr)
	add_child(post_layer)
	_rebuild_timer = Timer.new()
	_rebuild_timer.one_shot = true
	_rebuild_timer.wait_time = 0.35
	_rebuild_timer.timeout.connect(_rebuild_ui)
	add_child(_rebuild_timer)
	SettingsManager.changed.connect(_on_setting)
	_bg_update()
	_post_update()

func _bg_update() -> void:
	bg_mat.set_shader_parameter("speed", 1.0 if bool(SettingsManager.get_value("bg_effects")) else 0.0)
	bg_mat.set_shader_parameter("detail", [1, 2, 3, 5][clampi(int(SettingsManager.get_value("quality")), 0, 3)])

func _post_update() -> void:
	var cm := int(SettingsManager.get_value("color_mode"))
	var hc := bool(SettingsManager.get_value("high_contrast"))
	var q := int(SettingsManager.get_value("quality"))
	post_mat.set_shader_parameter("color_mode", cm)
	post_mat.set_shader_parameter("contrast", 1.25 if hc else 1.0)
	post_mat.set_shader_parameter("vignette", 0.6 if q >= 3 else 0.0)
	post_mat.set_shader_parameter("scan", 0.03 if q >= 3 else 0.0)
	post_layer.visible = cm != 0 or hc or q >= 3  # 默认关闭，避免不必要的整屏拷贝

func _on_setting(key: String) -> void:
	if key in ["bg_effects", "quality"]: _bg_update()
	if key in ["color_mode", "high_contrast", "quality"]: _post_update()
	if key in ["ui_scale", "card_size", "font_size", "ui_spacing", "layout_flipped", "info_density"]: _rebuild_timer.start()

func _rebuild_ui() -> void:
	if busy:
		_rebuild_timer.start()
		return
	cs = UIManager.card_scale()
	for n in [root_box, fx]:
		remove_child(n)
		n.queue_free()
	_build()
	move_child(root_box, 1)
	move_child(fx, 2)
	_refresh()

func _open_settings() -> void:
	if busy or get_node_or_null("SettingsPage"): return
	var p := SettingsPage.new()
	p.name = "SettingsPage"
	add_child(p)
	p.closed.connect(func():
		remove_child(p)
		p.queue_free())

func _idle(b: Control) -> void:  # 小丑牌独立的待机摆动
	if not bool(SettingsManager.get_value("animations")): return
	b.pivot_offset = Vector2(50, 35)
	var t := b.create_tween().set_loops()
	t.tween_interval(randf() * 0.8)
	t.tween_property(b, "rotation", deg_to_rad(2.0), 1.2).set_trans(Tween.TRANS_SINE)
	t.tween_property(b, "rotation", deg_to_rad(-2.0), 2.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(b, "rotation", 0.0, 1.2).set_trans(Tween.TRANS_SINE)

# ---------- 构建 ----------
func _build() -> void:
	var sp := UIManager.spacing()
	var safe := SafeBox.new()
	add_child(safe)
	root_box = safe
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", sp)
	safe.add_child(col)
	var top := UIStyle.panel(Color(0.1, 0.13, 0.18, 0.95))
	col.add_child(top)
	var tr := HBoxContainer.new()
	tr.add_theme_constant_override("separation", 48)
	top.add_child(tr)
	for k in ["ante", "hands", "discards"]:
		L[k] = UIStyle.label("", 24)
		tr.add_child(L[k])
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", sp)
	col.add_child(body)
	var parts := [_left(), _center(), _right()]
	if bool(SettingsManager.get_value("layout_flipped")): parts.reverse()
	for p in parts: body.add_child(p)
	fx = Control.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fx)

func _left() -> Control:
	var p := UIStyle.panel(Color(0.11, 0.14, 0.2, 0.96))
	p.custom_minimum_size.x = 250
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	L["blind"] = UIStyle.label("", 30, Color(1, 0.8, 0.3))
	L["target"] = UIStyle.label("", 40)
	L["boss"] = UIStyle.label("", 16, Color(1, 0.55, 0.5))
	L["boss"].autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	L["boss"].custom_minimum_size.x = 220
	L["reward"] = UIStyle.label("", 20, Color(1, 0.85, 0.3))
	L["score"] = UIStyle.label("0", 44, Astral.TEAL.lightened(0.35))
	v.add_child(L["blind"])
	v.add_child(L["boss"])
	v.add_child(Astral.divider(210))
	v.add_child(UIStyle.label("目标分数", 18, Astral.GOLD_DIM))
	v.add_child(L["target"])
	v.add_child(L["reward"])
	v.add_child(UIStyle.label("本盲注得分", 18, Astral.GOLD_DIM))
	v.add_child(L["score"])
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var b1 := UIStyle.button("按点数排序", Color(0.25, 0.35, 0.55), 44)
	var b2 := UIStyle.button("按花色排序", Color(0.25, 0.35, 0.55), 44)
	var b3 := UIStyle.button("安全区调节", Color(0.3, 0.3, 0.38), 44)
	var b4 := UIStyle.button("新游戏", Color(0.45, 0.25, 0.25), 44)
	b1.pressed.connect(func(): _sort(1))
	b2.pressed.connect(func(): _sort(2))
	b3.pressed.connect(_open_safe)
	b4.pressed.connect(_deck_select)
	var b5 := UIStyle.button("设置", Color(0.3, 0.3, 0.38), 44)
	b5.pressed.connect(_open_settings)
	for b in [b1, b2, b5, b3, b4]: v.add_child(b)
	return p

func _right() -> Control:
	var p := UIStyle.panel(Color(0.11, 0.14, 0.2, 0.96))
	p.custom_minimum_size.x = 250
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	L["type"] = UIStyle.label("", 24, Color(1, 0.9, 0.5))
	v.add_child(L["type"])
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(hb)
	var cp := UIStyle.panel(Astral.TEAL.darkened(0.5), Astral.TEAL)
	var mp := UIStyle.panel(Astral.CRIMSON.darkened(0.5), Astral.CRIMSON)
	L["chips"] = UIStyle.label("0", 32)
	L["mult"] = UIStyle.label("0", 32)
	cp.add_child(L["chips"])
	mp.add_child(L["mult"])
	hb.add_child(cp)
	hb.add_child(UIStyle.label(" × ", 28))
	hb.add_child(mp)
	L["money"] = UIStyle.label("", 34, Color(1, 0.85, 0.3))
	v.add_child(L["money"])
	v.add_child(UIStyle.label("小丑牌", 18, Astral.GOLD_DIM))
	var g := GridContainer.new()
	g.columns = 2
	v.add_child(g)
	L["jokers"] = g
	v.add_child(UIStyle.label("消耗牌（点击使用）", 18, Astral.GOLD_DIM))
	var g2 := GridContainer.new()
	g2.columns = 2
	v.add_child(g2)
	L["cons"] = g2
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	L["deck"] = UIStyle.label("", 20, Astral.GOLD_DIM)
	v.add_child(L["deck"])
	return p

func _center() -> Control:
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_theme_constant_override("separation", UIManager.spacing())
	play_area = Control.new()
	play_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_area.custom_minimum_size.y = 150
	play_area.draw.connect(func(): Astral.draw_sigil(play_area, play_area.size / 2.0, minf(play_area.size.x, play_area.size.y) * 0.48))
	c.add_child(play_area)
	hand_view = HandView.new()
	hand_view.custom_minimum_size.y = CardView.H * cs + 56
	hand_view.selection_changed.connect(_on_sel)
	c.add_child(hand_view)
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 24)
	c.add_child(bar)
	play_btn = UIStyle.button("出牌", Color(0.15, 0.55, 0.3))
	discard_btn = UIStyle.button("弃牌", Color(0.7, 0.25, 0.25))
	play_btn.pressed.connect(_do_play)
	discard_btn.pressed.connect(_do_discard)
	bar.add_child(play_btn)
	bar.add_child(discard_btn)
	return c

# ---------- 刷新 ----------
func _refresh() -> void:
	var g := GameManager
	L["ante"].text = "底注 %d / 8" % BlindManager.ante
	L["hands"].text = "出牌 %d" % g.hands_left
	L["discards"].text = "弃牌 %d" % g.discards_left
	L["blind"].text = BlindManager.blind_name()
	L["target"].text = str(BlindManager.target())
	L["boss"].text = BlindManager.desc()
	L["boss"].visible = L["boss"].text != ""
	L["reward"].text = "奖励 " + "$".repeat(BlindManager.reward())
	shown_score = g.round_score
	L["score"].text = str(shown_score)
	L["money"].text = "$ %d" % g.money
	L["deck"].text = "牌堆 %d / %d" % [DeckManager.draw_pile.size(), DeckManager.draw_pile.size() + DeckManager.discard_pile.size() + g.hand.size()]
	var dens := int(SettingsManager.get_value("info_density"))
	L["reward"].visible = dens >= 1
	L["deck"].visible = dens >= 1
	if dens >= 2: L["deck"].text += "\n上次牌型 %s Lv.%d" % [g.last_type, ScoreManager.levels[g.last_type]]
	hand_view.sync(g.hand)
	_side()
	_shop_overlay()
	_end_overlay()

func _on_sel() -> void:
	if busy: return
	var g := GameManager
	var idx := hand_view.selected_indices()
	var live: bool = g.phase == "playing"
	play_btn.disabled = idx.is_empty() or not live
	discard_btn.disabled = idx.is_empty() or not live or g.discards_left <= 0
	if idx.is_empty():
		L["type"].text = ""
		_set_cm(0, 0)
		return
	var cards := []
	for i in idx: cards.append(g.hand[i])
	var t: String = CardManager.evaluate(cards)["type"]
	var b: Array = ScoreManager.BASE[t]
	var lv: int = ScoreManager.levels[t]
	L["type"].text = "%s Lv.%d" % [t, lv]
	_set_cm(b[0] + b[2] * (lv - 1), b[1] + b[3] * (lv - 1))

func _set_cm(chips: float, mult: float) -> void:
	L["chips"].text = str(int(chips))
	L["mult"].text = str(snappedf(mult, 0.1)).trim_suffix(".0")

func _sort(mode: int) -> void:
	if busy: return
	CardManager.sort_hand(GameManager.hand, mode)
	hand_view.sync(GameManager.hand)

func _set_busy(b: bool) -> void:
	busy = b
	hand_view.mouse_filter = Control.MOUSE_FILTER_IGNORE if b else Control.MOUSE_FILTER_STOP
	if b:
		play_btn.disabled = true
		discard_btn.disabled = true

# ---------- 出牌 / 弃牌 ----------
func _grab(idx: Array) -> Array:  # 取出选中的牌视图并移到特效层
	var views := []
	for i in idx: views.append(hand_view.views[i])
	hand_view.detach(views)
	for v in views:
		var gp: Vector2 = v.global_position
		v.get_parent().remove_child(v)
		fx.add_child(v)
		v.global_position = gp
	return views

func _do_play() -> void:
	var idx := hand_view.selected_indices()
	if busy or idx.is_empty() or GameManager.phase != "playing": return
	_set_busy(true)
	var res := GameManager.play(idx)
	if res.is_empty():
		_set_busy(false)
		return
	# play() 已在逻辑层更新；视图在动画结束后再同步（busy 期间 state_changed 只记 pending）
	AudioManager.play("play")
	var views := _grab(idx)
	await _animate_score(views, res)
	if banner != "":
		AudioManager.play("coin")
		await _flash(banner)
		banner = ""
	_set_busy(false)
	pending = false
	_refresh()

func _do_discard() -> void:
	var idx := hand_view.selected_indices()
	if busy or idx.is_empty() or GameManager.phase != "playing" or GameManager.discards_left <= 0: return
	_set_busy(true)
	AudioManager.play("discard")
	var views := _grab(idx)
	GameManager.discard(idx)
	var d := AnimationManager.duration(0.3)
	for v in views:
		var tw := create_tween().set_parallel()
		tw.tween_property(v, "position:y", v.position.y + 320.0, d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(v, "modulate:a", 0.0, d)
	await _wait(0.35)
	for v in views: v.queue_free()
	_set_busy(false)
	pending = false
	_refresh()

# ---------- 计分动画 ----------
func _wait(t: float) -> void:
	await get_tree().create_timer(AnimationManager.duration(t)).timeout

func _animate_score(views: Array, res: Dictionary) -> void:
	var cw := CardView.W * cs
	var ch := CardView.H * cs
	var area := play_area.get_global_rect()
	var n := views.size()
	var x0 := area.position.x + (area.size.x - (n * cw + (n - 1) * 12.0)) * 0.5
	var y0 := area.position.y + (area.size.y - ch) * 0.5
	var d := AnimationManager.duration(0.3)
	for i in n:
		var tw := create_tween().set_parallel()
		tw.tween_property(views[i], "global_position", Vector2(x0 + i * (cw + 12.0), y0), d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(views[i], "rotation", 0.0, d)
	await _wait(0.4)
	L["type"].text = "%s Lv.%d" % [res["type"], res["level"]]
	_set_cm(res["start_chips"], res["start_mult"])
	await _wait(0.3)
	var si := 0
	for st in res["steps"]:
		si += 1
		AudioManager.play("combo" if st["card"] != null else "joker", minf(1.0 + 0.05 * si, 2.0))
		_set_cm(st["chips"], st["mult"])
		if st["card"] != null:
			for v in views:
				if is_same(v.card, st["card"]): _pop(v)
		elif st["joker"] < L["jokers"].get_child_count():
			_bump(L["jokers"].get_child(st["joker"]))
		_bump(L["chips"])
		_bump(L["mult"])
		await _wait(0.28)
	_set_cm(res["chips"], res["mult"])
	await _wait(0.25)
	_burst(area.get_center(), Color(1, 0.82, 0.3))
	AudioManager.play("score")
	await _roll(L["score"], shown_score, shown_score + int(res["total"]), 0.7)
	_shake(clampf(float(res["total"]) / 150.0, 2.0, 10.0))
	await _wait(0.5)
	for v in views: v.queue_free()

func _pop(v: Control) -> void:
	var t := create_tween()
	t.tween_property(v, "scale", Vector2(1.15, 1.15), 0.08)
	t.tween_property(v, "scale", Vector2.ONE, 0.12)

func _bump(c: Control) -> void:
	c.pivot_offset = c.size / 2.0
	var t := create_tween()
	t.tween_property(c, "scale", Vector2(1.3, 1.3), 0.06)
	t.tween_property(c, "scale", Vector2.ONE, 0.1)

func _roll(lbl: Label, from: int, to: int, dur: float) -> void:
	var d := AnimationManager.duration(dur)
	if d <= 0.0:
		lbl.text = str(to)
		return
	var t := create_tween()
	t.tween_method(func(v: float): lbl.text = str(int(v)), float(from), float(to), d).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished

func _burst(pos: Vector2, col: Color) -> void:
	if not bool(SettingsManager.get_value("particles")): return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 40
	p.lifetime = 0.8
	p.spread = 180.0
	p.initial_velocity_min = 150.0
	p.initial_velocity_max = 420.0
	p.gravity = Vector2(0, 600)
	p.texture = Astral.star_texture()
	p.angle_max = 180.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	p.color = col
	fx.add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(1.3).timeout.connect(p.queue_free)

func _shake(amount: float) -> void:
	if not bool(SettingsManager.get_value("screen_shake")) or not bool(SettingsManager.get_value("animations")): return
	var t := create_tween()
	for i in 6: t.tween_property(root_box, "position", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * amount, 0.03)
	t.tween_property(root_box, "position", Vector2.ZERO, 0.05)

func _flash(text: String) -> void:
	var l := UIStyle.label(text, 44, Color(1, 0.9, 0.4))
	fx.add_child(l)
	l.size = l.get_minimum_size()
	l.position = play_area.get_global_rect().get_center() - l.size / 2.0
	var d := AnimationManager.duration(1.0)
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:y", l.position.y - 60.0, d)
	t.tween_property(l, "modulate:a", 0.0, d).set_delay(d * 0.5)
	await _wait(1.0)
	l.queue_free()

# ---------- 结算 / 页面 ----------
func _end_overlay() -> void:
	var old := get_node_or_null("EndOverlay")
	if old:
		remove_child(old)
		old.queue_free()
	if GameManager.phase == "playing":
		_end_shown = false
		return
	var c := CenterContainer.new()
	c.name = "EndOverlay"
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bgc := ColorRect.new()
	bgc.color = Color(0, 0, 0, 0.7)
	bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	var p := UIStyle.panel(Color(0.1, 0.13, 0.18), Color(1, 0.8, 0.3))
	var v := VBoxContainer.new()
	p.add_child(v)
	var won: bool = GameManager.phase == "won"
	if not _end_shown:
		_end_shown = true
		AudioManager.play("win" if won else "lose")
		if won:
			for i in 4: _burst(Vector2(randf_range(0.2, 0.8) * size.x, randf_range(0.2, 0.6) * size.y), Color.from_hsv(randf(), 0.7, 1.0))
		else:
			_shake(10.0)
	v.add_child(UIStyle.label("通关！" if won else "挑战失败", 56, Color(1, 0.85, 0.3) if won else Color(1, 0.4, 0.4)))
	var again := UIStyle.button("再来一局", Color(0.15, 0.55, 0.3))
	again.pressed.connect(_deck_select)
	v.add_child(again)
	c.add_child(p)
	add_child(bgc)
	bgc.name = "EndOverlayBg"
	add_child(c)
	c.tree_exiting.connect(func(): if is_instance_valid(bgc): bgc.queue_free())

func _open_safe() -> void:
	if busy: return
	var p := SafePage.new()
	add_child(p)
	p.closed.connect(p.queue_free)

# ---------- 右侧栏：小丑牌 / 消耗牌 ----------
func _side() -> void:
	for k in ["jokers", "cons"]:
		for c in L[k].get_children():
			L[k].remove_child(c)
			c.queue_free()
	for j in JokerManager.owned:
		var b := ItemView.make({"kind": "joker", "id": j["id"], "ed": j["ed"]}, Vector2(100, 70))
		var info := ShopManager.info("joker", j["id"])
		b.pressed.connect(func(): _toast("%s：%s" % [info["n"], info["d"]]))
		L["jokers"].add_child(b)
		_idle(b)
	for i in ConsumableManager.owned.size():
		var b := ItemView.make(ConsumableManager.owned[i], Vector2(100, 70))
		b.pressed.connect(func(): _use_cons(i))
		L["cons"].add_child(b)

func _use_cons(i: int) -> void:
	if busy: return
	var m := ConsumableManager.use(i, hand_view.selected_indices())
	_toast(m if m != "" else "已使用")

func _toast(text: String) -> void:
	var l := UIStyle.label(text, 24, Color(1, 0.95, 0.7))
	fx.add_child(l)
	l.size = l.get_minimum_size()
	l.position = Vector2((size.x - l.size.x) * 0.5, size.y * 0.72)
	var t := create_tween()
	t.tween_interval(AnimationManager.duration(1.2) + 0.6)
	t.tween_property(l, "modulate:a", 0.0, 0.4)
	t.tween_callback(l.queue_free)

# ---------- 商店 / 牌组选择 ----------
func _shop_overlay() -> void:
	var old := get_node_or_null("ShopOverlay")
	if GameManager.phase == "shop":
		if old == null:
			var sv := ShopView.new()
			sv.name = "ShopOverlay"
			add_child(sv)
	elif old:
		remove_child(old)
		old.queue_free()

func _deck_select() -> void:
	if busy or get_node_or_null("DeckSelect"): return
	var ov := Control.new()
	ov.name = "DeckSelect"
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.08, 0.86)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(bg)
	var safe := SafeBox.new()
	ov.add_child(safe)
	var cc := CenterContainer.new()
	safe.add_child(cc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	cc.add_child(v)
	v.add_child(UIStyle.label("选择牌组", 40, Astral.GOLD))
	v.add_child(Astral.divider(360))
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	v.add_child(g)
	var st: Dictionary = SaveManager.profile["stats"]
	for id in GameManager.DECK_ORDER:
		var d: Array = GameManager.DECKS[id]
		var locked: bool = d[2] != "" and int(st.get(d[2], 0)) < int(d[3])
		if not locked and d[2] != "": SaveManager.unlock(id)
		var b := UIStyle.button("%s\n%s" % [d[0], d[4] if locked else d[1]], Color(0.2, 0.3, 0.5), 90)
		b.custom_minimum_size = Vector2(240, 90)
		b.disabled = locked
		b.pressed.connect(func():
			remove_child(ov)
			ov.queue_free()
			GameManager.start_run(id))
		g.add_child(b)
	add_child(ov)
