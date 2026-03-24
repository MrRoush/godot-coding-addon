@tool
class_name ESRotateAction
extends ESAction
## Action that rotates a node toward the mouse cursor, another node, or a fixed angle.
## Essential for tank-style dual-stick controls (turret aiming), top-down enemies
## that face the player, and any game that needs directional rotation.

enum RotateType {
	LOOK_AT_MOUSE,  ## Rotate to face the current mouse cursor position (2D only)
	LOOK_AT_NODE,   ## Rotate to face another node's position
	SET_ROTATION,   ## Set rotation to a specific angle in degrees
	ROTATE_BY,      ## Add a rotation offset (degrees, or degrees/second with use_delta)
}

## How to rotate the node.
@export var rotate_type: RotateType = RotateType.LOOK_AT_MOUSE

## Path to the node to rotate. Leave empty to rotate the EventController's parent.
## Use "$collider" to rotate the last collided node.
@export var target_path: NodePath = NodePath("")

## Path to the node to face (used with LOOK_AT_NODE).
@export var look_at_node_path: NodePath = NodePath("")

## Angle in degrees for SET_ROTATION, or degrees (per second) for ROTATE_BY.
@export var angle_degrees: float = 0.0

## Rotation offset added to the computed facing angle, in degrees.
## Use this to correct the sprite's natural orientation
## (e.g., 90 if the sprite points up instead of right).
@export var rotation_offset_degrees: float = 0.0

## If true, multiply ROTATE_BY amount by delta time (frame-independent rotation).
@export var use_delta: bool = true

## Smooth rotation speed in degrees/second toward the target angle.
## Set to 0 for instant snapping. Values around 360–720 feel natural.
@export var rotation_speed: float = 0.0


func get_summary() -> String:
	var target := str(target_path) if not target_path.is_empty() else "parent"
	match rotate_type:
		RotateType.LOOK_AT_MOUSE:
			return "Rotate %s toward mouse" % target
		RotateType.LOOK_AT_NODE:
			var goal := str(look_at_node_path) if not look_at_node_path.is_empty() else "?"
			return "Rotate %s toward %s" % [target, goal]
		RotateType.SET_ROTATION:
			return "Set %s rotation to %.1f°" % [target, angle_degrees]
		RotateType.ROTATE_BY:
			return "Rotate %s by %.1f°%s" % [target, angle_degrees, "/s" if use_delta else ""]
	return "Rotate"


func get_category() -> String:
	return "Movement"


func execute(controller: Node, delta: float) -> void:
	var target: Node = _resolve_target(controller)
	if not target:
		return

	var offset_rad := deg_to_rad(rotation_offset_degrees)

	if target is Node2D:
		_execute_2d(target as Node2D, offset_rad, delta, controller)
	elif target is Node3D:
		_execute_3d(target as Node3D, delta, controller)


func _execute_2d(node: Node2D, offset_rad: float, delta: float, controller: Node) -> void:
	match rotate_type:
		RotateType.LOOK_AT_MOUSE:
			var mouse_pos := node.get_global_mouse_position()
			var desired := node.global_position.angle_to_point(mouse_pos) + offset_rad
			node.global_rotation = _apply_speed(node.global_rotation, desired, delta)
		RotateType.LOOK_AT_NODE:
			var goal_node := _resolve_look_at_node(controller)
			if goal_node and goal_node is Node2D:
				var desired := node.global_position.angle_to_point(
					(goal_node as Node2D).global_position) + offset_rad
				node.global_rotation = _apply_speed(node.global_rotation, desired, delta)
		RotateType.SET_ROTATION:
			node.rotation_degrees = angle_degrees
		RotateType.ROTATE_BY:
			node.rotation_degrees += angle_degrees * (delta if use_delta else 1.0)


func _execute_3d(node: Node3D, delta: float, controller: Node) -> void:
	match rotate_type:
		RotateType.LOOK_AT_NODE:
			var goal_node := _resolve_look_at_node(controller)
			if goal_node and goal_node is Node3D:
				var dir := (goal_node as Node3D).global_position - node.global_position
				dir.y = 0.0
				if dir.length_squared() > 0.0001:
					node.look_at(node.global_position + dir, Vector3.UP)
		RotateType.SET_ROTATION:
			node.rotation_degrees.y = angle_degrees
		RotateType.ROTATE_BY:
			node.rotation_degrees.y += angle_degrees * (delta if use_delta else 1.0)


## Returns the new rotation angle, either snapped or smoothly interpolated.
func _apply_speed(current: float, desired: float, delta: float) -> float:
	if rotation_speed <= 0.0:
		return desired
	# Shortest-path angle interpolation to avoid 360° wrap-around jumps.
	var diff := fmod(desired - current, TAU)
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	var step := deg_to_rad(rotation_speed) * delta
	return current + clampf(diff, -step, step)


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
	push_warning("EventSheet: RotateAction: target not found at '%s'." % str(target_path))
	return null


func _resolve_look_at_node(controller: Node) -> Node:
	if look_at_node_path.is_empty():
		return null
	var path_str := str(look_at_node_path)
	if path_str == "$collider":
		var meta_val = controller.get_meta(&"_es_last_collided_node", null)
		return meta_val if meta_val is Node else null
	return controller.get_node_or_null(look_at_node_path)
