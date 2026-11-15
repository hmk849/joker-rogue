extends Node
# 动画时长统一入口：尊重“动画开关”和“卡牌动画速度”。
func duration(base: float) -> float:
	if not bool(SettingsManager.get_value("animations")): return 0.0
	return base / maxf(float(SettingsManager.get_value("card_anim_speed")), 0.1)
