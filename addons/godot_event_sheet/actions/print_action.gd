class_name ESPrintAction
extends ESAction
## Action that prints a message to the console. Useful for debugging.

## The message to print. Supports placeholders:
## {name} - the parent node's name
## {position} - the parent node's position (if Node2D/Node3D)
## {delta} - the current frame delta
@export var message: String = "Hello from Event Sheet!"

## If true, uses push_warning instead of print.
@export var as_warning: bool = false


func get_summary() -> String:
	var prefix := "⚠ " if as_warning else ""
	return "%sPrint: \"%s\"" % [prefix, message]


func get_category() -> String:
	return "Debug"


func execute(controller: Node, delta: float) -> void:
	var output := _resolve_placeholders(controller, delta)
	if as_warning:
		push_warning(output)
	else:
		print(output)


func _resolve_placeholders(controller: Node, delta: float) -> String:
	var result := message
	var parent := controller.get_parent()

	result = result.replace("{delta}", "%.4f" % delta)

	if parent:
		result = result.replace("{name}", parent.name)
		if parent is Node2D:
			result = result.replace("{position}", str(parent.position))
		elif parent is Node3D:
			result = result.replace("{position}", str(parent.position))
		else:
			result = result.replace("{position}", "N/A")
	else:
		result = result.replace("{name}", "null")
		result = result.replace("{position}", "N/A")

	return result
