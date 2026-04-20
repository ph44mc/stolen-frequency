extends CharacterBody2D
class_name Player

@onready var tile_placer: TilePlacer = $TilePlacer
@onready var choose: Node2D = $Choose
@onready var health_bar: TextureProgressBar = $CanvasLayer/HealthBar
@onready var enemies_left_text: Label = $CanvasLayer/EnemiesLeft
@onready var exp_text: Label = $CanvasLayer/Exp
@onready var wave_text: Label = $CanvasLayer/Wave
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var speed: float = 220.0
var speed_mult: float = 1
@export var test_shape: TileShape

var health: int = 10
var max_health: int = 10
var is_alive: bool = true

var experience: int = 0

var can_move: bool = true

func _ready() -> void:
	health = max_health
	animation_player.play("idle")
	
	if Config.won > 0:
		$Icon.texture = load("res://Assets/UI/player_win.png")
	
	await get_tree().create_timer(0.6, false).timeout
	
	tile_placer.select_shape(test_shape)
	#choose.start_choose()


var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time: float = 0.0
var knockback_duration: float = 0.2

func apply_knockback(dir: Vector2, knockback_power: float = 320.0):
	knockback_velocity = dir.normalized() * knockback_power
	knockback_time = knockback_duration

func _physics_process(delta):
	if !$RespawnTimer.is_stopped():
		$CanvasLayer/RespawnTimer.text = "Respawn in...\n%s s" % [snapped($RespawnTimer.time_left, 0.1)]
	
	if is_alive and can_move:
		if knockback_time > 0:
			global_position += knockback_velocity * delta
			knockback_time -= delta
			knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 8 * delta)

		var input_dir = Vector2.ZERO
		input_dir.x = Input.get_action_strength("run_right") - Input.get_action_strength("run_left")
		input_dir.y = Input.get_action_strength("run_down") - Input.get_action_strength("run_up")
		input_dir = input_dir.normalized()
		
		_update_animation(input_dir)
		
		velocity = input_dir * speed * speed_mult
		move_and_slide()
		
		var mouse_pos = get_global_mouse_position()
		var direction_to_mouse = (mouse_pos - global_position).normalized()
		
		$Icon.flip_h = direction_to_mouse.x > 0
		
		_handle_eye_follow()
	

@export var eye_bounds_rect: Vector2 = Vector2(8, 4)

func _handle_eye_follow() -> void:
	var viewport_size = get_viewport_rect().size
	var mouse_pos = get_viewport().get_mouse_position()

	var normalized = mouse_pos / viewport_size
	normalized = normalized * 2.0 - Vector2.ONE

	var target = normalized * eye_bounds_rect

	# --- ограничение в эллипсе ---
	var ellipse = Vector2(
		target.x / eye_bounds_rect.x,
		target.y / eye_bounds_rect.y
	)

	if ellipse.length() > 1.0:
		ellipse = ellipse.normalized()
		target = Vector2(
			ellipse.x * eye_bounds_rect.x,
			ellipse.y * eye_bounds_rect.y
		)
	$Icon/EyePivot/Eye.offset = target
	
func _update_animation(direction: Vector2) -> void:
	if animation_player.current_animation == "hurt":
		return
	
	if direction != Vector2.ZERO:
		if animation_player.current_animation != "run":
			play_anim("run")
	else:
		if animation_player.current_animation != "idle":
			play_anim("idle")
	
func add_exp(amount: int = 1):
	experience += amount
	exp_text.text = str(experience)
	
func take_damage(dmg: int = 1):
	
	health -= dmg

	health_bar.set_health(health, max_health)
	
	play_anim("hurt")
	Sounds.play_sound_at(global_position,["player_hurt","player_hurt1"].pick_random(),2,"SFX",randf_range(0.0,0.4))
	
		
func check_for_death():
	if health<=0:
		die()
		
func die():
	if is_alive:
		health = 0
		health_bar.set_health(health, max_health)
		
		is_alive = false

		$Icon.visible = false
		
		#animation_player.play("death")
		
		$RespawnTimer.start()
		$CanvasLayer/RespawnTimer.visible = true
		
		audio_listener_2d.current = false
		G.main.system.audio_listener_2d.current = true
		
		$Camera2D.enabled = false
		$Camera2D_fake.enabled = true
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		tween.tween_property($Camera2D_fake, "global_position", G.main.system.position, 0.6)
		
		global_position = Vector2(1152, 672)
	
@onready var audio_listener_2d: AudioListener2D = $AudioListener2D

func respawn():
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(false)
	tween.tween_property($Camera2D_fake, "global_position", $Camera2D.global_position, 0.6)
	tween.tween_callback(func(): 
		$Camera2D.enabled = true
		$Camera2D_fake.enabled = false
	)
	audio_listener_2d.current = true
	G.main.system.audio_listener_2d.current = false
	
	G.main.animation_player.play("respawn")
	await G.main.respawn_anim_signal
	
	is_alive = true
	$Icon.visible = true
	
	$CanvasLayer/RespawnTimer.visible = false
	
	health = max_health
	health_bar.set_health(health, max_health)
	
	
func game_over():
	Config.update_wave_record(G.main.wave_level)
	Config.update_score_record(experience)
	await UIManager.show_transition()
	UIManager.show_game_over([str(G.main.wave_level), str(G.main.stat_enemies_killed), str(G.main.stat_tiles_placed), str(experience)])


func _on_respawn_timer_timeout() -> void:
	respawn()

func play_anim(anim_name: String):
	if animation_player.current_animation != "hurt" or anim_name == "hurt":
		animation_player.play(anim_name)


#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#match anim_name:
		#"hurt":
			#animation_player.play("death")
