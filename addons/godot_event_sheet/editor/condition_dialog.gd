@tool
extends ConfirmationDialog
## Dialog for picking a new condition type or editing an existing condition.

# Preloaded condition scripts (no class_name, so we use preload constants).
const ESInputCondition := preload("res://addons/godot_event_sheet/conditions/input_condition.gd")
const ESCollisionCondition := preload("res://addons/godot_event_sheet/conditions/collision_condition.gd")
const ESButtonCondition := preload("res://addons/godot_event_sheet/conditions/button_condition.gd")
const ESSignalCondition := preload("res://addons/godot_event_sheet/conditions/signal_condition.gd")
const ESPropertyCondition := preload("res://addons/godot_event_sheet/conditions/property_condition.gd")
const ESTimerCondition := preload("res://addons/godot_event_sheet/conditions/timer_condition.gd")
const ESLifecycleCondition := preload("res://addons/godot_event_sheet/conditions/lifecycle_condition.gd")
const ESPhysicsCondition := preload("res://addons/godot_event_sheet/conditions/physics_condition.gd")
const ESMouseCondition := preload("res://addons/godot_event_sheet/conditions/mouse_condition.gd")
const ESRandomCondition := preload("res://addons/godot_event_sheet/conditions/random_condition.gd")
const ESDistanceCondition := preload("res://addons/godot_event_sheet/conditions/distance_condition.gd")
const ESGroupCondition := preload("res://addons/godot_event_sheet/conditions/group_condition.gd")
const ESStateCondition := preload("res://addons/godot_event_sheet/conditions/state_condition.gd")
const ESNodeCountCondition := preload("res://addons/godot_event_sheet/conditions/node_count_condition.gd")
const ESJoypadCondition := preload("res://addons/godot_event_sheet/conditions/joypad_condition.gd")
const ESVariableCondition := preload("res://addons/godot_event_sheet/conditions/variable_condition.gd")
const ESMouseHoverCondition := preload("res://addons/godot_event_sheet/conditions/mouse_hover_condition.gd")
const ESAnimationCondition := preload("res://addons/godot_event_sheet/conditions/animation_condition.gd")
const ESVisibilityCondition := preload("res://addons/godot_event_sheet/conditions/visibility_condition.gd")
const ESTreeLifecycleCondition := preload("res://addons/godot_event_sheet/conditions/tree_lifecycle_condition.gd")
const ESClickCondition := preload("res://addons/godot_event_sheet/conditions/click_condition.gd")
const PropertyHints := preload("res://addons/godot_event_sheet/editor/property_hints.gd")

var _condition_list: Tree
var _tree_item_to_key: Dictionary = {}
var _property_editor: VBoxContainer
var _selected_condition: ESCondition = null
var _editing_condition: ESCondition = null

## Reference to the current EventController used to walk the scene tree for node pickers.
var _controller: Node = null

# Categorized condition types.
const CONDITION_CATEGORIES := [
	{
		"label": "🎮 Input",
		"items": [
			{"label": "Input: Key/Action Pressed", "key": "input_pressed"},
			{"label": "Input: Key/Action Released", "key": "input_released"},
			{"label": "Input: Key/Action Held", "key": "input_held"},
			{"label": "Input: Any Key Pressed", "key": "input_any_pressed"},
			{"label": "Input: Any Key Released", "key": "input_any_released"},
			{"label": "Input: Mouse Button", "key": "mouse_button"},
			{"label": "Input: Joypad Stick", "key": "joypad_axis"},
			{"label": "Input: Joypad Button Pressed", "key": "joypad_button_pressed"},
			{"label": "Input: Joypad Button Released", "key": "joypad_button_released"},
			{"label": "Input: Joypad Button Held", "key": "joypad_button_held"},
			{"label": "Input: Joypad Connected", "key": "joypad_connected"},
			{"label": "UI: Button Pressed", "key": "ui_button_pressed"},
		]
	},
	{
		"label": "⏱ Lifecycle",
		"items": [
			{"label": "Lifecycle: Every Frame", "key": "lifecycle_process"},
			{"label": "Lifecycle: Every Physics Step", "key": "lifecycle_physics"},
			{"label": "Lifecycle: On Start of Scene (once)", "key": "lifecycle_ready"},
		]
	},
	{
		"label": "💥 Collision",
		"items": [
			{"label": "Collision: Body Entered", "key": "collision_body_entered"},
			{"label": "Collision: Body Exited", "key": "collision_body_exited"},
			{"label": "Collision: Area Entered", "key": "collision_area_entered"},
			{"label": "Collision: Area Exited", "key": "collision_area_exited"},
			{"label": "Collision: Is Overlapping (while inside)", "key": "collision_is_overlapping"},
		]
	},
	{
		"label": "🏃 Physics",
		"items": [
			{"label": "Physics: Is On Floor", "key": "physics_on_floor"},
			{"label": "Physics: Is On Wall", "key": "physics_on_wall"},
			{"label": "Physics: Is On Ceiling", "key": "physics_on_ceiling"},
			{"label": "Physics: Is Moving", "key": "physics_is_moving"},
			{"label": "Physics: Is Stopped", "key": "physics_is_stopped"},
			{"label": "Physics: Is Falling", "key": "physics_is_falling"},
		]
	},
	{
		"label": "📡 Signals",
		"items": [
			{"label": "Signal: Signal Received", "key": "signal_received"},
		]
	},
	{
		"label": "📦 Properties",
		"items": [
			{"label": "Property: Compare Value", "key": "property_compare"},
		]
	},
	{
		"label": "⏲ Timers",
		"items": [
			{"label": "Timer: Repeating Timer", "key": "timer_repeat"},
			{"label": "Timer: One-Shot Delay", "key": "timer_oneshot"},
		]
	},
	{
		"label": "🎲 Utility",
		"items": [
			{"label": "Utility: Random Chance", "key": "random_chance"},
			{"label": "Utility: Distance Check", "key": "distance_check"},
			{"label": "Utility: Is In Group", "key": "group_check"},
			{"label": "Utility: Node Count in Group", "key": "node_count"},
		]
	},
	{
		"label": "🔀 Game State (Phases)",
		"items": [
			{"label": "State: Check State", "key": "state_check"},
		]
	},
	{
		"label": "📊 Counters & Flags",
		"items": [
			{"label": "Variable: Compare Value", "key": "variable_compare"},
			{"label": "Variable: Array Contains", "key": "variable_contains"},
		]
	},
	{
		"label": "🖱 Hover & Click",
		"items": [
			{"label": "Hover: Mouse Entered", "key": "hover_mouse_entered"},
			{"label": "Hover: Mouse Exited", "key": "hover_mouse_exited"},
			{"label": "Hover: Is Hovered", "key": "hover_is_hovered"},
			{"label": "Click: Object Clicked", "key": "click_object"},
			{"label": "Click: Object Click Released", "key": "click_object_released"},
		]
	},
	{
		"label": "🎬 Animation",
		"items": [
			{"label": "Animation: Animation Finished", "key": "animation_finished"},
		]
	},
	{
		"label": "👁 Visibility",
		"items": [
			{"label": "Visibility: Appeared on Screen", "key": "visibility_screen_entered"},
			{"label": "Visibility: Left the Screen", "key": "visibility_screen_exited"},
			{"label": "Visibility: Is on Screen", "key": "visibility_is_on_screen"},
		]
	},
	{
		"label": "🌳 Scene Tree",
		"items": [
			{"label": "Tree: Added to Scene", "key": "tree_enter"},
			{"label": "Tree: Removed from Scene", "key": "tree_exit"},
			{"label": "Tree: Child Added", "key": "tree_child_entered"},
			{"label": "Tree: Child Removed", "key": "tree_child_exiting"},
		]
	},
]

