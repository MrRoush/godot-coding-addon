class_name ESCondition
extends Resource
## Base class for all Event Sheet conditions.
## Subclasses implement [method evaluate] to check whether the condition is met.

## Human-readable summary shown in the editor.
func get_summary() -> String:
	return "Base Condition"


## Return the category name for the condition picker.
func get_category() -> String:
	return "General"


## Evaluate whether the condition is currently true.
## [param controller] is the EventController node running this sheet.
## [param delta] is the frame delta time (if applicable).
func evaluate(controller: Node, delta: float) -> bool:
	return false
