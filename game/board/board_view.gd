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
var sweep: float = -1.0
var light: String = ""
var celebration: float = -1.0
var effect_tween: Tween

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
	resized.connect(_resize_cells)

func build(stage: Dictionary) -> void:
	stop_effects()
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

func cast(direction: String, reduced_motion: bool) -> void:
	stop_effects()
	light = direction
	if reduced_motion:
		return
	effect_tween = create_tween()
	effect_tween.tween_method(_set_sweep, 0.0, 1.0, 0.18)
	effect_tween.tween_callback(func() -> void: _set_sweep(-1.0))

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
	sweep = -1.0
	celebration = -1.0
	if effect:
		effect.queue_redraw()

func _set_sweep(value: float) -> void:
	sweep = value
	effect.queue_redraw()

func _set_celebration(value: float) -> void:
	celebration = value
	effect.queue_redraw()

func _draw_effect() -> void:
	if sweep >= 0:
		var at: float = lerpf(10, size.x - 10, sweep)
		if light == "S" or light == "E":
			at = size.x - at
		var horizontal: bool = light == "N" or light == "S"
		var start: Vector2 = Vector2(10, at) if horizontal else Vector2(at, 10)
		var end: Vector2 = Vector2(size.x - 10, at) if horizontal else Vector2(at, size.y - 10)
		effect.draw_line(start, end, Color(0.74, 0.92, 0.84, 0.25), 20, true)
		effect.draw_line(start, end, STYLE.MINT, 2, true)
	if celebration >= 0:
		for i: int in range(12):
			var angle: float = TAU * i / 12.0
			var at: Vector2 = size * 0.5 + Vector2.from_angle(angle) * lerpf(size.x * 0.2, size.x * 0.47, celebration)
			var extent: Vector2 = Vector2.ONE * (14 + 12 * sin(celebration * PI))
			effect.draw_texture_rect(STAR if i % 2 == 0 else GLOW, Rect2(at - extent * 0.5, extent), false, Color(0.74, 0.92, 0.84, 1 - celebration))
