extends SceneTree

const STYLE = preload("res://game/ui/style.gd")

func _init() -> void:
	var result: Error = ResourceSaver.save(STYLE.create_theme(), "res://game/ui/afterlux_theme.tres")
	quit(0 if result == OK else 1)
