@tool
class_name MovementBehavior
extends Resource
## Base class for all PlayerMovement behaviors.
##
## Subclasses implement [method process_movement] to drive a
## [CharacterBody2D]'s velocity and call [method CharacterBody2D.move_and_slide].
##
## Simulated-input variables allow the Event Sheet editor to override (or
## augment) the default keyboard/gamepad controls at runtime.

# ---------------------------------------------------------------------------
# Simulated inputs — set by Event Sheet actions before physics runs.
# Each flag is cleared automatically after [method process_movement] reads it.
# ---------------------------------------------------------------------------

## Simulated horizontal axis: -1 (left), 0 (neutral), 1 (right).
var sim_axis_x: float = 0.0

## Simulated vertical axis: -1 (up/forward), 0 (neutral), 1 (down/backward).
var sim_axis_y: float = 0.0

## When true, the behavior treats this as a jump/action input this frame.
var sim_jump: bool = false

## When true, the behavior treats this as a "dash" input this frame.
var sim_dash: bool = false

## When true, default keyboard/gamepad reading is disabled and only
## simulated inputs are used.
@export var use_simulated_input_only: bool = false


# ---------------------------------------------------------------------------
# Simulated-input helper methods (called from the Event Sheet).
# ---------------------------------------------------------------------------

## Simulate pressing the left direction this frame.
func simulate_left() -> void:
	sim_axis_x = -1.0

## Simulate pressing the right direction this frame.
func simulate_right() -> void:
	sim_axis_x = 1.0

## Simulate pressing the up direction this frame.
func simulate_up() -> void:
	sim_axis_y = -1.0

## Simulate pressing the down direction this frame.
func simulate_down() -> void:
	sim_axis_y = 1.0

## Simulate a jump/action input this frame.
func simulate_jump() -> void:
	sim_jump = true

## Simulate a dash input this frame.
func simulate_dash() -> void:
	sim_dash = true

## Reset all simulated inputs. Called automatically after each physics step.
func _clear_simulated_inputs() -> void:
	sim_axis_x = 0.0
	sim_axis_y = 0.0
	sim_jump = false
	sim_dash = false


# ---------------------------------------------------------------------------
# Core interface — override in subclasses.
# ---------------------------------------------------------------------------

## Process movement for one physics frame.
## [param body] is the parent [CharacterBody2D].
## [param delta] is the physics frame delta time.
##
## Implementations should update [code]body.velocity[/code] and call
## [code]body.move_and_slide()[/code], then clear simulated inputs by
## calling [method _clear_simulated_inputs].
func process_movement(body: CharacterBody2D, delta: float) -> void:
	pass
