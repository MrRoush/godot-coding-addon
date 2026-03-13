class_name ESSoundAction
extends ESAction
## Action that plays or stops an AudioStreamPlayer.

enum SoundOp {
	PLAY,  ## Play a sound
	STOP,  ## Stop a sound
}

## Whether to play or stop the sound.
@export var operation: SoundOp = SoundOp.PLAY

## Path to the AudioStreamPlayer, AudioStreamPlayer2D, or AudioStreamPlayer3D node.
## Leave empty to search for one in the parent's children.
@export var player_path: NodePath = NodePath("")

## Optional: path to an audio file to load and play.
## If empty, plays whatever stream is already assigned on the player.
@export_file("*.ogg", "*.wav", "*.mp3") var audio_path: String = ""

## Volume in dB.
@export var volume_db: float = 0.0


func get_summary() -> String:
	var op := "Play" if operation == SoundOp.PLAY else "Stop"
	var target := str(player_path) if not player_path.is_empty() else "auto"
	if not audio_path.is_empty():
		return "%s sound %s on %s" % [op, audio_path.get_file(), target]
	return "%s sound on %s" % [op, target]


func get_category() -> String:
	return "Audio"


func execute(controller: Node, _delta: float) -> void:
	var player: Node = _find_audio_player(controller)
	if not player:
		push_warning("EventSheet: No audio player found.")
		return

	match operation:
		SoundOp.PLAY:
			_play(player)
		SoundOp.STOP:
			_stop(player)


func _play(player: Node) -> void:
	# Load audio file if specified.
	if not audio_path.is_empty() and ResourceLoader.exists(audio_path):
		var stream := load(audio_path) as AudioStream
		if stream:
			player.set("stream", stream)

	player.set("volume_db", volume_db)

	if player.has_method("play"):
		player.call("play")


func _stop(player: Node) -> void:
	if player.has_method("stop"):
		player.call("stop")


func _find_audio_player(controller: Node) -> Node:
	if not player_path.is_empty():
		return controller.get_node_or_null(player_path)

	# Auto-detect: search parent's children.
	var parent := controller.get_parent()
	if parent:
		for child in parent.get_children():
			if child is AudioStreamPlayer or child is AudioStreamPlayer2D or child is AudioStreamPlayer3D:
				return child
	return null
