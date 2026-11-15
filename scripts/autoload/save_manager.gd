extends Node
# 存档：运行进度(崩溃恢复)、解锁、统计。写入先落临时文件并保留 .bak。
const RUN_PATH := "user://run.json"
const PROFILE_PATH := "user://profile.json"
var profile := {"unlocks": [], "stats": {"runs": 0, "wins": 0, "best_score": 0, "hands_played": 0}}

func _ready() -> void:
	var d := read_json(PROFILE_PATH)
	if d.has("unlocks"): profile["unlocks"] = d["unlocks"]
	if d.has("stats"): profile["stats"].merge(d["stats"], true)

func write_json(path: String, data: Variant) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(data))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path) == OK

func read_json(path: String) -> Dictionary:
	for p in [path, path + ".bak"]:
		if FileAccess.file_exists(p):
			var d = JSON.parse_string(FileAccess.get_file_as_string(p))
			if d is Dictionary: return d
	return {}

func save_run(d: Dictionary) -> void: write_json(RUN_PATH, d)
func load_run() -> Dictionary: return read_json(RUN_PATH)
func has_run() -> bool: return FileAccess.file_exists(RUN_PATH) or FileAccess.file_exists(RUN_PATH + ".bak")
func clear_run() -> void:
	for p in [RUN_PATH, RUN_PATH + ".bak", RUN_PATH + ".tmp"]:
		if FileAccess.file_exists(p): DirAccess.remove_absolute(p)
func save_profile() -> void: write_json(PROFILE_PATH, profile)
func add_stat(key: String, n: int = 1) -> void:
	profile["stats"][key] = int(profile["stats"].get(key, 0)) + n
	save_profile()
func set_best(v: int) -> void:
	if v > int(profile["stats"]["best_score"]):
		profile["stats"]["best_score"] = v
		save_profile()
func unlock(id: String) -> void:
	if not profile["unlocks"].has(id):
		profile["unlocks"].append(id)
		save_profile()
