@tool
class_name ESInputCondition
extends ESCondition
## Condition that checks for keyboard or action input.

enum InputType {
	JUST_PRESSED,      ## Key/action was just pressed this frame
	JUST_RELEASED,     ## Key/action was just released this frame
	IS_HELD,           ## Key/action is currently held down
	ANY_JUST_PRESSED,  ## Any key was just pressed this frame
	ANY_JUST_RELEASED, ## Any key was just released this frame
}

## The type of input check to perform.
@export var input_type: InputType = InputType.JUST_PRESSED

## The input action name (e.g., "ui_up", "ui_accept") or key name (e.g., "W", "Space").
## If this matches a registered Input Map action, the action is used.
## Otherwise, it is treated as a key name.
@export var action_or_key: String = ""


func get_summary() -> String:
	var type_names := ["just pressed", "just released", "is held", "any key pressed", "any key released"]
	if input_type >= InputType.ANY_JUST_PRESSED:
		return "Input %s" % type_names[input_type]
	return "Input \"%s\" %s" % [action_or_key, type_names[input_type]]


func get_category() -> String:
	return "Input"


func evaluate(controller: Node, delta: float) -> bool:
	# Handle "any key" conditions first.
	if input_type == InputType.ANY_JUST_PRESSED:
		var pressed_now := Input.is_anything_pressed()
		var was_pressed: bool = controller.get_meta("_es_any_key_prev", false)
		return pressed_now and not was_pressed
	elif input_type == InputType.ANY_JUST_RELEASED:
		var pressed_now := Input.is_anything_pressed()
		var was_pressed: bool = controller.get_meta("_es_any_key_prev", false)
		return not pressed_now and was_pressed

	if action_or_key.is_empty():
		return false

	# Check if it's a registered action first.
	if InputMap.has_action(action_or_key):
		match input_type:
			InputType.JUST_PRESSED:
				return Input.is_action_just_pressed(action_or_key)
			InputType.JUST_RELEASED:
				return Input.is_action_just_released(action_or_key)
			InputType.IS_HELD:
				return Input.is_action_pressed(action_or_key)
	else:
		# Treat as a physical key name.
		var keycode := OS.find_keycode_from_string(action_or_key)
		if keycode == KEY_NONE:
			return false
		match input_type:
			InputType.JUST_PRESSED:
				return Input.is_key_pressed(keycode) and not controller.get_meta("_es_prev_key_%d" % keycode, false)
			InputType.JUST_RELEASED:
				return not Input.is_key_pressed(keycode) and controller.get_meta("_es_prev_key_%d" % keycode, false)
			InputType.IS_HELD:
				return Input.is_key_pressed(keycode)

	return false
