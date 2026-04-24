@tool
class_name PlatformerBehavior
extends MovementBehavior
## Side-scrolling platformer movement behavior.
##
## Reads left/right input and applies horizontal velocity, gravity, and
## jumping.  Assign this resource to a [PlayerMovement] node that is a child
## of a [CharacterBody2D].

# ---------------------------------------------------------------------------
# Inspector properties
# ---------------------------------------------------------------------------

@export_group("Input Actions")
## Input map action for moving left.
@export var action_left: StringName = "ui_left"
## Input map action for moving right.
@export var action_right: StringName = "ui_right"
## Input map action for jumping.
@export var action_jump: StringName = "ui_accept"

@export_group("Movement Settings")
## Horizontal run speed in pixels per second.
@export var speed: float = 300.0
## Upward velocity applied when the player jumps (positive = up in Godot 2D).
@export var jump_force: float = 550.0
## Downward acceleration applied every second when the player is airborne.
@export var gravity: float = 980.0
## Maximum downward velocity (terminal velocity).
@export var max_fall_speed: float = 1200.0

@export_group("Advanced")
## Time window (seconds) after leaving a ledge during which a jump is still
## allowed ("coyote time").
@export var coyote_time: float = 0.1
## Time window (seconds) before landing during which a jump press is buffered.
@export var jump_buffer_time: float = 0.1
## Number of extra jumps allowed while airborne (0 = single jump only).
@export var extra_jumps: int = 0

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _jumps_remaining: int = 0


# ---------------------------------------------------------------------------
# process_movement
# ---------------------------------------------------------------------------

func process_movement(body: CharacterBody2D, delta: float) -> void:
	# --- Determine horizontal input ---
	var h_input: float = 0.0
	if use_simulated_input_only:
		h_input = sim_axis_x
	else:
		h_input = Input.get_axis(action_left, action_right)
		# Simulated input overrides hardware when non-zero.
		if sim_axis_x != 0.0:
			h_input = sim_axis_x

	body.velocity.x = h_input * speed

	# --- Coyote time ---
	if body.is_on_floor():
		_coyote_timer = coyote_time
		_jumps_remaining = extra_jumps
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	# --- Jump buffer ---
	var jump_pressed: bool = false
	if use_simulated_input_only:
		jump_pressed = sim_jump
	else:
		jump_pressed = Input.is_action_just_pressed(action_jump) or sim_jump

	if jump_pressed:
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)

	# --- Apply jump ---
	var can_jump_from_floor: bool = _coyote_timer > 0.0
	var can_extra_jump: bool = (not body.is_on_floor()) and _jumps_remaining > 0

	if _jump_buffer_timer > 0.0 and (can_jump_from_floor or can_extra_jump):
		body.velocity.y = -jump_force
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		if not can_jump_from_floor:
			_jumps_remaining -= 1

	# --- Apply gravity ---
	if not body.is_on_floor():
		body.velocity.y = minf(body.velocity.y + gravity * delta, max_fall_speed)

	body.move_and_slide()
	_clear_simulated_inputs()
