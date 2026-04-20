extends Control
@onready var label: RichTextLabel = $Highscore/MarginContainer/VBoxContainer/Highscore2/MarginContainer/Label

func start():
	visible = true
	$AnimationPlayer.play("start")
	await UIManager.hide_transition()

func set_stats(stats):
	label.text = "
Waves survived: %s
Enemies killed: %s
Tiles placed: %s
Experience: %s
		" % stats

func _on_restart_pressed() -> void:
	await UIManager.show_transition()
	visible = false
	get_tree().change_scene_to_file("res://Scenes/main.tscn")


func _on_menu_pressed() -> void:
	await UIManager.show_transition()
	visible = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
