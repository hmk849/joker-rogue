class_name UIStyle
extends RefCounted
# 统一美术规范：深蓝街机面板 + 圆角 + 描边。StyleBox 带缓存。
static var _cache := {}

static func box(bg: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, r: int = 12) -> StyleBoxFlat:
	var key := "%s|%s|%d|%d" % [bg, border, bw, r]
	if _cache.has(key): return _cache[key]
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(r)
	s.set_content_margin_all(12)
	_cache[key] = s
	return s

static func label(text: String, size: int = 20, col: Color = Color(-1, -1, -1)) -> Label:
	var l := Label.new()
	if col.r < 0.0: col = Astral.IVORY
	l.text = text
	l.add_theme_font_size_override("font_size", int(size * float(SettingsManager.get_value("font_size"))))
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

static func panel(bg: Color, border: Color = Color(1, 1, 1, 0.12)) -> PanelContainer:
	var p := OrnatePanel.new()
	p.bg = bg
	p.accent = border if border.a >= 0.35 else Astral.GOLD_DIM
	return p

static func _btn(bg: Color, edge: Color) -> StyleBoxFlat:
	var key := "btn|%s|%s|%s" % [bg, edge, ThemeManager.style()]
	if _cache.has(key): return _cache[key]
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(0)
	s.set_corner_radius_all(10 if ThemeManager.style() == "sketch" else 6)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 5
	s.shadow_offset = Vector2(0, 3)
	s.set_content_margin_all(12)
	_cache[key] = s
	return s

static func button(text: String, col: Color, h: int = 56) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, h)
	b.add_theme_font_size_override("font_size", 22)
	var base := col.darkened(0.3)
	b.add_theme_stylebox_override("normal", _btn(base, Astral.GOLD_DIM))
	b.add_theme_stylebox_override("hover", _btn(col, Astral.GOLD))
	b.add_theme_stylebox_override("pressed", _btn(col.darkened(0.5), Astral.GOLD))
	b.add_theme_stylebox_override("disabled", _btn(base.darkened(0.45), Color(0.3, 0.3, 0.36)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color"]: b.add_theme_color_override(k, Astral.IVORY)
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.6))
	b.draw.connect(func(): Astral.button_deco(b))
	return b
