extends Tile

func _on_hitbox_mouse_entered() -> void:
	if is_for_showcase: return
	if G.main.player.choose.is_closed:
		$Area.visible = true	
		outline.visible = true	
		UIManager.show_tooltip(self,tooltip_data())

func _on_hitbox_mouse_exited() -> void:
	if is_for_showcase: return
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
		"world": "Ocean",
		#"fields": [
			#{"name": "Damage", "value": "10"},
			#{"name": "Weight", "value": "3kg"}
		#]
	}

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.speed_mult = 0.5
		
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		tween.tween_property($TileImage/Sprite2D.material, "shader_parameter/flash_amount", 0, 0.6).from(1)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Enemy:
		body.speed_mult = 1
