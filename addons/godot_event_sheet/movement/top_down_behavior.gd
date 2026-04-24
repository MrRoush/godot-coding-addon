@tool
class_name TopDownBehavior
extends MovementBehavior
## 8-directional top-down movement behavior.
##
## Moves the parent [CharacterBody2D] in any of the eight compass directions
## using four input actions.  Acceleration and friction give the movement a
## smooth feel; set both to 0 for instant start/stop.
##
## Assign this resource to a [PlayerMovement] node that is a child of a
## [CharacterBody2D].

# ---------------------------------------------------------------------------
# Inspector properties
# ---------------------------------------------------------------------------

@export_group("Input Actions")
## Input map action for moving left.
@export var action_left: StringName = "ui_left"
## Input map action for moving right.
@export var action_right: StringName = "ui_right"
## Input map action for moving up.
@export var action_up: StringName = "ui_up"
## Input map action for moving down.
@export var action_down: StringName = "ui_down"

@export_group("Movement Settings")
## Maximum movement speed in pixels per second.
@export var speed: float = 300.0
## How quickly the body accelerates toward maximum speed (pixels/s²).
## Set to 0 for instant movement.
@export var acceleration: float = 1500.0
## How quickly the body decelerates when no input is held (pixels/s²).
## Set to 0 for no friction (the body keeps sliding).
@export var friction: float = 2000.0
## When true the sprite/body is rotated to face the movement direction.
@export var rotate_to_direction: bool = false


# ---------------------------------------------------------------------------
# process_movement
# ---------------------------------------------------------------------------

func process_movement(body: CharacterBody2D, delta: float) -> void:
	# --- Determine input direction ---
	var input_dir: Vector2 = Vector2.ZERO
	if use_simulated_input_only:
		input_dir = Vector2(sim_axis_x, sim_axis_y)
	else:
		input_dir = Input.get_vector(action_left, action_right, action_up, action_down)
		# Non-zero simulated axes override hardware axes individually.
		if sim_axis_x != 0.0:
			input_dir.x = sim_axis_x
		if sim_axis_y != 0.0:
			input_dir.y = sim_axis_y

	# Normalize so diagonal movement is not faster than cardinal movement.
	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()

	# --- Apply acceleration / friction ---
	if input_dir != Vector2.ZERO:
		if acceleration > 0.0:
			body.velocity = body.velocity.move_toward(input_dir * speed, acceleration * delta)
		else:
			body.velocity = input_dir * speed
	else:
		if friction > 0.0:
			body.velocity = body.velocity.move_toward(Vector2.ZERO, friction * delta)
		else:
			body.velocity = Vector2.ZERO

	# --- Optional: rotate body to face movement direction ---
	if rotate_to_direction and body.velocity.length_squared() > 1.0:
		body.rotation = body.velocity.angle()

	body.move_and_slide()
	_clear_simulated_inputs()
