extends Node
signal changed(key: String)
const PATH := "user://settings.json"
const DEFAULTS := {
	"quality": 2, "fps": 60, "animations": true, "particles": true, "screen_shake": true,
	"card_anim_speed": 1.0, "bg_effects": true, "high_contrast": false, "color_mode": 0, "fullscreen": true,
	"vol_master": 1.0, "vol_music": 0.7, "vol_sfx": 0.9, "music_on": true, "sfx_on": true,
	"tap_select": true, "drag_select": true, "auto_arrange": true, "auto_sort": 1, "haptics": true, "sensitivity": 1.0,
	"theme": 0, "ui_scale": 1.0, "card_size": 1.0, "font_size": 1.0, "ui_spacing": 1.0, "layout_flipped": false, "info_density": 1,
}
var data: Dictionary = DEFAULTS.duplicate()

func _ready() -> void:
	var d := SaveManager.read_json(PATH)
	for k in DEFAULTS:
		if d.has(k): data[k] = d[k]
	for k in DEFAULTS: _apply(k)

func get_value(key: String) -> Variant: return data.get(key, DEFAULTS.get(key))

func set_value(key: String, v: Variant) -> void:
	if not DEFAULTS.has(key): return
	data[key] = v
	_apply(key)
	changed.emit(key)
	SaveManager.write_json(PATH, data)

func reset_defaults() -> void:
	for k in DEFAULTS: set_value(k, DEFAULTS[k])

func _apply(key: String) -> void:
	match key:
		"fps":
			var hz := int(DisplayServer.screen_get_refresh_rate())
			if hz <= 0: hz = 60
			Engine.max_fps = mini(int(data["fps"]), maxi(hz, 30))  # 按设备刷新率自动限制
		"quality":
			var modes := [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X]
			get_viewport().msaa_2d = modes[clampi(int(data["quality"]), 0, 3)]
		"ui_scale":
			get_window().content_scale_factor = clampf(float(data["ui_scale"]), 0.7, 1.5)
		"fullscreen":
			if OS.has_feature("pc"):
				get_window().mode = Window.MODE_FULLSCREEN if data["fullscreen"] else Window.MODE_WINDOWED
		"vol_master", "vol_music", "vol_sfx", "music_on", "sfx_on":
			var am := get_node_or_null("/root/AudioManager")
			if am: am.apply_volumes()
