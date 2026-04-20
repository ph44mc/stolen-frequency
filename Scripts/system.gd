extends CharacterBody2D
class_name System

@onready var audio_listener_2d: AudioListener2D = $AudioListener2D

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var health: int = 100
var max_health: int = 100

var can_take_damage: bool = true
var used_second_chance: bool = false
	
func _ready() -> void:
	health = max_health
	
func take_damage(dmg: int = 1):
	if can_take_damage:
		
		health -= dmg

		health_bar.set_health(health, max_health)
		
		if !used_second_chance and health < max_health * 0.5:
			used_second_chance = true
			G.main.kill_all_enemies()
			can_take_damage = false
		
		animation_player.play("hurt")
		Sounds.play_sound("system_hurt",-4,"SFX",randf_range(0.0,0.4))

		if health<=0:
			die()
		
func die():
	G.main.player.game_over()



func _on_area_2d_mouse_entered() -> void:
	$SystemTransparent.visible = true
	$System.visible = false

func _on_area_2d_mouse_exited() -> void:
	$SystemTransparent.visible = false
	$System.visible = true
	
