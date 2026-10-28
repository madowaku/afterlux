extends Node2D

const HALO: Texture2D = preload("res://assets/kenney/light/halo.png")
const STAR: Texture2D = preload("res://assets/kenney/particles/star.png")

func _ready() -> void:
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	get_viewport().size_changed.connect(queue_redraw)

func _draw() -> void:
	var canvas_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = Vector2(canvas_size.x * 0.84, 92)
	draw_texture_rect(HALO, Rect2(center - Vector2(230, 230), Vector2(460, 460)), false, Color(0.11, 0.19, 0.16, 0.45))
	for radius: float in [102.0, 134.0, 166.0]:
		draw_arc(center, radius, 0, TAU, 100, Color(0.15, 0.24, 0.23, 0.2), 1, true)
	draw_texture_rect(STAR, Rect2(center + Vector2(-10, 123), Vector2(14, 14)), false, Color(0.5, 0.7, 0.6, 0.4))
