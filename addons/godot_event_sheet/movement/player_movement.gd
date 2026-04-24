@tool
class_name PlayerMovement
extends Node
## Attaches a [MovementBehavior] to a parent [CharacterBody2D].
##
## Drop this node as a child of any [CharacterBody2D].  Assign a
## [MovementBehavior] resource (e.g. [PlatformerBehavior] or
## [TopDownBehavior]) to the [member behavior] property in the inspector to
## give the body ready-made player controls.
##
## The Event Sheet can call the simulate_* helpers to drive movement
## programmatically, overriding or augmenting the default keyboard input.
##
## @tutorial: https://github.com/mechanical-gremlin/godot-coding-addon

## The active movement behavior resource.  Swap this at runtime to change
## how the player moves (e.g. switch between walking and swimming).
@export var behavior: MovementBehavior = null:
	set(value):
		behavior = value
		# Refresh the inspector so behavior-specific properties are visible.
		notify_property_list_changed()

## When true, [method _physics_process] is skipped.  Useful when the Event
## Sheet wants full manual control for a frame.
@export var enabled: bool = true


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not enabled:
		return
	if behavior == null:
		return

	var parent := get_parent()
	if not parent is CharacterBody2D:
		push_warning(
			"PlayerMovement: parent node is not a CharacterBody2D. " +
			"Move this node so it is a direct child of a CharacterBody2D."
		)
		return

	behavior.process_movement(parent as CharacterBody2D, delta)


# ---------------------------------------------------------------------------
# Simulated-input pass-through helpers.
# These delegate directly to the active behavior so Event Sheet actions can
# call them on the PlayerMovement node without needing a reference to the
# behavior resource itself.
# ---------------------------------------------------------------------------

## Simulate pressing the left direction for one physics frame.
func simulate_left() -> void:
	if behavior:
		behavior.simulate_left()

## Simulate pressing the right direction for one physics frame.
func simulate_right() -> void:
	if behavior:
		behavior.simulate_right()

## Simulate pressing the up direction for one physics frame.
func simulate_up() -> void:
	if behavior:
		behavior.simulate_up()

## Simulate pressing the down direction for one physics frame.
func simulate_down() -> void:
	if behavior:
		behavior.simulate_down()

## Simulate a jump input for one physics frame.
func simulate_jump() -> void:
	if behavior:
		behavior.simulate_jump()

## Simulate a dash input for one physics frame.
func simulate_dash() -> void:
	if behavior:
		behavior.simulate_dash()

## Set the horizontal simulated axis directly (-1 to 1).
func set_simulated_axis_x(value: float) -> void:
	if behavior:
		behavior.sim_axis_x = clampf(value, -1.0, 1.0)

## Set the vertical simulated axis directly (-1 to 1).
func set_simulated_axis_y(value: float) -> void:
	if behavior:
		behavior.sim_axis_y = clampf(value, -1.0, 1.0)