# Flat map kept for backward compat (used by add_event_dialog key lookup).
const CONDITION_TYPES := {
	"Input: Key/Action Pressed": "input_pressed",
	"Input: Key/Action Released": "input_released",
	"Input: Key/Action Held": "input_held",
	"Input: Any Key Pressed": "input_any_pressed",
	"Input: Any Key Released": "input_any_released",
	"Collision: Body Entered": "collision_body_entered",
	"Collision: Body Exited": "collision_body_exited",
	"Collision: Area Entered": "collision_area_entered",
	"Collision: Area Exited": "collision_area_exited",
	"Collision: Is Overlapping (while inside)": "collision_is_overlapping",
	"UI: Button Pressed": "ui_button_pressed",
	"Signal: Signal Received": "signal_received",
	"Property: Compare Value": "property_compare",
	"Timer: Repeating Timer": "timer_repeat",
	"Timer: One-Shot Delay": "timer_oneshot",
	"Lifecycle: On Start of Scene": "lifecycle_ready",
	"Lifecycle: Every Frame": "lifecycle_process",
	"Lifecycle: Every Physics Step": "lifecycle_physics",
	"Physics: Is On Floor": "physics_on_floor",
	"Physics: Is On Wall": "physics_on_wall",
	"Physics: Is On Ceiling": "physics_on_ceiling",
	"Physics: Is Moving": "physics_is_moving",
	"Physics: Is Stopped": "physics_is_stopped",
	"Physics: Is Falling": "physics_is_falling",
	"Input: Mouse Button": "mouse_button",
	"Utility: Random Chance": "random_chance",
	"Utility: Distance Check": "distance_check",
	"Utility: Is In Group": "group_check",
	"Utility: Node Count in Group": "node_count",
	"State: Check State": "state_check",
	"Input: Joypad Stick": "joypad_axis",
	"Input: Joypad Button Pressed": "joypad_button_pressed",
	"Input: Joypad Button Released": "joypad_button_released",
	"Input: Joypad Button Held": "joypad_button_held",
	"Input: Joypad Connected": "joypad_connected",
	"Variable: Compare Value": "variable_compare",
	"Variable: Array Contains": "variable_contains",
	"Hover: Mouse Entered": "hover_mouse_entered",
	"Hover: Mouse Exited": "hover_mouse_exited",
	"Hover: Is Hovered": "hover_is_hovered",
	"Click: Object Clicked": "click_object",
	"Click: Object Click Released": "click_object_released",
	"Animation: Animation Finished": "animation_finished",
	"Visibility: Appeared on Screen": "visibility_screen_entered",
	"Visibility: Left the Screen": "visibility_screen_exited",
	"Visibility: Is on Screen": "visibility_is_on_screen",
	"Tree: Added to Scene": "tree_enter",
	"Tree: Removed from Scene": "tree_exit",
	"Tree: Child Added": "tree_child_entered",
	"Tree: Child Removed": "tree_child_exiting",
}


## Create a picker dialog for selecting a new condition type.
static func create_picker(controller: Node = null) -> ConfirmationDialog:
	var dialog := preload("res://addons/godot_event_sheet/editor/condition_dialog.gd").new()
	dialog.title = "Add Condition"
	dialog._controller = controller
	dialog._build_picker_ui()
	return dialog


## Create an editor dialog for modifying an existing condition.
static func create_editor(condition: ESCondition, controller: Node = null) -> ConfirmationDialog:
	var dialog := preload("res://addons/godot_event_sheet/editor/condition_dialog.gd").new()
	dialog.title = "Edit Condition"
	dialog._controller = controller
	dialog._editing_condition = condition
	dialog._build_editor_ui(condition)
	return dialog


## Get the condition created/selected by the dialog.
func get_selected_condition() -> ESCondition:
	return _selected_condition


