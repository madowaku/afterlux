extends PanelContainer

signal cell_pressed(cell: Vector2i)
const CELL = preload("res://game/board/cell_view.gd")
const RULES = preload("res://src/core/afterlux_rules.gd")
const STYLE = preload("res://game/ui/style.gd")
const GLOW: Texture2D = preload("res://assets/kenney/particles/glow.png")
const STAR: Texture2D = preload("res://assets/kenney/particles/star.png")

var grid: GridContainer
var cells: Dictionary = {}
var effect: Node2D
var light: String = ""
var aim: String = ""
var beam_dots: Array[Vector2i] = []
var beam_time: float = -1.0
var last_delta: Array = []
var badge_pop: float = 0.0
var celebration: float = -1.0
var effect_tween: Tween
var badge_tween: Tween

# Each DOT casts its own shadow band; bands that share a cell visibly darken it.
const BEAM_TRAVEL: float = 0.22
const BEAM_STAGGER: float = 0.12
const BEAM_HOLD: float = 0.1
const SHADE: Color = Color(0.03, 0.08, 0.1, 0.42)

func _ready() -> void:
	add_theme_stylebox_override("panel", STYLE.box(Color("102227"), Color("3b5757"), 18, 10))
	grid = GridContainer.new()
	grid.name = "Grid"
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	effect = Node2D.new()
	effect.name = "LightEffect"
	add_child(effect)
	effect.draw.connect(_draw_effect)
	# Overlays are positioned from cell rects, so follow every grid re-layout.
	grid.sort_children.connect(effect.queue_redraw)
	resized.connect(_resize_cells)

func build(stage: Dictionary) -> void:
	stop_effects()
	clear_delta()
	for child: Node in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	cells.clear()
	grid.columns = int(stage["width"])
	for y: int in range(int(stage["height"])):
		for x: int in range(int(stage["width"])):
			var coord: Vector2i = Vector2i(x, y)
			var cell: Button = CELL.new()
			cell.coordinate = coord
			cell.name = RULES.cell_to_coord(coord)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cell.pressed.connect(func() -> void: cell_pressed.emit(coord))
			grid.add_child(cell)
			cells[coord] = cell
	_resize_cells()

func _resize_cells() -> void:
	if not grid or grid.columns == 0:
		return
	# Use the requested width, so cell minimum sizes can shrink after a resize.
	var side: float = maxf(44, (custom_minimum_size.x - 20 - (grid.columns - 1) * 6) / grid.columns)
	for cell: Button in cells.values():
		cell.custom_minimum_size = Vector2(side, side)

func refresh(stage: Dictionary, accumulated: Array, dots: Array[Vector2i], input_locked: bool) -> void:
	var sockets: Array[Vector2i] = RULES.stage_socket_cells(stage)
	for coord: Vector2i in cells:
		var cell: Button = cells[coord]
		cell.update_cell(sockets.has(coord), dots.has(coord), int(accumulated[coord.y][coord.x]), int(stage["target"][coord.y][coord.x]))
		cell.disabled = input_locked or not sockets.has(coord)

# Returns how long the shot animation runs, so the caller can apply the result afterwards.
func cast(direction: String, dots: Array[Vector2i], reduced_motion: bool) -> float:
	stop_effects()
	clear_delta()
	light = direction
	if reduced_motion or dots.is_empty():
		return 0.0
	beam_dots = dots.duplicate()
	var duration: float = BEAM_TRAVEL + BEAM_STAGGER * (dots.size() - 1)
	effect_tween = create_tween()
	effect_tween.tween_method(_set_beam_time, 0.0, duration, duration)
	effect_tween.tween_interval(BEAM_HOLD)
	return duration + BEAM_HOLD

func set_aim(direction: String) -> void:
	if aim != direction:
		aim = direction
		effect.queue_redraw()

