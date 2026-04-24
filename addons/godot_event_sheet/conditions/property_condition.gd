@tool
class_name ESPropertyCondition
extends ESCondition
## Condition that compares a property on a node against a value.

enum CompareOp {
	EQUAL,          ## ==
	NOT_EQUAL,      ## !=
	GREATER,        ## >
	LESS,           ## <
	GREATER_EQUAL,  ## >=
	LESS_EQUAL,     ## <=
}

## Path to the node whose property to check.
## Leave empty to use the EventController's parent node.
@export var node_path: NodePath = NodePath("")

## The property name to read (e.g., "position.x", "health", "visible").
@export var property_name: String = ""

## The comparison operator.
@export_enum("Equal (==):0", "Not Equal (!=):1", "Greater Than (>):2", "Less Than (<):3", "Greater or Equal (>=):4", "Less or Equal (<=):5") var compare_op: int = CompareOp.EQUAL

## The value to compare against.
## Stored as the correct Godot type (bool, float, int) when entered via the dialog.
## Store as a String to use placeholder expressions like {../Player:health}.
@export var compare_value: Variant = null


func get_summary() -> String:
	var ops := ["==", "!=", ">", "<", ">=", "<="]
	var target := str(node_path) if not node_path.is_empty() else "parent"
	var val_str := str(compare_value) if compare_value != null else ""
	return "%s.%s %s %s" % [target, property_name, ops[compare_op], val_str]


func get_category() -> String:
	return "Properties"


func evaluate(controller: Node, _delta: float) -> bool:
	var target: Node = _resolve_node(controller)
	if not target or property_name.is_empty():
		return false

	var current_value = _get_nested_property(target, property_name)
	if current_value == null:
		return false

	# Resolve the comparison value: support typed values and placeholder strings.
	var test_value: Variant
	if compare_value is String:
		test_value = _convert_value(compare_value as String, typeof(current_value))
	elif compare_value != null:
		test_value = compare_value
	else:
		test_value = _convert_value("0", typeof(current_value))

	match compare_op:
		CompareOp.EQUAL:
			return current_value == test_value
		CompareOp.NOT_EQUAL:
			return current_value != test_value
		CompareOp.GREATER:
			return current_value > test_value
		CompareOp.LESS:
			return current_value < test_value
		CompareOp.GREATER_EQUAL:
			return current_value >= test_value
		CompareOp.LESS_EQUAL:
			return current_value <= test_value
	return false


func _resolve_node(controller: Node) -> Node:
	if node_path.is_empty():
		return controller.get_parent()
	var path_str := str(node_path)
	if path_str == "$collider":
		var meta_val = controller.get_meta(&"_es_last_collided_node", null)
		return meta_val if meta_val is Node else null
	return controller.get_node_or_null(node_path)


## Get a property that may use dot notation (e.g., "position.x").
func _get_nested_property(node: Node, prop: String) -> Variant:
	var parts := prop.split(".")
	var current: Variant = node
	for part in parts:
		if current == null:
			return null
		if current is Object and part in current:
			current = current.get(part)
		elif current is Vector2:
			match part:
				"x": current = current.x
				"y": current = current.y
				_: return null
		elif current is Vector3:
			match part:
				"x": current = current.x
				"y": current = current.y
				"z": current = current.z
				_: return null
		else:
			return null
	return current


## Convert a string value to the expected type.
func _convert_value(val: String, target_type: int) -> Variant:
	match target_type:
		TYPE_INT:
			return int(val)
		TYPE_FLOAT:
			return float(val)
		TYPE_BOOL:
			return val.to_lower() == "true" or val == "1"
		TYPE_STRING:
			return val
		_:
			# Try numeric conversion as fallback.
			if val.is_valid_float():
				return float(val)
			if val.is_valid_int():
				return int(val)
			return val
