extends Tile

func on_ready():
	G.main.connect("wave_end", _on_wave_end)

func _on_wave_end():
	if is_for_showcase: return
	
	if randf() > 0.9:
		return

	var placer = G.main.player.tile_placer
	if placer == null:
		return

	var my_grid = placer.world_to_grid(global_position)

	var directions = [
		Vector2i(1,0),
		Vector2i(-1,0),
		Vector2i(0,1),
		Vector2i(0,-1)
	]

	directions.shuffle()

	for dir in directions:
		var pos = my_grid + dir

		if placer._is_inside_bounds(pos) and placer.can_place_tile(pos):
			placer.place_tile(pos, "tile_prism_1")
			break

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_for_showcase: return
	if body is Enemy:
		body.take_damage(1)
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		tween.tween_property($TileImage/Sprite2D.material, "shader_parameter/flash_amount", 0, 0.6).from(1)

func tooltip_data():
	return {
		"name": t_name,
		"description": t_name+"_desc",
		"world": "Prism",
		#"fields": [
			#{"name": "Damage", "value": "10"},
			#{"name": "Weight", "value": "3kg"}
		#]
	}

var enemies = []

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Enemy and !body.stealth:
		if not enemies.has(body):
			enemies.append(body)
			if not body.died.is_connected(on_enemy_killed):
				body.died.connect(on_enemy_killed)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Enemy:
		enemies.erase(body)
		if body.died.is_connected(on_enemy_killed):
			body.died.disconnect(on_enemy_killed)

func on_enemy_killed(enemy):
	enemies.erase(enemy) # важно: чистим список
	G.spawn_exp(global_position)
