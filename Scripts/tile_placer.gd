extends Node2D
class_name TilePlacer

@export var portal_color: Color = Color(0.2, 1.0, 0.4)

@export var tile_map: Node2D
@export var tile_size: Vector2i = Vector2i(64,48)

@export var placement_min: Vector2i = Vector2i.ZERO
@export var placement_max: Vector2i = Vector2i(19, 19)

@export var preview_texture: Texture2D  # 9-patch текстура для рамки
@export var preview_margin: Vector2i = Vector2i(16, 16)  # Отступы углов рамки
@export var portal_material: ShaderMaterial = preload("res://Assets/UI/tile_portal.tres")
@export var portal_fade_in: float = 0.1
@export var portal_hold: float = 0.3
@export var portal_fade_out: float = 0.4

var current_shape: TileShape
var preview_root: Node2D
var portal_rect: ColorRect          # Портал (форма фигуры)
var preview_ninepatch: NinePatchRect  # Рамка поверх портала

var grid := {} # Vector2i -> Node2D
var shape_rotation: int = 0
var is_placing: bool = false

# Цвета для рамки (NinePatchRect)
const VALID_COLOR = Color(1, 1, 1, 0.9)
const INVALID_COLOR = Color(1, 0.4, 0.4, 0.9)


# ========================
# SELECT / CANCEL
# ========================

func select_shape(shape: TileShape):
	var world = UIManager.tooltip.WORLD_COLORS.get(G.tiles_to_world(shape.tile_names[0]))
	if world:
		portal_color = Color.html(world)

	current_shape = shape
	shape_rotation = 0
	is_placing = false

	if not _has_any_valid_placement():
		cancel()
		return

	_create_preview()
	UIManager.set_cursor(1)


func cancel():
	current_shape = null
	shape_rotation = 0
	is_placing = false
	_cleanup_preview()
	
	UIManager.set_cursor(0)
	G.main.start_wave()


# ========================
# ROTATION
# ========================

func rotate_left():
	if current_shape == null or is_placing:
		return
	shape_rotation = (shape_rotation + 3) % 4
	_update_preview()


func rotate_right():
	if current_shape == null or is_placing:
		return
	shape_rotation = (shape_rotation + 1) % 4
	_update_preview()


# ========================
# PREVIEW: Portal + NinePatchRect
# ========================

func _create_preview():
	_cleanup_preview()

	preview_root = Node2D.new()
	preview_root.name = "PreviewRoot"
	preview_root.z_index = 3
	add_child(preview_root)

	# 1. Портал (основа — форма фигуры с шейдером)
	portal_rect = ColorRect.new()
	portal_rect.name = "Portal"

	var mat := portal_material.duplicate()
	mat.set_shader_parameter("base_color", portal_color) # 👈 ВАЖНО

	portal_rect.material = mat

	portal_rect.z_index = 0
	portal_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	
	preview_root.add_child(portal_rect)

	# 2. Рамка поверх портала (NinePatchRect)
	preview_ninepatch = NinePatchRect.new()
	preview_ninepatch.name = "PreviewFrame"
	preview_ninepatch.texture = preview_texture
	preview_ninepatch.patch_margin_left = preview_margin.x
	preview_ninepatch.patch_margin_top = preview_margin.y
	preview_ninepatch.patch_margin_right = preview_margin.x
	preview_ninepatch.patch_margin_bottom = preview_margin.y
	preview_ninepatch.draw_center = false  # Только рамка, центр прозрачный
	preview_ninepatch.z_index = 1  # Поверх портала
	preview_ninepatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_root.add_child(preview_ninepatch)

	_update_preview()


func _cleanup_preview():
	if preview_root:
		preview_root.queue_free()
		preview_root = null
		portal_rect = null
		preview_ninepatch = null


func _update_preview():
	if portal_rect == null or preview_ninepatch == null or current_shape == null or is_placing:
		return

	var rotated_tiles = _get_rotated_tiles()
	var offset = _get_normalize_offset(rotated_tiles)
	var cells: Array = []
	for c in rotated_tiles:
		cells.append(c + offset)

	var bounds = _get_bounds(cells)
	var pixel_size = Vector2i(
		bounds.size.x * tile_size.x,
		bounds.size.y * tile_size.y
	)

	# === Обновляем маску портала ===
	var image = Image.create(pixel_size.x, pixel_size.y, false, Image.FORMAT_RF)
	image.fill(Color(0,0,0))
	for cell in cells:
		for x in tile_size.x:
			for y in tile_size.y:
				var px = cell.x * tile_size.x + x
				var py = cell.y * tile_size.y + y
				image.set_pixel(px, py, Color(1,0,0))
	var tex = ImageTexture.create_from_image(image)
	portal_rect.material.set_shader_parameter("mask_tex", tex)

	# === Обновляем размер и позицию обоих элементов ===
	portal_rect.size = Vector2(pixel_size)
	portal_rect.position = Vector2(
		bounds.position.x * tile_size.x,
		bounds.position.y * tile_size.y
	)

	preview_ninepatch.size = Vector2(pixel_size)
	preview_ninepatch.position = Vector2(
		bounds.position.x * tile_size.x,
		bounds.position.y * tile_size.y
	)

	# === Валидация + позиционирование ===
	_validate_and_position_preview()


