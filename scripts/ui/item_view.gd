class_name ItemView
extends RefCounted
# 小丑牌 / 塔罗 / 星球 / 幻灵 / 卡包 的统一卡片按钮（按稀有度/种类上色）
static func make(item: Dictionary, sz: Vector2, price: int = -1) -> Button:
	var info := ShopManager.info(item["kind"], item["id"])
	var ed := String(item.get("ed", ""))
	var t: String = info["n"]
	if ed != "": t += "·" + JokerManager.ED[ed]
	if sz.y > 120: t += "\n" + info["d"]
	if price >= 0: t += "\n$%d" % price
	var b := UIStyle.button(t, info["col"], int(sz.y))
	b.custom_minimum_size = sz
	b.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	b.add_theme_font_size_override("font_size", 14 if sz.y <= 120 else 17)
	b.tooltip_text = info["d"]
	return b
