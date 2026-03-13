# Godot Event Sheet — Visual Programming Addon for Godot 4.5

A visual **Event Sheet** programming addon for Godot 4.5, designed for beginning programmers and game design students. Instead of writing traditional GDScript code, students create game logic by combining **Conditions** (when something happens) with **Actions** (what to do), similar to Construct 3 or GDevelop.

## Features

- **Event Sheet Editor** — A bottom panel in the Godot editor for visually building game logic
- **No Code Required** — Students define behavior with conditions and actions, not GDScript
- **Full Signal Support** — Create, emit, and listen for custom signals between nodes
- **Collision Detection** — Detect body and area collisions with group filtering; persistent overlap tracking
- **Input Handling** — Respond to keyboard input, action presses, and held keys; UI button clicks
- **Property Control** — Read, set, add, subtract, multiply, or toggle any node property; dynamic text with live value placeholders
- **Movement** — Translate, set position, move toward targets or dynamic nodes, physics velocity (2D and 3D)
- **Knockback** — Compute directional knockback between two nodes and push via velocity or position
- **Timers** — Repeating and one-shot timers without writing code
- **Animation & Audio** — Play/stop animations and sounds
- **Scene Management** — Instantiate scenes (with optional Marker2D spawn point), destroy nodes, change scenes, show/hide nodes
- **Debug Printing** — Print messages with variable placeholders for easy debugging
- **Collider Reference** — Use `$collider` in any target field to reference the node from the last collision

## Quick Start

### 1. Install the Addon

Copy the `addons/godot_event_sheet/` folder into your Godot project's `addons/` directory.

### 2. Enable the Plugin

Go to **Project → Project Settings → Plugins** and enable **Godot Event Sheet**.

### 3. Set Up Your Scene

```
CharacterBody2D (your game object)
  ├── Sprite2D
  ├── CollisionShape2D
  └── EventController  ← Add this node
```

1. Add an **EventController** node as a child of your game object
2. Click on the EventController — the **Event Sheet** panel opens at the bottom and is immediately ready to use (an EventSheet resource is auto-created for you)

### 4. Create Events

Click **+ Add Event** to open the event wizard. Each event uses a simple **"When → Then"** model:

1. Pick a **trigger** (WHEN this happens) from the left list
2. Configure its settings (e.g., which key to listen for)
3. Pick a **reaction** (THEN do this) from the right list
4. Configure its settings (e.g., which direction to move)
5. Click **Create Event** — done!

| Conditions (ALL must be true) | Actions (executed in order) |
|-------------------------------|---------------------------|
| Every Frame + Right key held | Move parent right at speed 200 |
| Every Frame + Left key held | Move parent left at speed 200 |
| Collision: body entered (group "coins") | Print "Coin collected!" + Emit "coin_collected" signal |
| Signal "coin_collected" received | Add 1 to score property |

## Available Conditions

| Category | Condition | Description |
|----------|-----------|-------------|
| **Input** | Key/Action Pressed | Triggers once when a key or input action is first pressed |
| **Input** | Key/Action Released | Triggers once when a key or input action is released |
| **Input** | Key/Action Held | True every frame while a key or input action is held down |
| **Collision** | Body Entered | A physics body entered the detector area (with optional group filter) |
| **Collision** | Body Exited | A physics body exited the detector area |
| **Collision** | Area Entered | Another area entered the detector area |
| **Collision** | Area Exited | Another area exited the detector area |
| **Collision** | Is Overlapping | True every frame while any matching body is inside the area (ideal for floor switches) |
| **UI** | Button Pressed | Fires once when a UI Button node is clicked |
| **Signals** | Signal Received | Listens for any signal on a target node |
| **Properties** | Compare Value | Compares a node property against a value (==, !=, >, <, >=, <=) |
| **Timing** | Repeating Timer | Triggers periodically at a set interval |
| **Timing** | One-Shot Delay | Triggers once after a set delay |
| **Lifecycle** | On Ready | Triggers once when the scene loads |
| **Lifecycle** | Every Frame | Triggers every frame (like `_process`) |
| **Lifecycle** | Every Physics Frame | Triggers every physics frame (like `_physics_process`) |

## Available Actions

| Category | Action | Description |
|----------|--------|-------------|
| **Movement** | Translate | Move a node by an offset at a given speed; includes direction presets (Up/Down/Left/Right) |
| **Movement** | Set Position | Set a node's absolute position |
| **Movement** | Move Toward Point | Move a node toward a fixed (x, y) coordinate |
| **Movement** | Move Toward Node | Move a node toward another node's live position (for chasing enemies) |
| **Movement** | Set Velocity (Physics) | Set `CharacterBody2D.velocity` and call `move_and_slide()` for wall-colliding movement |
| **Movement** | Apply Knockback | Push a target node away from a source node (supports `$collider` as target) |
| **Properties** | Set Value | Set a property to a value; supports `{../Node:prop}` placeholders for live HUD text |
| **Properties** | Add / Subtract / Multiply | Modify a numeric property |
| **Properties** | Toggle | Toggle a boolean property |
| **Signals** | Emit Signal | Emit a signal (with optional arguments) on any node |
| **Animation** | Play / Stop / Pause | Control AnimationPlayer or AnimatedSprite2D |
| **Scene** | Create Instance | Instantiate a scene; can spawn at a Marker2D's position and rotation |
| **Scene** | Destroy Node | Remove a node from the scene tree (supports `$collider`) |
| **Scene** | Change Scene | Transition to a completely different scene file |
| **Scene** | Show Node | Make a node visible (`visible = true`) |
| **Scene** | Hide Node | Make a node invisible (`visible = false`) |
| **Audio** | Play / Stop Sound | Control AudioStreamPlayer nodes |
| **Debug** | Print Message | Print to console (supports `{name}`, `{position}`, `{delta}` placeholders) |

