@tool
class_name ESPhysicsCondition
extends ESCondition
## Condition that checks physics state of a CharacterBody2D or CharacterBody3D node.
## Useful for platformer mechanics (e.g., only jump when on the floor).

enum PhysicsCheck {
	IS_ON_FLOOR,    ## True when the body is touching the floor
	IS_ON_WALL,     ## True when the body is touching a wall
	IS_ON_CEILING,  ## True when the body is touching the ceiling
	IS_MOVING,      ## True when the body's velocity length exceeds the stop threshold
	IS_STOPPED,     ## True when the body's velocity is at or below the stop threshold
	IS_FALLING,     ## True when the body's vertical velocity is positive (moving down)
}

## The physics check to perform.
@export var physics_check: PhysicsCheck = PhysicsCheck.IS_ON_FLOOR

## Path to the CharacterBody2D/3D node. Leave empty to use the EventController's parent.
@export var node_path: NodePath = NodePath("")

## Velocity threshold below which the body is considered "stopped".
@export var stop_threshold: float = 1.0


func get_summary() -> String:
	var names := ["Is on floor", "Is on wall", "Is on ceiling", "Is moving", "Is stopped", "Is falling"]
	var target := str(node_path) if not node_path.is_empty() else "parent"
	return "%s: %s" % [target, names[physics_check]]


func get_category() -> String:
	return "Physics"


func evaluate(controller: Node, _delta: float) -> bool:
	var target: Node = _resolve_node(controller)
	if not target:
		return false

	if target is CharacterBody2D:
		return _check_2d(target as CharacterBody2D)
	elif target is CharacterBody3D:
		return _check_3d(target as CharacterBody3D)

	return false


func _check_2d(body: CharacterBody2D) -> bool:
	match physics_check:
		PhysicsCheck.IS_ON_FLOOR:
			return body.is_on_floor()
		PhysicsCheck.IS_ON_WALL:
			return body.is_on_wall()
		PhysicsCheck.IS_ON_CEILING:
			return body.is_on_ceiling()
		PhysicsCheck.IS_MOVING:
			return body.velocity.length() > stop_threshold
		PhysicsCheck.IS_STOPPED:
			return body.velocity.length() <= stop_threshold
		PhysicsCheck.IS_FALLING:
			return body.velocity.y > 0.0
	return false


func _check_3d(body: CharacterBody3D) -> bool:
	match physics_check:
		PhysicsCheck.IS_ON_FLOOR:
			return body.is_on_floor()
		PhysicsCheck.IS_ON_WALL:
			return body.is_on_wall()
		PhysicsCheck.IS_ON_CEILING:
			return body.is_on_ceiling()
		PhysicsCheck.IS_MOVING:
			return body.velocity.length() > stop_threshold
		PhysicsCheck.IS_STOPPED:
			return body.velocity.length() <= stop_threshold
		PhysicsCheck.IS_FALLING:
			return body.velocity.y > 0.0
	return false


func _resolve_node(controller: Node) -> Node:
	if node_path.is_empty():
		return controller.get_parent()

	var target := controller.get_node_or_null(node_path)
	if target:
		return target

	# Fallback: try relative to the controller's parent.
	var parent := controller.get_parent()
	if parent:
		target = parent.get_node_or_null(node_path)
		if target:
			return target

	return null
