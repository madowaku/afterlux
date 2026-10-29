extends RefCounted

const INK: Color = Color("0c191e")
const PANEL: Color = Color("14262b")
const EDGE: Color = Color("2b4448")
const PAPER: Color = Color("eae9d9")
const MUTED: Color = Color("98b2b5")
const MINT: Color = Color("bcebd6")
const GOLD: Color = Color("ebc58e")
const ERROR: Color = Color("f3a393")

static func box(fill: Color, border: Color = EDGE, radius: int = 12, inset: int = 12) -> StyleBoxFlat:
	var result: StyleBoxFlat = StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(1)
	result.set_corner_radius_all(radius)
	result.content_margin_left = inset
	result.content_margin_right = inset
	result.content_margin_top = inset
	result.content_margin_bottom = inset
	return result

static func create_theme() -> Theme:
	var result: Theme = Theme.new()
	var font: FontVariation = FontVariation.new()
	font.base_font = load("res://assets/fonts/NotoSansJP.ttf") as Font
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 450.0}
	result.default_font = font
	result.default_font_size = 14
	result.set_color("font_color", "Label", PAPER)
	result.set_color("font_color", "Button", PAPER)
	result.set_color("font_hover_color", "Button", MINT)
	result.set_color("font_pressed_color", "Button", INK)
	result.set_color("font_disabled_color", "Button", Color("6e898d"))
	result.set_stylebox("normal", "Button", box(PANEL))
	result.set_stylebox("hover", "Button", box(Color("20373b"), MINT))
	result.set_stylebox("pressed", "Button", box(MINT, MINT))
	result.set_stylebox("disabled", "Button", box(Color("102126"), Color("263b40")))
	var focus: StyleBoxFlat = box(Color.TRANSPARENT, GOLD)
	focus.set_border_width_all(2)
	focus.draw_center = false
	result.set_stylebox("focus", "Button", focus)
	result.set_stylebox("panel", "PanelContainer", box(PANEL))
	result.set_constant("separation", "VBoxContainer", 12)
	result.set_constant("separation", "HBoxContainer", 8)
	return result

static func label(value: String, font_size: int = 14, tint: Color = PAPER) -> Label:
	var result: Label = Label.new()
	result.text = value
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", tint)
	return result

static func button(value: String, callback: Callable) -> Button:
	var result: Button = Button.new()
	result.text = value
	result.custom_minimum_size.y = 44
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.pressed.connect(callback)
	return result

static func accent(button_node: Button, active: bool) -> void:
	button_node.add_theme_stylebox_override("normal", box(MINT if active else PANEL, MINT if active else EDGE))
	button_node.add_theme_color_override("font_color", INK if active else PAPER)
	button_node.add_theme_color_override("font_hover_color", INK if active else MINT)
	button_node.add_theme_color_override("font_focus_color", INK if active else PAPER)
	button_node.add_theme_color_override("font_hover_pressed_color", INK)
	button_node.add_theme_stylebox_override("hover", box(Color("d4f6e6") if active else Color("20373b"), MINT))
