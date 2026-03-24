@tool
class_name ESRandomCondition
extends ESCondition
## Condition that passes with a random probability each time it is evaluated.
## Useful for power-up drop chances, random enemy behaviors, and procedural events.
##
## The probability value is stored internally as a fraction from 0.0 to 1.0,
## where 0.0 means "never true" and 1.0 means "always true". The editor and
## summary display it as a percentage for readability (e.g., 0.3 → "30%").
##
## Tip: Combine with a Timer or signal condition so the roll only happens once
## per event (e.g., "On enemy destroyed AND 30% chance → drop power-up").

## Probability that this condition evaluates to true.
## Enter a value between 0.0 (0% — never) and 1.0 (100% — always).
@export_range(0.0, 1.0, 0.01) var probability: float = 0.5


func get_summary() -> String:
	return "Random chance: %.0f%%" % (probability * 100.0)


func get_category() -> String:
	return "Utility"


func evaluate(_controller: Node, _delta: float) -> bool:
	return randf() < probability
