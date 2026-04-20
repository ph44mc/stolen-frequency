extends Node2D
class_name Main

@onready var player: Player = $YSort/Player
@onready var system: System = $YSort/System
@onready var y_sort: Node2D = $YSort
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var door_wall_1: TileMap = $DoorWall1
@onready var door_wall_2: TileMap = $DoorWall2
@onready var door_wall_3: TileMap = $DoorWall3

var wave_is_active: bool = false
var wave_level: int = 0

var reward_delay: float = 0

var stat_enemies_killed: int = 0
var stat_tiles_placed: int = 0

var enemies_alive: int = 0
var enemies: Array = []
var tiles: Array = []

var player_copies: Array = []

signal wave_end
signal respawn_anim_signal

func _ready() -> void:
	G.in_cutscene = false
	get_tree().current_scene.ready.connect(_on_scene_ready)
	
func _on_scene_ready():
	G.main = self
	await get_tree().create_timer(0.3,false).timeout
	update_doors_for_next_wave()
	UIManager.hide_transition()

func start_wave():

	
	player.wave_text.text = "Wave: " + str(wave_level)
	wave_is_active = true

	var wave_data = _get_wave_data(wave_level)
	
	var total_enemies = _get_enemy_count()

	enemies_alive = total_enemies

	player.enemies_left_text.visible = true
	player.enemies_left_text.text = str(enemies_alive)

	await _spawn_wave(wave_data, total_enemies)

	wave_level += 1
	
func _spawn_wave(wave_data: Dictionary, total_count: int):
	for i in total_count:
		var type_key = wave_data["enemies"].pick_random()
		var data = enemy_types[type_key]

		var spawn_index = wave_data["spawns"][i % wave_data["spawns"].size()]
		spawn_enemy(data, spawn_index)

		await get_tree().create_timer(0.4,false).timeout
		
func end_wave():
	if wave_is_active:
		update_doors_for_next_wave()
		
		wave_is_active = false
		if !player.is_alive: 
			player.respawn()
			reward_delay = 3
			
		if wave_level == 50:
			Config.add_won_times(1)
			player.icon.texture = load("res://Assets/UI/player_win.png")
			
		await get_tree().create_timer(reward_delay,false).timeout
		
		player.enemies_left_text.visible = false
		player.health_bar.visible = false
		
		player.choose.start_choose()
		reward_delay = 0
		
		wave_end.emit()
		
func on_enemy_die(enemy):
	enemies_alive-=1
	player.enemies_left_text.text = str(enemies_alive)
	enemies.erase(enemy)
	if enemies_alive<=0:
		end_wave()
		
func spawn_enemy(data: Dictionary, spawn_index: int):
	var enemy

	if data.has("scene"):
		enemy = load(data["scene"]).instantiate()
	else:
		enemy = load("res://Scenes/Enemies/enemy.tscn").instantiate()

	enemy.player_target = player
	enemy.died.connect(on_enemy_die)

	if data.has("texture") and enemy.has_node("Sprite2D"):
		enemy.start_texture = load(data["texture"])

	if data.has("health"):
		enemy.health = data["health"]

	if data.has("damage"):
		enemy.damage = data["damage"]

	if data.has("speed"):
		enemy.speed = data["speed"]

	if data.has("stealth"):
		enemy.stealth = data["stealth"]

	if not data.has("scene"):
		enemy.health += wave_level

	y_sort.add_child(enemy)
	enemies.append(enemy)

	var spawn_points = [
		Vector2(512,-60),
		Vector2(192,-60),
		Vector2(832,-60)
	]

	enemy.global_position = spawn_points[spawn_index]
	
var enemy_types := {
	"basic": {
		"texture": "res://Assets/Enemies/enemy.png",
		"health": 3,
		"damage": 1,
		"speed": 240
	},

	"strong": {
		"texture": "res://Assets/Enemies/enemy2.png",
		"health": 5,
		"damage": 3,
		"speed": 240
	},

	"fast": {
		"texture": "res://Assets/Enemies/enemy3.png",
		"health": 5,
		"damage": 1,
		"speed": 320
	},

	"tank1": {
		"texture": "res://Assets/Enemies/enemy4.png",
		"health": 55,
		"damage": 5,
		"speed": 190
	},

	"tank2": {
		"texture": "res://Assets/Enemies/enemy5.png",
		"health": 75,
		"damage": 10,
		"speed": 170
	},

	"tank3": {
		"texture": "res://Assets/Enemies/enemy6.png",
		"health": 95,
		"damage": 20,
		"speed": 150
	},

	"tank4": {
		"texture": "res://Assets/Enemies/enemy7.png",
		"health": 115,
		"damage": 10,
		"speed": 200
	},

	"stealth": {
		"texture": "res://Assets/Enemies/enemy8.png",
		"health": 50,
		"damage": 4,
		"speed": 170,
		"stealth": true
	},
	
	"monk": {
		"scene": "res://Scenes/Enemies/enemy9.tscn"
	}
}

var waves := [
	{ "min": 0,  "enemies": ["basic"], "spawns": [0] },
	{ "min": 5,  "enemies": ["basic","strong"], "spawns": [0,1] },
	{ "min": 10, "enemies": ["basic","fast"], "spawns": [0,1,2] },
	{ "min": 15, "enemies": ["strong","tank1"], "spawns": [0,2] },
	{ "min": 16, "enemies": ["basic","fast","strong","tank1"], "spawns": [0,1,2] },
	{ "min": 20, "enemies": ["tank2","stealth"], "spawns": [0,1,2] },
	{ "min": 21, "enemies": ["basic","fast","strong","tank1"], "spawns": [0,2] },
	{ "min": 25, "enemies": ["tank3","fast","strong","tank1"], "spawns": [0,2] },
	{ "min": 30, "enemies": ["tank4","fast","stealth","tank2"], "spawns": [0,1,2] },
	{ "min": 49, "enemies": ["stealth"], "spawns": [1] },
	{ "min": 50, "enemies": ["monk","stealth","tank4"], "spawns": [0,1,2] }
]


func _get_wave_data(level: int):
	var current = waves[0]

	for w in waves:
		if level >= w["min"]:
			current = w
		else:
			break

	return current
	
func update_doors_for_next_wave():
	var next_wave = wave_level
	var wave_data = _get_wave_data(next_wave)

	var active_spawns = wave_data["spawns"]

	var doors = [door_wall_1, door_wall_2, door_wall_3]
	var doors_col = [$WallCollider/Door1, $WallCollider/Door2, $WallCollider/Door3]
	
	for i in doors.size():
		if i in active_spawns:
			doors_col[i].disabled = true
			doors[i].visible = false
		else:
			doors_col[i].disabled = false
			doors[i].visible = true
			
func _get_enemy_count() -> int:
	return wave_level + 1
	
func kill_all_enemies():
	reward_delay = 3
	for enemy in enemies:
		enemy.die()
		
	await get_tree().create_timer(1.0,false).timeout
	player.respawn()
	system.can_take_damage = true
	
