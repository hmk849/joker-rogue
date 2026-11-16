class_name TitleScreen
extends Control
# 开始界面：流动手绘背景 + 涂鸦 + 摇晃的扇形手牌（正中一张带多彩闪光）+ 大标题 + 菜单按钮
signal start_new
signal continue_run
signal open_settings
const SafeBox := preload("res://scripts/ui/safe_area_container.gd")
var has_save := false
var fan: Array = []
var fan_area: Control
var title: Label
var _t := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = FxShaders.shader("bg")
	m.set_shader_parameter("detail", 4)
	bg.material = m
	add_child(bg)
	add_child(BgDoodles.new())
	var safe := SafeBox.new()
	add_child(safe)
	var hb := HBoxContainer.new()
	safe.add_child(hb)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 14)
	hb.add_child(left)
	title = UIStyle.label("小丑肉鸽", 120, Astral.CHALK)
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_outline_color", Astral.INK)
	left.add_child(title)
	left.add_child(UIStyle.label("J O K E R   R O G U E", 28, Astral.GOLD))
	left.add_child(Astral.divider(440))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	left.add_child(col)
	if has_save: col.add_child(_btn("继续游戏", Color(0.2, 0.55, 0.35), func(): continue_run.emit()))
	col.add_child(_btn("开始游戏", Color(0.2, 0.45, 0.85), func(): start_new.emit()))
	col.add_child(_btn("设置", Color(0.3, 0.3, 0.38), func(): open_settings.emit()))
	if OS.get_name() != "iOS": col.add_child(_btn("退出", Color(0.55, 0.25, 0.25), func(): get_tree().quit()))
	left.add_child(UIStyle.label("夜之手账 · 单机肉鸽卡牌", 16, Astral.GOLD_DIM))
	fan_area = Control.new()
	fan_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(fan_area)
	for d in [[14, 0], [13, 1], [11, 2], [10, 0], [12, 3]]:
		var card := CardManager.make_card(d[0], d[1])
		if d[0] == 12: card["ed"] = "poly"
		var v := CardView.make(card, 1.5)
		fan_area.add_child(v)
		fan.append(v)
	if not AnimationManager.duration(1.0) > 0.0: return
	title.pivot_offset = Vector2(120, 70)
	var tw := title.create_tween().set_loops()
	tw.tween_property(title, "rotation", deg_to_rad(1.4), 2.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(title, "rotation", deg_to_rad(-1.4), 4.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(title, "rotation", 0.0, 2.2).set_trans(Tween.TRANS_SINE)

func _btn(text: String, col: Color, cb: Callable) -> Button:
	var b := UIStyle.button(text, col, 58)
	b.custom_minimum_size.x = 320
	b.pressed.connect(cb)
	return b

func _process(dt: float) -> void:
	_t += dt
	var c := fan_area.size / 2.0
	for i in fan.size():
		var o: int = i - 2
		var v: CardView = fan[i]
		v.position = c + Vector2(o * 88.0, absf(o) * absf(o) * 12.0 - 10.0 + sin(_t * 1.3 + i) * 8.0) - v.size / 2.0
		v.rotation = o * 0.2 + sin(_t * 0.9 + i * 0.7) * 0.03
	if fan.size() == 5: fan_area.move_child(fan[2], -1)
