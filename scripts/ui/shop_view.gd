class_name ShopView
extends Control
# 商店：2 个商品、2 个卡包、刷新、出售、进入下一盲注；开包时显示三选一
const SafeBox := preload("res://scripts/ui/safe_area_container.gd")
var box: VBoxContainer
var msg := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.08, 0.86)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var safe := SafeBox.new()
	add_child(safe)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	safe.add_child(sc)
	box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", UIManager.spacing())
	sc.add_child(box)
	GameManager.state_changed.connect(_build)
	_build()

func _row(title: String) -> HBoxContainer:
	box.add_child(UIStyle.label(title, 20, Color(0.7, 0.75, 0.85)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	box.add_child(h)
	return h

func _try(m: String) -> void:  # 失败时提示并重建；成功时 manager 已 commit
	if m != "":
		msg = m
		_build()
	else:
		msg = ""
		AudioManager.play("buy")

func _build() -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	var g := GameManager
	box.add_child(UIStyle.label("商店     $ %d     %s" % [g.money, msg], 30, Color(1, 0.85, 0.3)))
	if not ShopManager.pack.is_empty():
		var h := _row("选择一张（%s）" % ShopManager.PACKS[ShopManager.pack["id"]][0])
		for i in ShopManager.pack["choices"].size():
			var b := ItemView.make(ShopManager.pack["choices"][i], Vector2(150, 200))
			b.pressed.connect(func(): _try(ShopManager.pick(i)))
			h.add_child(b)
		var sk := UIStyle.button("跳过", Color(0.4, 0.3, 0.3))
		sk.pressed.connect(ShopManager.skip_pack)
		box.add_child(sk)
		return
	var h1 := _row("商品")
	for i in ShopManager.offers.size():
		var o: Dictionary = ShopManager.offers[i]
		var b := ItemView.make(o, Vector2(150, 200), o["price"])
		b.pressed.connect(func(): _try(ShopManager.buy(i)))
		h1.add_child(b)
	if ShopManager.voucher != "":
		var vb := ItemView.make({"kind": "voucher", "id": ShopManager.voucher}, Vector2(150, 200), ShopManager.voucher_price())
		vb.pressed.connect(func(): _try(ShopManager.buy_voucher()))
		h1.add_child(vb)
	for i in ShopManager.packs.size():
		var pid: String = ShopManager.packs[i]
		var b := ItemView.make({"kind": "pack", "id": pid}, Vector2(150, 200), ShopManager.pack_price(pid))
		b.pressed.connect(func(): _try(ShopManager.open_pack(i)))
		h1.add_child(b)
	var h2 := _row("你的小丑牌（点击出售）")
	for i in JokerManager.owned.size():
		var b := ItemView.make({"kind": "joker", "id": JokerManager.owned[i]["id"], "ed": JokerManager.owned[i]["ed"]}, Vector2(130, 90))
		b.text += "\n出售 $%d" % JokerManager.sell_value(i)
		b.pressed.connect(func(): _sell(0, i))
		h2.add_child(b)
	var h3 := _row("你的消耗牌（点击出售）")
	for i in ConsumableManager.owned.size():
		var b := ItemView.make(ConsumableManager.owned[i], Vector2(130, 90))
		b.text += "\n出售 $%d" % ConsumableManager.sell_value(i)
		b.pressed.connect(func(): _sell(1, i))
		h3.add_child(b)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 20)
	box.add_child(bar)
	var rr := UIStyle.button("刷新 $%d" % ShopManager.reroll_cost, Color(0.2, 0.45, 0.35))
	rr.pressed.connect(func(): _try(ShopManager.reroll()))
	var nx := UIStyle.button("下一盲注（%s）" % BlindManager.blind_name(), Color(0.7, 0.3, 0.25))
	nx.pressed.connect(GameManager.leave_shop)
	bar.add_child(rr)
	bar.add_child(nx)

func _sell(kind: int, i: int) -> void:
	AudioManager.play("coin")
	if kind == 0: ShopManager.sell_joker(i)
	else: ShopManager.sell_cons(i)
