extends Node
const PACKS := {  # id: [名称, 价格, 说明, 颜色]
	"celestial": ["天体包", 4, "3 张星球牌中选 1 张立即升级", Color(0.2, 0.4, 0.75)],
	"arcana": ["秘术包", 4, "3 张塔罗牌中选 1 张", Color(0.5, 0.3, 0.7)],
	"buffoon": ["小丑包", 6, "2 张小丑牌中选 1 张", Color(0.75, 0.45, 0.15)],
	"spectral": ["幻灵包", 5, "3 张幻灵牌中选 1 张", Color(0.3, 0.3, 0.45)],
}
const VOUCHERS := {  # id: [名称, 价格, 说明]
	"overstock": ["超量库存", 10, "商店商品栏 +1"],
	"clearance": ["清仓大甩卖", 10, "商店所有商品 75 折"],
	"grabber": ["抓取者", 10, "每个盲注 +1 次出牌"],
	"wasteful": ["浪费", 10, "每个盲注 +1 次弃牌"],
	"crystal": ["水晶球", 10, "消耗牌栏 +1"],
	"seed": ["种子基金", 10, "利息上限提高到 $10"],
	"paint": ["画笔", 10, "手牌上限 +1"],
	"surplus": ["刷新盈余", 10, "刷新价格 -$2"],
}
const KCOL := {"tarot": Color(0.5, 0.3, 0.7), "planet": Color(0.2, 0.4, 0.75), "spectral": Color(0.3, 0.3, 0.4)}
var offers: Array = []
var packs: Array = []
var pack: Dictionary = {}
var reroll_cost := 5
var voucher := ""

func info(kind: String, id: String) -> Dictionary:
	match kind:
		"joker":
			var d: Array = JokerManager.DEFS[id]
			return {"n": d[0], "d": d[3], "col": JokerManager.RCOL[d[1]]}
		"voucher":
			var v: Array = VOUCHERS[id]
			return {"n": v[0], "d": v[2], "col": Color(0.8, 0.6, 0.2)}
		"pack":
			var p: Array = PACKS[id]
			return {"n": p[0], "d": p[2], "col": p[3]}
	var c: Array = ConsumableManager.DEFS[id]
	return {"n": c[1], "d": c[3], "col": KCOL[kind]}

func enter() -> void:
	reroll_cost = GameManager.reroll_base
	pack = {}
	var vp := []
	for k in VOUCHERS:
		if not GameManager.vouchers.has(k): vp.append(k)
	voucher = "" if vp.is_empty() else vp.pick_random()
	packs = []
	for i in 2: packs.append(PACKS.keys().pick_random())
	_roll()

func _roll() -> void:
	offers = []
	for i in GameManager.offer_slots: offers.append(_gen())

func _gen() -> Dictionary:
	var r := randf()
	if r < 0.6:
		var ex := []
		for o in offers: ex.append(o["id"])
		var id := JokerManager.random_id("", ex)
		if id != "":
			var ed := JokerManager.random_edition()
			return {"kind": "joker", "id": id, "ed": ed, "price": price(JokerManager.DEFS[id][2] + (3 if ed != "" else 0))}
	var kind := "planet" if r < 0.8 else "tarot"
	var cid := ConsumableManager.random_id(kind)
	return {"kind": kind, "id": cid, "ed": "", "price": price(ConsumableManager.DEFS[cid][2])}

func buy(i: int) -> String:
	var o: Dictionary = offers[i]
	if GameManager.money < o["price"]: return "金币不足"
	if o["kind"] == "joker":
		if not JokerManager.has_room(): return "小丑牌栏已满"
		JokerManager.add(o["id"], o["ed"])
	else:
		if not ConsumableManager.has_room(): return "消耗牌栏已满"
		ConsumableManager.add(o["kind"], o["id"])
	GameManager.money -= int(o["price"])
	offers.remove_at(i)
	GameManager.commit()
	return ""

