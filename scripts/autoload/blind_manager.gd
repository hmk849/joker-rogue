extends Node
const ANTE_BASE := [100, 300, 800, 2000, 5000, 11000, 20000, 35000, 50000]
const NAMES := ["小盲注", "大盲注", "Boss 盲注"]
const MULT := [1.0, 1.5, 2.0]
const REWARD := [3, 4, 5]
const BOSSES := {  # id: [名称, 效果]
	"hook": ["钩子", "每次出牌后随机弃 2 张手牌"],
	"wall": ["墙", "目标分数翻倍（底分的 4 倍）"],
	"needle": ["针", "只有 1 次出牌机会"],
	"water": ["水", "没有弃牌次数"],
	"tooth": ["牙", "每打出 1 张牌失去 $1"],
	"arm": ["臂", "打出的牌型等级 -1"],
	"club": ["棍棒", "所有梅花被削弱（不计分）"],
	"goad": ["刺", "所有黑桃被削弱（不计分）"],
	"window": ["窗", "所有方块被削弱（不计分）"],
	"head": ["头", "所有红桃被削弱（不计分）"],
}
const DEBUFF_SUIT := {"club": 2, "goad": 0, "window": 3, "head": 1}
var ante := 1
var index := 0
var boss := "hook"

func reset() -> void:
	ante = 1
	index = 0
	_pick()

func _pick() -> void: boss = BOSSES.keys().pick_random()

func active_boss() -> String:  # 奇科(传说小丑)会禁用 Boss 效果
	if index != 2: return ""
	for j in JokerManager.owned:
		if j["id"] == "chicot": return ""
	return boss

func target() -> int:
	var m: float = MULT[index] * (2.0 if active_boss() == "wall" else 1.0)
	return int(ANTE_BASE[clampi(ante, 1, 9) - 1] * m)

func blind_name() -> String: return BOSSES[boss][0] if index == 2 else NAMES[index]
func reward() -> int: return REWARD[index]
func desc() -> String:
	if index != 2: return ""
	return BOSSES[boss][1] if active_boss() != "" else "奇科禁用了 Boss 效果"
func is_debuffed(c: Dictionary) -> bool:
	var ab := active_boss()
	return DEBUFF_SUIT.has(ab) and c["suit"] == DEBUFF_SUIT[ab]

func advance() -> bool:  # true = 通关
	index += 1
	if index > 2:
		index = 0
		ante += 1
		_pick()
	return ante > 8
