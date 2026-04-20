extends Control

@export var duration: float = 0.6
@onready var texture_rect: TextureRect = $VBoxContainer/HBoxContainer/TextureRect
@onready var color_rect: ColorRect = $VBoxContainer/HBoxContainer/TextureRect/ColorRect

func start():
	$AnimationPlayer.play("in")
	
	await get_tree().create_timer(duration+0.1,false).timeout
	
func end():
	$AnimationPlayer.play("out")
	
	await get_tree().create_timer(duration,false).timeout
	
