extends Node
const BASE := {
	"高牌": [5, 1, 10, 1], "一对": [10, 2, 15, 1], "两对": [20, 2, 20, 1], "三条": [30, 3, 20, 2],
	"顺子": [30, 4, 30, 3], "同花": [35, 4, 15, 2], "葫芦": [40, 4, 25, 2], "四条": [60, 7, 30, 3],
	"同花顺": [100, 8, 40, 4], "皇家同花顺": [100, 8, 40, 4],
}
var levels := {}
var plays := {}

func _ready() -> void: reset()
func reset() -> void:
	for t in BASE:
		levels[t] = 1
		plays[t] = 0

func level_up(type: String, n: int = 1) -> void:  # 同花顺与皇家同花顺共享升级
	for t in (["同花顺", "皇家同花顺"] if type in ["同花顺", "皇家同花顺"] else [type]): levels[t] += n

func to_dict() -> Dictionary: return {"levels": levels, "plays": plays}
func from_dict(d: Dictionary) -> void:
	var lv: Dictionary = d.get("levels", {})
	var pl: Dictionary = d.get("plays", {})
	for t in BASE:
		levels[t] = int(lv.get(t, 1))
		plays[t] = int(pl.get(t, 0))

# 返回逐步结算(steps)，动画直接回放；逻辑与动画不会不一致
func score_hand(played: Array) -> Dictionary:
	var ev := CardManager.evaluate(played)
	var t: String = ev["type"]
	plays[t] += 1
	var lv: int = levels[t]
	var b: Array = BASE[t]
	var ctx := {"chips": float(b[0] + b[2] * (lv - 1)), "mult": float(b[1] + b[3] * (lv - 1)), "n": played.size(), "type": t, "ff": false, "money": 0}
	var start_c: float = ctx["chips"]
	var start_m: float = ctx["mult"]
	var steps := []
	for c in ev["scoring"]:
		if BlindManager.is_debuffed(c): continue
		for r in (2 if c["seal"] == "red" else 1):  # 红蜡封：重复触发
			CardManager.apply_card(c, ctx)
			JokerManager.on_card_scored(c, ctx)
			if c["seal"] == "gold" and r == 0: ctx["money"] += 3
			steps.append({"card": c, "chips": ctx["chips"], "mult": ctx["mult"], "joker": -1})
	for c in GameManager.hand:  # 留在手中的牌：钢铁牌 / 男爵 / 射月
		if BlindManager.is_debuffed(c): continue
		var m0: float = ctx["mult"]
		if c["enh"] == "steel": ctx["mult"] *= 1.5
		JokerManager.on_held(c, ctx)
		if ctx["mult"] != m0: steps.append({"card": c, "chips": ctx["chips"], "mult": ctx["mult"], "joker": -1})
	for i in JokerManager.owned.size():
		if JokerManager.on_hand_scored(i, ctx):
			steps.append({"card": null, "chips": ctx["chips"], "mult": ctx["mult"], "joker": i})
	return {"type": t, "level": lv, "scoring": ev["scoring"], "chips": ctx["chips"], "mult": ctx["mult"], "money": ctx["money"],
		"start_chips": start_c, "start_mult": start_m, "steps": steps, "total": int(ctx["chips"] * ctx["mult"])}
