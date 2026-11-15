extends Node
# 小丑牌：数据驱动（HAND_RULES / CARD_RULES）+ 少量特殊效果
const ED := {"foil": "闪箔", "holo": "镭射", "poly": "多彩"}
const RCOL := {"common": Color(0.25, 0.45, 0.8), "uncommon": Color(0.2, 0.6, 0.4), "rare": Color(0.75, 0.25, 0.3), "legendary": Color(0.85, 0.65, 0.15)}
const DEFS := {  # [名称, 稀有度, 价格, 说明]
	"joker": ["小丑", "common", 2, "+4 倍率"],
	"greedy": ["贪婪小丑", "common", 5, "计分的方块 +3 倍率"], "lusty": ["好色小丑", "common", 5, "计分的红桃 +3 倍率"],
	"wrathful": ["愤怒小丑", "common", 5, "计分的黑桃 +3 倍率"], "gluttonous": ["暴食小丑", "common", 5, "计分的梅花 +3 倍率"],
	"jolly": ["欢乐小丑", "common", 3, "包含对子 +8 倍率"], "zany": ["滑稽小丑", "common", 4, "包含三条 +12 倍率"],
	"mad": ["疯狂小丑", "common", 4, "包含两对 +10 倍率"], "crazy": ["狂热小丑", "common", 4, "包含顺子 +12 倍率"],
	"droll": ["古怪小丑", "common", 4, "包含同花 +10 倍率"], "sly": ["狡猾小丑", "common", 3, "包含对子 +50 筹码"],
	"wily": ["奸诈小丑", "common", 4, "包含三条 +100 筹码"], "clever": ["机灵小丑", "common", 4, "包含两对 +80 筹码"],
	"devious": ["阴险小丑", "common", 4, "包含顺子 +100 筹码"], "crafty": ["狡黠小丑", "common", 4, "包含同花 +80 筹码"],
	"half": ["半张小丑", "common", 5, "出牌不超过 3 张时 +20 倍率"], "banner": ["横幅", "common", 5, "每剩余 1 次弃牌 +30 筹码"],
	"mystic": ["神秘峰", "common", 5, "弃牌次数用完时 +15 倍率"], "scary": ["鬼脸", "common", 4, "计分的人头牌 +30 筹码"],
	"even": ["偶数史蒂文", "common", 4, "计分的偶数牌 +4 倍率"], "odd": ["奇数托德", "common", 4, "计分的奇数牌 +31 筹码"],
	"fib": ["斐波那契", "uncommon", 8, "计分的 A,2,3,5,8 +8 倍率"], "scholar": ["学者", "common", 4, "计分的 A +20 筹码 +4 倍率"],
	"walkie": ["对讲机", "common", 4, "计分的 10 或 4 +10 筹码 +4 倍率"], "photo": ["摄影师", "uncommon", 5, "第一张计分的人头牌 ×2 倍率"],
	"supernova": ["超新星", "uncommon", 5, "倍率 + 本局该牌型已打出的次数"], "blue": ["蓝色小丑", "common", 5, "牌堆每剩 1 张 +2 筹码"],
	"abstract": ["抽象小丑", "common", 4, "每张小丑牌 +3 倍率"], "bull": ["公牛", "uncommon", 6, "每持有 $1 +2 筹码"],
	"baron": ["男爵", "rare", 8, "手牌中的每张 K ×1.5 倍率"], "moon": ["射月", "common", 5, "手牌中的每张 Q +13 倍率"],
	"triboulet": ["特里布莱", "legendary", 20, "计分的 K 和 Q 各 ×2 倍率"], "chicot": ["奇科", "legendary", 20, "禁用 Boss 盲注效果"],
	"golden": ["金色小丑", "common", 6, "每回合结束 +$4"], "cavendish": ["卡文迪许", "rare", 8, "×3 倍率"],
}
const ALL := ["高牌", "一对", "两对", "三条", "顺子", "同花", "葫芦", "四条", "同花顺", "皇家同花顺"]
const CONTAINS := {
	"any": ALL, "pair": ["一对", "两对", "三条", "葫芦", "四条"], "three": ["三条", "葫芦", "四条"], "two": ["两对", "葫芦"],
	"straight": ["顺子", "同花顺", "皇家同花顺"], "flush": ["同花", "同花顺", "皇家同花顺"],
}
const HAND_RULES := {  # id: [牌型条件, 属性, 数值]
	"joker": ["any", "mult", 4], "jolly": ["pair", "mult", 8], "zany": ["three", "mult", 12], "mad": ["two", "mult", 10],
	"crazy": ["straight", "mult", 12], "droll": ["flush", "mult", 10], "sly": ["pair", "chips", 50], "wily": ["three", "chips", 100],
	"clever": ["two", "chips", 80], "devious": ["straight", "chips", 100], "crafty": ["flush", "chips", 80],
}
const CARD_RULES := {  # id: [条件, 参数, 筹码, 倍率]
	"greedy": ["suit", 3, 0, 3], "lusty": ["suit", 1, 0, 3], "wrathful": ["suit", 0, 0, 3], "gluttonous": ["suit", 2, 0, 3],
	"scary": ["face", 0, 30, 0], "even": ["even", 0, 0, 4], "odd": ["odd", 0, 31, 0], "fib": ["ranks", [14, 2, 3, 5, 8], 0, 8],
	"scholar": ["ranks", [14], 20, 4], "walkie": ["ranks", [10, 4], 10, 4],
}
var owned: Array = []  # {id, ed}

