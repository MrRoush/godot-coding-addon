# Godot Event Sheet — Visual Programming Addon for Godot 4.5

A visual **Event Sheet** programming addon for Godot 4.5, designed for beginning programmers and game design students. Instead of writing traditional GDScript code, students create game logic by combining **Conditions** (when something happens) with **Actions** (what to do), similar to Construct 3 or GDevelop.

## Features

- **Event Sheet Editor** — A bottom panel in the Godot editor for visually building game logic
- **No Code Required** — Students define behavior with conditions and actions, not GDScript
- **Full Signal Support** — Create, emit, and listen for custom signals between nodes
- **Collision Detection** — Detect body and area collisions with group filtering
- **Input Handling** — Respond to keyboard input, action presses, and held keys
- **Property Control** — Read, set, add, subtract, multiply, or toggle any node property
- **Movement** — Translate, set position, or move toward targets (2D and 3D)
- **Timers** — Repeating and one-shot timers without writing code
- **Animation & Audio** — Play/stop animations and sounds
- **Scene Management** — Instantiate scenes and destroy nodes at runtime
- **Debug Printing** — Print messages with variable placeholders for easy debugging

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
2. In the Inspector, create a new **EventSheet** resource for the EventController
3. Click on the EventController — the **Event Sheet** panel opens at the bottom

### 4. Create Events

Each event has **Conditions** (left side) and **Actions** (right side):

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
| **Movement** | Translate | Move a node by an offset at a given speed |
| **Movement** | Set Position | Set a node's absolute position |
| **Movement** | Move Toward | Move a node toward a target position |
| **Properties** | Set Value | Set a property to a specific value |
| **Properties** | Add / Subtract / Multiply | Modify a numeric property |
| **Properties** | Toggle | Toggle a boolean property |
| **Signals** | Emit Signal | Emit a signal (with optional arguments) on any node |
| **Animation** | Play / Stop / Pause | Control AnimationPlayer or AnimatedSprite2D |
| **Scene** | Create Instance | Instantiate a scene at a position |
| **Scene** | Destroy Node | Remove a node from the scene tree |
| **Audio** | Play / Stop Sound | Control AudioStreamPlayer nodes |
| **Debug** | Print Message | Print to console (supports `{name}`, `{position}`, `{delta}` placeholders) |

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
│   ├── signal_condition.gd
│   ├── property_condition.gd
│   ├── timer_condition.gd
│   └── lifecycle_condition.gd
├── actions/                # Action implementations
│   ├── move_action.gd
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