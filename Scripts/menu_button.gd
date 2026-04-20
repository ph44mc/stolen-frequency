extends Button

@onready var color_rect: NinePatchRect = $TextureRect
@onready var pulse_rect: NinePatchRect = $TextureRect/TextureRect2
@onready var label: Label = $Label
@onready var background: NinePatchRect = $Background

@export var button_text: String

var tween: Tween
var pulse_tween: Tween

func _ready() -> void:
	setText(button_text)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	
	_on_mouse_exited()
	
func setText(txt: String):
	label.text = txt

func kill_tween():
	if tween and tween.is_running():
		tween.kill()

func kill_pulse():
	if pulse_tween and pulse_tween.is_running():
		pulse_tween.kill()

func _on_mouse_entered() -> void:
	kill_tween()
	start_pulse()
	
	tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(color_rect.material, "shader_parameter/fade_amount", 1.0, 0.25)
	tween.tween_property(background, "modulate:a", 0.0, 0.2)
	tween.tween_property(label, "scale", Vector2(1.12, 1.12), 0.25)

	#UIManager.show_tooltip(self)


func _on_mouse_exited() -> void:
	kill_tween()
	stop_pulse()
	
	tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(color_rect.material, "shader_parameter/fade_amount", 0.2, 0.2)
	tween.tween_property(background, "modulate:a", 0.7, 0.2)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
	
	#UIManager.hide_tooltip(self)

func _on_button_down() -> void:
	kill_tween()
	tween = create_tween().set_parallel(true)
	
	# Эффект нажатия (сжатие)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "scale", Vector2(0.95, 0.95), 0.1)


func _on_button_up() -> void:
	kill_tween()
	tween = create_tween().set_parallel(true)
	
	# Возврат с bounce
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.12, 1.12), 0.15)
	
# =========================
# ✨ PULSE EFFECT
# =========================

func start_pulse():
	kill_pulse()
	
	pulse_tween = create_tween()
	pulse_tween.set_loops() # бесконечно
	
	pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# "дыхание"
	pulse_tween.tween_property(pulse_rect, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8)
	pulse_tween.tween_property(pulse_rect, "modulate", Color(0.64, 0.64, 0.64, 1.0), 0.8)


func stop_pulse():
	kill_pulse()
	
	# плавно убрать альфу
	var t = create_tween()
	t.tween_property(pulse_rect, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	
#func get_tooltip_data():
	#return {
		#"name": "Sword",
		#"description": "Sharp blade",
		#"rarity": 2,
		#"fields": [
			#{"name": "Damage", "value": "10"}
		#]
	#}
