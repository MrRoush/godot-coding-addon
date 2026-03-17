extends Node
## Example: How to set up player movement with the Event Sheet addon.
##
## Condition and action scripts declare class_name, so they can be referenced
## directly (e.g. ESMoveAction.new()). The preload() constants below are kept
## for explicitness but are no longer strictly required.

const ESLifecycleCondition := preload("res://addons/godot_event_sheet/conditions/lifecycle_condition.gd")
const ESInputCondition := preload("res://addons/godot_event_sheet/conditions/input_condition.gd")
const ESMoveAction := preload("res://addons/godot_event_sheet/actions/move_action.gd")
##
## This script shows how an EventSheet would be configured for basic
## WASD/Arrow key movement. In practice, students would use the visual
## Event Sheet editor panel instead of writing this code.
##
## Scene Setup Required:
##   CharacterBody2D (or Sprite2D)
##     ├── Sprite2D (or CollisionShape2D)
##     └── EventController  ← assign the EventSheet resource here
##
## The Event Sheet configuration below is equivalent to:
##   func _process(delta):
##       if Input.is_action_pressed("ui_right"):
##           position.x += 200 * delta
##       if Input.is_action_pressed("ui_left"):
##           position.x -= 200 * delta
##       if Input.is_action_pressed("ui_down"):
##           position.y += 200 * delta
##       if Input.is_action_pressed("ui_up"):
##           position.y -= 200 * delta


func create_movement_sheet() -> ESEventSheet:
	var sheet := ESEventSheet.new()
	sheet.sheet_name = "Player Movement"

	# --- Event 1: Move Right ---
	var event_right := ESEventItem.new()
	event_right.event_name = "Move Right"

	# Condition: Every frame + Right key held
	var cond_process := ESLifecycleCondition.new()
	cond_process.lifecycle_type = ESLifecycleCondition.LifecycleType.PROCESS
	event_right.add_condition(cond_process)

	var cond_right := ESInputCondition.new()
	cond_right.input_type = ESInputCondition.InputType.IS_HELD
	cond_right.action_or_key = "ui_right"
	event_right.add_condition(cond_right)

	# Action: Move right
	var action_right := ESMoveAction.new()
	action_right.move_type = ESMoveAction.MoveType.TRANSLATE
	action_right.x = 1.0
	action_right.y = 0.0
	action_right.speed = 200.0
	event_right.add_action(action_right)

	sheet.events.append(event_right)

	# --- Event 2: Move Left ---
	var event_left := ESEventItem.new()
	event_left.event_name = "Move Left"

	var cond_process2 := ESLifecycleCondition.new()
	cond_process2.lifecycle_type = ESLifecycleCondition.LifecycleType.PROCESS
	event_left.add_condition(cond_process2)

	var cond_left := ESInputCondition.new()
	cond_left.input_type = ESInputCondition.InputType.IS_HELD
	cond_left.action_or_key = "ui_left"
	event_left.add_condition(cond_left)

	var action_left := ESMoveAction.new()
	action_left.move_type = ESMoveAction.MoveType.TRANSLATE
	action_left.x = -1.0
	action_left.y = 0.0
	action_left.speed = 200.0
	event_left.add_action(action_left)

	sheet.events.append(event_left)

	# --- Event 3: Move Down ---
	var event_down := ESEventItem.new()
	event_down.event_name = "Move Down"

	var cond_process3 := ESLifecycleCondition.new()
	cond_process3.lifecycle_type = ESLifecycleCondition.LifecycleType.PROCESS
	event_down.add_condition(cond_process3)

	var cond_down := ESInputCondition.new()
	cond_down.input_type = ESInputCondition.InputType.IS_HELD
	cond_down.action_or_key = "ui_down"
	event_down.add_condition(cond_down)

	var action_down := ESMoveAction.new()
	action_down.move_type = ESMoveAction.MoveType.TRANSLATE
	action_down.x = 0.0
	action_down.y = 1.0
	action_down.speed = 200.0
	event_down.add_action(action_down)

	sheet.events.append(event_down)

	# --- Event 4: Move Up ---
	var event_up := ESEventItem.new()
	event_up.event_name = "Move Up"

	var cond_process4 := ESLifecycleCondition.new()
	cond_process4.lifecycle_type = ESLifecycleCondition.LifecycleType.PROCESS
	event_up.add_condition(cond_process4)

	var cond_up := ESInputCondition.new()
	cond_up.input_type = ESInputCondition.InputType.IS_HELD
	cond_up.action_or_key = "ui_up"
	event_up.add_condition(cond_up)

	var action_up := ESMoveAction.new()
	action_up.move_type = ESMoveAction.MoveType.TRANSLATE
	action_up.x = 0.0
	action_up.y = -1.0
	action_up.speed = 200.0
	event_up.add_action(action_up)

	sheet.events.append(event_up)

	return sheet
