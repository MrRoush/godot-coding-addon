@tool
class_name ESRandomAction
extends ESAction
## Action that sets a node property to a random value, or teleports a node to
## a random position within a rectangular boundary.
## Useful for power-up effects, random enemy spawn positions, and game variation.

enum RandomOp {
	SET_RANDOM_FLOAT,  ## Set a node property to a random float in [min, max]
	SET_RANDOM_INT,    ## Set a node property to a random integer in [min, max]
	RANDOM_POSITION,   ## Move the node to a random world position in a bounding box
}

## Operation to perform.
@export var operation: RandomOp = RandomOp.SET_RANDOM_FLOAT

## Path to the target node. Leave empty for the EventController's parent.
@export var target_path: NodePath = NodePath("")

## Property to set (SET_RANDOM_FLOAT / SET_RANDOM_INT). Supports dot notation (e.g. "speed", "scale.x").
@export var property_name: String = ""

## Minimum value of the random range.
@export var min_value: float = 0.0

## Maximum value of the random range.
@export var max_value: float = 100.0

## Minimum X boundary for RANDOM_POSITION.
@export var min_x: float = 0.0

## Maximum X boundary for RANDOM_POSITION.
@export var max_x: float = 1024.0

## Minimum Y boundary for RANDOM_POSITION.
@export var min_y: float = 0.0

## Maximum Y boundary for RANDOM_POSITION.
@export var max_y: float = 600.0


func get_summary() -> String:
	var target := str(target_path) if not target_path.is_empty() else "parent"
	match operation:
		RandomOp.SET_RANDOM_FLOAT:
			return "Random: Set %s.%s = float [%.1f–%.1f]" % [target, property_name, min_value, max_value]
		RandomOp.SET_RANDOM_INT:
			return "Random: Set %s.%s = int [%d–%d]" % [target, property_name, int(min_value), int(max_value)]
		RandomOp.RANDOM_POSITION:
			return "Random: Move %s to random position" % target
	return "Random action"


func get_category() -> String:
	return "Utility"


func execute(controller: Node, _delta: float) -> void:
	var target := _resolve_target(controller)
	if not target:
		return

	match operation:
		RandomOp.SET_RANDOM_FLOAT:
			if property_name.is_empty():
				push_warning("EventSheet: RandomAction: No property name specified.")
				return
			_set_property(target, property_name, randf_range(min_value, max_value))
		RandomOp.SET_RANDOM_INT:
			if property_name.is_empty():
				push_warning("EventSheet: RandomAction: No property name specified.")
				return
			_set_property(target, property_name, randi_range(int(min_value), int(max_value)))
		RandomOp.RANDOM_POSITION:
			var pos := Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
			if target is Node2D:
				(target as Node2D).global_position = pos
			elif target is Node3D:
				(target as Node3D).global_position = Vector3(pos.x, pos.y, 0.0)


func _set_property(node: Node, prop: String, value: Variant) -> void:
	if "." in prop:
		# Dot-notation: read the sub-object, mutate it, write it back.
		var parts := prop.split(".", false, 1)
		var base_val = node.get(parts[0])
		if base_val == null:
			push_warning("EventSheet: RandomAction: Property '%s' not found on %s." % [parts[0], node.name])
			return
		base_val.set(parts[1], value)
		node.set(parts[0], base_val)
	else:
		if prop in node:
			node.set(prop, value)
		else:
			push_warning("EventSheet: RandomAction: Property '%s' not found on %s." % [prop, node.name])


func _resolve_target(controller: Node) -> Node:
	if target_path.is_empty():
		return controller.get_parent()
	var path_str := str(target_path)
	if path_str == "$collider":
		var meta_val = controller.get_meta(&"_es_last_collided_node", null)
		return meta_val if meta_val is Node else null
	var target := controller.get_node_or_null(target_path)
	if target:
		return target
	var parent := controller.get_parent()
	if parent:
		target = parent.get_node_or_null(target_path)
		if target:
			return target
	push_warning("EventSheet: RandomAction: Target not found at '%s'." % str(target_path))
	return null
