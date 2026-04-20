extends Tile

var linked_portal: Tile
@onready var portal_texture: Sprite2D = $TileImage/Fire
@onready var timer: Timer = $Timer

func on_ready():
	await get_tree().create_timer(0.5,false).timeout
	if is_for_showcase or linked_portal != null: return
	G.main.player.tile_placer.tile_placed.connect(tile_placed)

func tile_placed(tile):
	linked_portal = tile
	tile.linked_portal = self
	G.main.player.tile_placer.tile_placed.disconnect(tile_placed)
	portal_texture.visible = true
	tile.portal_texture.visible = true
	

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_for_showcase or linked_portal == null: return
	if body is Enemy or body is Player:
		if timer.is_stopped():
	
			timer.start()
			linked_portal.timer.start()
			
			body.global_position = linked_portal.global_position + Vector2(0,1)
			if body is Enemy:
				body.take_damage(5)
			
			$TileImage/Fire.visible = false
			
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


func _on_timer_timeout() -> void:
	$TileImage/Fire.visible = true
