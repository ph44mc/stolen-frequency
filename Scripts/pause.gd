extends Control

var is_paused: bool = false

func _ready() -> void:
	get_tree().current_scene.ready.connect(_on_scene_ready)

func _on_scene_ready():
	UIManager.options.close_menu.connect(_on_options_closed)

func _input(event: InputEvent) -> void:		
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_focus_next"):
		if G.in_cutscene:
			await UIManager.show_transition()
			get_tree().change_scene_to_file("res://Scenes/main.tscn")
			return
		if is_paused:
			unpause()
		else:
			pause()

func pause():
	#UIManager.hide_tooltip(null)
	get_tree().paused = true
	get_parent().visible = true
	is_paused = true
	

func unpause():
	UIManager.options._on_back_pressed()
	get_tree().paused = false
	get_parent().visible = false
	is_paused = false


func _on_continue_pressed() -> void:
	unpause()

func _on_options_closed() -> void:
	visible = true
	UIManager.options_layer.visible = false

func _on_options_pressed() -> void:
	visible = false
	UIManager.options_layer.visible = true

func _on_exit_pressed() -> void:
	UIManager.set_cursor(0)
	unpause()
	if G.main:
		G.main.player.game_over()
