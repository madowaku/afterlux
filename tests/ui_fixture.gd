extends "res://game/main/main.gd"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	profile.save_path = "res://artifacts/ui_fixture.cfg"
	profile.language = "en"
	# Only remove the fixture's own disposable save, never player progress.
	if FileAccess.file_exists(profile.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(profile.save_path))
	super._ready()
	profile.sound = false
