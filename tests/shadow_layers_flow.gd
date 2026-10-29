extends SceneTree

# Shadow-layer readability: per-DOT beams, "+N" badges, stacking callout and the PAR retry loop.
const MAIN = preload("res://game/main/main.gd")
const RULES = preload("res://src/core/afterlux_rules.gd")
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
	game.profile.save_path = "res://artifacts/shadow_layers_test.cfg"
	if FileAccess.file_exists(game.profile.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.profile.save_path))
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.profile.sound = false
	game.profile.reduced_motion = false
	game._set_language("en")
	await process_frame
	var board: PanelContainer = game.board
	# Beam timing staggers one ray per DOT so a stacked cell visibly receives two arrivals.
	var one: float = board.cast("N", [Vector2i(1, 0)] as Array[Vector2i], false)
	var two: float = board.cast("N", [Vector2i(1, 0), Vector2i(1, 2)] as Array[Vector2i], false)
	check(one > 0.0 and two > one, "each extra DOT extends the beam animation")
	check(board.cast("N", [Vector2i(1, 0)] as Array[Vector2i], true) == 0.0, "reduced motion skips beams")
	board.stop_effects()
	# Study 013: B1+B3 under north light puts 2 on B4 in a single shot.
	game._load_stage(12)
	game._on_reset_pressed()
	game._on_light_pressed("N")
	check(board.aim == "N", "selected light marks its entry edge")
	await cast(["B1", "B3"], "N")
	check(game.history.size() == 1 and game.accumulated[3][1] == 2 and game.accumulated[2][1] == 0, "one shot stacks 2 beyond a DOT pair")
	check(int(board.last_delta[3][1]) == 2 and int(board.last_delta[1][1]) == 1, "latest shot keeps its +N per cell")
	check("+2" in game.status_label.text, "stacked shot names the +2")
	game._on_cell_pressed(RULES.coord_to_cell("B1"))
	check(board.last_delta.is_empty(), "next placement clears the previous +N")
	game._on_cell_pressed(RULES.coord_to_cell("B1"))
	await cast(["B1"], "N")
	check("+2" not in game.status_label.text, "single-layer shots keep the normal message")
	game._on_undo_pressed()
	check(board.last_delta.is_empty(), "undo clears the +N")
	# Study 007: the first +2 also clears at PAR, so the callout must live in the visible result.
	game._load_stage(6)
	game._on_reset_pressed()
	await cast(["A1", "A2"], "N")
	check(game.solved and game.result_panel.visible and not game.status_label.is_visible_in_tree(), "007 clears in one stacked shot")
	check("+2" in game.result_body.text and game.result_body.is_visible_in_tree(), "007 result names the +2")
	game._on_undo_pressed()
	check(not game.solved and not game.result_panel.visible and game.last_stack == 0, "undo forgets the stacked callout")
	# Study 010: a 3-shot clear offers a PAR retry; a PAR clear goes straight on.
	game._load_stage(9)
	game._on_reset_pressed()
	for coords: Array in [["A1"], ["A1"], ["B1"]]:
		await cast(coords, "N")
	check(game.solved and game.retry_button.visible, "above-PAR clear offers TRY FOR PAR")
	check(board.aim.is_empty(), "solved board hides the light marker")
	game.retry_button.pressed.emit()
	check(not game.solved and game.history.is_empty() and int(game.profile.best["010"]) == 3, "retry restarts and keeps the best")
	await cast(["A1"], "N")
	await cast(["A1", "B1"], "N")
	check(game.solved and not game.retry_button.visible, "PAR clear hides the retry")
	check("+2" not in game.result_body.text, "single-layer clear has no stacked callout")
	game._set_language("ja")
	game._load_stage(12)
	game._on_reset_pressed()
	await cast(["B1", "B3"], "N")
	check("+2" in game.status_label.text and "影が重なりました" in game.status_label.text, "stack message is translated")
	game._load_stage(6)
	game._on_reset_pressed()
	await cast(["A1", "A2"], "N")
	check("影が重なりました" in game.result_body.text, "007 result callout is translated")
	game._set_language("en")
	check("Shadows overlapped" in game.result_body.text, "language switch re-renders the result callout")
	game._set_language("en")
	game.queue_free()
	await process_frame
	print("AFTERLUX shadow layers: %s" % ("PASS" if failures == 0 else "%d FAILURES" % failures))
	quit(0 if failures == 0 else 1)

func cast(coords: Array, direction: String) -> void:
	for coord: String in coords:
		game._on_cell_pressed(RULES.coord_to_cell(coord))
	game._on_light_pressed(direction)
	await game._on_fire_pressed()
