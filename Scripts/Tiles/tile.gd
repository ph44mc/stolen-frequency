extends Node2D
class_name Tile

var t_name: String = "tile"
@onready var outline: NinePatchRect = $TileImage/Outline

var target
var action_speed: int = 1
var is_for_showcase: bool = false

func _ready() -> void:
	$TileImage/Sprite2D/AnimationPlayer.play("tile_spawn")
	on_ready()

func on_ready():
	pass

func _on_hitbox_body_entered(body: Node2D) -> void:
	pass
	
func _on_hitbox_body_exited(body: Node2D) -> void:
	pass # Replace with function body.


func _on_hitbox_mouse_entered() -> void:
	if G.main.player.choose.is_closed:
		outline.visible = true
		UIManager.show_tooltip(self,tooltip_data())

func _on_hitbox_mouse_exited() -> void:
	outline.visible = false
	UIManager.hide_tooltip(self)

func tooltip_data():
	return {
		"name": t_name,
		"description": t_name+"_desc",
		"world": "Hell",
		#"fields": [
			#{"name": "Damage", "value": "10"},
			#{"name": "Weight", "value": "3kg"}
		#]
	}
