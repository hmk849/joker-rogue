class_name ItemView
extends RefCounted
# 统一的“带插画的卡牌按钮”：上部程序化插画，下部名称/说明/价格
static func make(item: Dictionary, sz: Vector2, price: int = -1, sub: String = "") -> Button:
	var kind: String = item["kind"]
	var id: String = item["id"]
	var info := ShopManager.info(kind, id)
	var ed := String(item.get("ed", ""))
	var big := sz.y > 120
	var nm: String = info["n"]
	if ed != "": nm += "·" + JokerManager.ED[ed]
	var b := UIStyle.button("", info["col"], int(sz.y))
	b.custom_minimum_size = sz
	b.tooltip_text = info["d"]
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	var art := Control.new()
	art.custom_minimum_size = Vector2(sz.x, sz.y * (0.46 if big else 0.56))
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg: Color = info["col"].darkened(0.35)
	art.draw.connect(func(): ItemArt.draw(art, kind, id, Rect2(Vector2(6, 6), art.size - Vector2(12, 8)), bg))
	v.add_child(art)
	var nl := UIStyle.label(nm, 17 if big else 12)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nl)
	if big:
		var dl := UIStyle.label(info["d"], 13, Color(1, 1, 1, 0.85))
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		dl.custom_minimum_size.x = sz.x - 16
		v.add_child(dl)
	if price >= 0:
		var pl := UIStyle.label("$%d" % price, 18, Astral.GOLD)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(pl)
	if sub != "":
		var sl := UIStyle.label(sub, 12, Astral.GOLD)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(sl)
	b.add_child(v)
	return b
