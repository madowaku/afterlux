extends Control

const RULES = preload("res://src/core/afterlux_rules.gd")
const STYLE = preload("res://game/ui/style.gd")
const BOARD = preload("res://game/board/board_view.gd")
const PROFILE = preload("res://src/data/player_profile.gd")
const AMBIENCE = preload("res://game/ui/ambience.gd")
const STAGE_PATH: String = "res://data/stages/tutorial_001_100.json"
const SOUNDS: Dictionary = {
	"place": preload("res://assets/kenney/audio/place.ogg"),
	"cast": preload("res://assets/kenney/audio/cast.ogg"),
	"clear": preload("res://assets/kenney/audio/clear.ogg"),
}
const LIGHT_LABELS: Dictionary = {"N": "↓  N", "S": "↑  S", "W": "→  W", "E": "←  E"}
const ICON_SOUND: Texture2D = preload("res://assets/kenney/icons/audioOn.png")
const ICON_MUTE: Texture2D = preload("res://assets/kenney/icons/audioOff.png")
const ICON_MENU: Texture2D = preload("res://assets/kenney/icons/barsHorizontal.png")
const ICON_INFO: Texture2D = preload("res://assets/kenney/icons/information.png")
const TITLES: Array[String] = [
	"First light", "A new angle", "Afterglow", "Two beginnings", "Crossing paths",
	"Better together", "The quiet space", "One at a time", "A little of both", "Less is more",
	"Read between", "Hidden layers", "Three small acts", "A different sum", "Same places",
	"Full circle", "Changing sides", "A deeper shade", "Quiet complexity", "Light, mastered",
]
const HINTS: Array[String] = [
	"Tap the ring to place a DOT. Light from above casts a shadow below it.",
	"Choose where light enters. The arrow shows where the shadow travels.",
	"Shadows stay after each shot. A 2 needs two layers of shadow.",
	"Two sockets, one DOT per shot. Build one layer, then the next.",
	"Light can travel down or across. Find a place for each shadow.",
	"You can now place two DOTs before casting. Can one shot do both jobs?",
	"DOT cells receive no shadow this shot. Beyond them, shadows add up.",
	"Same sockets, a different target. What changes if you split the shots?",
	"One DOT or two? Different layers may need different groupings.",
	"Find a clear first. Then try to make the same shadows in fewer shots.",
	"Read the empty spaces, too. A zero tells you where a shadow cannot fall.",
	"Separate the target into simple layers. Which shadow belongs on its own?",
	"An aligned pair can leave a quiet space between layers.",
	"A 3 is several shadows meeting. Find the pieces of the sum.",
	"Familiar sockets, a new arrangement. Look again before casting.",
	"All four lights are available. Arrows show the direction shadows travel.",
	"Start with the cells that only one direction can reach.",
	"DOTs protect their cells while shadows continue beyond them.",
	"Small layers build a complex whole. Take your time; Undo is unlimited.",
	"Five by five. Everything you need is already in the rules.",
]

var stages: Array = []
var stage_index: int = 0
var stage: Dictionary = {}
var accumulated: Array = []
var selected_dots: Array[Vector2i] = []
var selected_light: String = ""
var history: Array = []
var profile: RefCounted = PROFILE.new()
var busy: bool = false
var solved: bool = false
var save_failed: bool = false
var last_stack: int = 0
var frame: MarginContainer
var column: VBoxContainer
var board: PanelContainer
var chapter_label: Label
var title_label: Label
var index_label: Label
var shots_label: Label
var par_label: Label
var best_label: Label
var remaining_label: Label
var dots_label: Label
var status_label: Label
var step_label: Label
var fire_button: Button
var undo_button: Button
var reset_button: Button
var next_button: Button
var retry_button: Button
var levels_button: Button
var help_button: Button
var sound_button: Button
var light_buttons: Dictionary = {}
var result_panel: PanelContainer
var result_title: Label
var result_body: Label
var overlay: Panel
var overlay_panel_body: VBoxContainer
var overlay_scroll: ScrollContainer
var overlay_column: VBoxContainer
var modal_return_focus: Control
var audio_player: AudioStreamPlayer
var language_buttons: Dictionary = {}

