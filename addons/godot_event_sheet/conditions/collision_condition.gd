class_name ESCollisionCondition
extends ESCondition
## Condition that detects collisions using Area2D/Area3D or CharacterBody signals.
## The EventController automatically connects collision signals at runtime.

enum CollisionType {
	BODY_ENTERED,   ## A physics body entered the area/body
	BODY_EXITED,    ## A physics body exited the area/body
	AREA_ENTERED,   ## Another area entered this area
	AREA_EXITED,    ## Another area exited this area
	IS_OVERLAPPING, ## True every frame while any matching body is overlapping
}

## The type of collision to detect.
@export var collision_type: CollisionType = CollisionType.BODY_ENTERED

## Path to the node that detects collisions (Area2D, Area3D, or parent).
## Leave empty to use the EventController's parent node.
@export var detector_path: NodePath = NodePath("")

## Optional: only trigger if the colliding node is in this group.
## Leave empty to trigger for any collision.
@export var filter_group: String = ""

## Internal flag set by the runtime when a matching collision occurs.
var _triggered: bool = false

## The node that triggered the collision (available during action execution).
var colliding_node: Node = null

## Internal set of currently overlapping nodes (used for IS_OVERLAPPING).
var _overlapping_nodes: Array = []


func get_summary() -> String:
	var type_names := ["body entered", "body exited", "area entered", "area exited", "is overlapping"]
	var desc := "Collision: %s" % type_names[collision_type]
	if not filter_group.is_empty():
		desc += " (group: %s)" % filter_group
	if not detector_path.is_empty():
		desc += " on %s" % str(detector_path)
	return desc


func get_category() -> String:
	return "Collision"


func evaluate(controller: Node, _delta: float) -> bool:
	if collision_type == CollisionType.IS_OVERLAPPING:
		# Remove any freed nodes from the tracking array.
		_overlapping_nodes = _overlapping_nodes.filter(func(n): return is_instance_valid(n))
		if not _overlapping_nodes.is_empty():
			colliding_node = _overlapping_nodes[0]
		else:
			colliding_node = null
		return not _overlapping_nodes.is_empty()
	if _triggered:
		_triggered = false
		return true
	return false


## Called by the EventController when a collision signal fires.
func _on_collision(node: Node) -> void:
	if filter_group.is_empty() or node.is_in_group(filter_group):
		colliding_node = node
		_triggered = true


## Called when a body/area enters — used for IS_OVERLAPPING tracking.
func _on_overlap_entered(node: Node) -> void:
	if filter_group.is_empty() or node.is_in_group(filter_group):
		if not _overlapping_nodes.has(node):
			_overlapping_nodes.append(node)
		colliding_node = node


## Called when a body/area exits — used for IS_OVERLAPPING tracking.
func _on_overlap_exited(node: Node) -> void:
	_overlapping_nodes.erase(node)
	if _overlapping_nodes.is_empty():
		colliding_node = null
