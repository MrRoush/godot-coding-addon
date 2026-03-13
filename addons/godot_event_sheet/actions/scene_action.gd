class_name ESSceneAction
extends ESAction
## Action for creating (instantiating) or destroying nodes.

enum SceneOp {
	INSTANTIATE, ## Create a new instance of a scene
	DESTROY,     ## Remove and free a node from the tree
}

## Whether to instantiate or destroy.
@export var operation: SceneOp = SceneOp.INSTANTIATE

## Path to the scene file to instantiate (e.g., "res://scenes/bullet.tscn").
## Only used when operation is INSTANTIATE.
@export_file("*.tscn") var scene_path: String = ""

## The parent node to add the new instance to.
## Leave empty to use the scene root.
@export var parent_path: NodePath = NodePath("")

## Position to spawn the new instance (2D).
@export var spawn_position: Vector2 = Vector2.ZERO

## If true, spawn at the parent's current position instead of spawn_position.
@export var use_parent_position: bool = false

## Path to the node to destroy (only used when operation is DESTROY).
@export var destroy_target_path: NodePath = NodePath("")


func get_summary() -> String:
	match operation:
		SceneOp.INSTANTIATE:
			return "Create instance of %s" % scene_path.get_file()
		SceneOp.DESTROY:
			var target := str(destroy_target_path) if not destroy_target_path.is_empty() else "parent"
			return "Destroy %s" % target
	return "Scene action"


func get_category() -> String:
	return "Scene"


func execute(controller: Node, _delta: float) -> void:
	match operation:
		SceneOp.INSTANTIATE:
			_do_instantiate(controller)
		SceneOp.DESTROY:
			_do_destroy(controller)


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

	# Set position.
	if instance is Node2D:
		if use_parent_position:
			var ctrl_parent := controller.get_parent()
			if ctrl_parent is Node2D:
				instance.position = ctrl_parent.position
		else:
			instance.position = spawn_position
	elif instance is Node3D:
		if use_parent_position:
			var ctrl_parent := controller.get_parent()
			if ctrl_parent is Node3D:
				instance.position = ctrl_parent.position
		else:
			instance.position = Vector3(spawn_position.x, spawn_position.y, 0)


func _do_destroy(controller: Node) -> void:
	var target: Node
	if destroy_target_path.is_empty():
		target = controller.get_parent()
	else:
		target = controller.get_node_or_null(destroy_target_path)

	if target:
		target.queue_free()
	else:
		push_warning("EventSheet: Destroy target not found.")
