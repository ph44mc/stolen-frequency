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
		"world": "Prism",
		#"fields": [
			#{"name": "Damage", "value": "10"},
			#{"name": "Weight", "value": "3kg"}
		#]
	}

var enemies_stealth_state := {}

func _on_area_2d_body_entered(body):
	if body is Enemy:
		if not enemies_stealth_state.has(body):
			enemies_stealth_state[body] = body.stealth
		
		if body.stealth:
			body.stealth = false
			
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
			tween.tween_property($TileImage/Sprite2D.material, "shader_parameter/flash_amount", 0, 0.6).from(1)

func _on_area_2d_body_exited(body):
	if body is Enemy:
		if enemies_stealth_state.has(body):
			var had_stealth = enemies_stealth_state[body]
			
			if had_stealth:
				body.stealth = true
			
			enemies_stealth_state.erase(body)
