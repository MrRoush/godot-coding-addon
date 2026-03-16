@tool
extends ESAction
## Action that applies a knockback push to a target node, moving it away from
## a source node. Ideal for hit reactions, weapon strikes, and enemy knockback.

## Path to the node causing the knockback.
## Leave empty to use the EventController's parent.
@export var source_node_path: NodePath = NodePath("")

## Path to the node being knocked back.
## Use "$collider" to target the last collided node.
@export var target_path: NodePath = NodePath("$collider")

## Force (magnitude) of the knockback in pixels/units.
@export var force: float = 300.0

## If true, sets CharacterBody2D/3D.velocity (smooth physics knockback).
## If false, instantly translates the node's position (one-frame jump).
@export var use_velocity: bool = true


func get_summary() -> String:
	var src := str(source_node_path) if not source_node_path.is_empty() else "parent"
	var tgt := str(target_path) if not target_path.is_empty() else "parent"
	return "Knockback %s away from %s (force %.0f)" % [tgt, src, force]


func get_category() -> String:
	return "Movement"


func execute(controller: Node, _delta: float) -> void:
	# Resolve source node.
	var source: Node
	if source_node_path.is_empty():
		source = controller.get_parent()
	else:
		source = _resolve_node(controller, source_node_path)

	# Resolve target node.
	var target: Node
	var path_str := str(target_path)
	if path_str == "$collider":
		var meta_val = controller.get_meta(&"_es_last_collided_node", null)
		target = meta_val if meta_val is Node else null
	else:
		target = _resolve_node(controller, target_path)

	if not source or not target:
		push_warning("EventSheet: Knockback source or target not found.")
		return

	# Compute knockback direction and apply.
	if source is Node2D and target is Node2D:
		var dir := ((target as Node2D).global_position - (source as Node2D).global_position).normalized()
		if use_velocity and target is CharacterBody2D:
			(target as CharacterBody2D).velocity = dir * force
			(target as CharacterBody2D).move_and_slide()
		else:
			# Instant position offset (one-frame impulse).
			# Scaled by 0.1 so that a force of 300 equals ~30 pixels of displacement.
			(target as Node2D).position += dir * force * 0.1
	elif source is Node3D and target is Node3D:
		var dir := ((target as Node3D).global_position - (source as Node3D).global_position).normalized()
		if use_velocity and target is CharacterBody3D:
			(target as CharacterBody3D).velocity = dir * force
			(target as CharacterBody3D).move_and_slide()
		else:
			# Instant position offset (one-frame impulse).
			(target as Node3D).position += dir * force * 0.1


## Resolve a node by path with sibling fallback.
func _resolve_node(controller: Node, path: NodePath) -> Node:
	var node := controller.get_node_or_null(path)
	if node:
		return node
	# Fallback: try relative to the controller's parent.
	var parent := controller.get_parent()
	if parent:
		node = parent.get_node_or_null(path)
		if node:
			return node
	return null
