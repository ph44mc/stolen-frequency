extends Tile

var copy_health: int = 3

func on_ready():
	G.main.connect("wave_end", _on_wave_end)
	$AnimationPlayer.play("attack")

func _on_wave_end():
	if is_for_showcase: return
	copy_health = 3
	$TileImage/FakeCopy.visible = true
	$TileImage/Fire.visible = false
	G.main.player_copies.append(self)
	
func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_for_showcase: return
	if body is Enemy:
		if copy_health > 0:
			copy_health -= 1
			$AnimationPlayer.play("attack")
			if copy_health <= 0:
				$TileImage/FakeCopy.visible = false
				$TileImage/Fire.visible = true
				G.main.player_copies.erase(self)
				for e in G.main.enemies:
					e.update_targets()
				
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
			tween.tween_property($TileImage/Sprite2D.material, "shader_parameter/flash_amount", 0, 0.6).from(1)

func tooltip_data():
	return {
		"name": t_name,
		"description": t_name+"_desc",
		"world": "Glyph",
		#"fields": [
			#{"name": "Damage", "value": "10"},
			#{"name": "Weight", "value": "3kg"}
		#]
	}
