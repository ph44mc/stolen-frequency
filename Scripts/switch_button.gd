extends TextureButton
class_name SwitchButton

var is_on: bool = false
@export var region_width: int = 50
@export var region_height: int = 50

@onready var normal_tex: AtlasTexture = texture_normal as AtlasTexture
@onready var hover_tex: AtlasTexture = texture_hover as AtlasTexture

signal switched(on: bool)

func _ready() -> void:
	update_regions(0)

func update_regions(x_offset: int) -> void:
	if normal_tex:
		normal_tex.region = Rect2(x_offset, 0, region_width, region_height)
	if hover_tex:
		hover_tex.region = Rect2(x_offset, region_height, region_width, region_height)

func _pressed() -> void:
	is_on = not is_on
	var x_offset = region_width if !is_on else 0
	update_regions(x_offset)
	emit_signal("switched", is_on)

func switch(to: bool):
	is_on = to
	var x_offset = region_width if !is_on else 0
	update_regions(x_offset)
	emit_signal("switched", is_on)
