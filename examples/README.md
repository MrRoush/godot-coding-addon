# Examples

This directory contains example scenes that demonstrate how to use the Godot Event Sheet addon.

**Note:** All condition and action scripts declare `class_name` (e.g.
`ESCollisionCondition`, `ESMoveAction`) so they can be referenced directly
from any script. The example scripts also include `preload()` constants for
explicitness, but these are optional.

## Example Descriptions

### 1. Player Movement (`player_movement_example.gd`)
Shows how to set up basic WASD/Arrow key player movement using:
- **Lifecycle: Every Frame** condition (runs every frame)
- **Input: Key Held** conditions (detect held keys)
- **Movement: Translate** actions (move the player)

### 2. Collision & Signals (`collision_signal_example.gd`)
Shows how to handle collisions and use signals:
- **Collision: Body Entered/Exited** conditions
- **Signal: Emit Signal** and **Signal: Signal Received** conditions/actions
- **Debug: Print Message** actions

### 3. Timer & Properties (`timer_property_example.gd`)
Shows how to use timers and modify properties:
- **Timer: Repeating Timer** conditions
- **Property: Set/Add Value** actions
- **Property: Compare Value** conditions

## Physics Conditions

The addon includes physics conditions useful for platformer mechanics:
- **Is On Floor** — true when a `CharacterBody2D/3D` is touching the floor
- **Is On Wall** — true when touching a wall
- **Is On Ceiling** — true when touching the ceiling
- **Is Moving** — true when velocity exceeds a threshold
- **Is Stopped** — true when velocity is below the threshold
- **Is Falling** — true when the body's vertical velocity is positive (moving downward)

## Condition Negation

Every condition supports a **Negate (NOT)** toggle.  When enabled, the
condition result is inverted.  This is useful for expressing rules like
"when the player is NOT on the floor → play falling animation".

## How to Run Examples

Since these are GDScript setup files (not full scenes), they demonstrate
how to programmatically create EventSheets. In a real project, you would:

1. Create a scene (e.g., a CharacterBody2D with a Sprite)
2. Add an **EventController** node as a child
3. Create a new **EventSheet** resource in the Inspector
4. Use the **Event Sheet** bottom panel to visually add events

The example scripts show the equivalent of what the visual editor creates.
