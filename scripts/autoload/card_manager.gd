extends Node
const SUITS := ["♠", "♥", "♣", "♦"]
const RANK_NAMES := {11: "J", 12: "Q", 13: "K", 14: "A"}

func make_card(rank: int, suit: int) -> Dictionary:
	return {"rank": rank, "suit": suit, "enh": "", "ed": "", "seal": ""}

func norm(c: Dictionary) -> Dictionary:  # JSON 读回后数字是 float，统一还原
	return {"rank": int(c.get("rank", 2)), "suit": int(c.get("suit", 0)), "enh": str(c.get("enh", "")),
		"ed": str(c.get("ed", "")), "seal": str(c.get("seal", ""))}

func norm_all(a: Array) -> Array:
	var out := []
	for c in a: out.append(norm(c))
	return out

func card_text(c: Dictionary) -> String:
	return "%s\n%s" % [SUITS[c["suit"]], RANK_NAMES.get(c["rank"], str(c["rank"]))]

func card_chips(c: Dictionary) -> int:
	if c["rank"] == 14: return 11
	return mini(int(c["rank"]), 10)

func sort_hand(hand: Array, mode: int) -> void:  # 0 不排序 1 按点数 2 按花色
	if mode == 1: hand.sort_custom(func(a, b): return a["rank"] > b["rank"])
	elif mode == 2: hand.sort_custom(func(a, b): return a["suit"] < b["suit"] or (a["suit"] == b["suit"] and a["rank"] > b["rank"]))

func _is_straight(keys: Array) -> bool:
	keys.sort()
	return keys[-1] - keys[0] == 4 or keys == [2, 3, 4, 5, 14]

func evaluate(cards: Array) -> Dictionary:
	if cards.is_empty(): return {"type": "高牌", "scoring": []}
	var counts := {}
	for c in cards: counts[c["rank"]] = counts.get(c["rank"], 0) + 1
	var groups: Array = counts.values()
	groups.sort()
	groups.reverse()
	var n := cards.size()
	var flush := n == 5 and cards.all(func(c): return c["suit"] == cards[0]["suit"])
	var straight := n == 5 and counts.size() == 5 and _is_straight(counts.keys())
	var type := "高牌"
	if straight and flush: type = "皇家同花顺" if counts.has(10) and counts.has(14) and counts.has(13) else "同花顺"
	elif groups[0] == 4: type = "四条"
	elif groups[0] == 3 and groups.size() > 1 and groups[1] == 2: type = "葫芦"
	elif flush: type = "同花"
	elif straight: type = "顺子"
	elif groups[0] == 3: type = "三条"
	elif groups.size() > 1 and groups[0] == 2 and groups[1] == 2: type = "两对"
	elif groups[0] == 2: type = "一对"
	var scoring := []
	if type == "高牌":
		var best: Dictionary = cards[0]
		for c in cards:
			if c["rank"] > best["rank"]: best = c
		scoring = [best]
	elif type in ["一对", "两对", "三条", "四条"]:
		for c in cards:
			if counts[c["rank"]] >= 2: scoring.append(c)
	else:
		scoring = cards.duplicate()
	return {"type": type, "scoring": scoring}

# 单张计分牌的筹码/倍率效果（增强牌、版本）。ctx = {chips, mult}
func apply_card(c: Dictionary, ctx: Dictionary) -> void:
	var e := String(c.get("enh", ""))
	ctx["chips"] += 50.0 if e == "stone" else float(card_chips(c))
	match e:
		"bonus": ctx["chips"] += 30.0
		"mult": ctx["mult"] += 4.0
		"glass": ctx["mult"] *= 2.0
		"lucky":
			if randf() < 0.2: ctx["mult"] += 20.0
			if randf() < 1.0 / 15.0: ctx["money"] = int(ctx.get("money", 0)) + 20
	match String(c.get("ed", "")):
		"foil": ctx["chips"] += 50.0
		"holo": ctx["mult"] += 10.0
		"poly": ctx["mult"] *= 1.5
