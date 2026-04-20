extends Tile

func _on_hitbox_mouse_entered() -> void:

	if G.main.player.choose.is_closed:
		$Area.visible = true	
		outline.visible = true	
		UIManager.show_tooltip(self,tooltip_data())

func _on_hitbox_mouse_exited() -> void:
	$Area.visible = false
	outline.visible = false
	UIManager.hide_tooltip(self)

var time_passed: float

func _process(delta: float) -> void:
	if $Area.visible:
		time_passed += delta
		$Area.modulate.a =  0.5 + 0.3 * sin(time_passed * 4)
		

func tooltip_data():
	return {
		"name": t_name,
		"description": t_name+"_desc",
		"world": "Overworld",
		#"fields": [
			#{"name": "Damage", "value": "10"},
			#{"name": "Weight", "value": "3kg"}
		#]
	}

var enemies = []

func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_for_showcase: return
	if body is Enemy and !body.stealth:
		if not enemies.has(body):
			enemies.append(body)
			if not body.died.is_connected(on_enemy_killed):
				body.died.connect(on_enemy_killed)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if is_for_showcase: return
	if body is Enemy:
		enemies.erase(body)
		if body.died.is_connected(on_enemy_killed):
			body.died.disconnect(on_enemy_killed)

func on_enemy_killed(enemy):
	enemies.erase(enemy) # важно: чистим список
	G.spawn_exp(global_position)
