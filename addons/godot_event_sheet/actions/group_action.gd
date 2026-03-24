@tool
class_name ESGroupAction
extends ESAction
## Action for managing node group membership.
## Groups serve as lightweight state flags and team markers —
## use them to track power-up states, enemy factions, collectible types,
## and any boolean-like "tag" on a node.

enum GroupOp {
	ADD_TO_GROUP,      ## Add the node to a named group
	REMOVE_FROM_GROUP, ## Remove the node from a named group
}

## Operation to perform.
@export var operation: GroupOp = GroupOp.ADD_TO_GROUP

## Path to the node to modify.
## Leave empty for the EventController's parent. Use "$collider" for last collision.
@export var target_path: NodePath = NodePath("")

## The group name to add to or remove from.
@export var group_name: String = ""


func get_summary() -> String:
	var target := str(target_path) if not target_path.is_empty() else "parent"
	match operation:
		GroupOp.ADD_TO_GROUP:
			return "Group: Add %s to \"%s\"" % [target, group_name]
		GroupOp.REMOVE_FROM_GROUP:
			return "Group: Remove %s from \"%s\"" % [target, group_name]
	return "Group action"


func get_category() -> String:
	return "Utility"


func execute(controller: Node, _delta: float) -> void:
	if group_name.is_empty():
		push_warning("EventSheet: GroupAction: No group name specified.")
		return

	var target := _resolve_target(controller)
	if not target:
		return

	match operation:
		GroupOp.ADD_TO_GROUP:
			if not target.is_in_group(group_name):
				target.add_to_group(group_name)
		GroupOp.REMOVE_FROM_GROUP:
			if target.is_in_group(group_name):
				target.remove_from_group(group_name)


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
	push_warning("EventSheet: GroupAction: Target not found at '%s'." % str(target_path))
	return null