func _validate_and_position_preview():
	if preview_root == null or current_shape == null or is_placing:
		return

	var cursor_grid_pos = world_to_grid(get_global_mouse_position())
	var rotated_tiles = _get_rotated_tiles()
	var offset = _get_normalize_offset(rotated_tiles)
	var pivot = _get_preview_pivot()

	# Проверка валидности
	var can_place = true
	for i in rotated_tiles.size():
		var normalized_cell = rotated_tiles[i] + offset
		var relative = normalized_cell - pivot
		var pos = cursor_grid_pos + relative
		if not _is_inside_bounds(pos) or not can_place_tile(pos):
			can_place = false
			break

	# Цвет рамки зависит от валидности
	preview_ninepatch.modulate = VALID_COLOR if can_place else INVALID_COLOR

	# Позиционирование: привязка к центру фигуры
	var pivot_world = _get_pivot_world_offset(pivot)
	preview_root.global_position = grid_to_world(cursor_grid_pos) - pivot_world


# ========================
# PORTAL ANIMATION AFTER PLACEMENT
# ========================

func _animate_portal_after_place():
	# 1. Скрываем рамку
	preview_ninepatch.visible = false
	
	# 2. ФИКСИРУЕМ портал в мировых координатах
	#    (чтобы он не двигался вместе с preview_root)
	var portal_global_pos = portal_rect.global_position
	portal_rect.reparent(get_tree().root)  # или tile_map, если нужно в конкретной группе
	portal_rect.global_position = portal_global_pos
	portal_rect.z_index = -2  # поверх всего
	
	# 3. Запускаем анимацию затухания
	portal_rect.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(portal_rect, "modulate:a", 0.0, portal_fade_out)
	tween.finished.connect(_on_portal_animation_finished)
	
var done_portal_setup: bool = false
	
signal tile_placed(t)
	
func _on_portal_animation_finished():
	portal_rect.queue_free()
	_cleanup_preview()
	
	if current_shape.tile_names[0] == "tile_glyph_2" and !done_portal_setup:
		done_portal_setup = true
		select_shape(G.shape_from_text("a", "tile_glyph_2"))
		return
	
	is_placing = false
	cancel()
		
# ========================
# UPDATE
# ========================

func _process(_delta):
	if current_shape == null or is_placing:
		return
	_validate_and_position_preview()


# ========================
# INPUT
# ========================

func _input(event):
	if current_shape == null or is_placing:
		return

	if event.is_action_pressed("rotate_left"):
		rotate_left()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("rotate_right"):
		rotate_right()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_shape()


# ========================
# PLACE SHAPE
# ========================

func _place_shape():
	var cursor_grid_pos = world_to_grid(get_global_mouse_position())
	var rotated_tiles = _get_rotated_tiles()
	var offset = _get_normalize_offset(rotated_tiles)
	var pivot = _get_preview_pivot()

	if not _can_place_shape_with_pivot(cursor_grid_pos, rotated_tiles, offset, pivot):
		return

	# Блокируем ввод
	is_placing = true

	# 1. Размещаем тайлы на сетке
	for i in rotated_tiles.size():
		var normalized_cell = rotated_tiles[i] + offset
		var relative = normalized_cell - pivot
		var pos = cursor_grid_pos + relative
		var tile_name = current_shape.tile_names[i]
		place_tile(pos, tile_name)

	# 2. Запускаем анимацию портала на месте
	_animate_portal_after_place()
	
	Sounds.play_sound("cell",-0,"SFX",randf_range(0.0,0.4))
	Sounds.play_sound("portal3",-8,"SFX",randf_range(0.0,0.4),1.4)


func _can_place_shape_with_pivot(origin: Vector2i, rotated_tiles: Array, offset: Vector2i, pivot: Vector2i) -> bool:
	for i in rotated_tiles.size():
		var normalized_cell = rotated_tiles[i] + offset
		var relative = normalized_cell - pivot
		var pos = origin + relative

		if not _is_inside_bounds(pos):
			return false
		if not can_place_tile(pos):
			return false
	return true


