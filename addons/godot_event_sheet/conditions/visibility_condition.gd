@tool
class_name ESVisibilityCondition
extends ESCondition
## Condition that detects when a node enters or exits the visible screen area.
## Requires a VisibleOnScreenNotifier2D or VisibleOnScreenNotifier3D node.
## The EventController automatically connects the appropriate signals at runtime.

enum VisibilityType {
	SCREEN_ENTERED,   ## Fires once when the node appears on screen
	SCREEN_EXITED,    ## Fires once when the node leaves the screen
	IS_ON_SCREEN,     ## True every frame while the node is visible on screen
}

## Which visibility event to detect.
@export_enum("Screen Entered (screen_entered):0", "Screen Exited (screen_exited):1", "Is On Screen (is_on_screen):2") var visibility_type: int = VisibilityType.SCREEN_ENTERED

## Path to the VisibleOnScreenNotifier2D/3D node.
## Leave empty to search the EventController's parent for a notifier child.
@export var notifier_path: NodePath = NodePath("")

## Internal flag set by the runtime when a matching visibility event occurs.
var _triggered: bool = false

## Whether the node is currently on screen.
var _is_on_screen: bool = false


func get_summary() -> String:
	var type_names := ["appeared on screen", "left the screen", "is on screen"]
	var desc := "Visibility: %s" % type_names[visibility_type]
	if not notifier_path.is_empty():
		desc += " (%s)" % str(notifier_path)
	return desc


func get_category() -> String:
	return "Visibility"


func evaluate(controller: Node, _delta: float) -> bool:
	if visibility_type == VisibilityType.IS_ON_SCREEN:
		return _is_on_screen
	if _triggered:
		_triggered = false
		return true
	return false


## Called when the notifier enters the screen.
func _on_screen_entered() -> void:
	_is_on_screen = true
	if visibility_type == VisibilityType.SCREEN_ENTERED:
		_triggered = true


## Called when the notifier exits the screen.
func _on_screen_exited() -> void:
	_is_on_screen = false
	if visibility_type == VisibilityType.SCREEN_EXITED:
		_triggered = true
