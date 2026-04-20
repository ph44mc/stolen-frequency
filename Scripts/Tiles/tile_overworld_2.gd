extends Tile

var pea_health: int = 10

func on_ready():
	G.main.connect("wave_end", _on_wave_end)
	
func _on_wave_end():
	if pea_health>0:
		G.spawn_exp(global_position, 5)
		$AnimationPlayer.play("attack")
	
func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_for_showcase: return
	if body is Enemy:
		if pea_health > 0:
			pea_health -= 1
			
			if pea_health <= 0:
				$TileImage/Peashooter.visible = false
			
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
			tween.tween_property($TileImage/Sprite2D.material, "shader_parameter/flash_amount", 0, 0.6).from(1)

	
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
