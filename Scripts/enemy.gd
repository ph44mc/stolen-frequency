extends CharacterBody2D
class_name Enemy

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_area: Area2D = $AttackArea
@onready var sprite: Sprite2D = $Sprite2D
var start_texture: Texture

@export var speed: float = 240.0
@export var damage: int = 1
@export var player_target: Node2D

@export var stealth: bool = false

var speed_mult: float = 1.0
var current_target: Node2D = null
var targets_in_range: Array = []


var is_attacking: bool = false
var attack_target_position: Vector2


var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time: float = 0.0
var knockback_duration: float = 0.2

var can_run: bool = true
@export var health: int = 3
var is_dead: bool = false

signal died(enemy)


func _ready():
	$CollisionShape2D.disabled = false
	if start_texture:
		sprite.texture = start_texture
	play_anim("run")

func _physics_process(delta):
	handle_knockback(delta)

	update_targets()

	if current_target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_attacking and targets_in_range.has(current_target):
		start_attack()

	if can_run and not is_attacking:
		move_to_target()
		
		var dist = global_position.distance_to(current_target.global_position)

		if dist <= 60 and not is_attacking and can_run:
			start_attack()
		
	elif is_attacking:
		move_attack()
	

		
	move_and_slide()



func update_targets():
	targets_in_range = targets_in_range.filter(func(t): return is_instance_valid(t))
	
	if !G.main.player_copies.is_empty():
		current_target = G.main.player_copies[0]
	elif player_target != null and player_target.is_alive:
		current_target = player_target
	else:
		current_target = G.main.system


func move_to_target():
	var dir = current_target.global_position - global_position
	var dist = dir.length()

	if dist > 40:
		velocity = dir.normalized() * speed * speed_mult
	else:
		velocity = Vector2.ZERO


func move_attack():
	var dir = attack_target_position - global_position
	
	if dir.length() > 5:
		velocity = dir.normalized() * speed
	else:
		velocity = Vector2.ZERO


func start_attack():
	is_attacking = true
	can_run = false
	
	$CollisionShape2D.disabled = true
	
	if current_target:
		var dir = (current_target.global_position - global_position).normalized()
		attack_target_position = global_position + dir * 80

	play_anim("attack")


func attack():
	if not is_attacking:
		return
	
	for target in targets_in_range:
		if not is_instance_valid(target):
			continue

		var dir = (target.global_position - global_position).normalized()

		if target.has_method("apply_knockback"):
			target.apply_knockback(dir, 400)

		if target.has_method("take_damage"):
			target.take_damage(damage)

	attack_area.get_node("CollisionShape2D").disabled = true


func _on_attack_area_body_entered(body):
	if (body is Player or body is System) and body not in targets_in_range:
		targets_in_range.append(body)

func _on_attack_area_body_exited(body):
	targets_in_range.erase(body)


func handle_knockback(delta):
	if knockback_time > 0:
		velocity = knockback_velocity
		move_and_slide()

		knockback_time -= delta
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 8 * delta)
		return


func apply_knockback(dir: Vector2, power: float = 320.0):
	knockback_velocity = dir.normalized() * power
	knockback_time = knockback_duration
	can_run = false


func take_damage(dmg: int):
	$HurtCooldown.start()
	can_run = false
	is_attacking = false
	play_anim("hurt")
	Sounds.play_sound_at(global_position,["hurt","hurt2"].pick_random(),0,"SFX",randf_range(0.0,0.4))
	
	health -= dmg

func check_for_death():
	if health <= 0:
		die()


func die():
	if is_dead:
		return

	is_dead = true
	G.spawn_exp(global_position)
	G.main.stat_enemies_killed += 1
	died.emit(self)
	queue_free()

func _on_animation_player_animation_finished(anim_name):
	match anim_name:
		"attack":
			is_attacking = false
			can_run = true
			attack_area.get_node("CollisionShape2D").disabled = false

			if targets_in_range.size() > 0:
				start_attack()
			else:
				play_anim("run")

		"hurt":
			can_run = true
			is_attacking = false
			play_anim("run")


func play_anim(anim_name: String):
	if animation_player.current_animation == "hurt":
		if anim_name != "hurt":
			return
	
	animation_player.play(anim_name)

func _on_hurt_cooldown_timeout():
	can_run = true
	if not is_attacking:
		play_anim("run")


func _on_target_update_timeout() -> void:
	update_targets()