## Build the picker UI (categorized tree of condition types to choose from).
func _build_picker_ui() -> void:
	var vbox := VBoxContainer.new()
	add_child(vbox)

	var label := Label.new()
	label.text = "Select a condition type:"
	vbox.add_child(label)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)

	_condition_list = Tree.new()
	_condition_list.custom_minimum_size = Vector2(300, 250)
	_condition_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_condition_list.hide_root = true
	split.add_child(_condition_list)

	var vsep := VSeparator.new()
	split.add_child(vsep)

	# Property editor area (shown when a type is selected).
	_property_editor = VBoxContainer.new()
	_property_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_property_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(_property_editor)

	# Build categorized tree.
	_tree_item_to_key.clear()
	var root := _condition_list.create_item()
	for cat in CONDITION_CATEGORIES:
		var cat_item := _condition_list.create_item(root)
		cat_item.set_text(0, cat["label"])
		cat_item.set_selectable(0, false)
		cat_item.set_custom_bg_color(0, Color(0.15, 0.17, 0.22))
		for entry in cat["items"]:
			var child := _condition_list.create_item(cat_item)
			child.set_text(0, "  " + entry["label"])
			_tree_item_to_key[child] = entry["key"]

	_condition_list.item_selected.connect(_on_condition_type_selected)


## When a condition type is selected in the tree, show its properties.
func _on_condition_type_selected() -> void:
	var selected := _condition_list.get_selected()
	if not selected or not _tree_item_to_key.has(selected):
		return  # Category header selected — ignore.

	var type_key: String = _tree_item_to_key[selected]

	# Clear previous properties.
	for child in _property_editor.get_children():
		child.queue_free()

	# Create the condition and show its properties.
	_selected_condition = create_condition_from_key(type_key)
	if _selected_condition:
		build_property_fields(_property_editor, _selected_condition)


## Create a condition resource from a type key.
func create_condition_from_key(key: String) -> ESCondition:
	match key:
		"input_pressed":
			var c := ESInputCondition.new()
			c.input_type = ESInputCondition.InputType.JUST_PRESSED
			return c
		"input_released":
			var c := ESInputCondition.new()
			c.input_type = ESInputCondition.InputType.JUST_RELEASED
			return c
		"input_held":
			var c := ESInputCondition.new()
			c.input_type = ESInputCondition.InputType.IS_HELD
			return c
		"input_any_pressed":
			var c := ESInputCondition.new()
			c.input_type = ESInputCondition.InputType.ANY_JUST_PRESSED
			return c
		"input_any_released":
			var c := ESInputCondition.new()
			c.input_type = ESInputCondition.InputType.ANY_JUST_RELEASED
			return c
		"collision_body_entered":
			var c := ESCollisionCondition.new()
			c.collision_type = ESCollisionCondition.CollisionType.BODY_ENTERED
			return c
		"collision_body_exited":
			var c := ESCollisionCondition.new()
			c.collision_type = ESCollisionCondition.CollisionType.BODY_EXITED
			return c
		"collision_area_entered":
			var c := ESCollisionCondition.new()
			c.collision_type = ESCollisionCondition.CollisionType.AREA_ENTERED
			return c
		"collision_area_exited":
			var c := ESCollisionCondition.new()
			c.collision_type = ESCollisionCondition.CollisionType.AREA_EXITED
			return c
		"collision_is_overlapping":
			var c := ESCollisionCondition.new()
			c.collision_type = ESCollisionCondition.CollisionType.IS_OVERLAPPING
			return c
		"ui_button_pressed":
			return ESButtonCondition.new()
		"signal_received":
			return ESSignalCondition.new()
		"property_compare":
			return ESPropertyCondition.new()
		"timer_repeat":
			var c := ESTimerCondition.new()
			c.one_shot = false
			return c
		"timer_oneshot":
			var c := ESTimerCondition.new()
			c.one_shot = true
			return c
		"lifecycle_ready":
			var c := ESLifecycleCondition.new()
			c.lifecycle_type = ESLifecycleCondition.LifecycleType.READY
			return c
		"lifecycle_process":
			var c := ESLifecycleCondition.new()
			c.lifecycle_type = ESLifecycleCondition.LifecycleType.PROCESS
			return c
		"lifecycle_physics":
			var c := ESLifecycleCondition.new()
			c.lifecycle_type = ESLifecycleCondition.LifecycleType.PHYSICS_PROCESS
			return c
		"physics_on_floor":
			var c := ESPhysicsCondition.new()
			c.physics_check = ESPhysicsCondition.PhysicsCheck.IS_ON_FLOOR
			return c
		"physics_on_wall":
			var c := ESPhysicsCondition.new()
			c.physics_check = ESPhysicsCondition.PhysicsCheck.IS_ON_WALL
			return c
		"physics_on_ceiling":
			var c := ESPhysicsCondition.new()
			c.physics_check = ESPhysicsCondition.PhysicsCheck.IS_ON_CEILING
			return c
		"physics_is_moving":
			var c := ESPhysicsCondition.new()
			c.physics_check = ESPhysicsCondition.PhysicsCheck.IS_MOVING
			return c
		"physics_is_stopped":
			var c := ESPhysicsCondition.new()
			c.physics_check = ESPhysicsCondition.PhysicsCheck.IS_STOPPED
			return c
		"physics_is_falling":
			var c := ESPhysicsCondition.new()
			c.physics_check = ESPhysicsCondition.PhysicsCheck.IS_FALLING
			return c
		"mouse_button":
			return ESMouseCondition.new()
		"random_chance":
			return ESRandomCondition.new()
		"distance_check":
			return ESDistanceCondition.new()
		"group_check":
			return ESGroupCondition.new()
		"node_count":
			return ESNodeCountCondition.new()
		"state_check":
			return ESStateCondition.new()
		"joypad_axis":
			var c := ESJoypadCondition.new()
			c.check_type = ESJoypadCondition.JoypadCheck.AXIS_ACTIVE
			return c
		"joypad_button_pressed":
			var c := ESJoypadCondition.new()
			c.check_type = ESJoypadCondition.JoypadCheck.BUTTON_PRESSED
			return c
		"joypad_button_released":
			var c := ESJoypadCondition.new()
			c.check_type = ESJoypadCondition.JoypadCheck.BUTTON_RELEASED
			return c
		"joypad_button_held":
			var c := ESJoypadCondition.new()
			c.check_type = ESJoypadCondition.JoypadCheck.BUTTON_HELD
			return c
		"joypad_connected":
			var c := ESJoypadCondition.new()
			c.check_type = ESJoypadCondition.JoypadCheck.ANY_CONNECTED
			return c
		"variable_compare":
			return ESVariableCondition.new()
		"variable_contains":
			var c := ESVariableCondition.new()
			c.compare_op = ESVariableCondition.CompareOp.CONTAINS
			return c
		"hover_mouse_entered":
			var c := ESMouseHoverCondition.new()
			c.hover_type = ESMouseHoverCondition.HoverType.MOUSE_ENTERED
			return c
		"hover_mouse_exited":
			var c := ESMouseHoverCondition.new()
			c.hover_type = ESMouseHoverCondition.HoverType.MOUSE_EXITED
			return c
		"hover_is_hovered":
			var c := ESMouseHoverCondition.new()
			c.hover_type = ESMouseHoverCondition.HoverType.IS_HOVERED
			return c
		"click_object":
			var c := ESClickCondition.new()
			c.click_type = ESClickCondition.ClickType.CLICKED
			return c
		"click_object_released":
			var c := ESClickCondition.new()
			c.click_type = ESClickCondition.ClickType.RELEASED
			return c
		"animation_finished":
			return ESAnimationCondition.new()
		"visibility_screen_entered":
			var c := ESVisibilityCondition.new()
			c.visibility_type = ESVisibilityCondition.VisibilityType.SCREEN_ENTERED
			return c
		"visibility_screen_exited":
			var c := ESVisibilityCondition.new()
			c.visibility_type = ESVisibilityCondition.VisibilityType.SCREEN_EXITED
			return c
		"visibility_is_on_screen":
			var c := ESVisibilityCondition.new()
			c.visibility_type = ESVisibilityCondition.VisibilityType.IS_ON_SCREEN
			return c
		"tree_enter":
			var c := ESTreeLifecycleCondition.new()
			c.tree_event = ESTreeLifecycleCondition.TreeEvent.ENTER_TREE
			return c
		"tree_exit":
			var c := ESTreeLifecycleCondition.new()
			c.tree_event = ESTreeLifecycleCondition.TreeEvent.EXIT_TREE
			return c
		"tree_child_entered":
			var c := ESTreeLifecycleCondition.new()
			c.tree_event = ESTreeLifecycleCondition.TreeEvent.CHILD_ENTERED_TREE
			return c
		"tree_child_exiting":
			var c := ESTreeLifecycleCondition.new()
			c.tree_event = ESTreeLifecycleCondition.TreeEvent.CHILD_EXITING_TREE
			return c
	return null


