@tool
class_name ESSceneAction
extends ESAction
## Action for creating (instantiating) or destroying nodes, changing scenes, or
## showing/hiding nodes.

enum SceneOp {
	INSTANTIATE,  ## Create a new instance of a scene
	DESTROY,      ## Remove and free a node from the tree
	CHANGE_SCENE, ## Change to a completely different scene
	SHOW,         ## Make a node visible (visible = true)
	HIDE,         ## Hide a node (visible = false)
}

## Whether to instantiate, destroy, change scene, show, or hide.
@export var operation: SceneOp = SceneOp.INSTANTIATE

## Path to the scene file (used for INSTANTIATE and CHANGE_SCENE).
@export_file("*.tscn") var scene_path: String = ""

## The parent node to add the new instance to.
## Leave empty to use the scene root. (INSTANTIATE only)
@export var parent_path: NodePath = NodePath("")

## Position to spawn the new instance (2D). (INSTANTIATE only)
@export var spawn_position: Vector2 = Vector2.ZERO

## If true, spawn at the parent's current position instead of spawn_position. (INSTANTIATE only)
@export var use_parent_position: bool = false

## Path to the node to destroy, show, or hide (DESTROY/SHOW/HIDE).
## Leave empty to use the EventController's parent.
## Use "$collider" to target the last collided node.
@export var destroy_target_path: NodePath = NodePath("")

## Path to a Marker2D/Node2D node. When set for INSTANTIATE, the new instance
## spawns at the marker's global position and rotation (overrides spawn_position
## and use_parent_position).
@export var spawn_at_node_path: NodePath = NodePath("")


func get_summary() -> String:
	match operation:
		SceneOp.INSTANTIATE:
			return "Create instance of %s" % scene_path.get_file()
		SceneOp.DESTROY:
			var target := str(destroy_target_path) if not destroy_target_path.is_empty() else "parent"
			return "Destroy %s" % target
		SceneOp.CHANGE_SCENE:
			return "Change scene to %s" % scene_path.get_file()
		SceneOp.SHOW:
			var target := str(destroy_target_path) if not destroy_target_path.is_empty() else "parent"
			return "Show %s" % target
		SceneOp.HIDE:
			var target := str(destroy_target_path) if not destroy_target_path.is_empty() else "parent"
			return "Hide %s" % target
	return "Scene action"


func get_category() -> String:
	return "Scene"


func execute(controller: Node, _delta: float) -> void:
	match operation:
		SceneOp.INSTANTIATE:
			_do_instantiate(controller)
		SceneOp.DESTROY:
			_do_destroy(controller)
		SceneOp.CHANGE_SCENE:
			_do_change_scene(controller)
		SceneOp.SHOW:
			_do_set_visible(controller, true)
		SceneOp.HIDE:
			_do_set_visible(controller, false)


func _do_instantiate(controller: Node) -> void:
	if scene_path.is_empty():
		push_warning("EventSheet: No scene path specified for instantiation.")
		return

	if not ResourceLoader.exists(scene_path):
		push_warning("EventSheet: Scene not found: %s" % scene_path)
		return

	var scene: PackedScene = load(scene_path)
	if not scene:
		push_warning("EventSheet: Failed to load scene: %s" % scene_path)
		return

	var instance: Node = scene.instantiate()

	# Determine parent.
	var parent: Node
	if parent_path.is_empty():
		parent = controller.get_tree().current_scene
	else:
		parent = controller.get_node_or_null(parent_path)

	if not parent:
		push_warning("EventSheet: Parent node not found for instantiation.")
		instance.queue_free()
		return

	parent.add_child(instance)

	# Resolve spawn marker node first.
	var spawn_marker: Node = null
	if not spawn_at_node_path.is_empty():
		spawn_marker = controller.get_node_or_null(spawn_at_node_path)

	# Set position.
	if instance is Node2D:
		if spawn_marker and spawn_marker is Node2D:
			instance.global_position = (spawn_marker as Node2D).global_position
			instance.global_rotation = (spawn_marker as Node2D).global_rotation
		elif use_parent_position:
			var ctrl_parent := controller.get_parent()
			if ctrl_parent is Node2D:
				instance.position = ctrl_parent.position
		else:
			instance.position = spawn_position
	elif instance is Node3D:
		if spawn_marker and spawn_marker is Node3D:
			instance.global_position = (spawn_marker as Node3D).global_position
			instance.global_rotation = (spawn_marker as Node3D).global_rotation
		elif use_parent_position:
			var ctrl_parent := controller.get_parent()
			if ctrl_parent is Node3D:
				instance.position = ctrl_parent.position
		else:
			instance.position = Vector3(spawn_position.x, spawn_position.y, 0)


func _do_destroy(controller: Node) -> void:
	var target: Node = _resolve_target_node(controller)
	if target:
		target.queue_free()
	else:
		push_warning("EventSheet: Destroy target not found.")


func _do_change_scene(controller: Node) -> void:
	if scene_path.is_empty():
		push_warning("EventSheet: No scene path specified for change scene.")
		return
	if not ResourceLoader.exists(scene_path):
		push_warning("EventSheet: Scene not found for change: %s" % scene_path)
		return
	controller.get_tree().change_scene_to_file(scene_path)


func _do_set_visible(controller: Node, vis: bool) -> void:
	var target: Node = _resolve_target_node(controller)
	if target and "visible" in target:
		target.set("visible", vis)
	else:
		push_warning("EventSheet: Show/Hide target not found or not a CanvasItem.")


func _resolve_target_node(controller: Node) -> Node:
	if destroy_target_path.is_empty():
		return controller.get_parent()
	var path_str := str(destroy_target_path)
	if path_str == "$collider":
		var meta_val = controller.get_meta(&"_es_last_collided_node", null)
		return meta_val if meta_val is Node else null
	return controller.get_node_or_null(destroy_target_path)
