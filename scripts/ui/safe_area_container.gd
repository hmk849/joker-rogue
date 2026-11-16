extends MarginContainer
# 所有界面的根容器：边距 = 当前有效安全区，内容不会进入刘海/灵动岛/圆角。
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SafeAreaManager.changed.connect(_apply)
	_apply()

func _apply() -> void:
	var e := SafeAreaManager.effective()
	add_theme_constant_override("margin_left", int(e["left"]))
	add_theme_constant_override("margin_right", int(e["right"]))
	add_theme_constant_override("margin_top", int(e["top"]))
	add_theme_constant_override("margin_bottom", int(e["bottom"]))
