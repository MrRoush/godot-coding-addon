# Examples

This directory contains **runnable example scenes** that demonstrate how to use
the Godot Event Sheet addon. Each example includes a `.tscn` scene file and a
pre-configured `.tres` EventSheet resource — open a scene, press **F5** (or
set it as the main scene), and see the addon in action.

## How to Run

1. Open the Godot project and make sure the **Godot Event Sheet** plugin is
   enabled in **Project → Project Settings → Plugins**.
2. Open any `.tscn` file from the examples below.
3. Press **F5** (Run Project) or **F6** (Run Current Scene).

## Example Scenes

### 1. Player Movement (`player_movement/player_movement.tscn`)

A Sprite2D icon that moves with the arrow keys.

| Event Sheet setup | What it teaches |
|---|---|
| **Lifecycle: Every Frame** + **Input: Key Held** → **Move: Translate** | Combining two conditions (run every frame AND key is held) with a movement action. Four events handle Up / Down / Left / Right. |

### 2. Timer & Properties (`timer_property/timer_property.tscn`)

A Sprite2D icon that rotates every 2 seconds and wraps its position.

| Event Sheet setup | What it teaches |
|---|---|
| **Lifecycle: Ready** → **Print Message** | Running an action once when the scene starts. |
| **Timer: Every 2 s** → **Set Property** (rotation += 0.5) + **Print** | Periodic events and modifying node properties. |
| **Property: position.x > 600** → **Set Property** (position.x = 100) | Checking a property condition and resetting a value. |

### 3. Collision & Signals (`collision_signal/collision_signal.tscn`)

Two Area2D nodes — a blue "Player" and a yellow "Coin". Move the player
into the coin with the arrow keys to trigger a collision message.

| Event Sheet setup | What it teaches |
|---|---|
| **Lifecycle: Every Frame** + **Input: Key Held** → **Move: Translate** | Basic movement (same pattern as the movement example). |
| **Collision: Area Entered** (group "coins") → **Print Message** | Detecting collisions with group filtering. |

## Scene Structure

Every example follows the same pattern:

```
Node2D  (scene root)
├── Label             (on-screen instructions)
└── Sprite2D / Area2D (the game object)
    └── EventController   (runs the EventSheet)
```

The **EventController** node is always a child of the game object it
controls. Its `event_sheet` property points to the `.tres` file in the
same folder.

## Tips for Students

- Click the **EventController** node in the Scene tree to open the
  **Event Sheet** panel at the bottom of the editor.
- Use **+ Add Event** in the panel to create new events visually.
- Every condition and action class has a global `class_name` (e.g.
  `ESMoveAction`, `ESCollisionCondition`) so you can also reference them
  from GDScript if needed.
