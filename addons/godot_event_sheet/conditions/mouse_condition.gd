@tool
class_name ESMouseCondition
extends ESCondition
## Condition that checks mouse button input.
## Useful for turret aiming (tank game), clicking to shoot, or UI interaction.
## The EventController automatically tracks previous mouse-button states so
## JUST_PRESSED / JUST_RELEASED detection works correctly each frame.

enum MouseButtonType {
	LEFT_JUST_PRESSED,    ## Left mouse button was clicked this frame
	LEFT_JUST_RELEASED,   ## Left mouse button was released this frame
	LEFT_IS_HELD,         ## Left mouse button is currently held down
	RIGHT_JUST_PRESSED,   ## Right mouse button was clicked this frame
	RIGHT_JUST_RELEASED,  ## Right mouse button was released this frame
	RIGHT_IS_HELD,        ## Right mouse button is currently held down
	MIDDLE_JUST_PRESSED,  ## Middle mouse button was clicked this frame
	MIDDLE_JUST_RELEASED, ## Middle mouse button was released this frame
	MIDDLE_IS_HELD,       ## Middle mouse button is currently held down
}

## Which mouse button and state to check.
@export var button_type: MouseButtonType = MouseButtonType.LEFT_JUST_PRESSED


func get_summary() -> String:
	var names := [
		"Left just pressed", "Left just released", "Left held",
		"Right just pressed", "Right just released", "Right held",
		"Middle just pressed", "Middle just released", "Middle held",
	]
	return "Mouse: %s" % names[button_type]


func get_category() -> String:
	return "Input"


func evaluate(controller: Node, _delta: float) -> bool:
	match button_type:
		MouseButtonType.LEFT_JUST_PRESSED:
			var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			var prev: bool = controller.get_meta("_es_prev_mouse_left", false)
			return held and not prev
		MouseButtonType.LEFT_JUST_RELEASED:
			var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			var prev: bool = controller.get_meta("_es_prev_mouse_left", false)
			return not held and prev
		MouseButtonType.LEFT_IS_HELD:
			return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		MouseButtonType.RIGHT_JUST_PRESSED:
			var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
			var prev: bool = controller.get_meta("_es_prev_mouse_right", false)
			return held and not prev
		MouseButtonType.RIGHT_JUST_RELEASED:
			var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
			var prev: bool = controller.get_meta("_es_prev_mouse_right", false)
			return not held and prev
		MouseButtonType.RIGHT_IS_HELD:
			return Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		MouseButtonType.MIDDLE_JUST_PRESSED:
			var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
			var prev: bool = controller.get_meta("_es_prev_mouse_middle", false)
			return held and not prev
		MouseButtonType.MIDDLE_JUST_RELEASED:
			var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
			var prev: bool = controller.get_meta("_es_prev_mouse_middle", false)
			return not held and prev
		MouseButtonType.MIDDLE_IS_HELD:
			return Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
	return false
