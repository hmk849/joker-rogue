extends Node
var draw_pile: Array = []
var discard_pile: Array = []
var hand_size := 8
var rng := RandomNumberGenerator.new()

func build_standard() -> void:
	rng.randomize()
	draw_pile.clear()
	discard_pile.clear()
	for s in 4:
		for r in range(2, 15): draw_pile.append(CardManager.make_card(r, s))
	_shuffle(draw_pile)

func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t

func reset_for_blind() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	_shuffle(draw_pile)

func draw_to(hand: Array, n: int) -> void:
	while hand.size() < n and not draw_pile.is_empty(): hand.append(draw_pile.pop_back())
	CardManager.sort_hand(hand, int(SettingsManager.get_value("auto_sort")) if bool(SettingsManager.get_value("auto_arrange")) else 0)

func to_dict() -> Dictionary: return {"draw": draw_pile, "discard": discard_pile}
func from_dict(d: Dictionary) -> void:
	draw_pile = CardManager.norm_all(d.get("draw", []))
	discard_pile = CardManager.norm_all(d.get("discard", []))
