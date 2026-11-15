extends Node
# 塔罗 / 星球 / 幻灵。DEFS: id -> [种类, 名称, 价格, 说明, 需选牌最少, 最多]
const DEFS := {
	"hiero": ["tarot", "教皇", 3, "选 1-2 张牌：变为奖励牌(+30 筹码)", 1, 2],
	"empress": ["tarot", "女皇", 3, "选 1-2 张牌：变为倍率牌(+4 倍率)", 1, 2],
	"tower": ["tarot", "高塔", 3, "选 1 张牌：变为石头牌", 1, 1],
	"justice": ["tarot", "正义", 3, "选 1 张牌：变为玻璃牌(×2 倍率)", 1, 1],
	"strength": ["tarot", "力量", 3, "选 1-2 张牌：点数 +1", 1, 2],
	"sun": ["tarot", "太阳", 3, "选 1-3 张牌：变为红桃", 1, 3],
	"moon": ["tarot", "月亮", 3, "选 1-3 张牌：变为梅花", 1, 3],
	"star": ["tarot", "星星", 3, "选 1-3 张牌：变为方块", 1, 3],
	"world": ["tarot", "世界", 3, "选 1-3 张牌：变为黑桃", 1, 3],
	"death": ["tarot", "死神", 3, "选 2 张牌：左边变成右边的复制", 2, 2],
	"hanged": ["tarot", "倒吊人", 3, "选 1-2 张牌：销毁", 1, 2],
	"hermit": ["tarot", "隐者", 3, "金币翻倍(最多 +$20)", 0, 0],
	"temper": ["tarot", "节制", 3, "获得小丑牌出售价总和(最多 $50)", 0, 0],
	"judgement": ["tarot", "审判", 3, "生成一张随机小丑牌", 0, 0],
	"wheel": ["tarot", "命运之轮", 3, "1/4 概率给随机小丑牌加版本", 0, 0],
	"chariot": ["tarot", "战车", 3, "选 1 张牌：变为钢铁牌(留在手中 ×1.5 倍率)", 1, 1],
	"magician": ["tarot", "魔术师", 3, "选 1-2 张牌：变为幸运牌", 1, 2],
	"priestess": ["tarot", "女祭司", 3, "生成最多 2 张随机星球牌", 0, 0],
	"emperor": ["tarot", "皇帝", 3, "生成最多 2 张随机塔罗牌", 0, 0],
	"pluto": ["planet", "冥王星", 3, "高牌 升级", 0, 0], "mercury": ["planet", "水星", 3, "一对 升级", 0, 0],
	"uranus": ["planet", "天王星", 3, "两对 升级", 0, 0], "venus": ["planet", "金星", 3, "三条 升级", 0, 0],
	"saturn": ["planet", "土星", 3, "顺子 升级", 0, 0], "jupiter": ["planet", "木星", 3, "同花 升级", 0, 0],
	"earth": ["planet", "地球", 3, "葫芦 升级", 0, 0], "mars": ["planet", "火星", 3, "四条 升级", 0, 0],
	"neptune": ["planet", "海王星", 3, "同花顺 升级", 0, 0],
	"talisman": ["spectral", "护身符", 4, "选 1 张牌：加金蜡封(计分 +$3)", 1, 1],
	"deja": ["spectral", "既视感", 4, "选 1 张牌：加红蜡封(重复触发)", 1, 1],
	"trance": ["spectral", "恍惚", 4, "选 1 张牌：加蓝蜡封(回合末生成星球牌)", 1, 1],
	"medium": ["spectral", "灵媒", 4, "选 1 张牌：加紫蜡封(弃牌时生成塔罗牌)", 1, 1],
	"aura": ["spectral", "光环", 4, "选 1 张牌：随机加闪箔/镭射/多彩", 1, 1],
	"familiar": ["spectral", "魔灵", 4, "销毁 1 张手牌，得到 3 张强化人头牌", 0, 0],
	"grim": ["spectral", "怨魂", 4, "销毁 1 张手牌，得到 2 张强化 A", 0, 0],
	"incant": ["spectral", "咒语", 4, "销毁 1 张手牌，得到 4 张强化数字牌", 0, 0],
	"immolate": ["spectral", "献祭", 4, "销毁最多 5 张手牌，获得 $20", 0, 0],
	"blackhole": ["spectral", "黑洞", 4, "所有牌型升 1 级", 0, 0],
	"wraith": ["spectral", "幽灵", 4, "生成随机稀有小丑牌，金币归零", 0, 0],
	"ankh": ["spectral", "安卡", 4, "复制一张随机小丑牌，销毁其余", 0, 0],
	"hex": ["spectral", "妖术", 4, "随机小丑牌变多彩，销毁其余", 0, 0],
	"soul": ["spectral", "灵魂", 4, "生成一张传说小丑牌", 0, 0],
}
const PLANET_TYPE := {"pluto": "高牌", "mercury": "一对", "uranus": "两对", "venus": "三条", "saturn": "顺子", "jupiter": "同花", "earth": "葫芦", "mars": "四条", "neptune": "同花顺"}
const HAND_DEP := ["familiar", "grim", "incant", "immolate"]
var owned: Array = []  # {kind, id}

func has_room() -> bool: return owned.size() < GameManager.cons_slots
func add(kind: String, id: String) -> void: owned.append({"kind": kind, "id": id})
func add_random(kind: String) -> void:
	if has_room(): add(kind, random_id(kind))
