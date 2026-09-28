class_name AfterluxRules
extends RefCounted

static func empty_grid(width: int, height: int) -> Array:
	var grid: Array = []
	for _y in range(height):
		var row: Array = []
		row.resize(width)
		row.fill(0)
		grid.append(row)
	return grid


static func coord_to_cell(coord: String) -> Vector2i:
	assert(coord.length() >= 2, "Invalid coordinate: %s" % coord)
	var x := coord.unicode_at(0) - "A".unicode_at(0)
	var y := int(coord.substr(1)) - 1
	return Vector2i(x, y)


static func cell_to_coord(cell: Vector2i) -> String:
	return "%s%d" % [String.chr("A".unicode_at(0) + cell.x), cell.y + 1]


static func stage_socket_cells(stage: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in stage.get("sockets", []):
		result.append(coord_to_cell(str(coord)))
	return result


static func make_shot(stage: Dictionary, dot_cells: Array[Vector2i], light: String) -> Dictionary:
	var width := int(stage["width"])
	var height := int(stage["height"])
	var delta := empty_grid(width, height)
	var dot_lookup: Dictionary = {}
	for cell in dot_cells:
		dot_lookup[cell] = true

	var step := _light_step(light)
	assert(step != Vector2i.ZERO, "Unknown light direction: %s" % light)

	for dot in dot_cells:
		var cell := dot + step
		while _in_bounds(cell, width, height):
			# A DOT cell is always a zero-hole for this SHOT.
			# The ray continues through it.
			if not dot_lookup.has(cell):
				delta[cell.y][cell.x] += 1
			cell += step

	return {
		"dots": dot_cells.duplicate(),
		"light": light,
		"delta": delta,
	}


static func apply_shot(accumulated: Array, delta: Array) -> Array:
	var result := accumulated.duplicate(true)
	for y in range(result.size()):
		for x in range(result[y].size()):
			result[y][x] += int(delta[y][x])
	return result


static func is_overshot(stage: Dictionary, accumulated: Array) -> bool:
	var target: Array = stage["target"]
	for y in range(target.size()):
		for x in range(target[y].size()):
			if int(accumulated[y][x]) > int(target[y][x]):
				return true
	return false


static func is_solved(stage: Dictionary, accumulated: Array) -> bool:
	var target: Array = stage["target"]
	for y in range(target.size()):
		for x in range(target[y].size()):
			if int(accumulated[y][x]) != int(target[y][x]):
				return false
	return true


static func remaining_at(stage: Dictionary, accumulated: Array, cell: Vector2i) -> int:
	return int(stage["target"][cell.y][cell.x]) - int(accumulated[cell.y][cell.x])


static func validate_stage(stage: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var width := int(stage.get("width", 0))
	var height := int(stage.get("height", 0))
	if width <= 0 or height <= 0:
		errors.append("width/height must be positive")
		return errors

	var target: Array = stage.get("target", [])
	if target.size() != height:
		errors.append("target height mismatch")
	else:
		for row in target:
			if row.size() != width:
				errors.append("target width mismatch")
				break

	for coord in stage.get("sockets", []):
		var cell := coord_to_cell(str(coord))
		if not _in_bounds(cell, width, height):
			errors.append("socket out of bounds: %s" % coord)

	var allowed_lights: Array = stage.get("allowed_lights", [])
	for light in allowed_lights:
		if _light_step(str(light)) == Vector2i.ZERO:
			errors.append("invalid light: %s" % light)

	if int(stage.get("max_dots_per_shot", 0)) <= 0:
		errors.append("max_dots_per_shot must be positive")
	if int(stage.get("par", 0)) <= 0:
		errors.append("par must be positive")
	return errors


static func _light_step(light: String) -> Vector2i:
	match light:
		"N":
			return Vector2i(0, 1)
		"S":
			return Vector2i(0, -1)
		"W":
			return Vector2i(1, 0)
		"E":
			return Vector2i(-1, 0)
	return Vector2i.ZERO


static func _in_bounds(cell: Vector2i, width: int, height: int) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height
