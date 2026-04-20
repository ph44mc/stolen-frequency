extends Tile

var pea_health: int = 10
var bullet: PackedScene = preload("res://Scenes/bullet.tscn")

func on_ready():
	$AnimationPlayer.play("attack")

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_for_showcase: return
	if body is Enemy:
		if pea_health > 0:
			pea_health -= 1
			
			if pea_health <= 0:
				$AttackCooldown.stop()
				$TileImage/Peashooter.visible = false
			
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
			tween.tween_property($TileImage/Sprite2D.material, "shader_parameter/flash_amount", 0, 0.6).from(1)

func tooltip_data():
	return {
		"name": t_name,
		"description": t_name+"_desc",
		"world": "Spore",
		#"fields": [
			#{"name": "Damage", "value": "10"},
			#{"name": "Weight", "value": "3kg"}
		#]
	}


func _on_attack_cooldown_timeout() -> void:
	if G.main.player.choose.is_closed:
		var enemies = G.main.enemies.duplicate()

		enemies = enemies.filter(func(e):
			return !e.stealth
		)
		enemies.sort_custom(func(a, b):
			return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
		)

		if !enemies.is_empty():
			target = enemies.get(0)
			if target:
				$AnimationPlayer.play("attack")
				spawn_bullet(
					self,
					bullet,
					global_position + Vector2(0, -30),
					global_position.direction_to(target.global_position)
				)
			
func spawn_bullet(sender, bullet_scn, pos, dir, dmg = 1):
	await get_tree().create_timer(0.2,false).timeout
	var bullet = bullet_scn.instantiate()
	bullet.global_position = pos
	bullet.direction = dir
	bullet.sender = sender
	bullet.damage = dmg

	G.main.add_child(bullet)
