extends Node2D

@export var speed: float = 700.0
@export var acceleration: float = 700.0

var velocity: Vector2 = Vector2.ZERO
var target: Node2D

var value: int = 1

func _ready() -> void:
	target = get_parent()

func _process(delta: float) -> void:
	if target == null:
		return
		
	var dir = (target.global_position - global_position).normalized()

	velocity = velocity.move_toward(dir * speed, acceleration * delta)

	global_position += velocity * delta

	if global_position.distance_to(target.global_position) < 64:
		_collect()

func _collect():
	G.main.player.add_exp(value)
	Sounds.play_sound_at(global_position,"pop",2,"SFX",randf_range(0.0,0.4))

	queue_free()