# Keeps the "+N" of the latest shot readable until the next action.
func show_delta(delta: Array, reduced_motion: bool) -> void:
	beam_dots.clear()
	beam_time = -1.0
	last_delta = delta.duplicate(true)
	if badge_tween:
		badge_tween.kill()
	badge_pop = 0.0
	if not reduced_motion:
		badge_pop = 1.0
		badge_tween = create_tween()
		badge_tween.tween_method(_set_badge_pop, 1.0, 0.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	effect.queue_redraw()

func clear_delta() -> void:
	if badge_tween:
		badge_tween.kill()
	last_delta = []
	badge_pop = 0.0
	if effect:
		effect.queue_redraw()

func flash_delta(delta: Array) -> void:
	for coord: Vector2i in cells:
		if int(delta[coord.y][coord.x]) > 0:
			cells[coord].flash()

func celebrate(reduced_motion: bool) -> void:
	if reduced_motion:
		return
	effect_tween = create_tween()
	effect_tween.tween_method(_set_celebration, 0.0, 1.0, 0.7)
	effect_tween.tween_callback(func() -> void: _set_celebration(-1.0))

func stop_effects() -> void:
	if effect_tween:
		effect_tween.kill()
	beam_dots.clear()
	beam_time = -1.0
	celebration = -1.0
	if effect:
		effect.queue_redraw()

func _set_beam_time(value: float) -> void:
	beam_time = value
	effect.queue_redraw()

func _set_badge_pop(value: float) -> void:
	badge_pop = value
	effect.queue_redraw()

func _set_celebration(value: float) -> void:
	celebration = value
	effect.queue_redraw()

func _draw_effect() -> void:
	if not aim.is_empty() and beam_time < 0:
		_draw_light_source(aim)
	if beam_time >= 0:
		_draw_beams()
	elif not last_delta.is_empty():
		for coord: Vector2i in cells:
			var amount: int = int(last_delta[coord.y][coord.x])
			if amount > 0:
				_draw_badge(coord, amount, 1.0 + badge_pop * 0.35)
	if celebration >= 0:
		for i: int in range(12):
			var angle: float = TAU * i / 12.0
			var at: Vector2 = size * 0.5 + Vector2.from_angle(angle) * lerpf(size.x * 0.2, size.x * 0.47, celebration)
			var extent: Vector2 = Vector2.ONE * (14 + 12 * sin(celebration * PI))
			effect.draw_texture_rect(STAR if i % 2 == 0 else GLOW, Rect2(at - extent * 0.5, extent), false, Color(0.74, 0.92, 0.84, 1 - celebration))

func _cell_rect(coord: Vector2i) -> Rect2:
	var cell: Control = cells[coord]
	return Rect2(grid.position + cell.position, cell.size)

func _light_step(direction: String) -> Vector2i:
	return {"N": Vector2i(0, 1), "S": Vector2i(0, -1), "W": Vector2i(1, 0), "E": Vector2i(-1, 0)}.get(direction, Vector2i.ZERO)

# The edge the light enters from, with chevrons pointing where shadows travel.
func _draw_light_source(direction: String) -> void:
	var step: Vector2i = _light_step(direction)
	if step == Vector2i.ZERO or cells.is_empty():
		return
	var tint: Color = Color(STYLE.GOLD, 0.85)
	for coord: Vector2i in cells:
		var entering: Vector2i = coord - step
		if cells.has(entering):
			continue
		var rect: Rect2 = _cell_rect(coord)
		var forward: Vector2 = Vector2(step)
		var side: Vector2 = Vector2(-forward.y, forward.x)
		var tip: Vector2 = rect.get_center() - forward * (rect.size.x * 0.5 + 2.0)
		var base: Vector2 = tip - forward * 5.0
		effect.draw_colored_polygon(PackedVector2Array([tip, base + side * 5.0, base - side * 5.0]), tint)
		effect.draw_line(base + side * rect.size.x * 0.32, base - side * rect.size.x * 0.32, Color(STYLE.GOLD, 0.35), 2.0, true)

func _draw_beams() -> void:
	var step: Vector2i = _light_step(light)
	var arrivals: Dictionary = {}
	for index: int in range(beam_dots.size()):
		var progress: float = clampf((beam_time - index * BEAM_STAGGER) / BEAM_TRAVEL, 0.0, 1.0)
		if progress <= 0.0:
			continue
		var dot: Vector2i = beam_dots[index]
		var path: Array[Vector2i] = []
		var cursor: Vector2i = dot + step
		while cells.has(cursor):
			path.append(cursor)
			cursor += step
		var reach: float = progress * path.size()
		for i: int in range(path.size()):
			var cover: float = clampf(reach - i, 0.0, 1.0)
			if cover <= 0.0:
				break
			var coord: Vector2i = path[i]
			var rect: Rect2 = _cell_rect(coord)
			if beam_dots.has(coord):
				# The ray passes a DOT without shading it.
				var from_edge: Vector2 = rect.get_center() - Vector2(step) * rect.size.x * 0.5
				effect.draw_dashed_line(from_edge, from_edge + Vector2(step) * rect.size.x * cover, Color(STYLE.MINT, 0.7), 1.5, 4.0)
				continue
			var band: Rect2 = rect.grow(-3.0)
			if step.x != 0:
				band.size.x *= cover
				if step.x < 0:
					band.position.x = rect.end.x - 3.0 - band.size.x
			else:
				band.size.y *= cover
				if step.y < 0:
					band.position.y = rect.end.y - 3.0 - band.size.y
			effect.draw_rect(band, SHADE)
			if cover >= 1.0:
				arrivals[coord] = int(arrivals.get(coord, 0)) + 1
		var dot_rect: Rect2 = _cell_rect(dot)
		effect.draw_texture_rect(GLOW, Rect2(dot_rect.get_center() - dot_rect.size * 0.4, dot_rect.size * 0.8), false, Color(STYLE.MINT, 0.5 * (1.0 - progress)))
	for coord: Vector2i in arrivals:
		_draw_badge(coord, int(arrivals[coord]), 1.0)

func _draw_badge(coord: Vector2i, amount: int, zoom: float) -> void:
	var rect: Rect2 = _cell_rect(coord)
	var font: Font = get_theme_default_font()
	var text: String = "+%d" % amount
	var font_size: int = int(round((12 if amount == 1 else 14) * zoom))
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var chip: Rect2 = Rect2(rect.position + Vector2(4, 4), text_size + Vector2(8, 0))
	chip.size.y = font_size + 6
	var fill: Color = STYLE.GOLD if amount > 1 else STYLE.INK
	var tint: Color = STYLE.INK if amount > 1 else STYLE.MINT
	effect.draw_style_box(STYLE.box(fill, STYLE.GOLD if amount > 1 else Color(STYLE.MINT, 0.6), 7, 0), chip)
	effect.draw_string(font, chip.position + Vector2(4, font_size + 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)
