extends Control

const RULES = preload("res://src/core/afterlux_rules.gd")
const STAGE_PATH := "res://data/stages/tutorial_001_010.json"

var stages: Array = []
var stage_index := 0
var stage: Dictionary = {}

var accumulated: Array = []
var selected_dots: Array[Vector2i] = []
var selected_light := ""
var history: Array = []
var best_by_stage: Dictionary = {}

var stage_label: Label
var score_label: Label
var status_label: Label
var board_grid: GridContainer
var light_row: HBoxContainer
var fire_button: Button
var undo_button: Button
var reset_button: Button
var prev_button: Button
var next_button: Button

var cell_buttons: Dictionary = {}
var light_buttons: Dictionary = {}


func _ready() -> void:
	_build_ui()
	_load_stages()
	_load_stage(0)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#F5F2E9")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var title := Label.new()
	title.text = "AFTERLUX"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 22)
	root.add_child(header)

	stage_label = Label.new()
	stage_label.add_theme_font_size_override("font_size", 18)
	header.add_child(stage_label)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 18)
	header.add_child(score_label)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 8)
	root.add_child(spacer_top)

	var board_center := CenterContainer.new()
	board_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(board_center)

	board_grid = GridContainer.new()
	board_grid.add_theme_constant_override("h_separation", 5)
	board_grid.add_theme_constant_override("v_separation", 5)
	board_center.add_child(board_grid)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 44)
	status_label.add_theme_font_size_override("font_size", 16)
	root.add_child(status_label)

	light_row = HBoxContainer.new()
	light_row.alignment = BoxContainer.ALIGNMENT_CENTER
	light_row.add_theme_constant_override("separation", 8)
	root.add_child(light_row)

	var glyphs := {"N": "↑ N", "S": "↓ S", "W": "← W", "E": "→ E"}
	for light in ["N", "S", "W", "E"]:
		var button := Button.new()
		button.text = glyphs[light]
		button.custom_minimum_size = Vector2(66, 46)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_light_pressed.bind(light))
		light_row.add_child(button)
		light_buttons[light] = button

	fire_button = Button.new()
	fire_button.text = "FIRE"
	fire_button.custom_minimum_size = Vector2(0, 58)
	fire_button.add_theme_font_size_override("font_size", 20)
	fire_button.focus_mode = Control.FOCUS_NONE
	fire_button.pressed.connect(_on_fire_pressed)
	root.add_child(fire_button)

	var utility_row := HBoxContainer.new()
	utility_row.alignment = BoxContainer.ALIGNMENT_CENTER
	utility_row.add_theme_constant_override("separation", 8)
	root.add_child(utility_row)

	undo_button = Button.new()
	undo_button.text = "UNDO"
	undo_button.focus_mode = Control.FOCUS_NONE
	undo_button.pressed.connect(_on_undo_pressed)
	utility_row.add_child(undo_button)

	reset_button = Button.new()
	reset_button.text = "RESET"
	reset_button.focus_mode = Control.FOCUS_NONE
	reset_button.pressed.connect(_on_reset_pressed)
	utility_row.add_child(reset_button)

	var stage_nav := HBoxContainer.new()
	stage_nav.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_nav.add_theme_constant_override("separation", 16)
	root.add_child(stage_nav)

	prev_button = Button.new()
	prev_button.text = "← STAGE"
	prev_button.focus_mode = Control.FOCUS_NONE
	prev_button.pressed.connect(_on_prev_stage)
	stage_nav.add_child(prev_button)

	next_button = Button.new()
	next_button.text = "STAGE →"
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.pressed.connect(_on_next_stage)
	stage_nav.add_child(next_button)


func _load_stages() -> void:
	var file := FileAccess.open(STAGE_PATH, FileAccess.READ)
	assert(file != null, "Could not open stage data: %s" % STAGE_PATH)
	var parsed = JSON.parse_string(file.get_as_text())
	assert(parsed is Array, "Stage JSON must contain an array.")
	stages = parsed

	for item in stages:
		var errors := RULES.validate_stage(item)
		assert(errors.is_empty(), "Invalid stage %s: %s" % [item.get("id", "?"), ", ".join(errors)])


func _load_stage(index: int) -> void:
	stage_index = clampi(index, 0, stages.size() - 1)
	stage = stages[stage_index]
	accumulated = RULES.empty_grid(int(stage["width"]), int(stage["height"]))
	selected_dots.clear()
	history.clear()

	var allowed: Array = stage["allowed_lights"]
	selected_light = str(allowed[0]) if allowed.size() == 1 else ""

	_rebuild_board()
	_refresh_all()
	status_label.text = _stage_hint(str(stage["id"]))


func _rebuild_board() -> void:
	for child in board_grid.get_children():
		child.queue_free()
	cell_buttons.clear()

	board_grid.columns = int(stage["width"])
	var side := 68.0 if int(stage["width"]) <= 4 else 54.0

	for y in range(int(stage["height"])):
		for x in range(int(stage["width"])):
			var cell := Vector2i(x, y)
			var button := Button.new()
			button.custom_minimum_size = Vector2(side, side)
			button.focus_mode = Control.FOCUS_NONE
			button.add_theme_font_size_override("font_size", 18)
			button.pressed.connect(_on_cell_pressed.bind(cell))
			board_grid.add_child(button)
			cell_buttons[cell] = button


func _refresh_all() -> void:
	_refresh_board()
	_refresh_controls()
	_refresh_header()


