class_name ESMoveAction
extends ESAction
## Action that moves a 2D or 3D node.

enum MoveType {
	TRANSLATE,    ## Move by an offset (relative)
	SET_POSITION, ## Set absolute position
	MOVE_TOWARD,  ## Move toward a target position at a given speed
}

## How to move the node.
@export var move_type: MoveType = MoveType.TRANSLATE

## Path to the node to move. Leave empty to move the EventController's parent.
@export var target_path: NodePath = NodePath("")

## X component of the movement or position.
@export var x: float = 0.0

## Y component of the movement or position.
@export var y: float = 0.0

## Speed in pixels/units per second (used with TRANSLATE and MOVE_TOWARD).
@export var speed: float = 200.0

## If true, multiply the translation by delta time for frame-independent movement.
@export var use_delta: bool = true


func get_summary() -> String:
	var target := str(target_path) if not target_path.is_empty() else "parent"
	match move_type:
		MoveType.TRANSLATE:
			return "Move %s by (%.0f, %.0f) at speed %.0f" % [target, x, y, speed]
		MoveType.SET_POSITION:
			return "Set %s position to (%.0f, %.0f)" % [target, x, y]
		MoveType.MOVE_TOWARD:
			return "Move %s toward (%.0f, %.0f) at speed %.0f" % [target, x, y, speed]
	return "Move"


func get_category() -> String:
	return "Movement"


func execute(controller: Node, delta: float) -> void:
	var target: Node = _resolve_target(controller)
	if not target:
		return

	var dt: float = delta if use_delta else 1.0

	if target is Node2D:
		_execute_2d(target as Node2D, dt)
	elif target is Node3D:
		_execute_3d(target as Node3D, dt)


func _execute_2d(node: Node2D, dt: float) -> void:
	match move_type:
		MoveType.TRANSLATE:
			var direction := Vector2(x, y).normalized()
			node.position += direction * speed * dt
		MoveType.SET_POSITION:
			node.position = Vector2(x, y)
		MoveType.MOVE_TOWARD:
			var goal := Vector2(x, y)
			node.position = node.position.move_toward(goal, speed * dt)


func _execute_3d(node: Node3D, dt: float) -> void:
	match move_type:
		MoveType.TRANSLATE:
			var direction := Vector3(x, y, 0).normalized()
			node.position += direction * speed * dt
		MoveType.SET_POSITION:
			node.position = Vector3(x, y, 0)
		MoveType.MOVE_TOWARD:
			var goal := Vector3(x, y, 0)
			node.position = node.position.move_toward(goal, speed * dt)


func _resolve_target(controller: Node) -> Node:
	if target_path.is_empty():
		return controller.get_parent()
	return controller.get_node_or_null(target_path)
