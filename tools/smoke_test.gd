extends SceneTree

const RULES = preload("res://src/core/afterlux_rules.gd")


func _init() -> void:
	var stage := {
		"width": 1,
		"height": 4,
		"sockets": ["A1", "A2"],
		"allowed_lights": ["N"],
		"max_dots_per_shot": 2,
		"target": [[0], [0], [0], [0]],
		"par": 1,
	}

	var one_dot: Array[Vector2i] = [Vector2i(0, 0)]
	var stacked: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
	var second_dot: Array[Vector2i] = [Vector2i(0, 1)]

	var shot_a := RULES.make_shot(stage, one_dot, "N")
	_assert_column(shot_a["delta"], [0, 1, 1, 1], "one DOT")

	var shot_b := RULES.make_shot(stage, stacked, "N")
	_assert_column(shot_b["delta"], [0, 0, 2, 2], "two DOTs grouped")

	var total := RULES.empty_grid(1, 4)
	total = RULES.apply_shot(total, shot_a["delta"])
	var shot_c := RULES.make_shot(stage, second_dot, "N")
	total = RULES.apply_shot(total, shot_c["delta"])
	_assert_column(total, [0, 1, 2, 2], "two DOTs split")

	print("AFTERLUX smoke test: PASS")
	quit(0)


func _assert_column(grid: Array, expected: Array, label: String) -> void:
	for y in range(expected.size()):
		if int(grid[y][0]) != int(expected[y]):
			push_error("%s failed at row %d: got %s expected %s" % [label, y, grid[y][0], expected[y]])
			quit(1)
