class_name SettingsPage
extends Control
# 完整设置页：画面 / 音频 / 操作 / 界面，实时生效并保存
signal closed
const SafeBox := preload("res://scripts/ui/safe_area_container.gd")
const SafePage := preload("res://scripts/ui/safe_area_page.gd")
const SPEC := {
	"画面": [
		["quality", "画面质量", "choice", ["低", "中", "高", "极高"]],
		["fps", "帧率（按设备能力限制）", "choice", ["30", "60", "90", "120"], [30, 60, 90, 120]],
		["animations", "动画效果", "bool"], ["particles", "粒子效果", "bool"], ["screen_shake", "屏幕震动", "bool"],
		["card_anim_speed", "卡牌动画速度", "slider", 0.5, 2.0, 0.1], ["bg_effects", "背景动态效果", "bool"],
		["high_contrast", "高对比度模式", "bool"], ["color_mode", "色彩模式", "choice", ["正常", "鲜艳", "柔和", "护眼"]],
		["fullscreen", "全屏显示", "bool"],
	],
	"音频": [
		["vol_master", "总音量", "slider", 0.0, 1.0, 0.05], ["vol_music", "背景音乐音量", "slider", 0.0, 1.0, 0.05],
		["vol_sfx", "游戏音效音量", "slider", 0.0, 1.0, 0.05], ["music_on", "音乐开关", "bool"], ["sfx_on", "音效开关", "bool"],
	],
	"操作": [
		["tap_select", "点击选择卡牌", "bool"], ["drag_select", "拖动排序卡牌", "bool"], ["auto_arrange", "自动整理手牌", "bool"],
		["auto_sort", "自动排序方式", "choice", ["不排序", "按点数", "按花色"]], ["haptics", "操作震动", "bool"],
		["sensitivity", "操作灵敏度", "slider", 0.5, 2.0, 0.1],
	],
	"界面": [
		["ui_scale", "UI 整体缩放", "slider", 0.8, 1.3, 0.05], ["card_size", "卡牌大小", "slider", 0.8, 1.3, 0.05],
		["font_size", "字体大小", "slider", 0.8, 1.4, 0.05], ["ui_spacing", "界面间距", "slider", 0.6, 1.6, 0.1],
		["layout_flipped", "左右布局对调", "bool"], ["info_density", "信息密度", "choice", ["精简", "标准", "详细"]],
	],
}
var holder: Control

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.08, 0.86)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	holder = SafeBox.new()
	add_child(holder)
	_build()

func _build() -> void:
	for c in holder.get_children():
		holder.remove_child(c)
		c.queue_free()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	holder.add_child(v)
	v.add_child(UIStyle.label("设置", 34, Astral.GOLD))
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 22)
	v.add_child(tabs)
	for name in SPEC:
		var sc := ScrollContainer.new()
		sc.name = name
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 14)
		sc.add_child(col)
		for s in SPEC[name]: _row(col, s)
		tabs.add_child(sc)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	v.add_child(bar)
	var sa := UIStyle.button("安全区调节", Color(0.3, 0.3, 0.38), 48)
	sa.pressed.connect(func():
		var p := SafePage.new()
		add_child(p)
		p.closed.connect(p.queue_free))
	var rs := UIStyle.button("恢复默认", Color(0.45, 0.25, 0.25), 48)
	rs.pressed.connect(func():
		SettingsManager.reset_defaults()
		_build())
	var ok := UIStyle.button("返回", Color(0.15, 0.55, 0.3), 48)
	ok.pressed.connect(func(): closed.emit())
	for b in [sa, rs, ok]: bar.add_child(b)

func _row(parent: Control, s: Array) -> void:
	var h := HBoxContainer.new()
	parent.add_child(h)
	var lb := UIStyle.label(s[1], 22)
	lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lb)
	var key: String = s[0]
	var cur = SettingsManager.get_value(key)
	match s[2]:
		"bool":
			var c := CheckButton.new()
			c.button_pressed = bool(cur)
			c.toggled.connect(func(on: bool): SettingsManager.set_value(key, on))
			h.add_child(c)
		"choice":
			var o := OptionButton.new()
			o.custom_minimum_size = Vector2(200, 44)
			for n in s[3]: o.add_item(n)
			var vals: Array = s[4] if s.size() > 4 else range(s[3].size())
			o.select(maxi(vals.find(cur), 0))
			o.item_selected.connect(func(i: int): SettingsManager.set_value(key, vals[i]))
			h.add_child(o)
		"slider":
			var vl := UIStyle.label("%.2f" % float(cur), 20, Color(0.7, 0.75, 0.85))
			var sl := HSlider.new()
			sl.min_value = s[3]
			sl.max_value = s[4]
			sl.step = s[5]
			sl.value = float(cur)
			sl.custom_minimum_size = Vector2(280, 40)
			sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			sl.value_changed.connect(func(v: float):
				SettingsManager.set_value(key, v)
				vl.text = "%.2f" % v)
			h.add_child(sl)
			h.add_child(vl)
