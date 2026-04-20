extends Node2D

@onready var start_button: Button = $StartLayer/Buttons/Start
@onready var options_button: Button = $StartLayer/Buttons/Options
@onready var exit_button: Button = $StartLayer/Buttons/Exit

@onready var options: Control = $OptionsLayer/Options

@onready var wave: Label = $StartLayer/Highscore/MarginContainer/VBoxContainer/Wave
@onready var exp: Label = $StartLayer/Highscore/MarginContainer/VBoxContainer/Exp

func _ready() -> void:
	Config._load()
	if Config.watched_cutscene:
		$StartLayer/Buttons/Cutscene.visible = true
		$StartLayer/Buttons/MarginContainer3.visible = true
		$StartLayer/Highscore.visible = true
		
	options.close_menu.connect(change_ui.bind(0))
	
	start_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	await get_tree().create_timer(0.3,false).timeout
	UIManager.hide_transition()
	
	$AnimationPlayer.play("start")
	
	wave.text = "Wave: " + str(Config.records.get("max_wave","-"))
	exp.text = "Exp: " + str(Config.records.get("max_score","-"))
	
var current_ui: int = 0
	
func change_ui(ui: int = 0):
	current_ui = ui
	
	$StartLayer.visible = false
	$OptionsLayer.visible = false
	
	match current_ui:
		0:
			$StartLayer.visible = true
			#
			#var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(false)
			#tween.tween_property(camera, "fov", 28.4, 0.5).from(24)
		1:
			$OptionsLayer.visible = true
			#var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(false)
			#tween.tween_property(camera, "fov", 24, 0.5).from(28.4)
		#2:
			#$StartRun.visible = true
			#$StartRun.on_open()

func _on_play_pressed() -> void:
	await UIManager.show_transition()
	if Config.watched_cutscene:
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/cutscene.tscn")
	
func _on_options_pressed() -> void:
	change_ui(1)
	
func _on_exit_pressed() -> void:
	await UIManager.show_transition()
	get_tree().quit()


func _on_cutscene_pressed() -> void:
	await UIManager.show_transition()
	get_tree().change_scene_to_file("res://Scenes/cutscene.tscn")
