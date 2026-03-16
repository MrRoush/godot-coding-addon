@tool
extends ESAction
## Action that applies gravity to a CharacterBody2D/3D or any Node2D/3D.
## Use this with "Every Physics Frame" to simulate platformer-style gravity.
##
## For CharacterBody2D/3D nodes the action modifies velocity.y and
## optionally calls move_and_slide().  For plain Node2D/3D nodes it
## tracks an internal vertical velocity and applies position-based
## movement each frame so gravity works even without a physics body.

## Gravity force in pixels/units per second squared.
@export var gravity: float = 980.0

## Maximum downward speed (terminal velocity).
@export var max_fall_speed: float = 1500.0

## Path to the target node. Leave empty to use the EventController's parent.
## Works with CharacterBody2D/3D (velocity-based) and plain Node2D/3D
## (position-based fallback).
@export var target_path: NodePath = NodePath("")

## If true, call move_and_slide() after applying gravity.
## Disable this if another action already calls move_and_slide().
@export var call_move_and_slide: bool = true

## Internal vertical velocity for the position-based fallback (Node2D/3D
## without a CharacterBody).
var _internal_velocity_y: float = 0.0


func get_summary() -> String:
	var target := str(target_path) if not target_path.is_empty() else "parent"
	return "Apply gravity (%.0f) to %s" % [gravity, target]


func get_category() -> String:
	return "Physics"


func execute(controller: Node, delta: float) -> void:
	var target: Node = _resolve_target(controller)
	if not target:
		return

	if target is CharacterBody2D:
		var body := target as CharacterBody2D
		if not body.is_on_floor():
			body.velocity.y += gravity * delta
			body.velocity.y = clampf(body.velocity.y, -max_fall_speed, max_fall_speed)
		else:
			# Reset downward velocity when on floor so that a subsequent
			# upward impulse (jump) isn't immediately cancelled.
			if body.velocity.y > 0.0:
				body.velocity.y = 0.0
		if call_move_and_slide:
			body.move_and_slide()
	elif target is CharacterBody3D:
		var body := target as CharacterBody3D
		if not body.is_on_floor():
			body.velocity.y += gravity * delta
			body.velocity.y = clampf(body.velocity.y, -max_fall_speed, max_fall_speed)
		else:
			if body.velocity.y > 0.0:
				body.velocity.y = 0.0
		if call_move_and_slide:
			body.move_and_slide()
	elif target is Node2D:
		# Position-based gravity fallback for non-CharacterBody 2D nodes.
		_internal_velocity_y += gravity * delta
		_internal_velocity_y = clampf(_internal_velocity_y, -max_fall_speed, max_fall_speed)
		target.position += Vector2(0, _internal_velocity_y * delta)
	elif target is Node3D:
		# Position-based gravity fallback for non-CharacterBody 3D nodes.
		_internal_velocity_y += gravity * delta
		_internal_velocity_y = clampf(_internal_velocity_y, -max_fall_speed, max_fall_speed)
		target.position += Vector3(0, _internal_velocity_y * delta, 0)
	else:
		push_warning("EventSheet: Gravity action requires a Node2D/3D or CharacterBody2D/3D. Got: %s" % target.get_class())


func _resolve_target(controller: Node) -> Node:
	if target_path.is_empty():
		return controller.get_parent()

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

	push_warning("EventSheet: Gravity target node not found at path '%s'. " \
		+ "Try '../NodeName' for sibling nodes." % str(target_path))
	return null
