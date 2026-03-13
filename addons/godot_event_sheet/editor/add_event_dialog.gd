@tool
extends ConfirmationDialog
## Combined "When → Then" dialog for adding events to the event sheet.
## Presents a simple cause-and-effect model: pick a trigger and a reaction
## in a single step, so students see the full event at once.

# --- Trigger (condition) choices, using student-friendly labels ---
const TRIGGER_TYPES := {
	"When a key/button is pressed": "input_pressed",
	"When a key/button is released": "input_released",
	"While a key/button is held down": "input_held",
	"When a UI button is clicked": "ui_button_pressed",
	"Every frame (continuous)": "lifecycle_process",
	"Every physics frame": "lifecycle_physics",
	"On game start (once)": "lifecycle_ready",
	"When a timer fires (repeating)": "timer_repeat",
	"When a timer fires (once)": "timer_oneshot",
	"When a body collides (entered)": "collision_body_entered",
	"When a body stops colliding (exited)": "collision_body_exited",
	"When an area is entered": "collision_area_entered",
	"When an area is exited": "collision_area_exited",
	"While an object is overlapping (floor switch)": "collision_is_overlapping",
	"When a signal is received": "signal_received",
	"When a property matches a value": "property_compare",
}

# --- Reaction (action) choices, using student-friendly labels ---
const REACTION_TYPES := {
	"Move the object": "move_translate",
	"Set the object's position": "move_set_position",
	"Move toward a point": "move_toward",
	"Move toward another object (chase)": "move_toward_node",
	"Set velocity (physics movement)": "move_velocity",
	"Knock back an object": "knockback",
	"Set a property": "prop_set",
	"Add to a property": "prop_add",
	"Subtract from a property": "prop_subtract",
	"Multiply a property": "prop_multiply",
	"Toggle a property (on/off)": "prop_toggle",
	"Play an animation": "anim_play",
	"Stop an animation": "anim_stop",
	"Play a sound": "sound_play",
	"Stop a sound": "sound_stop",
	"Create (spawn) a scene": "scene_create",
	"Destroy a node": "scene_destroy",
	"Change to a different scene": "scene_change",
	"Show a node": "scene_show",
	"Hide a node": "scene_hide",
	"Emit a signal": "emit_signal",
	"Print a debug message": "debug_print",
}

var _trigger_list: ItemList
var _reaction_list: ItemList
var _trigger_props: VBoxContainer
var _reaction_props: VBoxContainer

var _selected_condition: ESCondition = null
var _selected_action: ESAction = null

# Preload scripts for creating conditions and actions.
const ConditionDialog := preload("res://addons/godot_event_sheet/editor/condition_dialog.gd")
const ActionDialog := preload("res://addons/godot_event_sheet/editor/action_dialog.gd")


## Create and return a new "Add Event" dialog ready to show.
static func create() -> ConfirmationDialog:
	var dialog := preload("res://addons/godot_event_sheet/editor/add_event_dialog.gd").new()
	dialog.title = "Add New Event"
	dialog.ok_button_text = "Create Event"
	dialog._build_ui()
	return dialog


## Return the condition selected by the user (or null).
func get_selected_condition() -> ESCondition:
	return _selected_condition


## Return the action selected by the user (or null).
func get_selected_action() -> ESAction:
	return _selected_action


## Build the full dialog layout.
func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)

	# ===== TRIGGER SECTION =====
	var trigger_header := Label.new()
	trigger_header.text = "📋  WHEN this happens (trigger):"
	trigger_header.add_theme_font_size_override("font_size", 15)
	root.add_child(trigger_header)

	var trigger_split := HBoxContainer.new()
	trigger_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(trigger_split)

	_trigger_list = ItemList.new()
	_trigger_list.custom_minimum_size = Vector2(260, 0)
	_trigger_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	trigger_split.add_child(_trigger_list)

	_trigger_props = VBoxContainer.new()
	_trigger_props.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_trigger_props.size_flags_vertical = Control.SIZE_EXPAND_FILL
	trigger_split.add_child(_trigger_props)

	for label_text in TRIGGER_TYPES:
		_trigger_list.add_item(label_text)
	_trigger_list.item_selected.connect(_on_trigger_selected)

	# Separator between sections.
	var sep := HSeparator.new()
	root.add_child(sep)

	# ===== REACTION SECTION =====
	var reaction_header := Label.new()
	reaction_header.text = "⚡  THEN do this (reaction):"
	reaction_header.add_theme_font_size_override("font_size", 15)
	root.add_child(reaction_header)

	var reaction_split := HBoxContainer.new()
	reaction_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(reaction_split)

	_reaction_list = ItemList.new()
	_reaction_list.custom_minimum_size = Vector2(260, 0)
	_reaction_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reaction_split.add_child(_reaction_list)

	_reaction_props = VBoxContainer.new()
	_reaction_props.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reaction_props.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reaction_split.add_child(_reaction_props)

	for label_text in REACTION_TYPES:
		_reaction_list.add_item(label_text)
	_reaction_list.item_selected.connect(_on_reaction_selected)


## When a trigger type is selected, create the condition and show its property editors.
func _on_trigger_selected(index: int) -> void:
	var label_text := _trigger_list.get_item_text(index)
	var key: String = TRIGGER_TYPES[label_text]

	for child in _trigger_props.get_children():
		child.queue_free()

	# Use condition_dialog factory to create the condition and build its UI.
	var helper := ConditionDialog.new()
	_selected_condition = helper.create_condition_from_key(key)
	if _selected_condition:
		helper.build_property_fields(_trigger_props, _selected_condition)
	helper.free()


## When a reaction type is selected, create the action and show its property editors.
func _on_reaction_selected(index: int) -> void:
	var label_text := _reaction_list.get_item_text(index)
	var key: String = REACTION_TYPES[label_text]

	for child in _reaction_props.get_children():
		child.queue_free()

	# Use action_dialog factory to create the action and build its UI.
	var helper := ActionDialog.new()
	_selected_action = helper.create_action_from_key(key)
	if _selected_action:
		helper.build_property_fields(_reaction_props, _selected_action)
	helper.free()