func _ready() -> void:
	profile.load_profile()
	if profile.language.is_empty():
		profile.language = "ja" if OS.get_locale_language() == "ja" else "en"
	TranslationServer.set_locale(profile.language)
	_load_stages()
	_build_ui()
	_load_stage(clampi(profile.stage_index, 0, stages.size() - 1))
	resized.connect(_fit_layout)
	_fit_layout()

func _build_ui() -> void:
	add_child(AMBIENCE.new())
	audio_player = AudioStreamPlayer.new()
	audio_player.volume_db = -15
	add_child(audio_player)
	frame = MarginContainer.new()
	frame.name = "Frame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_top", 12)
	frame.add_theme_constant_override("margin_bottom", 12)
	add_child(frame)
	column = VBoxContainer.new()
	column.name = "Column"
	frame.add_child(column)
	var masthead: HBoxContainer = _row(column, "Masthead")
	var brand: VBoxContainer = VBoxContainer.new()
	brand.add_theme_constant_override("separation", 0)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	masthead.add_child(brand)
	brand.add_child(STYLE.label("A F T E R L U X", 20, STYLE.MINT))
	brand.add_child(STYLE.label("THE ART OF A LITTLE LESS", 9, STYLE.MUTED))
	help_button = STYLE.button("?", _show_help)
	help_button.name = "Help"
	help_button.custom_minimum_size.x = 44
	help_button.tooltip_text = "How to play & settings"
	_set_icon(help_button, ICON_INFO)
	masthead.add_child(help_button)
	levels_button = STYLE.button("⋮", _show_levels)
	levels_button.name = "Levels"
	levels_button.custom_minimum_size.x = 44
	levels_button.tooltip_text = "Choose a study"
	_set_icon(levels_button, ICON_MENU)
	masthead.add_child(levels_button)
	chapter_label = STYLE.label("", 10, STYLE.GOLD)
	chapter_label.name = "Chapter"
	column.add_child(chapter_label)
	var heading: HBoxContainer = _row(column, "Heading")
	title_label = STYLE.label("", 25)
	title_label.name = "Title"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title_label)
	index_label = STYLE.label("", 24, STYLE.MUTED)
	heading.add_child(index_label)
	var scores: HBoxContainer = _row(column, "Scores")
	shots_label = _stat(scores, "SHOTS", "Shots")
	par_label = _stat(scores, "PAR", "Par")
	best_label = _stat(scores, "BEST", "Best")
	var board_slot: CenterContainer = CenterContainer.new()
	board_slot.name = "BoardSlot"
	board_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(board_slot)
	var board_column: VBoxContainer = VBoxContainer.new()
	board_column.add_theme_constant_override("separation", 8)
	board_slot.add_child(board_column)
	var board_meta: HBoxContainer = _row(board_column, "BoardMeta")
	remaining_label = STYLE.label("", 10, STYLE.MUTED)
	remaining_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_meta.add_child(remaining_label)
	dots_label = STYLE.label("", 10, STYLE.MINT)
	board_meta.add_child(dots_label)
	board = BOARD.new()
	board.name = "Board"
	board_column.add_child(board)
	board.cell_pressed.connect(_on_cell_pressed)
	var legend: Label = STYLE.label("○  DOT socket    1  shadow still needed    ●○  layers", 10, STYLE.MUTED)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_column.add_child(legend)
	var instruction: VBoxContainer = VBoxContainer.new()
	instruction.name = "Instruction"
	instruction.add_theme_constant_override("separation", 4)
	column.add_child(instruction)
	step_label = STYLE.label("", 10, STYLE.GOLD)
	instruction.add_child(step_label)
	status_label = STYLE.label("", 14, STYLE.PAPER)
	status_label.name = "Status"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 40
	instruction.add_child(status_label)
	var light_row: HBoxContainer = _row(column, "Lights")
	for direction: String in ["N", "S", "W", "E"]:
		var button: Button = STYLE.button(str(LIGHT_LABELS[direction]), _on_light_pressed.bind(direction))
		button.name = direction
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = "Light from " + {"N": "north", "S": "south", "W": "west", "E": "east"}[direction]
		light_row.add_child(button)
		light_buttons[direction] = button
	fire_button = STYLE.button("CAST LIGHT", _on_fire_pressed)
	fire_button.name = "Fire"
	fire_button.custom_minimum_size.y = 52
	fire_button.add_theme_font_size_override("font_size", 16)
	STYLE.accent(fire_button, true)
	column.add_child(fire_button)
	result_panel = PanelContainer.new()
	result_panel.name = "Result"
	result_panel.add_theme_stylebox_override("panel", STYLE.box(Color("203c35"), Color("567c66"), 12, 12))
	column.add_child(result_panel)
	var result_column: VBoxContainer = VBoxContainer.new()
	result_column.add_theme_constant_override("separation", 4)
	result_panel.add_child(result_column)
	result_title = STYLE.label("", 19, STYLE.MINT)
	result_column.add_child(result_title)
	result_body = STYLE.label("", 12)
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_column.add_child(result_body)
	var result_actions: HBoxContainer = _row(result_column, "ResultActions")
	retry_button = STYLE.button("TRY FOR PAR", _on_reset_pressed)
	retry_button.name = "Retry"
	retry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_actions.add_child(retry_button)
	next_button = STYLE.button("NEXT STUDY  →", _on_next_stage)
	next_button.name = "Next"
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_actions.add_child(next_button)
	var utility: HBoxContainer = _row(column, "Utility")
	undo_button = STYLE.button("Undo", _on_undo_pressed)
	undo_button.name = "Undo"
	undo_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility.add_child(undo_button)
	reset_button = STYLE.button("Restart", _request_reset)
	reset_button.name = "Reset"
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility.add_child(reset_button)
	sound_button = STYLE.button("♪", _toggle_sound)
	sound_button.name = "Sound"
	sound_button.custom_minimum_size.x = 44
	utility.add_child(sound_button)
	result_panel.hide()

