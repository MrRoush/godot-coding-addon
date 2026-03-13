class_name ESLifecycleCondition
extends ESCondition
## Condition based on the node lifecycle: ready, every frame, or every physics frame.

enum LifecycleType {
	READY,           ## Triggers once when the scene is ready
	PROCESS,         ## Triggers every frame (_process)
	PHYSICS_PROCESS, ## Triggers every physics frame (_physics_process)
}

## Which lifecycle event to respond to.
@export var lifecycle_type: LifecycleType = LifecycleType.PROCESS

## Internal state tracking.
var _ready_triggered: bool = false
var _ready_consumed: bool = false


func get_summary() -> String:
	var names := ["On Ready (once)", "Every Frame", "Every Physics Frame"]
	return names[lifecycle_type]


func get_category() -> String:
	return "Lifecycle"


func evaluate(controller: Node, _delta: float) -> bool:
	match lifecycle_type:
		LifecycleType.READY:
			if _ready_triggered and not _ready_consumed:
				_ready_consumed = true
				return true
			return false
		LifecycleType.PROCESS:
			return true  # Always true during _process
		LifecycleType.PHYSICS_PROCESS:
			return true  # Always true during _physics_process
	return false


## Called by the EventController during _ready.
func _on_ready() -> void:
	_ready_triggered = true
	_ready_consumed = false
