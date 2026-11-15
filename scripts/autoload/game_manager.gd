extends Node
signal state_changed
signal hand_scored(info: Dictionary)
signal blind_cleared(reward: int)
# 牌组: [名称, 说明, 解锁统计项, 需要值, 解锁提示]
const DECK_ORDER := ["red", "blue", "yellow", "black", "abandoned", "magic"]
const DECKS := {
	"red": ["红牌组", "+1 次弃牌", "", 0, ""],
	"blue": ["蓝牌组", "+1 次出牌", "", 0, ""],
	"yellow": ["黄牌组", "开局 +$10", "runs", 1, "完成 1 局游戏后解锁"],
	"black": ["黑牌组", "+1 小丑牌栏，-1 次出牌", "best_score", 300, "单手得分达到 300 后解锁"],
	"abandoned": ["废弃牌组", "牌组中没有 J/Q/K", "wins", 1, "通关 1 次后解锁"],
	"magic": ["魔术牌组", "开局带 2 张塔罗牌", "hands_played", 30, "累计出牌 30 次后解锁"],
}
var phase := "idle"  # playing / shop / won / lost
var deck_id := "red"
var max_hands := 4
var max_discards := 3
var joker_slots := 5
var cons_slots := 2
var hands_left := 0
var discards_left := 0
var money := 4
var round_score := 0
var last_type := "高牌"
var hand: Array = []
var vouchers: Array = []
var offer_slots := 2
var price_mult := 1.0
var interest_cap := 5
var reroll_base := 5

func start_run(deck: String = "red") -> void:
	deck_id = deck
	DeckManager.build_standard()
	ScoreManager.reset()
	BlindManager.reset()
	JokerManager.owned = []
	ConsumableManager.owned = []
	max_hands = 4
	max_discards = 3
	joker_slots = 5
	cons_slots = 2
	money = 4
	vouchers = []
	offer_slots = 2
	price_mult = 1.0
	interest_cap = 5
	reroll_base = 5
	DeckManager.hand_size = 8
	match deck:
		"red": max_discards += 1
		"blue": max_hands += 1
		"yellow": money += 10
		"black":
			joker_slots += 1
			max_hands -= 1
		"abandoned": DeckManager.draw_pile = DeckManager.draw_pile.filter(func(c): return c["rank"] < 11 or c["rank"] == 14)
		"magic":
			ConsumableManager.add_random("tarot")
			ConsumableManager.add_random("tarot")
	hand = []
	SaveManager.add_stat("runs")
	_start_blind()

func _start_blind() -> void:
	hands_left = max_hands
	discards_left = max_discards
	var ab := BlindManager.active_boss()
	if ab == "needle": hands_left = 1
	if ab == "water": discards_left = 0
	round_score = 0
	DeckManager.discard_pile.append_array(hand)
	hand = []
	DeckManager.reset_for_blind()
	DeckManager.draw_to(hand, DeckManager.hand_size)
	phase = "playing"
	commit()

func _take(indices: Array) -> Array:
	var idx := indices.duplicate()
	idx.sort()
	var out := []
	for i in idx: out.append(hand[i])
	idx.reverse()
	for i in idx: hand.remove_at(i)
	return out

func play(indices: Array) -> Dictionary:
	if phase != "playing" or hands_left <= 0 or indices.is_empty() or indices.size() > 5: return {}
	var played := _take(indices)
	var ab := BlindManager.active_boss()
	if ab == "arm":
		var pt: String = CardManager.evaluate(played)["type"]
		ScoreManager.levels[pt] = maxi(1, ScoreManager.levels[pt] - 1)
	var res := ScoreManager.score_hand(played)
	if ab == "tooth": money = maxi(0, money - played.size())
	round_score += int(res["total"])
	money += int(res["money"])
	last_type = res["type"]
	hands_left -= 1
	DeckManager.discard_pile.append_array(played)
	SaveManager.add_stat("hands_played")
	SaveManager.set_best(int(res["total"]))
	hand_scored.emit(res)
	if round_score >= BlindManager.target(): _clear()
	elif hands_left == 0: _end(false)
	else:
		if ab == "hook": _discard_random(2)
		DeckManager.draw_to(hand, DeckManager.hand_size)
	commit()
	return res