func _row(parent: Node, node_name: String) -> HBoxContainer:
	var result: HBoxContainer = HBoxContainer.new()
	result.name = node_name
	parent.add_child(result)
	return result

func _stat(parent: Node, caption: String, node_name: String) -> Label:
	var item: HBoxContainer = HBoxContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(item)
	item.add_child(STYLE.label(caption, 10, STYLE.MUTED))
	var value: Label = STYLE.label("--", 22)
	value.name = node_name
	item.add_child(value)
	return value

func _fit_layout() -> void:
	var inset: int = int(maxf(20, (size.x - 400) * 0.5))
	frame.add_theme_constant_override("margin_left", inset)
	frame.add_theme_constant_override("margin_right", inset)
	var side: float = minf(minf(360, size.y - 480), size.x - inset * 2)
	board.custom_minimum_size = Vector2(side, side)
	board._resize_cells()
	column.add_theme_constant_override("separation", 8 if size.y < 850 else 12)

func _load_stages() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STAGE_PATH))
	assert(parsed is Array and parsed.size() == 100, "Stage bank must contain exactly 100 curated puzzles.")
	stages = parsed
	for item: Dictionary in stages:
		assert(RULES.validate_stage(item).is_empty(), "Invalid stage data")

func _load_stage(index: int) -> void:
	stage_index = clampi(index, 0, stages.size() - 1)
	profile.stage_index = stage_index
	stage = stages[stage_index]
	selected_dots.clear()
	last_stack = 0
	selected_light = str(stage["allowed_lights"][0])
	history = _validated_history(profile.runs.get(str(stage["id"]), []))
	_rebuild_accumulated()
	busy = false
	board.build(stage)
	status_label.text = _stage_hint()
	status_label.add_theme_color_override("font_color", STYLE.PAPER)
	_refresh_all()
	_save()

func _validated_history(raw: Variant) -> Array:
	var result: Array = []
	if not raw is Array or raw.size() > 1000:
		return result
	for item: Variant in raw:
		if not item is Dictionary or not item.get("dots", null) is Array or not stage["allowed_lights"].has(item.get("light", "")):
			return []
		var dots: Array[Vector2i] = []
		for coord: Variant in item["dots"]:
			if not coord is String or not stage["sockets"].has(coord):
				return []
			var cell: Vector2i = RULES.coord_to_cell(coord)
			if dots.has(cell):
				return []
			dots.append(cell)
		if dots.is_empty() or dots.size() > int(stage["max_dots_per_shot"]):
			return []
		result.append({"dots": item["dots"].duplicate(), "light": str(item["light"])})
	return result

