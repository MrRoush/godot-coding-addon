class_name ESCollisionCondition
extends ESCondition
## Condition that detects collisions using Area2D/Area3D or CharacterBody signals.
## The EventController automatically connects collision signals at runtime.

enum CollisionType {
	BODY_ENTERED,  ## A physics body entered the area/body
	BODY_EXITED,   ## A physics body exited the area/body
	AREA_ENTERED,  ## Another area entered this area
	AREA_EXITED,   ## Another area exited this area
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


func get_summary() -> String:
	var type_names := ["body entered", "body exited", "area entered", "area exited"]
	var desc := "Collision: %s" % type_names[collision_type]
	if not filter_group.is_empty():
		desc += " (group: %s)" % filter_group
	if not detector_path.is_empty():
		desc += " on %s" % str(detector_path)
	return desc


func get_category() -> String:
	return "Collision"


func evaluate(controller: Node, _delta: float) -> bool:
	if _triggered:
		_triggered = false
		return true
	return false


## Called by the EventController when a collision signal fires.
func _on_collision(node: Node) -> void:
	if filter_group.is_empty() or node.is_in_group(filter_group):
		colliding_node = node
		_triggered = true
