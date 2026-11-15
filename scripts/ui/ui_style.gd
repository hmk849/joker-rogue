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

static func label(text: String, size: int = 20, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", int(size * float(SettingsManager.get_value("font_size"))))
	l.add_theme_color_override("font_color", col)
	return l

static func panel(bg: Color, border: Color = Color(1, 1, 1, 0.12)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border, 2, 14))
	return p

static func button(text: String, col: Color, h: int = 56) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, h)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_stylebox_override("normal", box(col, Color(0, 0, 0, 0.45), 2, 12))
	b.add_theme_stylebox_override("hover", box(col.lightened(0.15), Color(1, 1, 1, 0.5), 2, 12))
	b.add_theme_stylebox_override("pressed", box(col.darkened(0.25), Color(0, 0, 0, 0.6), 2, 12))
	b.add_theme_stylebox_override("disabled", box(col.darkened(0.55), Color(0, 0, 0, 0.3), 2, 12))
	return b