func _rebuild_accumulated() -> void:
	accumulated = RULES.empty_grid(int(stage["width"]), int(stage["height"]))
	for shot: Dictionary in history:
		var dots: Array[Vector2i] = []
		for coord: String in shot["dots"]:
			dots.append(RULES.coord_to_cell(coord))
		accumulated = RULES.apply_shot(accumulated, RULES.make_shot(stage, dots, str(shot["light"]))["delta"])

func _refresh_all() -> void:
	solved = RULES.is_solved(stage, accumulated)
	board.refresh(stage, accumulated, selected_dots, busy or solved)
	chapter_label.text = tr(str(stage.get("chapter_key", "01 / READING LIGHT")))
	title_label.text = tr(str(stage.get("title_key", TITLES[stage_index % TITLES.size()])))
	index_label.text = "%03d" % (stage_index + 1)
	shots_label.text = "%02d" % history.size()
	par_label.text = "%02d" % int(stage["par"])
	best_label.text = "%02d" % int(profile.best[str(stage["id"])]) if profile.best.has(str(stage["id"])) else "—"
	var remaining: int = 0
	for y: int in range(int(stage["height"])):
		for x: int in range(int(stage["width"])):
			remaining += maxi(0, RULES.remaining_at(stage, accumulated, Vector2i(x, y)))
	remaining_label.text = tr("%02d  SHADOWS LEFT") % remaining
	dots_label.text = tr("DOTS  %d / %d") % [selected_dots.size(), int(stage["max_dots_per_shot"])]
	for direction: String in light_buttons:
		var button: Button = light_buttons[direction]
		button.disabled = busy or not stage["allowed_lights"].has(direction)
		STYLE.accent(button, selected_light == direction)
		button.get_parent().visible = not solved
	fire_button.disabled = busy or selected_dots.is_empty() or solved
	fire_button.visible = not solved
	fire_button.text = "CASTING…" if busy else "CAST LIGHT"
	undo_button.disabled = busy or history.is_empty()
	reset_button.disabled = busy or (history.is_empty() and selected_dots.is_empty())
	help_button.disabled = busy
	levels_button.disabled = busy
	board.set_aim("" if solved or busy else selected_light)
	result_panel.visible = solved
	status_label.get_parent().visible = not solved
	if solved:
		var at_par: bool = history.size() <= int(stage["par"])
		result_title.text = "Perfectly simple." if at_par else "A beautiful beginning."
		result_title.add_theme_color_override("font_color", STYLE.GOLD if at_par else STYLE.MINT)
		result_panel.add_theme_stylebox_override("panel", STYLE.box(Color("2c2a20") if at_par else Color("203c35"), STYLE.GOLD if at_par else Color("567c66"), 12, 12))
		result_body.text = tr("PAR %d · Every shot earned its place.") % history.size() if at_par else tr("Cleared in %d. Can you find the %d-shot solution?") % [history.size(), int(stage["par"])]
		# The status line is hidden once solved, so a clearing shot that stacked is named here (e.g. study 007).
		if last_stack > 1:
			result_body.text += "
" + _stack_message()
		next_button.text = "EXPLORE THE STUDIES" if stage_index == stages.size() - 1 else "NEXT STUDY  →"
		# CLEAR above PAR invites one more compression attempt; PAR moves on.
		retry_button.visible = not at_par
		STYLE.accent(retry_button, not at_par)
		STYLE.accent(next_button, at_par)
	step_label.text = tr("01 / PLACE A DOT") if selected_dots.is_empty() else tr("02 / LIGHT FROM %s · READY") % tr({"N": "NORTH", "S": "SOUTH", "W": "WEST", "E": "EAST"}[selected_light])
	_update_sound_button()

func _on_cell_pressed(cell: Vector2i) -> void:
	if busy or solved or is_instance_valid(overlay) or not RULES.stage_socket_cells(stage).has(cell):
		return
	if selected_dots.has(cell):
		selected_dots.erase(cell)
	elif selected_dots.size() >= int(stage["max_dots_per_shot"]):
		status_label.text = tr("Up to %d DOTs this shot. Tap a placed DOT to remove it.") % int(stage["max_dots_per_shot"])
		return
	else:
		selected_dots.append(cell)
	board.clear_delta()
	last_stack = 0
	_play("place")
	status_label.text = _stage_hint()
	_refresh_all()