func _refresh_board() -> void:
	var sockets := RULES.stage_socket_cells(stage)
	for y in range(int(stage["height"])):
		for x in range(int(stage["width"])):
			var cell := Vector2i(x, y)
			var button: Button = cell_buttons[cell]
			var is_socket := sockets.has(cell)
			var is_dot := selected_dots.has(cell)
			var remaining := RULES.remaining_at(stage, accumulated, cell)
			var current := int(accumulated[y][x])

			var marker := ""
			if is_dot:
				marker = "●"
			elif is_socket:
				marker = "○"

			if remaining > 0:
				button.text = "%s\n%d" % [marker, remaining]
			elif remaining == 0:
				button.text = marker
			else:
				button.text = "%s\n%d" % [marker, remaining]

			var shade := clampf(0.96 - float(current) * 0.13, 0.28, 0.96)
			var style := StyleBoxFlat.new()
			style.bg_color = Color(shade, shade, shade)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color("#B8B3A7")
			style.corner_radius_top_left = 7
			style.corner_radius_top_right = 7
			style.corner_radius_bottom_left = 7
			style.corner_radius_bottom_right = 7
			button.add_theme_stylebox_override("normal", style)

			var hover := style.duplicate()
			hover.bg_color = Color(minf(shade + 0.04, 1.0), minf(shade + 0.04, 1.0), minf(shade + 0.04, 1.0))
			button.add_theme_stylebox_override("hover", hover)

			var pressed := style.duplicate()
			pressed.bg_color = Color(maxf(shade - 0.06, 0.2), maxf(shade - 0.06, 0.2), maxf(shade - 0.06, 0.2))
			button.add_theme_stylebox_override("pressed", pressed)


func _refresh_controls() -> void:
	var allowed: Array = stage["allowed_lights"]
	var glyphs := {"N": "↑ N", "S": "↓ S", "W": "← W", "E": "→ E"}

	for light in ["N", "S", "W", "E"]:
		var button: Button = light_buttons[light]
		var available := allowed.has(light)
		button.visible = available
		if available:
			button.text = ("%s  %s" % ["●" if selected_light == light else "○", glyphs[light]])

	fire_button.disabled = selected_dots.is_empty() or selected_light.is_empty()
	undo_button.disabled = history.is_empty()
	prev_button.disabled = stage_index <= 0
	next_button.disabled = stage_index >= stages.size() - 1


func _refresh_header() -> void:
	stage_label.text = "STAGE %s" % stage["id"]
	var shots := history.size()
	var par := int(stage["par"])
	var best_text := ""
	if best_by_stage.has(str(stage["id"])):
		best_text = "  BEST %d" % int(best_by_stage[str(stage["id"])])
	score_label.text = "SHOT %d  PAR %d%s" % [shots, par, best_text]


func _on_cell_pressed(cell: Vector2i) -> void:
	var sockets := RULES.stage_socket_cells(stage)
	if not sockets.has(cell):
		return

	if selected_dots.has(cell):
		selected_dots.erase(cell)
	else:
		var max_dots := int(stage["max_dots_per_shot"])
		if selected_dots.size() >= max_dots:
			status_label.text = "This SHOT allows up to %d DOT%s." % [max_dots, "" if max_dots == 1 else "s"]
			return
		selected_dots.append(cell)

	_refresh_all()


func _on_light_pressed(light: String) -> void:
	selected_light = light
	_refresh_controls()
	status_label.text = "No preview. Read it, then FIRE."


func _on_fire_pressed() -> void:
	if selected_dots.is_empty() or selected_light.is_empty():
		return

	history.append(accumulated.duplicate(true))
	var shot := RULES.make_shot(stage, selected_dots, selected_light)
	accumulated = RULES.apply_shot(accumulated, shot["delta"])
	selected_dots.clear()

	var allowed: Array = stage["allowed_lights"]
	selected_light = str(allowed[0]) if allowed.size() == 1 else ""

	var shots := history.size()
	var par := int(stage["par"])

	if RULES.is_solved(stage, accumulated):
		var id := str(stage["id"])
		if not best_by_stage.has(id) or shots < int(best_by_stage[id]):
			best_by_stage[id] = shots
		if shots == par:
			status_label.text = "PAR. Clean light."
		else:
			status_label.text = "CLEAR in %d. PAR is %d. Can you compress it?" % [shots, par]
	elif RULES.is_overshot(stage, accumulated):
		status_label.text = "OVER. A zero-hole or a split SHOT can save it."
	else:
		status_label.text = "Shadow fixed. Build the next layer."

	_refresh_all()


func _on_undo_pressed() -> void:
	if history.is_empty():
		return
	accumulated = history.pop_back()
	selected_dots.clear()
	var allowed: Array = stage["allowed_lights"]
	selected_light = str(allowed[0]) if allowed.size() == 1 else ""
	status_label.text = "Rewound one SHOT."
	_refresh_all()


func _on_reset_pressed() -> void:
	accumulated = RULES.empty_grid(int(stage["width"]), int(stage["height"]))
	selected_dots.clear()
	history.clear()
	var allowed: Array = stage["allowed_lights"]
	selected_light = str(allowed[0]) if allowed.size() == 1 else ""
	status_label.text = _stage_hint(str(stage["id"]))
	_refresh_all()


func _on_prev_stage() -> void:
	_load_stage(stage_index - 1)


func _on_next_stage() -> void:
	_load_stage(stage_index + 1)


func _stage_hint(id: String) -> String:
	match id:
		"001":
			return "Place the DOT. FIRE."
		"002":
			return "Same DOT, different light."
		"003":
			return "Shadows stay."
		"004":
			return "Two SOCKETS. One DOT per SHOT."
		"005":
			return "Let two directions cross."
		"006":
			return "Two DOTs can share one SHOT."
		"007":
			return "A DOT cell is a zero-hole."
		"008":
			return "Same SOCKETS. This time, splitting matters."
		"009":
			return "SOLO + GROUP."
		"010":
			return "CLEAR is good. PAR is the puzzle."
	return "Make every remaining number zero."