## Build editor UI for modifying an existing condition.
func _build_editor_ui(condition: ESCondition) -> void:
	var vbox := VBoxContainer.new()
	add_child(vbox)

	var label := Label.new()
	label.text = "Edit condition properties:"
	vbox.add_child(label)

	var type_label := Label.new()
	type_label.text = "Type: %s" % condition.get_summary()
	type_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(type_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	build_property_fields(vbox, condition)
	_selected_condition = condition


## Build property input fields for any condition type.
func build_property_fields(container: VBoxContainer, condition: ESCondition) -> void:
	# Negation toggle – available for every condition type.
	_add_bool_field(container, "Negate (NOT):", condition, "negated")

	if condition is ESInputCondition:
		_add_enum_field(container, "Input Type:", condition, "input_type",
			["Just Pressed (is_action_just_pressed)", "Just Released (is_action_just_released)",
			 "Is Held (is_action_pressed)", "Any Just Pressed", "Any Just Released"])
		# Only show action/key field for specific key conditions.
		if condition.input_type < ESInputCondition.InputType.ANY_JUST_PRESSED:
			_add_string_field(container, "Action or Key Name:", condition, "action_or_key",
				"Enter an input action (e.g., ui_up, ui_accept) or key name (e.g., W, Space, Up)")

	elif condition is ESCollisionCondition:
		# --- Mutual exclusion: Specific Node vs. Group ---
		var detect_mode_hbox := HBoxContainer.new()
		container.add_child(detect_mode_hbox)
		var detect_mode_label := Label.new()
		detect_mode_label.text = "Detect using:"
		detect_mode_label.custom_minimum_size.x = 150
		detect_mode_hbox.add_child(detect_mode_label)
		var detect_mode_btn := OptionButton.new()
		detect_mode_btn.add_item("Specific Node")
		detect_mode_btn.add_item("All Nodes in Group")
		detect_mode_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detect_mode_hbox.add_child(detect_mode_btn)

		# Containers for each mode (only one visible at a time).
		var node_row := VBoxContainer.new()
		container.add_child(node_row)
		var group_row := VBoxContainer.new()
		container.add_child(group_row)

		_add_node_path_field(node_row, "Detector Node:", condition, "detector_path",
			"Path to the Area2D/Area3D node (leave empty for parent)",
			Callable(), ["Area2D", "Area3D", "CharacterBody2D", "CharacterBody3D",
			             "RigidBody2D", "RigidBody3D"])
		_add_string_field(group_row, "Detector Group:", condition, "detector_group",
			"Group name — connect ALL nodes in this group as detectors (e.g., hazards, saws)")

		# Determine initial mode from current condition state.
		var initial_mode := 0 if condition.detector_group.is_empty() else 1
		detect_mode_btn.selected = initial_mode
		node_row.visible = initial_mode == 0
		group_row.visible = initial_mode == 1

		detect_mode_btn.item_selected.connect(func(idx: int):
			node_row.visible = idx == 0
			group_row.visible = idx == 1
			if idx == 0:
				condition.detector_group = ""
			else:
				condition.detector_path = NodePath("")
		)

		_add_string_field(container, "Filter Group:", condition, "filter_group",
			"Only trigger for colliding nodes in this group (leave empty for all)")
		_add_string_field(container, "Filter Class:", condition, "filter_class",
			"Only trigger for colliding nodes of this class (e.g., Player, CharacterBody2D)")

	elif condition is ESButtonCondition:
		_add_node_path_field(container, "Button Node:", condition, "button_path",
			"Path to the Button node to listen to (e.g., ../StartButton)",
			Callable(), ["Button", "CheckBox", "CheckButton", "LinkButton",
			             "OptionButton", "TextureButton", "BaseButton"])

	elif condition is ESSignalCondition:
		_add_node_path_field(container, "Source Node:", condition, "source_path",
			"Path to the node that emits the signal (leave empty for parent)")
		_add_string_field(container, "Signal Name:", condition, "signal_name",
			"The signal to listen for (e.g., health_changed)")

	elif condition is ESPropertyCondition:
		_add_node_and_property_fields_condition(container, condition)
		_add_enum_field(container, "Comparison:", condition, "compare_op",
			["Equal (==)", "Not Equal (!=)", "Greater Than (>)", "Less Than (<)", "Greater or Equal (>=)", "Less or Equal (<=)"])
		_add_variant_value_field(container, "Compare Value:", condition, "compare_value",
			str(condition.node_path), condition.property_name,
			"Value to compare against")

	elif condition is ESTimerCondition:
		_add_float_field(container, "Wait Time (seconds):", condition, "wait_time")
		_add_bool_field(container, "One-Shot:", condition, "one_shot")

	elif condition is ESLifecycleCondition:
		_add_enum_field(container, "Event Type:", condition, "lifecycle_type",
			["On Start of Scene (once)", "Every Frame", "Every Physics Step"])

	elif condition is ESPhysicsCondition:
		_add_node_path_field(container, "Target Node:", condition, "node_path",
			"Path to CharacterBody2D/3D (leave empty for parent)",
			Callable(), ["CharacterBody2D", "CharacterBody3D"])
		_add_enum_field(container, "Physics Check:", condition, "physics_check",
			["Is On Floor", "Is On Wall", "Is On Ceiling", "Is Moving", "Is Stopped", "Is Falling"])

	elif condition is ESMouseCondition:
		_add_enum_field(container, "Mouse Button:", condition, "button_type",
			["Left Just Pressed", "Left Just Released", "Left Held",
			 "Right Just Pressed", "Right Just Released", "Right Held",
			 "Middle Just Pressed", "Middle Just Released", "Middle Held"])

	elif condition is ESRandomCondition:
		_add_float_field(container, "Probability (0–1):", condition, "probability")

	elif condition is ESDistanceCondition:
		_add_node_path_field(container, "Node A:", condition, "node_a_path",
			"First node (leave empty for parent)")
		_add_node_path_field(container, "Node B:", condition, "node_b_path",
			"Second node to measure distance to (e.g., ../Player)")
		_add_enum_field(container, "Comparison:", condition, "compare_op",
			["Less Than (<)", "Greater Than (>)", "Less or Equal (<=)", "Greater or Equal (>=)"])
		_add_float_field(container, "Distance (pixels):", condition, "distance")

	elif condition is ESGroupCondition:
		_add_node_path_field(container, "Node:", condition, "node_path",
			"Node to check (leave empty for parent, or $collider)")
		_add_string_field(container, "Group Name:", condition, "group_name",
			"e.g., enemies, power_ups, coins")

	elif condition is ESNodeCountCondition:
		_add_string_field(container, "Group Name:", condition, "group_name",
			"Group to count nodes in (e.g., bricks, enemies, coins)")
		_add_enum_field(container, "Comparison:", condition, "compare_op",
			["Equal (==)", "Not Equal (!=)", "Greater Than (>)", "Less Than (<)", "Greater or Equal (>=)", "Less or Equal (<=)"])
		_add_int_field(container, "Count Value:", condition, "compare_value")

	elif condition is ESStateCondition:
		_add_node_path_field(container, "Node:", condition, "node_path",
			"Node to check state on (leave empty for parent)")
		_add_string_field(container, "State Name:", condition, "state_name",
			"Metadata key (must match the State action's state_name)")
		_add_enum_field(container, "Comparison:", condition, "compare_op",
			["Equal (==)", "Not Equal (!=)"])
		_add_string_field(container, "State Value:", condition, "compare_value",
			"e.g., player_turn, phase_2, powered_up, game_over")

	elif condition is ESJoypadCondition:
		_add_enum_field(container, "Check Type:", condition, "check_type",
			["Stick/Axis Active", "Button Pressed", "Button Released",
			 "Button Held", "Any Joypad Connected"])
		if condition.check_type == ESJoypadCondition.JoypadCheck.AXIS_ACTIVE:
			_add_enum_field(container, "Axis:", condition, "axis",
				["Left Stick X", "Left Stick Y", "Right Stick X",
				 "Right Stick Y", "Left Trigger", "Right Trigger"])
			_add_float_field(container, "Threshold (0–1):", condition, "axis_threshold")
			_add_bool_field(container, "Positive Direction (+/right/down):", condition, "positive_direction")
		if condition.check_type in [ESJoypadCondition.JoypadCheck.BUTTON_PRESSED,
				ESJoypadCondition.JoypadCheck.BUTTON_RELEASED,
				ESJoypadCondition.JoypadCheck.BUTTON_HELD]:
			_add_int_field(container, "Button Index (0=A, 1=B, ...):", condition, "joypad_button")
		_add_int_field(container, "Device ID (0=first):", condition, "device_id")

	elif condition is ESVariableCondition:
		_add_string_field(container, "Variable Name:", condition, "variable_name",
			"Name of the variable (must match a Variable action)")
		_add_enum_field(container, "Comparison:", condition, "compare_op",
			["Equal (==)", "Not Equal (!=)", "Greater Than (>)", "Less Than (<)",
			 "Greater or Equal (>=)", "Less or Equal (<=)", "Contains (in / has)"])
		_add_string_field(container, "Compare Value:", condition, "compare_value",
			"Value to compare against (number, string, true/false)")
		_add_enum_field(container, "Scope:", condition, "scope",
			["Local (this controller)", "Global (survives scene changes)"])

	elif condition is ESMouseHoverCondition:
		_add_enum_field(container, "Hover Event:", condition, "hover_type",
			["Mouse Entered", "Mouse Exited", "Is Hovered"])
		_add_node_path_field(container, "Target Node:", condition, "target_path",
			"Node to detect hover on (leave empty for parent)",
			Callable(), ["Area2D", "Area3D", "CollisionObject2D", "CollisionObject3D", "Control"])

	elif condition is ESClickCondition:
		_add_enum_field(container, "Click Type:", condition, "click_type",
			["Clicked", "Click Released"])
		_add_node_path_field(container, "Target Node:", condition, "target_path",
			"CollisionObject2D/3D to detect clicks on (leave empty for parent)",
			Callable(), ["CollisionObject2D", "CollisionObject3D", "Area2D", "Area3D"])

	elif condition is ESAnimationCondition:
		_add_node_path_field(container, "Animation Player:", condition, "player_path",
			"Path to AnimationPlayer or AnimatedSprite2D (leave empty to auto-find)",
			Callable(), ["AnimationPlayer", "AnimatedSprite2D", "AnimatedSprite3D"])
		_add_string_field(container, "Animation Name:", condition, "animation_name",
			"Only trigger for this animation (leave empty for any)")

	elif condition is ESVisibilityCondition:
		_add_enum_field(container, "Visibility Event:", condition, "visibility_type",
			["Screen Entered (screen_entered)", "Screen Exited (screen_exited)", "Is On Screen (is_on_screen)"])
		_add_node_path_field(container, "Notifier Node:", condition, "notifier_path",
			"Path to VisibleOnScreenNotifier2D/3D (leave empty to auto-find)",
			Callable(), ["VisibleOnScreenNotifier2D", "VisibleOnScreenNotifier3D"])

	elif condition is ESTreeLifecycleCondition:
		_add_enum_field(container, "Tree Event:", condition, "tree_event",
			["Added to Scene", "Removed from Scene", "Child Added", "Child Removed"])
		_add_node_path_field(container, "Target Node:", condition, "target_path",
			"Node to monitor (leave empty for parent)")


## Detect the Godot Variant type of a named property on the resolved node.
## Returns TYPE_NIL if the node or property cannot be resolved.
func _get_property_godot_type(node_path: NodePath, property_name: String) -> int:
	if _controller == null or not is_instance_valid(_controller):
		return TYPE_NIL
	var node: Node = null
	var path_str := str(node_path)
	if path_str.is_empty():
		node = _controller.get_parent()
	elif path_str == "$collider":
		return TYPE_NIL  # Runtime-only; type unknown at edit time.
	else:
		node = _controller.get_node_or_null(node_path)
		if node == null and _controller.get_parent():
			node = _controller.get_parent().get_node_or_null(node_path)
	if not node or property_name.is_empty():
		return TYPE_NIL
	var parts := property_name.split(".")
	if parts.size() == 1:
		if property_name in node:
			return typeof(node.get(property_name))
		return TYPE_NIL
	# Dot notation (e.g., velocity.x): Vector2/Vector3/Color components are always float.
	var parent_prop := parts[0]
	if not (parent_prop in node):
		return TYPE_NIL
	var parent_val = node.get(parent_prop)
	if parent_val is Vector2 or parent_val is Vector3 or parent_val is Color:
		return TYPE_FLOAT
	return TYPE_NIL


## Add a type-aware value input for a Variant property.
## Detects the property type from the target node and shows a CheckBox (bool),
## SpinBox (int/float), or LineEdit (string/unknown/placeholder).
func _add_variant_value_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String, node_path_str: String, property_name: String, hint: String = "") -> void:
	var current_val = obj.get(prop)

	# If the current value is a placeholder string, always show a string field.
	var is_placeholder := current_val is String and "{" in (current_val as String)
	if is_placeholder:
		_add_string_field(container, label_text, obj, prop, hint)
		return

	var prop_type := _get_property_godot_type(NodePath(node_path_str), property_name)
	match prop_type:
		TYPE_BOOL:
			var bool_val: bool = false
			if current_val is bool:    bool_val = current_val
			elif current_val is int:   bool_val = current_val != 0
			elif current_val is float: bool_val = current_val != 0.0
			elif current_val is String:
				var s := (current_val as String).strip_edges().to_lower()
				bool_val = s == "true" or s == "1" or s == "yes" or s == "on"
			obj.set(prop, bool_val)
			_add_bool_typed_field(container, label_text, obj, prop)
		TYPE_INT:
			var int_val: int = 0
			if current_val is int:   int_val = current_val
			elif current_val is float: int_val = int(current_val)
			elif current_val is String:
				var s := current_val as String
				if s.is_valid_int():   int_val = s.to_int()
				elif s.is_valid_float(): int_val = int(s.to_float())
			obj.set(prop, int_val)
			_add_int_typed_field(container, label_text, obj, prop)
		TYPE_FLOAT:
			var float_val: float = 0.0
			if current_val is float: float_val = current_val
			elif current_val is int: float_val = float(current_val)
			elif current_val is String:
				var s := current_val as String
				if s.is_valid_float():   float_val = s.to_float()
				elif s.is_valid_int():   float_val = float(s.to_int())
			obj.set(prop, float_val)
			_add_float_typed_field(container, label_text, obj, prop)
		_:
			# Unknown or complex type: fall back to a string field that also
			# supports {../Node:prop} placeholder expressions.
			var str_val: String = str(current_val) if current_val != null else ""
			if not (current_val is String):
				obj.set(prop, str_val)
			_add_string_field(container, label_text, obj, prop, hint)