func _on_light_pressed(direction: String) -> void:
	if busy or solved or not stage["allowed_lights"].has(direction):
		return
	selected_light = direction
	_play("place")
	_refresh_all()

func _on_fire_pressed() -> void:
	if busy or solved or selected_dots.is_empty() or is_instance_valid(overlay):
		return
	busy = true
	_refresh_all()
	var shot: Dictionary = RULES.make_shot(stage, selected_dots, selected_light)
	var coords: Array[String] = []
	for cell: Vector2i in selected_dots:
		coords.append(RULES.cell_to_coord(cell))
	history.append({"dots": coords, "light": selected_light})
	_play("cast")
	var duration: float = board.cast(selected_light, selected_dots, profile.reduced_motion)
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
	accumulated = RULES.apply_shot(accumulated, shot["delta"])
	last_stack = _max_layer(shot["delta"])
	selected_dots.clear()
	busy = false
	if RULES.is_solved(stage, accumulated):
		var id: String = str(stage["id"])
		profile.best[id] = mini(history.size(), int(profile.best.get(id, history.size())))
		board.celebrate(profile.reduced_motion)
		_play("clear")
	elif RULES.is_overshot(stage, accumulated):
		status_label.text = "Too much shadow. Coral cells show the excess. Undo and try another layer."
		status_label.add_theme_color_override("font_color", STYLE.ERROR)
	elif last_stack > 1:
		# A single shot that stacks shadows is the rule most often misread; name it right away.
		status_label.text = _stack_message()
		status_label.add_theme_color_override("font_color", STYLE.GOLD)
	else:
		status_label.text = "That shadow stays. Place the next layer."
		status_label.add_theme_color_override("font_color", STYLE.PAPER)
	_refresh_all()
	board.show_delta(shot["delta"], profile.reduced_motion)
	if not profile.reduced_motion:
		board.flash_delta(shot["delta"])
	_save()
	if solved:
		next_button.grab_focus()

func _on_undo_pressed() -> void:
	if busy or history.is_empty():
		return
	history.pop_back()
	selected_dots.clear()
	_rebuild_accumulated()
	board.stop_effects()
	board.clear_delta()
	last_stack = 0
	status_label.text = "One layer rewound. Try a different grouping or light."
	status_label.add_theme_color_override("font_color", STYLE.PAPER)
	_play("place")
	_refresh_all()
	_save()

func _on_reset_pressed() -> void:
	if busy:
		return
	history.clear()
	selected_dots.clear()
	_rebuild_accumulated()
	board.stop_effects()
	board.clear_delta()
	last_stack = 0
	status_label.text = _stage_hint()
	status_label.add_theme_color_override("font_color", STYLE.PAPER)
	_refresh_all()
	_save()

func _on_next_stage() -> void:
	if busy:
		return
	if stage_index >= stages.size() - 1:
		_show_levels()
	else:
		_load_stage(stage_index + 1)

func _save() -> void:
	profile.runs[str(stage["id"])] = history.duplicate(true)
	save_failed = profile.save_profile() != OK
	if save_failed:
		status_label.text = "Progress could not be saved. You can keep playing this session."

func _play(sound_name: String) -> void:
	if profile.sound:
		audio_player.stream = SOUNDS[sound_name]
		audio_player.play()

func _toggle_sound() -> void:
	profile.sound = not profile.sound
	if not profile.sound:
		audio_player.stop()
	_update_sound_button()
	_play("place")
	_save()

func _update_sound_button() -> void:
	_set_icon(sound_button, ICON_SOUND if profile.sound else ICON_MUTE)
	sound_button.tooltip_text = "Sound on · tap to mute" if profile.sound else "Sound off · tap to unmute"

func _set_icon(button: Button, texture: Texture2D) -> void:
	button.text = ""
	button.icon = texture
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 18)

