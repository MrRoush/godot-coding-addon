@tool
class_name ESDistanceCondition
extends ESCondition
## Condition that checks the distance between two nodes.
## Useful for enemy detection ranges, item pickup triggers, and proximity events.
## Works with both Node2D and Node3D hierarchies.

enum CompareOp {
	LESS_THAN,       ## True when distance < threshold (within range)
	GREATER_THAN,    ## True when distance > threshold (outside range)
	LESS_OR_EQUAL,   ## True when distance <= threshold
	GREATER_OR_EQUAL, ## True when distance >= threshold
}

## Path to the first node. Leave empty to use the EventController's parent.
@export var node_a_path: NodePath = NodePath("")

## Path to the second node to measure distance to (e.g., "../Player").
@export var node_b_path: NodePath = NodePath("")

## Comparison operator applied to the measured distance.
@export var compare_op: CompareOp = CompareOp.LESS_THAN

## Distance threshold in pixels (2D) or units (3D).
@export var distance: float = 200.0


func get_summary() -> String:
	var op_names := ["<", ">", "<=", ">="]
	var a := str(node_a_path) if not node_a_path.is_empty() else "parent"
	var b := str(node_b_path) if not node_b_path.is_empty() else "?"
	return "Distance(%s → %s) %s %.0f" % [a, b, op_names[compare_op], distance]


func get_category() -> String:
	return "Utility"


func evaluate(controller: Node, _delta: float) -> bool:
	var node_a := _resolve_node(controller, node_a_path, true)
	var node_b := _resolve_node(controller, node_b_path, false)
	if not node_a or not node_b:
		return false

	var dist: float
	if node_a is Node2D and node_b is Node2D:
		dist = (node_a as Node2D).global_position.distance_to(
			(node_b as Node2D).global_position)
	elif node_a is Node3D and node_b is Node3D:
		dist = (node_a as Node3D).global_position.distance_to(
			(node_b as Node3D).global_position)
	else:
		return false

	match compare_op:
		CompareOp.LESS_THAN:
			return dist < distance
		CompareOp.GREATER_THAN:
			return dist > distance
		CompareOp.LESS_OR_EQUAL:
			return dist <= distance
		CompareOp.GREATER_OR_EQUAL:
			return dist >= distance
	return false


func _resolve_node(controller: Node, path: NodePath, use_parent_if_empty: bool) -> Node:
	if path.is_empty():
		return controller.get_parent() if use_parent_if_empty else null
	var target := controller.get_node_or_null(path)
	if target:
		return target
	var parent := controller.get_parent()
	if parent:
		target = parent.get_node_or_null(path)
		if target:
			return target
	return null
