@tool
class_name ESMoveAction
extends ESAction
## Action that moves a 2D or 3D node.

enum MoveType {
	TRANSLATE,         ## Move by an offset (relative)
	SET_POSITION,      ## Set absolute position
	MOVE_TOWARD,       ## Move toward a target position (x, y) at a given speed
	MOVE_TOWARD_NODE,  ## Move toward another node's current position at a given speed
	SET_VELOCITY,      ## Set velocity and call move_and_slide() (CharacterBody2D/3D)
}

## How to move the node.
@export var move_type: MoveType = MoveType.TRANSLATE

## Path to the node to move. Leave empty to move the EventController's parent.
@export var target_path: NodePath = NodePath("")

## X component of the movement, position, or velocity direction.
@export var x: float = 0.0

## Y component of the movement, position, or velocity direction.
@export var y: float = 0.0

## Speed in pixels/units per second (used with TRANSLATE, MOVE_TOWARD, MOVE_TOWARD_NODE, SET_VELOCITY).
@export var speed: float = 200.0

## If true, multiply the translation by delta time for frame-independent movement.
@export var use_delta: bool = true

## Path to the target node to move toward (used with MOVE_TOWARD_NODE).
## Use "$collider" to target the last collided node.
@export var toward_node_path: NodePath = NodePath("")


func get_summary() -> String:
	var target := str(target_path) if not target_path.is_empty() else "parent"
	match move_type:
		MoveType.TRANSLATE:
			return "Move %s by (%.0f, %.0f) at speed %.0f" % [target, x, y, speed]
		MoveType.SET_POSITION:
			return "Set %s position to (%.0f, %.0f)" % [target, x, y]
		MoveType.MOVE_TOWARD:
			return "Move %s toward (%.0f, %.0f) at speed %.0f" % [target, x, y, speed]
		MoveType.MOVE_TOWARD_NODE:
			var goal_node := str(toward_node_path) if not toward_node_path.is_empty() else "?"
			return "Move %s toward node %s at speed %.0f" % [target, goal_node, speed]
		MoveType.SET_VELOCITY:
			return "Set %s velocity (%.0f, %.0f) * speed %.0f" % [target, x, y, speed]
	return "Move"


func get_category() -> String:
	return "Movement"


func execute(controller: Node, delta: float) -> void:
	var target: Node = _resolve_target(controller)
	if not target:
		return

	var dt: float = delta if use_delta else 1.0

	if target is Node2D:
		_execute_2d(target as Node2D, dt, controller)
	elif target is Node3D:
		_execute_3d(target as Node3D, dt, controller)


func _execute_2d(node: Node2D, dt: float, controller: Node) -> void:
	match move_type:
		MoveType.TRANSLATE:
			var direction := Vector2(x, y).normalized()
			node.position += direction * speed * dt
		MoveType.SET_POSITION:
			node.position = Vector2(x, y)
		MoveType.MOVE_TOWARD:
			var goal := Vector2(x, y)
			node.position = node.position.move_toward(goal, speed * dt)
		MoveType.MOVE_TOWARD_NODE:
			var goal_node := _resolve_toward_node(controller)
			if goal_node and goal_node is Node2D:
				node.position = node.position.move_toward(
					(goal_node as Node2D).global_position, speed * dt)
		MoveType.SET_VELOCITY:
			if node is CharacterBody2D:
				var body := node as CharacterBody2D
				var direction := Vector2(x, y)
				if direction.length() > 0:
					direction = direction.normalized()
				# When direction is zero and speed is zero the user wants
				# to stop all movement (e.g. "any key released → stop").
				if direction == Vector2.ZERO and speed == 0.0:
					body.velocity = Vector2.ZERO
				else:
					# Only modify velocity axes that have a non-zero direction
					# component.  This preserves gravity on velocity.y when
					# doing horizontal movement and preserves horizontal
					# velocity when jumping.
					if x != 0.0:
						body.velocity.x = direction.x * speed
					if y != 0.0:
						body.velocity.y = direction.y * speed
				body.move_and_slide()


func _execute_3d(node: Node3D, dt: float, controller: Node) -> void:
	match move_type:
		MoveType.TRANSLATE:
			var direction := Vector3(x, y, 0).normalized()
			node.position += direction * speed * dt
		MoveType.SET_POSITION:
			node.position = Vector3(x, y, 0)
		MoveType.MOVE_TOWARD:
			var goal := Vector3(x, y, 0)
			node.position = node.position.move_toward(goal, speed * dt)
		MoveType.MOVE_TOWARD_NODE:
			var goal_node := _resolve_toward_node(controller)
			if goal_node and goal_node is Node3D:
				node.position = node.position.move_toward(
					(goal_node as Node3D).global_position, speed * dt)
		MoveType.SET_VELOCITY:
			if node is CharacterBody3D:
				var body := node as CharacterBody3D
				var direction := Vector3(x, y, 0)
				if direction.length() > 0:
					direction = direction.normalized()
				# When direction is zero and speed is zero the user wants
				# to stop all movement (see 2D counterpart above).
				if direction == Vector3.ZERO and speed == 0.0:
					body.velocity = Vector3.ZERO
				else:
					# Only modify velocity axes that have a non-zero direction
					# component (see 2D counterpart above for rationale).
					if x != 0.0:
						body.velocity.x = direction.x * speed
					if y != 0.0:
						body.velocity.y = direction.y * speed
				body.move_and_slide()


func _resolve_target(controller: Node) -> Node:
	if target_path.is_empty():
		return controller.get_parent()
	var path_str := str(target_path)
	if path_str == "$collider":
		var meta_val = controller.get_meta(&"_es_last_collided_node", null)
		return meta_val if meta_val is Node else null

	# Try the path relative to the controller first.
	var target := controller.get_node_or_null(target_path)
	if target:
		return target

	# Fallback: try relative to the controller's parent (e.g. user typed
	# "Player" instead of "../Player" for a sibling node).
	var parent := controller.get_parent()
	if parent:
		target = parent.get_node_or_null(target_path)
		if target:
			return target

	push_warning("EventSheet: Move target node not found at path '%s'. " \
		+ "Try '../NodeName' for sibling nodes." % str(target_path))
	return null


func _resolve_toward_node(controller: Node) -> Node:
	if toward_node_path.is_empty():
		return null
	var path_str := str(toward_node_path)
	if path_str == "$collider":
		var meta_val = controller.get_meta(&"_es_last_collided_node", null)
		return meta_val if meta_val is Node else null
	return controller.get_node_or_null(toward_node_path)
