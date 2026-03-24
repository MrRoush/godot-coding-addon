@tool
class_name ESPathfindingAction
extends ESAction
## Action for A* navigation using Godot's NavigationAgent2D.
## The moving node must live inside a scene that has a NavigationRegion2D
## with a baked NavigationPolygon (or NavigationMesh).
## A NavigationAgent2D child is created automatically if one is not found.
##
## Typical usage pattern:
##   Every physics frame → Pathfind: Set target to Player   (keeps destination fresh)
##   Every physics frame → Pathfind: Move along path         (actually moves the enemy)

enum PathfindingOp {
	SET_TARGET_NODE, ## Update the destination to another node's current position
	SET_TARGET_POS,  ## Set the destination to fixed world coordinates
	MOVE_ALONG_PATH, ## Move the node one step along the computed path this frame
	STOP,            ## Stop movement and clear the current path target
}

## The pathfinding operation to perform.
@export var operation: PathfindingOp = PathfindingOp.MOVE_ALONG_PATH

## Path to the node to move. Must be or contain a CharacterBody2D, or a plain Node2D.
## Leave empty to use the EventController's parent.
@export var target_path: NodePath = NodePath("")

## Path to the destination node (SET_TARGET_NODE).
@export var destination_node_path: NodePath = NodePath("")

## Fixed destination X coordinate in world space (SET_TARGET_POS).
@export var destination_x: float = 0.0

## Fixed destination Y coordinate in world space (SET_TARGET_POS).
@export var destination_y: float = 0.0

## Movement speed in pixels/second (MOVE_ALONG_PATH).
@export var speed: float = 150.0

## Distance in pixels at which the agent is considered to have arrived.
@export var arrival_distance: float = 10.0


func get_summary() -> String:
	var mover := str(target_path) if not target_path.is_empty() else "parent"
	match operation:
		PathfindingOp.SET_TARGET_NODE:
			var dest := str(destination_node_path) if not destination_node_path.is_empty() else "?"
			return "Pathfind: Set target of %s → %s" % [mover, dest]
		PathfindingOp.SET_TARGET_POS:
			return "Pathfind: Set target of %s → (%.0f, %.0f)" % [mover, destination_x, destination_y]
		PathfindingOp.MOVE_ALONG_PATH:
			return "Pathfind: Move %s along path (speed %.0f)" % [mover, speed]
		PathfindingOp.STOP:
			return "Pathfind: Stop %s" % mover
	return "Pathfinding"


func get_category() -> String:
	return "Movement"


func execute(controller: Node, delta: float) -> void:
	var mover := _resolve_node(controller, target_path, true)
	if not mover:
		return

	var agent := _get_or_create_agent(mover)
	if not agent:
		return

	match operation:
		PathfindingOp.SET_TARGET_NODE:
			var dest_node := _resolve_node(controller, destination_node_path, false)
			if dest_node and dest_node is Node2D:
				agent.target_position = (dest_node as Node2D).global_position
		PathfindingOp.SET_TARGET_POS:
			agent.target_position = Vector2(destination_x, destination_y)
		PathfindingOp.MOVE_ALONG_PATH:
			_move_along_path(mover, agent, delta)
		PathfindingOp.STOP:
			if mover is CharacterBody2D:
				(mover as CharacterBody2D).velocity = Vector2.ZERO
			if mover is Node2D:
				# Setting target to current position effectively stops pathing.
				agent.target_position = (mover as Node2D).global_position


func _move_along_path(mover: Node, agent: NavigationAgent2D, delta: float) -> void:
	if agent.is_navigation_finished():
		return
	if not mover is Node2D:
		return

	var node2d := mover as Node2D
	var next_pos: Vector2 = agent.get_next_path_position()
	var direction := (next_pos - node2d.global_position).normalized()

	if mover is CharacterBody2D:
		var body := mover as CharacterBody2D
		body.velocity = direction * speed
		body.move_and_slide()
	else:
		node2d.global_position += direction * speed * delta


func _get_or_create_agent(node: Node) -> NavigationAgent2D:
	for child in node.get_children():
		if child is NavigationAgent2D:
			return child as NavigationAgent2D
	# No agent found — create one automatically.
	var agent := NavigationAgent2D.new()
	agent.name = "ESNavAgent"
	agent.path_desired_distance = arrival_distance
	agent.target_desired_distance = arrival_distance
	node.add_child(agent)
	return agent


func _resolve_node(controller: Node, path: NodePath, use_parent_if_empty: bool) -> Node:
	if path.is_empty():
		return controller.get_parent() if use_parent_if_empty else null
	var path_str := str(path)
	if path_str == "$collider":
		var meta_val = controller.get_meta(&"_es_last_collided_node", null)
		return meta_val if meta_val is Node else null
	var target := controller.get_node_or_null(path)
	if target:
		return target
	var parent := controller.get_parent()
	if parent:
		target = parent.get_node_or_null(path)
		if target:
			return target
	return null
