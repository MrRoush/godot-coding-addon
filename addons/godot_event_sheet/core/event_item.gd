@tool
class_name ESEventItem
extends Resource
## A single event that pairs one or more Conditions with one or more Actions.
## When conditions are met (using AND or OR logic), all actions are executed.

enum LogicMode {
	AND, ## All conditions must be true
	OR,  ## At least one condition must be true
}

## Display name for this event (shown in the editor).
@export var event_name: String = ""

## Whether this event is active.
@export var enabled: bool = true

## How conditions are combined: AND (all must be true) or OR (any must be true).
@export var logic_mode: LogicMode = LogicMode.AND

## Conditions that are evaluated using the logic mode.
@export var conditions: Array[Resource] = []  # Array of ESCondition

## Actions executed (in order) when the conditions are met.
@export var actions: Array[Resource] = []  # Array of ESAction

## If true, this event acts as a block/group container.
## Its own conditions gate whether its sub_events are evaluated.
## Its own actions (if any) run first when conditions pass, then sub_events are evaluated.
@export var is_block: bool = false

## Whether this event is collapsed in the editor (UI-only, does not affect runtime).
@export var collapsed: bool = false

## Child events nested under this block.
## Only evaluated when this block's own conditions all pass.
## Sub-events inherit the parent block's execution loop (process vs physics).
@export var sub_events: Array[Resource] = []  # Array of ESEventItem


## Add a condition and return it.
func add_condition(condition: Resource) -> void:
	conditions.append(condition)
	emit_changed()


## Remove a condition at the given index.
func remove_condition(index: int) -> void:
	if index >= 0 and index < conditions.size():
		conditions.remove_at(index)
		emit_changed()


## Add an action and return it.
func add_action(action: Resource) -> void:
	actions.append(action)
	emit_changed()


## Remove an action at the given index.
func remove_action(index: int) -> void:
	if index >= 0 and index < actions.size():
		actions.remove_at(index)
		emit_changed()


## Add a sub-event under this block.
func add_sub_event(item: Resource) -> void:
	sub_events.append(item)
	emit_changed()


## Remove a sub-event at the given index.
func remove_sub_event(index: int) -> void:
	if index >= 0 and index < sub_events.size():
		sub_events.remove_at(index)
		emit_changed()