func _open_overlay(title: String, subtitle: String) -> void:
	if busy:
		return
	modal_return_focus = get_viewport().gui_get_focus_owner()
	frame.hide()
	overlay = Panel.new()
	overlay.name = "Overlay"
	overlay.add_theme_stylebox_override("panel", STYLE.box(Color("0c191ef5"), STYLE.INK, 0, 0))
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = 320
	panel.custom_minimum_size.y = minf(680.0, size.y - 48.0)
	panel.add_theme_stylebox_override("panel", STYLE.box(STYLE.PANEL, STYLE.EDGE, 18, 20))
	center.add_child(panel)
	overlay_panel_body = VBoxContainer.new()
	overlay_panel_body.name = "Body"
	overlay_panel_body.add_theme_constant_override("separation", 8)
	panel.add_child(overlay_panel_body)
	overlay_scroll = ScrollContainer.new()
	overlay_scroll.name = "Scroll"
	overlay_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_panel_body.add_child(overlay_scroll)
	overlay_column = VBoxContainer.new()
	overlay_column.name = "Content"
	overlay_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_scroll.add_child(overlay_column)
	overlay_column.add_child(STYLE.label(title, 26, STYLE.MINT))
	var caption: Label = STYLE.label(subtitle, 12, STYLE.MUTED)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_column.add_child(caption)

func _close_overlay() -> void:
	if not is_instance_valid(overlay):
		return
	remove_child(overlay)
	overlay.queue_free()
	overlay = null
	frame.show()
	if is_instance_valid(modal_return_focus) and modal_return_focus.is_visible_in_tree():
		modal_return_focus.grab_focus()

func _overlay_close_button() -> void:
	var close: Button = STYLE.button("BACK TO THE LIGHT", _close_overlay)
	close.name = "Close"
	overlay_panel_body.add_child(close)
	close.grab_focus()

func _show_levels() -> void:
	_open_overlay("Light studies", "100 small puzzles. Explore freely; every study remembers your layers.")
	var chapters: Array[String] = ["01 / READING LIGHT", "02 / TOGETHER & APART", "03 / HIDDEN LAYERS", "04 / EVERY DIRECTION", "05 / ZERO HAS A SHAPE", "06 / CROSSING LIGHT", "07 / GROUP & SPLIT", "08 / FOUR EDGES", "09 / DEEPER LOGIC", "10 / OPEN HORIZON", "11 / MASTERY", "12 / FINALE"]
	var first_stage: int = 0
	for chapter: int in range(chapters.size()):
		overlay_column.add_child(STYLE.label(chapters[chapter], 10, STYLE.GOLD))
		var grid: GridContainer = GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 6)
		overlay_column.add_child(grid)
		var stage_count: int = 5 if chapter < 4 else 10
		for offset: int in range(stage_count):
			var index: int = first_stage + offset
			var stage_item: Dictionary = stages[index]
			var id: String = str(stage_item["id"])
			var badge: String = ""
			if profile.best.has(id):
				badge = "·" if int(profile.best[id]) > int(stage_item["par"]) else "*"
			var button: Button = STYLE.button("%03d%s" % [index + 1, badge], _select_study.bind(index))
			button.name = "Study%03d" % (index + 1)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 11)
			button.add_theme_stylebox_override("normal", STYLE.box(STYLE.MINT if index == stage_index else STYLE.PANEL, STYLE.MINT if index == stage_index else STYLE.EDGE, 9, 4))
			button.add_theme_stylebox_override("hover", STYLE.box(Color("20373b"), STYLE.MINT, 9, 4))
			button.add_theme_stylebox_override("pressed", STYLE.box(STYLE.MINT, STYLE.MINT, 9, 4))
			button.add_theme_stylebox_override("focus", STYLE.box(Color.TRANSPARENT, STYLE.GOLD, 9, 4))
			button.add_theme_color_override("font_color", STYLE.INK if index == stage_index else STYLE.PAPER)
			button.tooltip_text = tr(str(stage_item.get("title_key", ""))) + (tr(" · PAR achieved") if badge == "*" else "")
			grid.add_child(button)
		first_stage += stage_count
	var progress: Label = STYLE.label(tr("%d / 100 CLEARED    ·  clear    *  at PAR") % mini(profile.best.size(), 100), 11, STYLE.MUTED)
	overlay_column.add_child(progress)
	_overlay_close_button()
	call_deferred("_scroll_to_current_study")

