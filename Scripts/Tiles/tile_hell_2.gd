extends Tile

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_for_showcase: return
	if body is Enemy or body is Player:
		enemies.append(body)
		
		if $Timer.is_stopped():
			if randf()>0.5:
				$Timer.start()
				$AnimationPlayer.play("lava")
				for enemy in enemies:
					enemy.take_damage(10)
		else:
			body.take_damage(10)
		
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		tween.tween_property($TileImage/Sprite2D.material, "shader_parameter/flash_amount", 0, 0.6).from(1)

func _on_hitbox_body_exited(body: Node2D) -> void:
	if is_for_showcase: return
	if body is Enemy or body is Player:
		enemies.erase(body)

func tooltip_data():
	return {
		"name": t_name,
		"description": t_name+"_desc",
		"world": "Hell",
		#"fields": [
			#{"name": "Damage", "value": "10"},
			#{"name": "Weight", "value": "3kg"}
		#]
	}

var enemies = []
