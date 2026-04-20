extends Node2D

@onready var choose_cards: Node2D = $ChooseCards
@onready var view: Button = $View
@onready var reroll: Button = $Reroll

var is_closed: bool = true

var reroll_cost: int = 5

func start_choose():
	visible = true
	
	is_closed = false
	
	G.main.player.set_collision_layer_value(2, false)
	G.main.player.health_bar.visible = false
	G.main.player.enemies_left_text.visible = false
	
	Sounds.play_sound(["portal1","portal2"].pick_random(),-8,"SFX",randf_range(0.0,0.4))
	Sounds.play_sound("respawn",-10,"SFX",randf_range(0.0,0.4))

	
	
	#UIManager.hide_tooltip(null)
	for tile in G.main.tiles:
		tile._on_hitbox_mouse_exited()
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
	tween.tween_property($ColorRect, "modulate:a", 1, 0.6).from(0)
	tween.tween_property($Fisheye.material, "shader_parameter/strength", 1.0, 1.0)
	
	for child in choose_cards.get_children():
		child.queue_free()
		
	var spacing := 500
	var count := 3
	var start_x := -((count - 1) * spacing) / 2.0

	for i in count:
		var card = load("res://Scenes/choose_card.tscn").instantiate()
		choose_cards.add_child(card)
	
		card.position.x = start_x + i * spacing

		var shape = G.shape_from_text(G.shapes_texts.pick_random(), G.tiles.pick_random())
		if shape.tile_names[0] in ["tile_glyph_2"]:
			G.main.player.tile_placer.done_portal_setup = false
			shape = G.shape_from_text("a", shape.tile_names[0])
		card.setup(shape)
		
		card.chosen.connect(end_choose)
		
func end_choose():
	for child in choose_cards.get_children():
		child.queue_free()
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
	tween.tween_property($ColorRect, "modulate:a", 0, 0.6).from(1)
	tween.tween_property($Fisheye.material, "shader_parameter/strength", 0.0, 1.0)
	visible = false
		
	G.main.player.set_collision_layer_value(2, true)
	G.main.player.health_bar.visible = true
	G.main.player.enemies_left_text.visible = true
	
	is_closed = true
	
func _on_view_pressed() -> void:
	is_closed = !is_closed
	
	$ChooseCards.visible = !$ChooseCards.visible
	$Label.visible = !$Label.visible
	$Reroll.visible = !$Reroll.visible
	
	if !$ChooseCards.visible:
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		tween.tween_property($ColorRect, "modulate:a", 0, 0.6).from(1)
		tween.tween_property($Fisheye.material, "shader_parameter/strength", 0.0, 0.5)
	else:
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		tween.tween_property($ColorRect, "modulate:a", 1, 0.6).from(0)
		tween.tween_property($Fisheye.material, "shader_parameter/strength", 1.0, 0.5)
			
func _on_reroll_pressed() -> void:
	if G.main.player.experience - reroll_cost > 0 :
		reroll_cost += 2
		
		G.main.player.add_exp(-reroll_cost)
		
		$RerollCost.text = "(%s exp)" % [reroll_cost]
		start_choose()
