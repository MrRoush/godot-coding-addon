@tool
class_name ESTimerCondition
extends ESCondition
## Condition that triggers periodically or after a delay.
## The EventController creates a Timer node automatically.

## Time in seconds between triggers (or time until first trigger if one-shot).
@export var wait_time: float = 1.0

## If true, the timer only triggers once. If false, it repeats.
@export var one_shot: bool = false

## Internal: set by the runtime when the timer fires.
var _triggered: bool = false

## Reference to the runtime Timer node (set by EventController).
var _timer: Timer = null


func get_summary() -> String:
	if one_shot:
		return "After %.1f seconds (once)" % wait_time
	else:
		return "Every %.1f seconds" % wait_time


func get_category() -> String:
	return "Timing"


func evaluate(controller: Node, _delta: float) -> bool:
	if _triggered:
		_triggered = false
		return true
	return false


## Called by the EventController when the timer fires.
func _on_timer_timeout() -> void:
	_triggered = true
