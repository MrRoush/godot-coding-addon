class_name ESButtonCondition
extends ESCondition
## Condition that fires once when a UI Button node is clicked.
## The EventController automatically connects to the button's "pressed" signal.

## Path to the Button node to listen to.
@export var button_path: NodePath = NodePath("")

## Internal flag set when the button is pressed.
var _pressed: bool = false


func get_summary() -> String:
	var btn := str(button_path) if not button_path.is_empty() else "?"
	return "UI button pressed: %s" % btn


func get_category() -> String:
	return "UI"


func evaluate(controller: Node, _delta: float) -> bool:
	if _pressed:
		_pressed = false
		return true
	return false


## Called by the EventController when the button emits "pressed".
func _on_button_pressed() -> void:
	_pressed = true
