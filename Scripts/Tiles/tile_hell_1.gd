extends Tile

var targets = []

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_for_showcase: return
	if body is Enemy or body is Player:
		body.take_damage(1)
		targets.append(body)

func _on_hitbox_body_exited(body: Node2D) -> void:
	if is_for_showcase: return
	if body is Enemy or body is Player:
		targets.erase(body)

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



func _on_cooldown_timeout() -> void:
	for target in targets:
		target.take_damage(1)
		
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		tween.tween_property($TileImage/Sprite2D.material, "shader_parameter/flash_amount", 0, 0.6).from(1)