func sell_value(i: int) -> int: return maxi(1, int(DEFS[owned[i]["id"]][2] / 2.0))
func random_id(kind: String) -> String:
	var pool := []
	for id in DEFS:
		if DEFS[id][0] == kind: pool.append(id)
	return pool.pick_random()
func planet_for(type: String) -> String:
	for id in PLANET_TYPE:
		if PLANET_TYPE[id] == type: return id
	return "pluto"

func _enhanced(pool: Array) -> Dictionary:
	var c := CardManager.make_card(pool.pick_random(), randi() % 4)
	c["enh"] = ["bonus", "mult", "glass"].pick_random()
	return c

func _destroy_random(n: int) -> void:
	var h: Array = GameManager.hand
	for k in n:
		if not h.is_empty(): h.remove_at(randi() % h.size())

func use(i: int, sel: Array) -> String:  # 成功返回 ""，失败返回原因
	var id: String = owned[i]["id"]
	var d: Array = DEFS[id]
	var h: Array = GameManager.hand
	if id in HAND_DEP and (GameManager.phase != "playing" or h.is_empty()): return "只能在盲注中使用"
	if d[5] > 0 and (sel.size() < d[4] or sel.size() > d[5]): return "请先选择 %d-%d 张手牌" % [d[4], d[5]]
	var cs := []
	if d[5] > 0:
		for k in sel: cs.append(h[k])
	var jk: Array = JokerManager.owned
	var removed := false
	if d[0] == "planet":
		ScoreManager.level_up(PLANET_TYPE[id])
	else:
		match id:
			"hiero":
				for c in cs:
					c["enh"] = "bonus"
			"empress":
				for c in cs:
					c["enh"] = "mult"
			"tower":
				for c in cs:
					c["enh"] = "stone"
			"justice":
				for c in cs:
					c["enh"] = "glass"
			"strength":
				for c in cs:
					c["rank"] = 2 if c["rank"] == 14 else c["rank"] + 1
			"sun":
				for c in cs:
					c["suit"] = 1
			"moon":
				for c in cs:
					c["suit"] = 2
			"star":
				for c in cs:
					c["suit"] = 3
			"world":
				for c in cs:
					c["suit"] = 0
			"death":
				for key in cs[1]: cs[0][key] = cs[1][key]
			"hanged":
				var idx := sel.duplicate()
				idx.sort()
				idx.reverse()
				for k in idx: h.remove_at(k)
			"hermit": GameManager.money += mini(maxi(GameManager.money, 0), 20)
			"temper":
				var s := 0
				for k in jk.size(): s += JokerManager.sell_value(k)
				GameManager.money += mini(s, 50)
			"judgement":
				if not JokerManager.has_room(): return "小丑牌栏已满"
				JokerManager.add(JokerManager.random_id())
			"wheel":
				if jk.is_empty(): return "没有小丑牌"
				if randf() < 0.25: jk.pick_random()["ed"] = ["foil", "holo", "poly"].pick_random()
			"talisman":
				for c in cs:
					c["seal"] = "gold"
			"deja":
				for c in cs:
					c["seal"] = "red"
			"trance":
				for c in cs:
					c["seal"] = "blue"
			"medium":
				for c in cs:
					c["seal"] = "purple"
			"aura":
				for c in cs:
					c["ed"] = ["foil", "holo", "poly"].pick_random()
			"familiar":
				_destroy_random(1)
				for k in 3: h.append(_enhanced([11, 12, 13]))
			"grim":
				_destroy_random(1)
				for k in 2: h.append(_enhanced([14]))
			"incant":
				_destroy_random(1)
				for k in 4: h.append(_enhanced([2, 3, 4, 5, 6, 7, 8, 9, 10]))
			"immolate":
				_destroy_random(5)
				GameManager.money += 20
			"blackhole":
				for t in ScoreManager.BASE: ScoreManager.level_up(t)
			"wraith":
				if not JokerManager.has_room(): return "小丑牌栏已满"
				JokerManager.add(JokerManager.random_id("rare"))
				GameManager.money = 0
			"chariot":
				for c in cs: c["enh"] = "steel"
			"magician":
				for c in cs: c["enh"] = "lucky"
			"priestess", "emperor":
				owned.remove_at(i)  # 先腾出栏位再生成
				removed = true
				for k in 2: add_random("planet" if id == "priestess" else "tarot")
			"soul":
				if not JokerManager.has_room(): return "小丑牌栏已满"
				var lid := JokerManager.random_id("legendary")
				if lid == "": return "没有可生成的传说小丑牌"
				JokerManager.add(lid)
			"ankh", "hex":
				if jk.is_empty(): return "没有小丑牌"
				var keep: Dictionary = jk.pick_random()
				var kept := keep.duplicate()
				if id == "hex": kept["ed"] = "poly"
				jk.clear()
				jk.append(kept)
				if id == "ankh" and jk.size() < GameManager.joker_slots: jk.append(kept.duplicate())
	if not removed: owned.remove_at(i)
	GameManager.commit()
	return ""

func to_dict() -> Array: return owned
func from_dict(a: Array) -> void:
	owned = []
	for c in a: owned.append({"kind": str(c.get("kind", "tarot")), "id": str(c.get("id", "hermit"))})
