extends Node

@onready var transition: Control = $Game/Transition
@onready var tooltip: Tooltip = $Game/Tooltip
@onready var options_layer: CanvasLayer = $OptionsLayer
@onready var options: Control = $OptionsLayer/Options

func _ready() -> void:
	await get_tree().create_timer(0.6, false).timeout
	hide_transition()
	_apply_cursor()
		



func show_transition():
	await transition.start()

func hide_transition():
	await transition.end()

func show_game_over(stats):
	$Game/GameOver.start()
	$Game/GameOver.set_stats(stats)
		



var cursor_state: int = 0

var cursor_normal = load("res://Assets/UI/cursor.png")
var cursor_click = load("res://Assets/UI/cursor_click.png")
var cursor_place = load("res://Assets/UI/cursor_place.png")

func _apply_cursor():
	match cursor_state:
		0:
			Input.set_custom_mouse_cursor(cursor_normal, Input.CURSOR_ARROW, Vector2(18, 6))
		1:
			Input.set_custom_mouse_cursor(cursor_place, Input.CURSOR_ARROW, Vector2(55, 69))
		
func set_cursor(state: int):
	cursor_state = state
	_apply_cursor()

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if cursor_state == 0:
			Input.set_custom_mouse_cursor(cursor_click, Input.CURSOR_ARROW, Vector2(20, 10))
			if event.is_released():
				await get_tree().create_timer(0.02, false).timeout
				_apply_cursor()
		


var current_target = null
var tween: Tween

func show_tooltip(target, data = null):
	if target == null:
		return

	current_target = target

	# передаём данные в тултип
	tooltip.setup(target, data)

	tooltip.visible = true
	tooltip.scale = Vector2(1, 0)

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(tooltip, "scale", Vector2(1, 1), 0.35)
		

func hide_tooltip(target):
	if current_target != target:
		return

	current_target = null
	tooltip.set_target(null)
	
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(tooltip, "scale", Vector2(1, 0), 0.2)

	await get_tree().create_timer(0.2, false).timeout

	if current_target == null:
		tooltip.visible = false
		
