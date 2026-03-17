@tool
class_name ESAnimationAction
extends ESAction
## Action that controls an AnimationPlayer or AnimatedSprite2D.

enum AnimOp {
	PLAY,           ## Play an animation
	PLAY_BACKWARDS, ## Play an animation backwards
	STOP,           ## Stop the current animation
	PAUSE,          ## Pause the current animation
}

## The animation operation to perform.
@export var operation: AnimOp = AnimOp.PLAY

## Path to the AnimationPlayer or AnimatedSprite2D node.
## Leave empty to search for one in the parent's children.
@export var player_path: NodePath = NodePath("")

## The animation name to play.
@export var animation_name: String = ""


func get_summary() -> String:
	var op_names := ["Play", "Play backwards", "Stop", "Pause"]
	var target := str(player_path) if not player_path.is_empty() else "auto"
	return "%s animation \"%s\" on %s" % [op_names[operation], animation_name, target]


func get_category() -> String:
	return "Animation"


func execute(controller: Node, _delta: float) -> void:
	var player: Node = _find_player(controller)
	if not player:
		push_warning("EventSheet: No AnimationPlayer or AnimatedSprite2D found.")
		return

	if player is AnimationPlayer:
		_execute_animation_player(player as AnimationPlayer)
	elif player is AnimatedSprite2D:
		_execute_animated_sprite(player as AnimatedSprite2D)


func _execute_animation_player(player: AnimationPlayer) -> void:
	match operation:
		AnimOp.PLAY:
			if not animation_name.is_empty():
				player.play(animation_name)
			else:
				player.play()
		AnimOp.PLAY_BACKWARDS:
			if not animation_name.is_empty():
				player.play_backwards(animation_name)
			else:
				player.play_backwards()
		AnimOp.STOP:
			player.stop()
		AnimOp.PAUSE:
			player.pause()


func _execute_animated_sprite(sprite: AnimatedSprite2D) -> void:
	match operation:
		AnimOp.PLAY:
			if not animation_name.is_empty():
				sprite.play(animation_name)
			else:
				sprite.play()
		AnimOp.PLAY_BACKWARDS:
			if not animation_name.is_empty():
				sprite.play_backwards(animation_name)
			else:
				sprite.play_backwards()
		AnimOp.STOP:
			sprite.stop()
		AnimOp.PAUSE:
			sprite.pause()


func _find_player(controller: Node) -> Node:
	if not player_path.is_empty():
		return controller.get_node_or_null(player_path)

	# Auto-detect: check the parent itself first, then search its children.
	var parent := controller.get_parent()
	if parent:
		if parent is AnimatedSprite2D or parent is AnimationPlayer:
			return parent
		for child in parent.get_children():
			if child is AnimationPlayer or child is AnimatedSprite2D:
				return child
	return null
