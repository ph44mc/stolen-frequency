extends Node2D

@onready var text_label: RichTextLabel = $CanvasLayer/Text

var full_text: String = ""
var text_tween: Tween
@export var text_speed: float = 0.02

var frame: int = 1

func _ready() -> void:
	_on_button_pressed()
	await UIManager.hide_transition()

func _on_button_pressed() -> void:
	if frame>9:
		if Config.watched_cutscene:
			await UIManager.show_transition()
			get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
			return
		Config.set_watched_cutscene(true)
		await UIManager.show_transition()
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
	
	$AnimationPlayer.stop()
	$AnimationPlayer.play("cutscene")
	$CanvasLayer/Frame.texture = load("res://Assets/UI/frame" + str(frame) + ".png")
	
	full_text = tr("frame_" + str(frame))
	prints(full_text,Config.data.get("language"),TranslationServer.get_locale())
	show_text_with_tween(full_text)
	
	frame += 1
	
	
func show_text_with_tween(text: String):
	full_text = text
	
	if text_tween:
		text_tween.kill()
	
	text_label.text = full_text
	text_label.visible_characters = 0
	
	text_tween = create_tween()
	text_tween.tween_property(
		text_label,
		"visible_characters",
		full_text.length(),
		full_text.length() * text_speed
	)
