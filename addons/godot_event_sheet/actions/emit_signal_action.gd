class_name ESEmitSignalAction
extends ESAction
## Action that emits a signal on a target node.
## Works with both built-in signals and custom signals defined in the EventSheet.

## Path to the node that should emit the signal.
## Leave empty to emit on the EventController itself.
@export var target_path: NodePath = NodePath("")

## The signal name to emit.
@export var signal_name: String = ""

## Arguments to pass with the signal (as strings, auto-converted).
## Supports up to 4 arguments.
@export var arguments: PackedStringArray = PackedStringArray()


func get_summary() -> String:
	var target := str(target_path) if not target_path.is_empty() else "self"
	var args_str := ", ".join(arguments) if arguments.size() > 0 else ""
	return "Emit \"%s\" on %s(%s)" % [signal_name, target, args_str]


func get_category() -> String:
	return "Signals"


func execute(controller: Node, _delta: float) -> void:
	if signal_name.is_empty():
		push_warning("EventSheet: EmitSignal action has no signal name.")
		return

	var target: Node = _resolve_target(controller)
	if not target:
		push_warning("EventSheet: EmitSignal target node not found.")
		return

	if not target.has_signal(signal_name):
		# Register the signal dynamically if it doesn't exist yet.
		target.add_user_signal(signal_name)

	# Convert arguments and emit.
	var args: Array = []
	for arg_str in arguments:
		args.append(_convert_arg(arg_str))

	match args.size():
		0: target.emit_signal(signal_name)
		1: target.emit_signal(signal_name, args[0])
		2: target.emit_signal(signal_name, args[0], args[1])
		3: target.emit_signal(signal_name, args[0], args[1], args[2])
		4: target.emit_signal(signal_name, args[0], args[1], args[2], args[3])


## Convert a string argument to the appropriate type.
func _convert_arg(val: String) -> Variant:
	if val.to_lower() == "true":
		return true
	if val.to_lower() == "false":
		return false
	if val.is_valid_int():
		return int(val)
	if val.is_valid_float():
		return float(val)
	return val


func _resolve_target(controller: Node) -> Node:
	if target_path.is_empty():
		return controller
	return controller.get_node_or_null(target_path)