func has_room() -> bool: return owned.size() < GameManager.joker_slots
func add(id: String, ed: String = "") -> void: owned.append({"id": id, "ed": ed})
func sell_value(i: int) -> int: return maxi(1, int(DEFS[owned[i]["id"]][2] / 2.0))

func random_id(rarity: String = "", exclude: Array = []) -> String:
	if rarity == "":
		var r := randf()
		rarity = "common" if r < 0.7 else ("uncommon" if r < 0.95 else "rare")
	var pool := []
	for id in DEFS:
		if DEFS[id][1] == rarity and not _owns(id) and not exclude.has(id): pool.append(id)
	if pool.is_empty():
		for id in DEFS:
			if not _owns(id) and not exclude.has(id) and (rarity == "legendary" or DEFS[id][1] != "legendary"): pool.append(id)
	return "" if pool.is_empty() else pool.pick_random()

func _owns(id: String) -> bool:
	for j in owned:
		if j["id"] == id: return true
	return false

func random_edition() -> String:
	var r := randf()
	return "poly" if r < 0.02 else ("holo" if r < 0.05 else ("foil" if r < 0.09 else ""))

func round_end_money() -> int:
	var m := 0
	for j in owned:
		if j["id"] == "golden": m += 4
	return m

func on_card_scored(c: Dictionary, ctx: Dictionary) -> void:
	var r: int = c["rank"]
	var face := r >= 11 and r <= 13
	for j in owned:
		var id: String = j["id"]
		if id == "triboulet":
			if r == 12 or r == 13: ctx["mult"] *= 2.0
			continue
		if id == "photo":
			if face and not ctx["ff"]:
				ctx["ff"] = true
				ctx["mult"] *= 2.0
			continue
		if not CARD_RULES.has(id): continue
		var ru: Array = CARD_RULES[id]
		var ok := false
		match ru[0]:
			"suit": ok = c["suit"] == ru[1]
			"face": ok = face
			"even": ok = r <= 10 and r % 2 == 0
			"odd": ok = (r <= 9 and r % 2 == 1) or r == 14
			"ranks": ok = r in ru[1]
		if ok:
			ctx["chips"] += float(ru[2])
			ctx["mult"] += float(ru[3])

func on_hand_scored(i: int, ctx: Dictionary) -> bool:
	var j: Dictionary = owned[i]
	var id: String = j["id"]
	var c0: float = ctx["chips"]
	var m0: float = ctx["mult"]
	var t: String = ctx["type"]
	if HAND_RULES.has(id):
		var ru: Array = HAND_RULES[id]
		if t in CONTAINS[ru[0]]: ctx[ru[1]] += float(ru[2])
	else:
		match id:
			"half":
				if ctx["n"] <= 3: ctx["mult"] += 20.0
			"banner": ctx["chips"] += 30.0 * GameManager.discards_left
			"mystic":
				if GameManager.discards_left == 0: ctx["mult"] += 15.0
			"supernova": ctx["mult"] += float(ScoreManager.plays[t])
			"blue": ctx["chips"] += 2.0 * DeckManager.draw_pile.size()
			"abstract": ctx["mult"] += 3.0 * owned.size()
			"bull": ctx["chips"] += 2.0 * maxi(GameManager.money, 0)
			"cavendish": ctx["mult"] *= 3.0
	match String(j["ed"]):
		"foil": ctx["chips"] += 50.0
		"holo": ctx["mult"] += 10.0
		"poly": ctx["mult"] *= 1.5
	return ctx["chips"] != c0 or ctx["mult"] != m0

func to_dict() -> Array: return owned
func from_dict(a: Array) -> void:
	owned = []
	for j in a: owned.append({"id": str(j.get("id", "joker")), "ed": str(j.get("ed", ""))})

func on_held(c: Dictionary, ctx: Dictionary) -> void:
	for j in owned:
		match j["id"]:
			"baron":
				if c["rank"] == 13: ctx["mult"] *= 1.5
			"moon":
				if c["rank"] == 12: ctx["mult"] += 13.0