func discard(indices: Array) -> void:
	if phase != "playing" or discards_left <= 0 or indices.is_empty() or indices.size() > 5: return
	var out := _take(indices)
	for c in out:
		if c["seal"] == "purple": ConsumableManager.add_random("tarot")  # 紫蜡封
	DeckManager.discard_pile.append_array(out)
	discards_left -= 1
	DeckManager.draw_to(hand, DeckManager.hand_size)
	commit()

func _clear() -> void:
	var interest := mini(floori(maxi(money, 0) / 5.0), interest_cap)
	var r := BlindManager.reward() + hands_left + interest + JokerManager.round_end_money()
	money += r
	for c in hand:
		if c["seal"] == "blue" and ConsumableManager.has_room(): ConsumableManager.add("planet", ConsumableManager.planet_for(last_type))
	blind_cleared.emit(r)
	if BlindManager.advance():
		_end(true)
	else:
		DeckManager.discard_pile.append_array(hand)
		hand = []
		phase = "shop"
		ShopManager.enter()

func leave_shop() -> void:
	if phase == "shop": _start_blind()

func _end(won: bool) -> void:
	phase = "won" if won else "lost"
	if won: SaveManager.add_stat("wins")
	SaveManager.clear_run()

func commit() -> void:
	if phase == "playing" or phase == "shop":
		SaveManager.save_run({"phase": phase, "deck_id": deck_id, "max_hands": max_hands, "max_discards": max_discards,
			"joker_slots": joker_slots, "cons_slots": cons_slots, "money": money, "hands": hands_left, "discards": discards_left,
			"score": round_score, "last_type": last_type, "ante": BlindManager.ante, "blind": BlindManager.index, "boss": BlindManager.boss,
			"mods": {"vouchers": vouchers, "offer_slots": offer_slots, "price_mult": price_mult, "interest_cap": interest_cap, "reroll_base": reroll_base, "hand_size": DeckManager.hand_size}, "hand": hand,
			"deck": DeckManager.to_dict(), "score_data": ScoreManager.to_dict(), "jokers": JokerManager.to_dict(),
			"cons": ConsumableManager.to_dict(), "shop": ShopManager.to_dict()})
	state_changed.emit()

func load_run() -> bool:
	var d := SaveManager.load_run()
	if d.is_empty(): return false
	deck_id = str(d.get("deck_id", "red"))
	max_hands = int(d.get("max_hands", 4))
	max_discards = int(d.get("max_discards", 3))
	joker_slots = int(d.get("joker_slots", 5))
	cons_slots = int(d.get("cons_slots", 2))
	money = int(d.get("money", 4))
	hands_left = int(d.get("hands", max_hands))
	discards_left = int(d.get("discards", max_discards))
	round_score = int(d.get("score", 0))
	last_type = str(d.get("last_type", "高牌"))
	BlindManager.ante = int(d.get("ante", 1))
	BlindManager.index = int(d.get("blind", 0))
	BlindManager.boss = str(d.get("boss", "hook"))
	var md: Dictionary = d.get("mods", {})
	vouchers = []
	for v in md.get("vouchers", []): vouchers.append(str(v))
	offer_slots = int(md.get("offer_slots", 2))
	price_mult = float(md.get("price_mult", 1.0))
	interest_cap = int(md.get("interest_cap", 5))
	reroll_base = int(md.get("reroll_base", 5))
	DeckManager.hand_size = int(md.get("hand_size", 8))
	hand = CardManager.norm_all(d.get("hand", []))
	DeckManager.from_dict(d.get("deck", {}))
	ScoreManager.from_dict(d.get("score_data", {}))
	JokerManager.from_dict(d.get("jokers", []))
	ConsumableManager.from_dict(d.get("cons", []))
	ShopManager.from_dict(d.get("shop", {}))
	phase = str(d.get("phase", "playing"))
	state_changed.emit()
	return true

func _discard_random(n: int) -> void:  # 钩子 Boss
	for k in n:
		if hand.is_empty(): return
		DeckManager.discard_pile.append(hand.pop_at(randi() % hand.size()))
