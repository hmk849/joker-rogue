extends Node
# 游戏主题：0 夜之手账（手绘粉笔）/ 1 咸风酒馆（西部风暴码头 + 酒馆赌局）/ 2 暗河赌厅（威尼斯地下赌城 + 赌桌）
# 每个主题决定：调色板、面板/按钮样式、背景场景、背景音乐
signal changed
const THEMES := [
	{"name": "夜之手账", "en": "Night Sketchbook", "style": "sketch", "jitter": 1.0, "pal": {
		"INK": Color(0.05, 0.05, 0.1), "NIGHT": Color(0.09, 0.12, 0.22), "INDIGO": Color(0.15, 0.18, 0.36), "GOLD": Color(0.98, 0.82, 0.42),
		"GOLD_DIM": Color(0.74, 0.64, 0.44), "IVORY": Color(0.97, 0.94, 0.86), "PARCHMENT": Color(0.97, 0.93, 0.83), "CHALK": Color(0.95, 0.92, 0.82),
		"TEAL": Color(0.3, 0.74, 0.74), "CRIMSON": Color(0.88, 0.34, 0.36), "VIOLET": Color(0.56, 0.4, 0.84)}},
	{"name": "咸风酒馆", "en": "Saltwind Tavern", "style": "wood", "jitter": 0.12, "pal": {
		"INK": Color(0.07, 0.04, 0.03), "NIGHT": Color(0.24, 0.14, 0.08), "INDIGO": Color(0.33, 0.2, 0.11), "GOLD": Color(0.96, 0.74, 0.3),
		"GOLD_DIM": Color(0.74, 0.54, 0.3), "IVORY": Color(0.97, 0.91, 0.78), "PARCHMENT": Color(0.96, 0.9, 0.75), "CHALK": Color(0.9, 0.82, 0.62),
		"TEAL": Color(0.28, 0.62, 0.64), "CRIMSON": Color(0.8, 0.28, 0.2), "VIOLET": Color(0.52, 0.36, 0.6)}},
	{"name": "暗河赌厅", "en": "Casino Sotterraneo", "style": "velvet", "jitter": 0.12, "pal": {
		"INK": Color(0.05, 0.02, 0.04), "NIGHT": Color(0.25, 0.06, 0.1), "INDIGO": Color(0.3, 0.1, 0.15), "GOLD": Color(0.93, 0.78, 0.38),
		"GOLD_DIM": Color(0.72, 0.57, 0.3), "IVORY": Color(0.97, 0.92, 0.82), "PARCHMENT": Color(0.96, 0.92, 0.84), "CHALK": Color(0.9, 0.85, 0.7),
		"TEAL": Color(0.18, 0.52, 0.42), "CRIMSON": Color(0.8, 0.18, 0.28), "VIOLET": Color(0.5, 0.3, 0.6)}},
]
var current := 0

func _ready() -> void:
	apply(int(SettingsManager.get_value("theme")), false)
	SettingsManager.changed.connect(func(k: String):
		if k == "theme": apply(int(SettingsManager.get_value("theme"))))

func apply(i: int, notify: bool = true) -> void:
	current = clampi(i, 0, THEMES.size() - 1)
	Astral.apply(THEMES[current]["pal"])
	if notify: changed.emit()

func style() -> String: return THEMES[current]["style"]
func jitter() -> float: return THEMES[current]["jitter"]
func theme_name() -> String: return THEMES[current]["name"]
