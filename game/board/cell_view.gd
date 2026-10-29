extends Button

const STYLE = preload("res://game/ui/style.gd")
var coordinate: Vector2i = Vector2i.ZERO
var socket: bool = false
var dot: bool = false
var remaining: int = 0
var accumulated: int = 0
var target: int = 0
var pulse: float = 0.0
var pulse_tween: Tween

func _ready() -> void:
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func update_cell(is_socket: bool, is_dot: bool, value: int, goal: int) -> void:
	socket = is_socket
	dot = is_dot
	accumulated = value
	target = goal
	remaining = goal - value
	focus_mode = Control.FOCUS_ALL if socket else Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if socket else Control.CURSOR_ARROW
	tooltip_text = tr("%s%d · %d shadow needed%s") % [String.chr(65 + coordinate.x), coordinate.y + 1, remaining, tr(" · DOT socket") if socket else ""]
	queue_redraw()

func flash() -> void:
	if pulse_tween:
		pulse_tween.kill()
	pulse = 1.0
	pulse_tween = create_tween()
	pulse_tween.tween_method(_set_pulse, 1.0, 0.0, 0.38)

func _set_pulse(value: float) -> void:
	pulse = value
	queue_redraw()

func _draw() -> void:
	var fill: Color = Color("1b3035")
	var border: Color = Color("2b4549")
	var numeral: Color = STYLE.PAPER
	if remaining > 0:
		# Lit paper darkens one step per shadow layer it has already received.
		fill = STYLE.PAPER.darkened(minf(0.3, 0.11 * accumulated))
		border = fill
		numeral = STYLE.INK
	elif accumulated > 0:
		fill = Color("25483f")
		border = Color("477264")
	if remaining < 0:
		fill = Color("623b38")
		border = STYLE.ERROR
		numeral = STYLE.ERROR
	if socket:
		border = STYLE.MINT if dot or is_hovered() else Color("668a83")
	fill = fill.lerp(STYLE.MINT, pulse * 0.3)
	var style: StyleBoxFlat = STYLE.box(fill, border, 10, 0)
	style.set_border_width_all(2 if dot else 1)
	draw_style_box(style, Rect2(Vector2.ZERO, size))
	var center: Vector2 = size * 0.5
	var font: Font = get_theme_default_font()
	if socket:
		var radius: float = size.x * 0.22
		draw_arc(center, radius, 0, TAU, 48, STYLE.INK if remaining > 0 else STYLE.MINT, 1.5, true)
		if dot:
			draw_circle(center, radius - 4.0, STYLE.INK if remaining > 0 else STYLE.MINT, true, -1, true)
		else:
			draw_circle(center, 2, STYLE.INK if remaining > 0 else STYLE.MUTED, true, -1, true)
		if remaining != 0:
			_draw_number(font, str(remaining), Vector2(size.x - 12, 18), 16, numeral)
	elif remaining != 0:
		_draw_number(font, str(remaining), center + Vector2(0, 9), 26, numeral)
	elif target > 0:
		draw_polyline(PackedVector2Array([center + Vector2(-5, 0), center + Vector2(-1, 4), center + Vector2(6, -4)]), STYLE.MINT, 1.5, true)
	else:
		draw_circle(center, 1.5, Color("476066"), true, -1, true)
	_draw_layers()
	if has_focus():
		var focus: StyleBoxFlat = STYLE.box(Color.TRANSPARENT, STYLE.GOLD, 10, 0)
		focus.draw_center = false
		focus.set_border_width_all(2)
		draw_style_box(focus, Rect2(Vector2(2, 2), size - Vector2(4, 4)))

func _draw_number(font: Font, value: String, baseline: Vector2, font_size: int, tint: Color) -> void:
	var width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, baseline - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)

# One pip per shadow layer: filled = received, hollow = still needed, coral = excess.
func _draw_layers() -> void:
	var count: int = maxi(target, accumulated)
	if count == 0:
		return
	var gap: float = minf(9.0, (size.x - 16.0) / count)
	var radius: float = minf(2.6, gap * 0.32)
	var origin: Vector2 = Vector2(size.x * 0.5 - gap * (count - 1) * 0.5, size.y - 8.0)
	var lit: bool = remaining > 0
	for i: int in range(count):
		var at: Vector2 = origin + Vector2(gap * i, 0)
		if i >= target:
			draw_circle(at, radius, STYLE.ERROR, true, -1, true)
		elif i < accumulated:
			draw_circle(at, radius, STYLE.INK if lit else STYLE.MINT, true, -1, true)
		else:
			draw_arc(at, radius, 0, TAU, 16, STYLE.INK if lit else STYLE.MUTED, 1.0, true)