func _scroll_to_current_study() -> void:
	await get_tree().process_frame
	if not is_instance_valid(overlay_scroll):
		return
	var current: Node = overlay_scroll.find_child("Study%03d" % (stage_index + 1), true, false)
	if current is Control:
		overlay_scroll.ensure_control_visible(current)

func _select_study(index: int) -> void:
	_close_overlay()
	_load_stage(index)

func _show_help() -> void:
	_open_overlay("A little light.", "Make every number reach zero. Take all the time you need.")
	overlay_column.add_theme_constant_override("separation", 8)
	var languages: HBoxContainer = _row(overlay_column, "Languages")
	language_buttons.clear()
	for locale: String in ["ja", "en"]:
		var language_button: Button = STYLE.button("日本語" if locale == "ja" else "English", _set_language.bind(locale))
		language_button.name = locale
		language_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		language_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		languages.add_child(language_button)
		language_buttons[locale] = language_button
		STYLE.accent(language_button, profile.language == locale)
	var lessons: Array[Array] = [
		["01  PLACE", "Tap a ring to place a DOT. Tap it again to remove it."],
		["02  CAST", "Pick a light. Each DOT adds 1 shadow to every cell beyond it. Shadows stay between shots."],
		["03  STACK", "Every DOT casts its own shadow. DOTs in the same line overlap, so one shot can add 2 to a cell. The dots under each cell count its layers."],
		["04  DISCOVER", "DOT cells receive no shadow that shot, but rays continue through them. Grouping and splitting give different results."],
		["05  COMPRESS", "Any exact solution is a clear. PAR is the proven fewest shots. Undo is unlimited."],
	]
	for lesson: Array in lessons:
		overlay_column.add_child(STYLE.label(lesson[0], 11, STYLE.GOLD))
		var body: Label = STYLE.label(lesson[1], 13)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		overlay_column.add_child(body)
	var motion: Button = STYLE.button("", _toggle_motion)
	motion.name = "Motion"
	motion.text = "Motion: reduced" if profile.reduced_motion else "Motion: full"
	overlay_column.add_child(motion)
	var credits: Label = STYLE.label("Art & audio: Kenney · CC0\nNo timer. No penalty for trying.\nKeyboard: Tab / Enter · Ctrl+Z to undo", 10, STYLE.MUTED)
	overlay_column.add_child(credits)
	_overlay_close_button()

func _set_language(locale: String) -> void:
	if locale not in ["en", "ja"] or busy:
		return
	profile.language = locale
	TranslationServer.set_locale(locale)
	# Plain Control text re-translates automatically. Reformat numeric captions.
	status_label.text = "Too much shadow. Coral cells show the excess. Undo and try another layer." if RULES.is_overshot(stage, accumulated) else _stage_hint()
	_refresh_all()
	if is_instance_valid(overlay):
		for code: String in language_buttons:
			var button: Button = language_buttons[code]
			if is_instance_valid(button):
				STYLE.accent(button, code == locale)
	_save()

func _toggle_motion() -> void:
	profile.reduced_motion = not profile.reduced_motion
	var button: Button = overlay_column.get_node("Motion") as Button
	button.text = "Motion: reduced" if profile.reduced_motion else "Motion: full"
	_save()

func _max_layer(delta: Array) -> int:
	var result: int = 0
	for row: Array in delta:
		for value: Variant in row:
			result = maxi(result, int(value))
	return result

func _stack_message() -> String:
	return tr("Shadows overlapped: one shot added +%d to a cell. DOTs in a line each cast their own shadow.") % last_stack

func _stage_hint() -> String:
	return tr(str(stage.get("hint_key", HINTS[stage_index % HINTS.size()])))

func _request_reset() -> void:
	if history.is_empty() or solved:
		_on_reset_pressed()
		return
	_open_overlay("A fresh start?", "This clears the current layers. Your best result stays saved.")
	var restart: Button = STYLE.button("RESTART THIS STUDY", _confirm_reset)
	overlay_column.add_child(restart)
	_overlay_close_button()

func _confirm_reset() -> void:
	_close_overlay()
	_on_reset_pressed()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE and is_instance_valid(overlay):
		_close_overlay()
		get_viewport().set_input_as_handled()
	elif not is_instance_valid(overlay) and event.keycode == KEY_Z and event.ctrl_pressed:
		_on_undo_pressed()
		get_viewport().set_input_as_handled()
