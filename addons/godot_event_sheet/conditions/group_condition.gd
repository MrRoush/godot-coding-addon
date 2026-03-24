@tool
class_name ESGroupCondition
extends ESCondition
## Condition that checks whether a node belongs to a named group.
## Useful for checking game state, enemy team membership, power-up status,
## and filtering which objects to act on in a given event.

## Path to the node whose group membership is checked.
## Leave empty for the EventController's parent. Use "$collider" for last collision.
@export var node_path: NodePath = NodePath("")

## The group name to check.
@export var group_name: String = ""


func get_summary() -> String:
	var target := str(node_path) if not node_path.is_empty() else "parent"
	return "Is %s in group \"%s\"" % [target, group_name]


func get_category() -> String:
	return "Utility"


func evaluate(controller: Node, _delta: float) -> bool:
	if group_name.is_empty():
		return false
	var target := _resolve_node(controller)
	if not target:
		return false
	return target.is_in_group(group_name)


func _resolve_node(controller: Node) -> Node:
	if node_path.is_empty():
		return controller.get_parent()
	var path_str := str(node_path)
	if path_str == "$collider":
		var meta_val = controller.get_meta(&"_es_last_collided_node", null)
		return meta_val if meta_val is Node else null
	var target := controller.get_node_or_null(node_path)
	if target:
		return target
	var parent := controller.get_parent()
	if parent:
		target = parent.get_node_or_null(node_path)
		if target:
			return target
	return null
