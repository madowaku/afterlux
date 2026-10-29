extends SceneTree

# Renders key AFTERLUX moments to artifacts/screens/ for visual review.
# Needs a rendering driver: run without --headless.
const MAIN = preload("res://game/main/main.gd")
const RULES = preload("res://src/core/afterlux_rules.gd")
const OUT: String = "res://artifacts/screens"
var game: Control

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(360, 800)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game = MAIN.new()
	game.profile.save_path = "res://artifacts/capture_test.cfg"
	if FileAccess.file_exists(game.profile.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.profile.save_path))
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.profile.sound = false
	for locale: String in ["en", "ja"]:
		game._set_language(locale)
		await _capture_stack_lesson(locale)
	game._set_language("en")
	game._load_stage(19)
	game._on_reset_pressed()
	await _quick_cast(["B2", "D2"], "N")
	await _snap("020_5x5_progress_en")
	game._load_stage(9)
	game._on_reset_pressed()
	for coords: Array in [["A1"], ["A1"], ["B1"]]:
		await _quick_cast(coords, "N")
	await _snap("010_clear_above_par_en")
	game._on_reset_pressed()
	await _quick_cast(["A1"], "N")
	await _quick_cast(["A1", "B1"], "N")
	await _snap("010_par_en")
	game._show_help()
	await _snap("help_en")
	game._close_overlay()
	game.queue_free()
	await process_frame
	print("AFTERLUX capture: PASS")
	quit(0)

# Study 013: B1+B3 under north light stacks two shadows on B4 in one shot.
func _capture_stack_lesson(locale: String) -> void:
	game.profile.reduced_motion = false
	game._load_stage(12)
	game._on_reset_pressed()
	await _snap("013_fresh_%s" % locale)
	for coord: String in ["B1", "B3"]:
		game._on_cell_pressed(RULES.coord_to_cell(coord))
	game._on_light_pressed("N")
	await _snap("013_aimed_%s" % locale)
	game._on_fire_pressed()
	await create_timer(0.27).timeout
	await _snap("013_beams_%s" % locale)
	await create_timer(0.6).timeout
	await _snap("013_after_stack_%s" % locale)

func _quick_cast(coords: Array, direction: String) -> void:
	game.profile.reduced_motion = true
	for coord: String in coords:
		game._on_cell_pressed(RULES.coord_to_cell(coord))
	game._on_light_pressed(direction)
	await game._on_fire_pressed()
	game.profile.reduced_motion = false

func _snap(file_name: String) -> void:
	for _i: int in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, file_name])
