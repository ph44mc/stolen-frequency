extends Node2D

var shape: TileShape
var tile_size: Vector2i = Vector2i(64,48)

func _ready() -> void:
	$Portal.modulate.a = 0
	await get_tree().create_timer(randf(),false).timeout
	$Portal/AnimationPlayer.play("rotate")
	
func setup(p_shape: TileShape):
	shape = p_shape
	_draw_shape()
	
	$Name.text = $Shape.get_child(0).tooltip_data().get("name")
	$FromWorld.text = $Shape.get_child(0).tooltip_data().get("world")
	$Portal/Whirl.self_modulate = Color.html(UIManager.tooltip.WORLD_COLORS.get($Shape.get_child(0).tooltip_data().get("world")))
	$FromWorld.self_modulate = Color.html(UIManager.tooltip.WORLD_COLORS.get($Shape.get_child(0).tooltip_data().get("world")))
	
func _draw_shape():

	for child in $Shape.get_children():
		child.queue_free()

	var tiles = G.get_rotated_tiles(shape, 0)
	var offset = G.get_shape_offset(tiles)

	for i in tiles.size():
		var cell = tiles[i]
		var tile_name = shape.tile_names[i]

		var scene: PackedScene = load("res://Scenes/Tiles/" + tile_name + ".tscn")
		if scene == null:
			return

		var tile = scene.instantiate()

		var pos = Vector2(
			(cell.x - offset.x) * tile_size.x,
			(cell.y - offset.y) * tile_size.y
		)

		tile.position = pos
		tile.is_for_showcase = true
		tile.t_name = tile_name
		$Shape.add_child(tile)
		
signal chosen
	
func _on_button_pressed() -> void:
	emit_signal("chosen")
	G.main.player.tile_placer.select_shape(shape)


func _on_button_mouse_entered() -> void:
	$AnimationPlayer.play("portal_in")

	$Portal/CPUParticles2D.emitting = true
	$Portal/CPUParticles2D2.emitting = true
	
	UIManager.show_tooltip(self,$Shape.get_child(0).tooltip_data())

func _on_button_mouse_exited() -> void:
	$AnimationPlayer.play("portal_out")
	
	$Portal/CPUParticles2D.emitting = false
	$Portal/CPUParticles2D2.emitting = false
	
	UIManager.hide_tooltip(self)
