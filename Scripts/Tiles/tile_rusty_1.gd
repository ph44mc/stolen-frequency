extends Tile

var is_spikes_out: bool = false

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_for_showcase: return
	if (body is Enemy and !body.stealth) or body is Player:
		
		if !is_spikes_out:
			is_spikes_out = true
			
			$TileImage/Spikes.visible = true
			body.speed_mult = 0
			body.take_damage(3)
			
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
			tween.tween_property($TileImage/Sprite2D.material, "shader_parameter/flash_amount", 0, 0.6).from(1)

			
			await get_tree().create_timer(1,false).timeout
			
			
			if body:
				body.speed_mult = 1
				
			is_spikes_out = false
			$TileImage/Spikes.visible = false
			

func tooltip_data():
	return {
		"name": t_name,
		"description": t_name+"_desc",
		"world": "Rusty",
		#"fields": [
			#{"name": "Damage", "value": "10"},
			#{"name": "Weight", "value": "3kg"}
		#]
	}
