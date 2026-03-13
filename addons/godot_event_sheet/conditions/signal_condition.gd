class_name ESSignalCondition
extends ESCondition
## Condition that listens for a signal on a target node.
## The EventController connects the signal at startup.

## Path to the node that emits the signal.
## Leave empty to listen on the EventController's parent node.
@export var source_path: NodePath = NodePath("")

## The signal name to listen for (e.g., "health_changed", "died").
@export var signal_name: String = ""

## Internal: set to true when the signal fires.
var _triggered: bool = false

## Arguments passed with the signal (available during action execution).
var signal_args: Array = []


func get_summary() -> String:
	var src := str(source_path) if not source_path.is_empty() else "parent"
	return "Signal \"%s\" on %s" % [signal_name, src]


func get_category() -> String:
	return "Signals"


func evaluate(controller: Node, _delta: float) -> bool:
	if _triggered:
		_triggered = false
		return true
	return false


## Generic callback connected by the EventController.
## Supports signals with 0-4 arguments.
func _on_signal_received(arg1 = null, arg2 = null, arg3 = null, arg4 = null) -> void:
	signal_args.clear()
	for arg in [arg1, arg2, arg3, arg4]:
		if arg != null:
			signal_args.append(arg)
	_triggered = true
