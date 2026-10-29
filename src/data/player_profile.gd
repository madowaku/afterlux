extends RefCounted

var best: Dictionary = {}
var runs: Dictionary = {}
var stage_index: int = 0
var sound: bool = true
var reduced_motion: bool = false
var language: String = ""
var save_path: String = "user://afterlux_progress.cfg"

func load_profile() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(save_path) != OK:
		return
	var stored_best: Variant = config.get_value("progress", "best", {})
	if stored_best is Dictionary:
		for id: Variant in stored_best:
			if str(id).is_valid_int() and stored_best[id] is int and stored_best[id] > 0:
				best[str(id)] = stored_best[id]
	var stored_runs: Variant = config.get_value("progress", "runs", {})
	if stored_runs is Dictionary:
		runs = stored_runs
	stage_index = int(config.get_value("progress", "stage", 0))
	sound = bool(config.get_value("settings", "sound", true))
	reduced_motion = bool(config.get_value("settings", "reduced_motion", false))
	var stored_language: String = str(config.get_value("settings", "language", ""))
	if stored_language in ["en", "ja"]:
		language = stored_language

func save_profile() -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("progress", "best", best)
	config.set_value("progress", "runs", runs)
	config.set_value("progress", "stage", stage_index)
	config.set_value("settings", "sound", sound)
	config.set_value("settings", "reduced_motion", reduced_motion)
	config.set_value("settings", "language", language)
	return config.save(save_path)