## CheckBox field that writes a bool to a Variant property.
func _add_bool_typed_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)
	var check := CheckBox.new()
	check.text = label_text
	var cur = obj.get(prop)
	check.button_pressed = bool(cur) if cur != null else false
	check.toggled.connect(func(val: bool): obj.set(prop, val))
	hbox.add_child(check)


## SpinBox field that writes a float to a Variant property.
func _add_float_typed_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	hbox.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = -99999.0
	spin.max_value = 99999.0
	spin.step = 0.1
	var cur = obj.get(prop)
	spin.value = float(cur) if cur != null else 0.0
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(func(val: float): obj.set(prop, val))
	hbox.add_child(spin)


## SpinBox field that writes an int to a Variant property.
func _add_int_typed_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	hbox.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = -99999
	spin.max_value = 99999
	spin.step = 1
	var cur = obj.get(prop)
	spin.value = int(cur) if cur != null else 0
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(func(val: float): obj.set(prop, int(val)))
	hbox.add_child(spin)


## Helper: add a string input field.
func _add_string_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String, hint: String = "") -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	hbox.add_child(label)

	var edit := LineEdit.new()
	edit.text = str(obj.get(prop))
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.placeholder_text = hint
	edit.text_changed.connect(func(new_text: String):
		obj.set(prop, new_text)
	)
	hbox.add_child(edit)


