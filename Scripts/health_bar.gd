extends TextureProgressBar

@onready var delay: TextureProgressBar = $Delay

var delay_timer: Timer

func _ready():
	delay_timer = Timer.new()
	delay_timer.one_shot = true
	delay_timer.wait_time = 0.7
	add_child(delay_timer)
	delay_timer.timeout.connect(_on_delay_timeout)

func set_health(health: float, max_health: float):
	var health_percentage = health / max_health * max_value
	
	# Анимация основной полоски
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "tint_over", Color(1, 1, 1, 0), 0.2).from(Color(1, 1, 1, 1))
	tween.tween_property(self, "value", health_percentage, 0.3)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_callback(update_hp_label.bindv([health, max_health]))

	# Сбрасываем таймер задержки
	delay_timer.stop()
	delay_timer.start()

func _on_delay_timeout():
	end_delay()

func end_delay():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(delay, "value", value, 0.7)

func update_hp_label(health: float, max_health: float):
	#hp.text = "%.0f / %.0f" % [health, max_health]
	pass
