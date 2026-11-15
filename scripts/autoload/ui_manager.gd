extends Node
func spacing() -> int: return int(10.0 * float(SettingsManager.get_value("ui_spacing")))
func card_scale() -> float: return float(SettingsManager.get_value("card_size"))