## Helper: add a node path input field.
## When a controller reference is available, shows an OptionButton populated
## from the scene tree.  Falls back to a plain LineEdit otherwise.
## [param filter_classes] optionally restricts the dropdown to nodes whose
## class matches one of the given class names (via node.is_class()).  An empty
## array means "show all nodes" (backward-compatible default).
## Returns a Callable that, when called with a new path String, updates the field.
func _add_node_path_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String, hint: String = "", on_path_changed: Callable = Callable(),
		filter_classes: Array = []) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	hbox.add_child(label)

	if _controller != null and is_instance_valid(_controller):
		# --- Dropdown mode ---
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(col)

		var dropdown := OptionButton.new()
		dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(dropdown)

		var custom_edit := LineEdit.new()
		custom_edit.placeholder_text = hint
		custom_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		custom_edit.visible = false
		col.add_child(custom_edit)

		# Populate — always include the special sentinel entries first.
		var nodes := _get_scene_nodes(filter_classes)
		dropdown.add_item("(leave empty — use parent)")
		dropdown.add_item("$collider")
		for node_info in nodes:
			dropdown.add_item(node_info["display"])
		dropdown.add_item("(Custom path...)")

		# Pre-select current value.
		var current_path := str(obj.get(prop))
		var selected_idx := 0
		if current_path.is_empty():
			selected_idx = 0
		elif current_path == "$collider":
			selected_idx = 1
		else:
			var found := false
			for i in range(nodes.size()):
				if nodes[i]["path"] == current_path:
					selected_idx = 2 + i
					found = true
					break
			if not found:
				selected_idx = dropdown.item_count - 1
				custom_edit.text = current_path
				custom_edit.visible = true
		dropdown.selected = selected_idx

		dropdown.item_selected.connect(func(idx: int):
			var item_text := dropdown.get_item_text(idx)
			if item_text == "(Custom path...)":
				custom_edit.visible = true
				obj.set(prop, NodePath(custom_edit.text))
				if on_path_changed.is_valid():
					on_path_changed.call(custom_edit.text)
			elif item_text == "(leave empty — use parent)":
				custom_edit.visible = false
				obj.set(prop, NodePath(""))
				if on_path_changed.is_valid():
					on_path_changed.call("")
			else:
				custom_edit.visible = false
				var path_str: String
				if idx == 1:  # $collider
					path_str = "$collider"
				else:
					path_str = nodes[idx - 2]["path"]
				obj.set(prop, NodePath(path_str))
				if on_path_changed.is_valid():
					on_path_changed.call(path_str)
		)

		custom_edit.text_changed.connect(func(new_text: String):
			obj.set(prop, NodePath(new_text))
			if on_path_changed.is_valid():
				on_path_changed.call(new_text)
		)
	else:
		# --- Plain LineEdit fallback ---
		var edit := LineEdit.new()
		edit.text = str(obj.get(prop))
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.placeholder_text = hint
		edit.text_changed.connect(func(new_text: String):
			obj.set(prop, NodePath(new_text))
			if on_path_changed.is_valid():
				on_path_changed.call(new_text)
		)
		hbox.add_child(edit)


