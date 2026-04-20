extends Label3D
class_name DebugLabel

@export var parent_variables: Array[StringName] = []

func _process(_delta: float) -> void:
	var parent_node = get_parent()
	if parent_node == null: return

	var lines: Array[String] = []
	for var_name in parent_variables:
		var value = parent_node.get(var_name)
		if value != null: lines.append(var_name +": "+ str(value))
			
	text = "\n".join(lines)