func open_pack(i: int) -> String:
	var id: String = packs[i]
	var cost: int = pack_price(id)
	if GameManager.money < cost: return "金币不足"
	var ch := []
	match id:
		"celestial":
			for k in 3: ch.append({"kind": "planet", "id": ConsumableManager.random_id("planet"), "ed": ""})
		"spectral":
			for k in 3: ch.append({"kind": "spectral", "id": ConsumableManager.random_id("spectral"), "ed": ""})
		"arcana":
			for k in 3: ch.append({"kind": "tarot", "id": ConsumableManager.random_id("tarot"), "ed": ""})
		_:
			var ex := []
			for k in 2:
				var jid := JokerManager.random_id("", ex)
				if jid != "":
					ex.append(jid)
					ch.append({"kind": "joker", "id": jid, "ed": JokerManager.random_edition()})
	GameManager.money -= cost
	packs.remove_at(i)
	pack = {"id": id, "choices": ch}
	GameManager.commit()
	return ""

func pick(i: int) -> String:
	var c: Dictionary = pack["choices"][i]
	match c["kind"]:
		"planet": ScoreManager.level_up(ConsumableManager.PLANET_TYPE[c["id"]])
		"joker":
			if not JokerManager.has_room(): return "小丑牌栏已满"
			JokerManager.add(c["id"], c["ed"])
		_:
			if not ConsumableManager.has_room(): return "消耗牌栏已满"
			ConsumableManager.add(c["kind"], c["id"])
	pack = {}
	GameManager.commit()
	return ""

func skip_pack() -> void:
	pack = {}
	GameManager.commit()

func reroll() -> String:
	if GameManager.money < reroll_cost: return "金币不足"
	GameManager.money -= reroll_cost
	reroll_cost += 1
	_roll()
	GameManager.commit()
	return ""

func sell_joker(i: int) -> void:
	GameManager.money += JokerManager.sell_value(i)
	JokerManager.owned.remove_at(i)
	GameManager.commit()

func sell_cons(i: int) -> void:
	GameManager.money += ConsumableManager.sell_value(i)
	ConsumableManager.owned.remove_at(i)
	GameManager.commit()

func to_dict() -> Dictionary: return {"offers": offers, "packs": packs, "pack": pack, "reroll": reroll_cost, "voucher": voucher}
func from_dict(d: Dictionary) -> void:
	offers = []
	for o in d.get("offers", []): offers.append({"kind": str(o["kind"]), "id": str(o["id"]), "ed": str(o.get("ed", "")), "price": int(o["price"])})
	packs = []
	for p in d.get("packs", []): packs.append(str(p))
	pack = {}
	var pk: Dictionary = d.get("pack", {})
	if not pk.is_empty():
		var ch := []
		for c in pk["choices"]: ch.append({"kind": str(c["kind"]), "id": str(c["id"]), "ed": str(c.get("ed", ""))})
		pack = {"id": str(pk["id"]), "choices": ch}
	reroll_cost = int(d.get("reroll", 5))
	voucher = str(d.get("voucher", ""))

func price(base: int) -> int: return maxi(1, ceili(base * GameManager.price_mult))
func pack_price(id: String) -> int: return price(PACKS[id][1])
func voucher_price() -> int: return price(VOUCHERS[voucher][1])

func _base(o: Dictionary) -> int:
	if o["kind"] == "joker": return JokerManager.DEFS[o["id"]][2] + (3 if o["ed"] != "" else 0)
	return ConsumableManager.DEFS[o["id"]][2]

func buy_voucher() -> String:
	if voucher == "": return "没有优惠券"
	var cost := voucher_price()
	if GameManager.money < cost: return "金币不足"
	var g := GameManager
	match voucher:
		"overstock":
			g.offer_slots += 1
			offers.append(_gen())
		"clearance":
			g.price_mult = 0.75
			for o in offers: o["price"] = price(_base(o))
		"grabber": g.max_hands += 1
		"wasteful": g.max_discards += 1
		"crystal": g.cons_slots += 1
		"seed": g.interest_cap = 10
		"paint": DeckManager.hand_size += 1
		"surplus":
			g.reroll_base = 3
			reroll_cost = maxi(reroll_cost - 2, 0)
	g.money -= cost
	g.vouchers.append(voucher)
	voucher = ""
	g.commit()
	return ""