## Referencing the Collided Node with `$collider`

After any collision condition fires, actions can use **`$collider`** as a target path to reference the node involved in the collision. This works in any action that accepts a target node path:

```
Event: "Weapon hits enemy"
  Condition: Collision - Area Entered (group: "enemies")
  Action: Apply Knockback — target: $collider, force: 300
  Action: Destroy Node — target: $collider
```

## Working with Signals

Signals are a vital part of Godot and are fully supported:

### Defining Custom Signals
In the EventSheet resource, add signal names to the **Custom Signals** array. These are automatically registered on the EventController at runtime.

### Emitting Signals
Use the **Emit Signal** action. You can:
- Emit on the EventController itself (leave target empty)
- Emit on any node in the scene (specify a node path)
- Pass up to 4 arguments with the signal

### Listening for Signals
Use the **Signal Received** condition. You can:
- Listen on the parent node (leave source empty)
- Listen on any node in the scene (specify a source path)
- Access signal arguments in subsequent actions

### Cross-Node Communication
Example: A coin emits `"coin_collected"`, and a score display listens for it:

```
# On the Coin's EventController:
Event: "Notify Collection"
  Condition: Collision - Area Entered (group: "player")
  Action: Emit Signal "coin_collected" on /root/Main/ScoreManager

# On the ScoreManager's EventController:
Event: "Update Score"
  Condition: Signal "coin_collected" received
  Action: Set Property "score" Add 1
  Action: Print "Score: {name}"
```

## Collision Detection

The addon connects to Godot's collision system automatically:

1. Your game object needs an **Area2D** or **Area3D** with a **CollisionShape2D/3D**
2. Add a **Collision** condition to your event
3. Optionally filter by **group** (e.g., only trigger for nodes in the "enemies" group)
4. The EventController automatically connects the correct signals at runtime

## Project Structure

```
addons/godot_event_sheet/
├── plugin.cfg              # Plugin configuration
├── plugin.gd               # Editor plugin entry point
├── core/                   # Data model
│   ├── event_sheet.gd      # ESEventSheet - main container resource
│   ├── event_item.gd       # ESEventItem - single event (conditions + actions)
│   ├── event_condition.gd  # ESCondition - base condition class
│   └── event_action.gd     # ESAction - base action class
├── conditions/             # Condition implementations
│   ├── input_condition.gd
│   ├── collision_condition.gd
│   ├── button_condition.gd
│   ├── signal_condition.gd
│   ├── property_condition.gd
│   ├── timer_condition.gd
│   └── lifecycle_condition.gd
├── actions/                # Action implementations
│   ├── move_action.gd
│   ├── knockback_action.gd
│   ├── set_property_action.gd
│   ├── emit_signal_action.gd
│   ├── animation_action.gd
│   ├── scene_action.gd
│   ├── sound_action.gd
│   └── print_action.gd
├── runtime/
│   └── event_controller.gd # Runtime event processor node
└── editor/                 # Editor UI
    ├── event_sheet_editor.gd
    ├── add_event_dialog.gd
    ├── condition_dialog.gd
    └── action_dialog.gd
```

## Extending the Addon

### Adding Custom Conditions

Create a new script extending `ESCondition`:

```gdscript
class_name ESMyCustomCondition
extends ESCondition

@export var my_parameter: String = ""

func get_summary() -> String:
    return "My Condition: %s" % my_parameter

func get_category() -> String:
    return "Custom"

func evaluate(controller: Node, delta: float) -> bool:
    # Return true when your condition is met
    return some_check()
```

### Adding Custom Actions

Create a new script extending `ESAction`:

```gdscript
class_name ESMyCustomAction
extends ESAction

@export var my_parameter: String = ""

func get_summary() -> String:
    return "My Action: %s" % my_parameter

func get_category() -> String:
    return "Custom"

func execute(controller: Node, delta: float) -> void:
    # Perform your action
    var target = controller.get_parent()
    # ... do something with target
```

## Inspiration

This addon draws inspiration from:
- [Construct 3](https://www.construct.net/) — Event sheet programming model
- [GDevelop](https://gdevelop.io/) — Visual event-based game logic
- [FlowKit](https://github.com/LexianDEV/FlowKit) — Flow-based visual scripting for Godot
- [Orchestra](https://github.com/CraterCrash/godot-orchestrator) — Visual scripting for Godot
- [Endless Block Coding](https://github.com/endlessm/godot-block-coding) — Block-based coding for Godot

## License

MIT License