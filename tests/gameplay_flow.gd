extends SceneTree

const MAIN = preload("res://game/main/main.gd")
const RULES = preload("res://src/core/afterlux_rules.gd")
const PROFILE = preload("res://src/data/player_profile.gd")
var failures: int = 0
var game: Control

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _run() -> void:
	root.size = Vector2i(360, 800)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	game = MAIN.new()
	game.profile.save_path = "res://artifacts/gameplay_test.cfg"
	if FileAccess.file_exists(game.profile.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.profile.save_path))
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.profile.sound = false
	game.profile.reduced_motion = true
	game._set_language("en")
	await process_frame
	check(game.stages.size() == 100, "all 100 stages available")
	check(game.fire_button.disabled, "empty selection cannot fire")
	game._on_cell_pressed(Vector2i(1, 1))
	check(game.selected_dots.is_empty(), "non-sockets reject input")
	var solutions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/stage_solutions_001_100.json"))
	for index: int in range(100):
		game._load_stage(index)
		game._on_reset_pressed()
		var id: String = str(game.stage["id"])
		for shot: Dictionary in solutions[id]:
			await cast(shot["dots"], shot["light"])
		check(game.solved, "stage %s exact clear" % id)
		check(game.history.size() == int(game.stage["par"]), "stage %s PAR" % id)
		check(game.fire_button.disabled and game.result_panel.visible, "stage %s clear locks casting" % id)
		var shot_count: int = game.history.size()
		await game._on_fire_pressed()
		check(game.history.size() == shot_count, "solved state ignores firing")
		game._on_undo_pressed()
		check(not game.solved and game.history.size() == shot_count - 1, "undo clear %s" % id)
		check(int(game.profile.best[id]) == int(game.stage["par"]), "undo preserves personal best")
	# The defining contrast: grouping yields a zero-hole; splitting fills it.
	game._load_stage(6)
	game._on_reset_pressed()
	await cast(["A1", "A2"], "N")
	check(game.accumulated[1][0] == 0 and game.accumulated[2][0] == 2, "grouped zero-hole")
	game._load_stage(7)
	game._on_reset_pressed()
	await cast(["A1"], "N")
	await cast(["A2"], "N")
	check(game.accumulated[1][0] == 1 and game.solved, "split signature")
	# Above-PAR solutions are still clears, and only improve the best downward.
	game.profile.best.erase("010")
	game._load_stage(9)
	game._on_reset_pressed()
	await cast(["A1"], "N")
	await cast(["A1"], "N")
	await cast(["B1"], "N")
	check(game.solved and game.profile.best["010"] == 3, "above PAR clear accepted")
	game._on_reset_pressed()
	await cast(["A1"], "N")
	await cast(["A1", "B1"], "N")
	check(game.profile.best["010"] == 2, "PAR improves best")
	game._load_stage(1)
	game._on_reset_pressed()
	await cast(["A1"], "N")
	check(RULES.is_overshot(game.stage, game.accumulated), "overshoot remains undoable")
	game._on_undo_pressed()
	check(not RULES.is_overshot(game.stage, game.accumulated), "undo removes overshoot")
	await cast(["A1"], "W")
	check(game.solved, "recover and solve after overshoot")
	# Validate persistence by creating a second independent profile.
	var restored: RefCounted = PROFILE.new()
	restored.save_path = game.profile.save_path
	restored.load_profile()
	check(restored.best["010"] == 2 and restored.runs["002"].size() == 1, "save reload best and run")
	game.profile = restored
	game._load_stage(1)
	check(game.solved and game.history.size() == 1, "resume reconstructs solved board")
	check(game._validated_history([{"dots": ["Z999"], "light": "N"}]).is_empty(), "invalid save coordinates rejected")
	check(game._validated_history([{"dots": ["A1", "A1"], "light": "N"}]).is_empty(), "duplicate saved DOT rejected")
	game._show_help()
	check(game.overlay != null and not game.frame.visible, "help hides inactive controls")
	game._toggle_motion()
	game._close_overlay()
	check(game.frame.visible, "help returns to board")
	game._show_levels()
	check(game.overlay.find_child("Study100", true, false) is Button, "level selector exposes study 100")
	game._select_study(99)
	check(game.stage_index == 99 and game.board.cells.size() == int(game.stage["width"]) * int(game.stage["height"]), "navigation to study 100")
	game._on_reset_pressed()
	await cast(["B2", "C2"], "N")
	game._on_cell_pressed(Vector2i(1, 1))
	game._on_light_pressed("S")
	var before_switch: Array = game.accumulated.duplicate(true)
	var history_before: Array = game.history.duplicate(true)
	var best_before: Dictionary = game.profile.best.duplicate(true)
	game._show_help()
	game._set_language("ja")
	check(TranslationServer.get_locale() == "ja", "Japanese selected")
	check(TranslationServer.translate("CAST LIGHT") == "光を放つ", "Japanese translations registered")
	check(game.accumulated == before_switch and game.history == history_before, "switch preserves layers and history")
	check(game.selected_dots == [Vector2i(1, 1)] and game.selected_light == "S", "switch preserves pending DOT and direction")
	check(game.profile.best == best_before, "switch preserves bests")
	var language_reload: RefCounted = PROFILE.new()
	language_reload.save_path = game.profile.save_path
	language_reload.load_profile()
	check(language_reload.language == "ja", "language preference persists")
	game._set_language("en")
	check(TranslationServer.translate("CAST LIGHT") == "CAST LIGHT", "switch back to English")
	game._close_overlay()
	await process_frame
	game.queue_free()
	await process_frame
	print("AFTERLUX gameplay flow: %s" % ("PASS" if failures == 0 else "%d FAILURES" % failures))
	quit(0 if failures == 0 else 1)

func cast(coords: Array, direction: String) -> void:
	for coord: String in coords:
		game._on_cell_pressed(RULES.coord_to_cell(coord))
	game._on_light_pressed(direction)
	await game._on_fire_pressed()