# ========================
# GRID LOGIC
# ========================

func _is_inside_bounds(pos: Vector2i) -> bool:
	return pos.x >= placement_min.x \
		and pos.y >= placement_min.y \
		and pos.x <= placement_max.x \
		and pos.y <= placement_max.y


func can_place_tile(pos: Vector2i) -> bool:
	return not grid.has(pos)


func place_tile(pos: Vector2i, tile_name: String):
	if grid.has(pos):
		return

	var scene: PackedScene = load("res://Scenes/Tiles/" + tile_name + ".tscn")
	if scene == null:
		return

	var tile = scene.instantiate()
	tile.global_position = grid_to_world(pos) + Vector2(tile_size) / 2
	tile.t_name = tile_name
	
	tile_map.add_child(tile)
	G.main.tiles.append(tile)
	G.main.stat_tiles_placed += 1
	
	grid[pos] = tile
	
	tile_placed.emit(tile)


# ========================
# SHAPE HELPERS
# ========================

func _get_shape_pivot() -> Vector2i:
	if current_shape == null or current_shape.tiles.is_empty():
		return Vector2i.ZERO
	var sum := Vector2.ZERO
	for cell in current_shape.tiles:
		sum += Vector2(cell)
	var avg = sum / float(current_shape.tiles.size())
	return Vector2i(int(round(avg.x)), int(round(avg.y)))

func _has_any_valid_placement() -> bool:
	if current_shape == null:
		return false

	var rotated_tiles = _get_rotated_tiles()
	var offset = _get_normalize_offset(rotated_tiles)
	var pivot = _get_preview_pivot()

	for x in range(placement_min.x, placement_max.x + 1):
		for y in range(placement_min.y, placement_max.y + 1):
			var origin = Vector2i(x, y)

			if _can_place_shape_with_pivot(origin, rotated_tiles, offset, pivot):
				return true

	return false

func _get_preview_pivot() -> Vector2i:
	if current_shape == null:
		return Vector2i.ZERO
	var original_pivot = _get_shape_pivot()
	var rotated_pivot = _rotate_cell(original_pivot, shape_rotation)
	var offset = _get_normalize_offset(_get_rotated_tiles())
	return rotated_pivot + offset


func _get_pivot_world_offset(pivot_cell: Vector2i) -> Vector2:
	return Vector2(
		pivot_cell.x * tile_size.x,
		pivot_cell.y * tile_size.y
	)


func _get_rotated_tiles() -> Array:
	var result: Array = []
	for cell in current_shape.tiles:
		result.append(_rotate_cell(cell, shape_rotation))
	return result


func _rotate_cell(cell: Vector2i, rot: int) -> Vector2i:
	match rot % 4:
		0: return cell
		1: return Vector2i(-cell.y, cell.x)
		2: return Vector2i(-cell.x, -cell.y)
		3: return Vector2i(cell.y, -cell.x)
	return cell


func _get_normalize_offset(rotated_tiles: Array) -> Vector2i:
	if rotated_tiles.is_empty():
		return Vector2i.ZERO
	var min_x = 999999
	var min_y = 999999
	for cell in rotated_tiles:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
	return Vector2i(-min_x, -min_y)


func _get_bounds(cells: Array) -> Rect2i:
	var min_x = 999999
	var min_y = 999999
	var max_x = -999999
	var max_y = -999999
	for c in cells:
		min_x = min(min_x, c.x)
		min_y = min(min_y, c.y)
		max_x = max(max_x, c.x)
		max_y = max(max_y, c.y)
	return Rect2i(
		Vector2i(min_x, min_y),
		Vector2i(max_x - min_x + 1, max_y - min_y + 1)
	)


# ========================
# GRID <-> WORLD
# ========================

func world_to_grid(w: Vector2) -> Vector2i:
	return Vector2i(
		floor(w.x / tile_size.x),
		floor(w.y / tile_size.y)
	)

func grid_to_world(g: Vector2i) -> Vector2:
	return Vector2(
		g.x * tile_size.x,
		g.y * tile_size.y
	)

func remove_tile(pos: Vector2i):
	if not grid.has(pos):
		return

	var tile = grid[pos]

	if tile in G.main.tiles:
		G.main.tiles.erase(tile)

	grid.erase(pos)

	if is_instance_valid(tile):
		tile.queue_free()

func remove_tile_world(world_pos: Vector2):
	var grid_pos = world_to_grid(world_pos)
	remove_tile(grid_pos)
