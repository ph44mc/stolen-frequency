extends Enemy

@export var destroy_radius: float = 100.0

func die():
	if is_dead:
		return
	
	if randf()>0.7:
		_destroy_random_tile()
	super.die()


func _destroy_random_tile():
	var tiles = G.main.tiles.filter(func(e):
		return is_instance_valid(e) and global_position.distance_to(e.global_position) <= destroy_radius
	)

	if tiles.is_empty():
		return

	var random_tile = tiles.pick_random()

	if is_instance_valid(random_tile):
		G.main.player.tile_placer.remove_tile_world(random_tile.global_position)