## Helper: add a float input field.
func _add_float_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	hbox.add_child(label)

	var spin := SpinBox.new()
	spin.min_value = 0.01
	spin.max_value = 9999.0
	spin.step = 0.1
	spin.value = obj.get(prop)
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(func(val: float):
		obj.set(prop, val)
	)
	hbox.add_child(spin)


## Helper: add an integer spin-box field.
func _add_int_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	hbox.add_child(label)

	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = 9999
	spin.step = 1
	spin.value = obj.get(prop)
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(func(val: float):
		obj.set(prop, int(val))
	)
	hbox.add_child(spin)


## Helper: add a boolean checkbox field.
func _add_bool_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)

	var check := CheckBox.new()
	check.text = label_text
	check.button_pressed = obj.get(prop)
	check.toggled.connect(func(val: bool):
		obj.set(prop, val)
	)
	hbox.add_child(check)


## Helper: add an enum dropdown field.
func _add_enum_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String, options: Array) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	hbox.add_child(label)

	var option_btn := OptionButton.new()
	for opt in options:
		option_btn.add_item(opt)
	option_btn.selected = obj.get(prop)
	option_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_btn.item_selected.connect(func(idx: int):
		obj.set(prop, idx)
	)
	hbox.add_child(option_btn)


## Build node path + property name fields for ESPropertyCondition with
## a cascading property dropdown that updates when the node changes.
func _add_node_and_property_fields_condition(container: VBoxContainer,
		condition: ESPropertyCondition) -> void:
	# Property dropdown — built here, populated after node is known.
	var prop_dropdown := OptionButton.new()
	var prop_custom_edit := LineEdit.new()

	_add_node_path_field(container, "Target Node:", condition, "node_path",
		"Path to the node (leave empty for parent)",
		func(new_path: String):
			_populate_property_dropdown(prop_dropdown, prop_custom_edit, new_path, condition, "property_name")
	)

	# Property name row.
	var prop_hbox := HBoxContainer.new()
	container.add_child(prop_hbox)

	var prop_label := Label.new()
	prop_label.text = "Property Name:"
	prop_label.custom_minimum_size.x = 150
	prop_hbox.add_child(prop_label)

	var prop_col := VBoxContainer.new()
	prop_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prop_hbox.add_child(prop_col)

	prop_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prop_col.add_child(prop_dropdown)

	prop_custom_edit.placeholder_text = "e.g., position.x, health, visible"
	prop_custom_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prop_col.add_child(prop_custom_edit)

	# Initial population based on current node path.
	_populate_property_dropdown(prop_dropdown, prop_custom_edit,
		str(condition.node_path), condition, "property_name")


