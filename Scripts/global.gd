extends Node

var main: Main

var shapes_texts = [
	"""
	a a a
	. a .
	""",
	
	"""
	a a
	""",
	
	"""
	a
	""",
	
	"""
	a a
	a a
	""",
	
	"""
	a a
	a .
	""",
	
	"""
	a
	a
	a
	""",
	
	"""
	a
	a
	a
	a
	""",
]

var tiles = [
	"tile_overworld_1",
	"tile_overworld_2",
	"tile_spore_1",
	"tile_hell_1",
	"tile_hell_2",
	"tile_ocean_1",
	"tile_ocean_2",
	"tile_rusty_1",
	"tile_prism_1",
	"tile_prism_2",
	"tile_glyph_1",
	"tile_glyph_2",
]

func tiles_to_world(tile_name: String):

	tile_name = tile_name.trim_prefix("tile_")

	var i = tile_name.rfind("_")
	if i != -1: tile_name = tile_name.substr(0, i)

	return tile_name.to_pascal_case()
	
func spawn_exp(pos: Vector2, value: int = 1):
	var experience = load("res://Scenes/exp.tscn").instantiate()
	experience.value = value
	G.main.system.add_child(experience)
	experience.global_position = pos
	
func rotate_cell(cell: Vector2i, rotation_steps: int) -> Vector2i:
	match rotation_steps:
		0:
			return cell
		1:
			return Vector2i(-cell.y, cell.x)
		2:
			return Vector2i(-cell.x, -cell.y)
		3:
			return Vector2i(cell.y, -cell.x)
	return cell


func get_rotated_tiles(shape: TileShape, rotation_steps: int) -> Array:
	var result := []
	for cell in shape.tiles:
		result.append(rotate_cell(cell, rotation_steps))
	return result


func get_shape_offset(tiles: Array) -> Vector2:
	var min_v = Vector2i(9999, 9999)
	var max_v = Vector2i(-9999, -9999)

	for cell in tiles:
		min_v.x = min(min_v.x, cell.x)
		min_v.y = min(min_v.y, cell.y)
		max_v.x = max(max_v.x, cell.x)
		max_v.y = max(max_v.y, cell.y)

	return Vector2(min_v + max_v) * 0.5

func shape_from_text(text: String, tile_name: String) -> TileShape:
	var shape = TileShape.new()

	var lines = text.strip_edges().split("\n")

	for y in lines.size():
		var row = lines[y].strip_edges().split(" ")

		for x in row.size():
			if row[x] != ".":
				shape.tiles.append(Vector2i(x, y))
				shape.tile_names.append(tile_name)

	return shape
