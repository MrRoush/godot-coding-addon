class_name ESAction
extends Resource
## Base class for all Event Sheet actions.
## Subclasses implement [method execute] to perform the action.

## Human-readable summary shown in the editor.
func get_summary() -> String:
	return "Base Action"


## Return the category name for the action picker.
func get_category() -> String:
	return "General"


## Execute this action.
## [param controller] is the EventController node running this sheet.
## [param delta] is the frame delta time (if applicable).
func execute(controller: Node, delta: float) -> void:
	pass
