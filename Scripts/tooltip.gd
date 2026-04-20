extends Control
class_name Tooltip

# ==============================
# NODES
# ==============================
@onready var container = $Container
@onready var name_label = %Name
@onready var rareness = %Rareness
@onready var desc = %Desc
@onready var from_world = %FromWorld

# ==============================
# SETTINGS
# ==============================
const BASE_OFFSET := Vector2(60, -70)
const SIDE_SPACING := 10
const SCREEN_MARGIN := 10

const MINI_HEIGHT_OFFSET := 60
const MINI_LEFT_FIX := 80

# ==============================
# STATE
# ==============================
var target: Node = null
var data: Dictionary = {}
var active_effect_tooltips: Array = []
var tooltip_side := 1

var desc_tween: Tween

# ==============================
# PUBLIC API
# ==============================
func set_target(t):
	target = t	
	if t == null:
		_clear_all()
		return

	_update_content()


func set_data(d):
	# отдельный метод под данные (строка или dict)
	if target and target.has_method("get_tooltip_data"):
		data = target.get_tooltip_data()
	elif typeof(d) == TYPE_STRING:
		data = {
			"name": d,
			"description": ""
		}
	elif typeof(d) == TYPE_DICTIONARY:
		data = d
	else:
		data = {
			"name": str(d),
			"description": ""
		}

	_update_content()


func setup(target_node, d):
	set_target(target_node)
	set_data(d)


# ==============================
# PROCESS
# ==============================
func _process(_delta):
	if visible and target!=null:
		_update_position()


# ==============================
# CONTENT
# ==============================
func _update_content():
	_clear_text()

	name_label.text = data.get("name", "")
	desc.text = data.get("description", "")

	_fill_rarity()
	_fill_world()

	_clear_effects()
	_create_fields()

	await get_tree().process_frame
	_animate_desc()


func _clear_all():
	_clear_text()
	_clear_effects()
	data = {}


func _clear_text():
	name_label.text = ""
	rareness.text = ""
	desc.text = ""
	from_world.text = ""


# ==============================
# RARITY
# ==============================
func _fill_rarity():
	if not data.has("rarity"):
		rareness.visible = false
		return

	rareness.visible = true
	rareness.text = _rarity_bbcode(data.rarity)


const RARITY_NAMES := ["Common","Uncommon","Rare","Artifact"]
const RARITY_COLORS := ["#8B6A4A","#3E8F55","#4A4DB8","#C0392B"]

func _rarity_bbcode(rarity: int) -> String:
	if rarity < 0 or rarity >= RARITY_NAMES.size():
		return ""

	var name = RARITY_NAMES[rarity]
	var color = RARITY_COLORS[rarity]

	if rarity == 2:
		return "[color=%s][wave amp=4 freq=6]%s[/wave][/color]" % [color, name]

	if rarity == 3:
		return "[color=%s][wave amp=10 freq=10]%s[/wave][/color]" % [color, name]

	return "[color=%s]%s[/color]" % [color, name]

func _fill_world():
	if not data.has("world"):
		from_world.visible = false
		return

	from_world.visible = true
	from_world.text = _world_bbcode(data.world)
	
const WORLD_COLORS := {
	"Hell": "#FF1000",
	"Overworld": "#FFFFFF",
	"Prism": "#BCA0FF",
	"Ocean": "#00A1FF",
	"Spore": "#9b60e2",
	"Void": "#C1C1C1",
	"Rusty": "#BF8261",
	"Glyph": "#BC0983",
}
	
func _world_bbcode(world: String) -> String:

	var color = WORLD_COLORS[world]

	return "[color=%s][wave amp=6 freq=6]%s[/wave][/color]" % [color, world]
	
# ==============================
# FIELDS → MINI TOOLTIPS
# ==============================
func _clear_effects():
	for t in active_effect_tooltips:
		t.queue_free()
	active_effect_tooltips.clear()


func _create_fields():
	if not data.has("fields"):
		return
		
	for field in data.fields:
		var title = str(field.get("name", ""))
		var value = str(field.get("value", ""))
		var description = str(field.get("desc", ""))

		var text = value if description == "" else description

		_create_mini_tooltip(title, text)


func _create_mini_tooltip(title: String, description: String):
	var scene = load("res://Scenes/simplified_tooltip.tscn")
	if scene == null:
		return

	var t = scene.instantiate()
	add_child(t)

	await get_tree().process_frame

	var name_node = t.get_node_or_null("%Name")
	var desc_node = t.get_node_or_null("%Desc")

	if name_node:
		name_node.text = title

	if desc_node:
		desc_node.text = description

	active_effect_tooltips.append(t)


# ==============================
# POSITION
# ==============================
func _update_position():
	var viewport_size = get_viewport().size
	var target_pos = get_viewport().get_mouse_position()

	var main_size = container.size

	var total_width = _get_total_width(main_size)
	tooltip_side = _get_side(target_pos, viewport_size, total_width)

	var offset = BASE_OFFSET

	if tooltip_side == -1:
		offset.x = -main_size.x - abs(offset.x)

	var final_pos = target_pos + offset
	final_pos.y = clamp(final_pos.y, SCREEN_MARGIN, viewport_size.y - main_size.y - SCREEN_MARGIN)

	global_position = final_pos

	_update_effect_positions(main_size)

	# fallback
	return get_viewport().get_mouse_position()
	
func _get_total_width(main_size):
	var max_effect_width := 0.0

	for t in active_effect_tooltips:
		max_effect_width = max(max_effect_width, t.size.x)

	if active_effect_tooltips.is_empty():
		return main_size.x

	return main_size.x + SIDE_SPACING + max_effect_width


func _get_side(target_pos, viewport_size, total_width):
	var side := 1

	if target_pos.x > viewport_size.x / 2:
		side = -1

	if side == 1 and target_pos.x + total_width > viewport_size.x:
		side = -1
	elif side == -1 and target_pos.x - total_width < 0:
		side = 1

	return side


# ==============================
# MINI TOOLTIP POSITIONS
# ==============================
func _update_effect_positions(main_size):
	for i in active_effect_tooltips.size():
		var t = active_effect_tooltips[i]

		var x_offset = (main_size.x + SIDE_SPACING) if tooltip_side == 1 else (-t.size.x + MINI_LEFT_FIX)
		var y_offset = i * (t.size.y - MINI_HEIGHT_OFFSET)

		t.global_position = Vector2(
			global_position.x + x_offset,
			global_position.y + y_offset
		)


# ==============================
# DESC ANIMATION
# ==============================
func _animate_desc():
	if desc_tween and desc_tween.is_running():
		desc_tween.kill()

	desc.visible_ratio = 0

	await get_tree().process_frame

	desc_tween = create_tween()
	desc_tween.set_ease(Tween.EASE_OUT)
	desc_tween.set_trans(Tween.TRANS_EXPO)

	desc_tween.tween_property(desc, "visible_ratio", 1.2, 0.5)
