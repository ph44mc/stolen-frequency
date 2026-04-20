extends Node2D
class_name Bullet

@export var speed: int = 450
var direction: Vector2 = Vector2.ZERO 
var damage: int = 1
var sender

var target = null

func _ready() -> void:
	await get_tree().create_timer(6,false).timeout
	queue_free()

func _process(delta: float) -> void:

	if target: direction = global_position.direction_to(target.global_position)
	rotation = direction.angle()
	global_position += direction * delta * speed

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body and body is Enemy:

		body.take_damage(damage)
		body.apply_knockback(direction,100)
		queue_free()