## Populate a property dropdown for the given node path.
func _populate_property_dropdown(dropdown: OptionButton, custom_edit: LineEdit,
		node_path: String, obj: Object, prop: String) -> void:
	dropdown.clear()

	var node: Node = null
	if _controller != null and is_instance_valid(_controller):
		if node_path.is_empty():
			node = _controller.get_parent()
		elif node_path == "$collider":
			node = null  # Runtime-only; no static type available.
		else:
			node = _controller.get_node_or_null(NodePath(node_path))
			if node == null and _controller.get_parent():
				node = _controller.get_parent().get_node_or_null(NodePath(node_path))

	var common: Array = []
	var exports := PackedStringArray()
	if node:
		common = PropertyHints.get_properties_for_node(node)
		exports = PropertyHints.get_custom_exports(node)

	var current_prop: String = str(obj.get(prop))
	var selected_idx := 0
	var found_in_list := false

	var idx := 0
	for item in common:
		dropdown.add_item(item["label"])
		dropdown.set_item_metadata(idx, item["prop"])
		if item["prop"] == current_prop:
			selected_idx = idx
			found_in_list = true
		idx += 1

	if exports.size() > 0:
		if common.size() > 0:
			dropdown.add_separator()
			idx += 1
		for p in exports:
			dropdown.add_item(p)
			dropdown.set_item_metadata(idx, p)
			if p == current_prop:
				selected_idx = idx
				found_in_list = true
			idx += 1

	if common.size() > 0 or exports.size() > 0:
		dropdown.add_separator()
		idx += 1

	dropdown.add_item("(Custom property...)")
	var custom_idx := idx

	if not found_in_list and not current_prop.is_empty():
		selected_idx = custom_idx
		custom_edit.text = current_prop
		custom_edit.visible = true
	else:
		custom_edit.visible = (selected_idx == custom_idx)
		if found_in_list:
			custom_edit.visible = false

	dropdown.selected = selected_idx

	# Disconnect all previous item_selected connections then reconnect.
	# (Safe here because prop_dropdown is owned exclusively by this function.)
	for conn in dropdown.item_selected.get_connections():
		dropdown.item_selected.disconnect(conn["callable"])
	dropdown.item_selected.connect(func(sel_idx: int):
		_on_prop_dropdown_item_selected(sel_idx, dropdown, custom_edit, obj, prop)
	)

	# Disconnect and reconnect text_changed to avoid duplicate handlers on repopulation.
	for conn in custom_edit.text_changed.get_connections():
		custom_edit.text_changed.disconnect(conn["callable"])
	custom_edit.text_changed.connect(func(new_text: String):
		obj.set(prop, new_text)
	)


func _on_prop_dropdown_item_selected(idx: int, dropdown: OptionButton,
		custom_edit: LineEdit, obj: Object, prop: String) -> void:
	var item_text := dropdown.get_item_text(idx)
	if item_text == "(Custom property...)":
		custom_edit.visible = true
		obj.set(prop, custom_edit.text)
	elif item_text.is_empty():
		pass  # Separator — ignore.
	else:
		custom_edit.visible = false
		var meta = dropdown.get_item_metadata(idx)
		if meta != null and typeof(meta) == TYPE_STRING and not (meta as String).is_empty():
			obj.set(prop, meta as String)
		else:
			push_warning("EventSheet: Property dropdown item '%s' has no metadata; using display text as fallback." % item_text)
			obj.set(prop, item_text)


## Walk the scene tree from the controller's owner and return node info entries.
## [param filter_classes] restricts results to nodes matching at least one class
## in the list.  Empty array = no filter (show all nodes).
func _get_scene_nodes(filter_classes: Array = []) -> Array:
	var result := []
	if not _controller or not is_instance_valid(_controller):
		return result

	var scene_root: Node = _controller.owner if _controller.owner else _controller.get_parent()
	if not scene_root:
		return result

	_walk_scene_tree(scene_root, result, filter_classes)
	return result


func _walk_scene_tree(node: Node, result: Array, filter_classes: Array = []) -> void:
	if not is_instance_valid(_controller):
		return
	if node == _controller:
		for child in node.get_children():
			_walk_scene_tree(child, result, filter_classes)
		return

	# Apply class filter when provided.
	var passes_filter := filter_classes.is_empty()
	if not passes_filter:
		for cls in filter_classes:
			if node.is_class(cls):
				passes_filter = true
				break

	if passes_filter:
		var path_to_node: NodePath = _controller.get_path_to(node)
		var type_name := node.get_class()
		result.append({
			"path": str(path_to_node),
			"display": "%s (%s)" % [str(path_to_node), type_name],
		})

	for child in node.get_children():
		_walk_scene_tree(child, result, filter_classes)
