@tool
extends ConfirmationDialog
## Dialog for picking a new action type or editing an existing action.

# Preloaded action scripts (no class_name, so we use preload constants).
const ESMoveAction := preload("res://addons/godot_event_sheet/actions/move_action.gd")
const ESKnockbackAction := preload("res://addons/godot_event_sheet/actions/knockback_action.gd")
const ESSetPropertyAction := preload("res://addons/godot_event_sheet/actions/set_property_action.gd")
const ESEmitSignalAction := preload("res://addons/godot_event_sheet/actions/emit_signal_action.gd")
const ESAnimationAction := preload("res://addons/godot_event_sheet/actions/animation_action.gd")
const ESSceneAction := preload("res://addons/godot_event_sheet/actions/scene_action.gd")
const ESSoundAction := preload("res://addons/godot_event_sheet/actions/sound_action.gd")
const ESPrintAction := preload("res://addons/godot_event_sheet/actions/print_action.gd")
const ESGravityAction := preload("res://addons/godot_event_sheet/actions/gravity_action.gd")
const ESRotateAction := preload("res://addons/godot_event_sheet/actions/rotate_action.gd")
const ESCameraAction := preload("res://addons/godot_event_sheet/actions/camera_action.gd")
const ESPathfindingAction := preload("res://addons/godot_event_sheet/actions/pathfinding_action.gd")
const ESRandomAction := preload("res://addons/godot_event_sheet/actions/random_action.gd")
const ESGroupAction := preload("res://addons/godot_event_sheet/actions/group_action.gd")
const ESStateAction := preload("res://addons/godot_event_sheet/actions/state_action.gd")
const ESClampAction := preload("res://addons/godot_event_sheet/actions/clamp_action.gd")
const ESWaitAction := preload("res://addons/godot_event_sheet/actions/wait_action.gd")
const ESVariableAction := preload("res://addons/godot_event_sheet/actions/variable_action.gd")
const ESCallMethodAction := preload("res://addons/godot_event_sheet/actions/call_method_action.gd")
const ESRepeatAction := preload("res://addons/godot_event_sheet/actions/repeat_action.gd")
const ESMathAction := preload("res://addons/godot_event_sheet/actions/math_action.gd")
const PropertyHints := preload("res://addons/godot_event_sheet/editor/property_hints.gd")

var _action_list: Tree
var _tree_item_to_key: Dictionary = {}
var _property_editor: VBoxContainer
var _selected_action: ESAction = null
var _editing_action: ESAction = null

## Reference to the current EventController used to walk the scene tree for node pickers.
var _controller: Node = null

# Direction presets for TRANSLATE / SET_VELOCITY.
const DIRECTION_PRESETS := {
	"Right →": Vector2(1, 0),
	"Left ←": Vector2(-1, 0),
	"Down ↓": Vector2(0, 1),
	"Up ↑": Vector2(0, -1),
	"Down-Right ↘": Vector2(1, 1),
	"Down-Left ↙": Vector2(-1, 1),
	"Up-Right ↗": Vector2(1, -1),
	"Up-Left ↖": Vector2(-1, -1),
	"Custom (X/Y)": Vector2.ZERO,
}

# Categorized action types.
const ACTION_CATEGORIES := [
	{
		"label": "🏃 Movement",
		"items": [
			{"label": "Movement: Move (Translate)", "key": "move_translate"},
			{"label": "Movement: Set Position", "key": "move_set_position"},
			{"label": "Movement: Move Toward Point", "key": "move_toward"},
			{"label": "Movement: Move Toward Node (dynamic)", "key": "move_toward_node"},
			{"label": "Movement: Set Velocity (Physics)", "key": "move_velocity"},
			{"label": "Movement: Rotate / Aim", "key": "rotate"},
			{"label": "Movement: Pathfind (A*)", "key": "pathfind"},
			{"label": "Physics: Apply Gravity", "key": "gravity"},
			{"label": "Movement: Apply Knockback", "key": "knockback"},
		]
	},
	{
		"label": "📦 Properties",
		"items": [
			{"label": "Property: Set Value", "key": "prop_set"},
			{"label": "Property: Add Value", "key": "prop_add"},
			{"label": "Property: Subtract Value", "key": "prop_subtract"},
			{"label": "Property: Multiply Value", "key": "prop_multiply"},
			{"label": "Property: Divide Value", "key": "prop_divide"},
			{"label": "Property: Toggle (Boolean)", "key": "prop_toggle"},
			{"label": "Property: Clamp (Min/Max)", "key": "prop_clamp"},
		]
	},
	{
		"label": "🎬 Animation & Audio",
		"items": [
			{"label": "Animation: Play", "key": "anim_play"},
			{"label": "Animation: Play Backwards", "key": "anim_play_back"},
			{"label": "Animation: Stop", "key": "anim_stop"},
			{"label": "Animation: Pause", "key": "anim_pause"},
			{"label": "Audio: Play Sound", "key": "sound_play"},
			{"label": "Audio: Stop Sound", "key": "sound_stop"},
		]
	},
	{
		"label": "🎭 Scene",
		"items": [
			{"label": "Scene: Create Instance", "key": "scene_create"},
			{"label": "Scene: Destroy Node", "key": "scene_destroy"},
			{"label": "Scene: Change Scene", "key": "scene_change"},
			{"label": "Scene: Show Node", "key": "scene_show"},
			{"label": "Scene: Hide Node", "key": "scene_hide"},
			{"label": "Scene: Pause Tree", "key": "scene_pause"},
			{"label": "Scene: Unpause Tree", "key": "scene_unpause"},
		]
	},
	{
		"label": "📡 Signals",
		"items": [
			{"label": "Signal: Emit Signal", "key": "emit_signal"},
		]
	},
	{
		"label": "🔧 Methods",
		"items": [
			{"label": "Method: Call Method", "key": "call_method"},
		]
	},
	{
		"label": "🐛 Debug",
		"items": [
			{"label": "Debug: Print Message", "key": "debug_print"},
		]
	},
	{
		"label": "📷 Camera",
		"items": [
			{"label": "Camera: Follow Target", "key": "camera_follow"},
			{"label": "Camera: Set Zoom", "key": "camera_zoom"},
			{"label": "Camera: Shake", "key": "camera_shake"},
			{"label": "Camera: Reset Zoom", "key": "camera_reset_zoom"},
			{"label": "Camera: Set Offset", "key": "camera_offset"},
		]
	},
	{
		"label": "🎲 Utility",
		"items": [
			{"label": "Utility: Random Float Value", "key": "random_float"},
			{"label": "Utility: Random Int Value", "key": "random_int"},
			{"label": "Utility: Random Position", "key": "random_position"},
			{"label": "Utility: Add to Group", "key": "group_add"},
			{"label": "Utility: Remove from Group", "key": "group_remove"},
		]
	},
	{
		"label": "🔀 Game State (Phases)",
		"items": [
			{"label": "State: Set State", "key": "state_set"},
			{"label": "State: Clear State", "key": "state_clear"},
		]
	},
	{
		"label": "⏲ Timing",
		"items": [
			{"label": "Timing: Wait (Delay)", "key": "wait"},
			{"label": "Timing: Repeat N Times", "key": "repeat"},
		]
	},
	{
		"label": "📊 Counters & Flags",
		"items": [
			{"label": "Variable: Set Value", "key": "var_set"},
			{"label": "Variable: Add Value", "key": "var_add"},
			{"label": "Variable: Subtract Value", "key": "var_subtract"},
			{"label": "Variable: Multiply Value", "key": "var_multiply"},
			{"label": "Variable: Divide Value", "key": "var_divide"},
			{"label": "Variable: Toggle (Boolean)", "key": "var_toggle"},
			{"label": "Variable: Append to Array", "key": "var_append"},
			{"label": "Variable: Remove from Array", "key": "var_remove"},
			{"label": "Variable: Clear Array", "key": "var_clear_array"},
		]
	},
	{
		"label": "🔢 Math",
		"items": [
			{"label": "Math: Apply Math Function", "key": "math_op"},
		]
	},
]

# Flat map kept for backward compat (used by add_event_dialog key lookup).
const ACTION_TYPES := {
	"Movement: Move (Translate)": "move_translate",
	"Movement: Set Position": "move_set_position",
	"Movement: Move Toward Point": "move_toward",
	"Movement: Move Toward Node (dynamic)": "move_toward_node",
	"Movement: Set Velocity (Physics)": "move_velocity",
	"Movement: Apply Knockback": "knockback",
	"Property: Set Value": "prop_set",
	"Property: Add Value": "prop_add",
	"Property: Subtract Value": "prop_subtract",
	"Property: Multiply Value": "prop_multiply",
	"Property: Divide Value": "prop_divide",
	"Property: Toggle (Boolean)": "prop_toggle",
	"Signal: Emit Signal": "emit_signal",
	"Animation: Play": "anim_play",
	"Animation: Play Backwards": "anim_play_back",
	"Animation: Stop": "anim_stop",
	"Animation: Pause": "anim_pause",
	"Scene: Create Instance": "scene_create",
	"Scene: Destroy Node": "scene_destroy",
	"Scene: Change Scene": "scene_change",
	"Scene: Show Node": "scene_show",
	"Scene: Hide Node": "scene_hide",
	"Audio: Play Sound": "sound_play",
	"Audio: Stop Sound": "sound_stop",
	"Physics: Apply Gravity": "gravity",
	"Debug: Print Message": "debug_print",
	"Movement: Rotate / Aim": "rotate",
	"Movement: Pathfind (A*)": "pathfind",
	"Camera: Follow Target": "camera_follow",
	"Camera: Set Zoom": "camera_zoom",
	"Camera: Shake": "camera_shake",
	"Camera: Reset Zoom": "camera_reset_zoom",
	"Camera: Set Offset": "camera_offset",
	"Utility: Random Float Value": "random_float",
	"Utility: Random Int Value": "random_int",
	"Utility: Random Position": "random_position",
	"Utility: Add to Group": "group_add",
	"Utility: Remove from Group": "group_remove",
	"State: Set State": "state_set",
	"State: Clear State": "state_clear",
	"Property: Clamp (Min/Max)": "prop_clamp",
	"Timing: Wait (Delay)": "wait",
	"Timing: Repeat N Times": "repeat",
	"Variable: Set Value": "var_set",
	"Variable: Add Value": "var_add",
	"Variable: Subtract Value": "var_subtract",
	"Variable: Multiply Value": "var_multiply",
	"Variable: Divide Value": "var_divide",
	"Variable: Toggle (Boolean)": "var_toggle",
	"Variable: Append to Array": "var_append",
	"Variable: Remove from Array": "var_remove",
	"Variable: Clear Array": "var_clear_array",
	"Scene: Pause Tree": "scene_pause",
	"Scene: Unpause Tree": "scene_unpause",
	"Method: Call Method": "call_method",
	"Math: Apply Math Function": "math_op",
}


## Create a picker dialog for selecting a new action type.
static func create_picker(controller: Node = null) -> ConfirmationDialog:
	var dialog := preload("res://addons/godot_event_sheet/editor/action_dialog.gd").new()
	dialog.title = "Add Action"
	dialog._controller = controller
	dialog._build_picker_ui()
	return dialog


## Create an editor dialog for modifying an existing action.
static func create_editor(action: ESAction, controller: Node = null) -> ConfirmationDialog:
	var dialog := preload("res://addons/godot_event_sheet/editor/action_dialog.gd").new()
	dialog.title = "Edit Action"
	dialog._controller = controller
	dialog._editing_action = action
	dialog._build_editor_ui(action)
	return dialog


## Get the action created/selected by the dialog.
func get_selected_action() -> ESAction:
	return _selected_action


## Build the picker UI.
func _build_picker_ui() -> void:
	var vbox := VBoxContainer.new()
	add_child(vbox)

	var label := Label.new()
	label.text = "Select an action type:"
	vbox.add_child(label)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)

	_action_list = Tree.new()
	_action_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_action_list.custom_minimum_size = Vector2(300, 250)
	_action_list.hide_root = true
	split.add_child(_action_list)

	var vsep := VSeparator.new()
	split.add_child(vsep)

	_property_editor = VBoxContainer.new()
	_property_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_property_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(_property_editor)

	# Build categorized tree.
	_tree_item_to_key.clear()
	var root := _action_list.create_item()
	for cat in ACTION_CATEGORIES:
		var cat_item := _action_list.create_item(root)
		cat_item.set_text(0, cat["label"])
		cat_item.set_selectable(0, false)
		cat_item.set_custom_bg_color(0, Color(0.15, 0.17, 0.22))
		for entry in cat["items"]:
			var child := _action_list.create_item(cat_item)
			child.set_text(0, "  " + entry["label"])
			_tree_item_to_key[child] = entry["key"]

	_action_list.item_selected.connect(_on_action_type_selected)


## When an action type is selected in the tree, show its properties.
func _on_action_type_selected() -> void:
	var selected := _action_list.get_selected()
	if not selected or not _tree_item_to_key.has(selected):
		return  # Category header selected — ignore.

	var type_key: String = _tree_item_to_key[selected]

	for child in _property_editor.get_children():
		child.queue_free()

	_selected_action = create_action_from_key(type_key)
	if _selected_action:
		build_property_fields(_property_editor, _selected_action)


## Create an action resource from a type key.
func create_action_from_key(key: String) -> ESAction:
	match key:
		"move_translate":
			var a := ESMoveAction.new()
			a.move_type = ESMoveAction.MoveType.TRANSLATE
			return a
		"move_set_position":
			var a := ESMoveAction.new()
			a.move_type = ESMoveAction.MoveType.SET_POSITION
			return a
		"move_toward":
			var a := ESMoveAction.new()
			a.move_type = ESMoveAction.MoveType.MOVE_TOWARD
			return a
		"move_toward_node":
			var a := ESMoveAction.new()
			a.move_type = ESMoveAction.MoveType.MOVE_TOWARD_NODE
			return a
		"move_velocity":
			var a := ESMoveAction.new()
			a.move_type = ESMoveAction.MoveType.SET_VELOCITY
			return a
		"knockback":
			return ESKnockbackAction.new()
		"prop_set":
			var a := ESSetPropertyAction.new()
			a.set_mode = ESSetPropertyAction.SetMode.SET
			return a
		"prop_add":
			var a := ESSetPropertyAction.new()
			a.set_mode = ESSetPropertyAction.SetMode.ADD
			return a
		"prop_subtract":
			var a := ESSetPropertyAction.new()
			a.set_mode = ESSetPropertyAction.SetMode.SUBTRACT
			return a
		"prop_multiply":
			var a := ESSetPropertyAction.new()
			a.set_mode = ESSetPropertyAction.SetMode.MULTIPLY
			return a
		"prop_toggle":
			var a := ESSetPropertyAction.new()
			a.set_mode = ESSetPropertyAction.SetMode.TOGGLE
			return a
		"emit_signal":
			return ESEmitSignalAction.new()
		"anim_play":
			var a := ESAnimationAction.new()
			a.operation = ESAnimationAction.AnimOp.PLAY
			return a
		"anim_play_back":
			var a := ESAnimationAction.new()
			a.operation = ESAnimationAction.AnimOp.PLAY_BACKWARDS
			return a
		"anim_stop":
			var a := ESAnimationAction.new()
			a.operation = ESAnimationAction.AnimOp.STOP
			return a
		"anim_pause":
			var a := ESAnimationAction.new()
			a.operation = ESAnimationAction.AnimOp.PAUSE
			return a
		"scene_create":
			var a := ESSceneAction.new()
			a.operation = ESSceneAction.SceneOp.INSTANTIATE
			return a
		"scene_destroy":
			var a := ESSceneAction.new()
			a.operation = ESSceneAction.SceneOp.DESTROY
			return a
		"scene_change":
			var a := ESSceneAction.new()
			a.operation = ESSceneAction.SceneOp.CHANGE_SCENE
			return a
		"scene_show":
			var a := ESSceneAction.new()
			a.operation = ESSceneAction.SceneOp.SHOW
			return a
		"scene_hide":
			var a := ESSceneAction.new()
			a.operation = ESSceneAction.SceneOp.HIDE
			return a
		"sound_play":
			var a := ESSoundAction.new()
			a.operation = ESSoundAction.SoundOp.PLAY
			return a
		"sound_stop":
			var a := ESSoundAction.new()
			a.operation = ESSoundAction.SoundOp.STOP
			return a
		"debug_print":
			return ESPrintAction.new()
		"gravity":
			return ESGravityAction.new()
		"rotate":
			return ESRotateAction.new()
		"pathfind":
			return ESPathfindingAction.new()
		"camera_follow":
			var a := ESCameraAction.new()
			a.operation = ESCameraAction.CameraOp.FOLLOW_TARGET
			return a
		"camera_zoom":
			var a := ESCameraAction.new()
			a.operation = ESCameraAction.CameraOp.SET_ZOOM
			return a
		"camera_shake":
			var a := ESCameraAction.new()
			a.operation = ESCameraAction.CameraOp.SHAKE
			return a
		"camera_reset_zoom":
			var a := ESCameraAction.new()
			a.operation = ESCameraAction.CameraOp.RESET_ZOOM
			return a
		"camera_offset":
			var a := ESCameraAction.new()
			a.operation = ESCameraAction.CameraOp.SET_OFFSET
			return a
		"random_float":
			var a := ESRandomAction.new()
			a.operation = ESRandomAction.RandomOp.SET_RANDOM_FLOAT
			return a
		"random_int":
			var a := ESRandomAction.new()
			a.operation = ESRandomAction.RandomOp.SET_RANDOM_INT
			return a
		"random_position":
			var a := ESRandomAction.new()
			a.operation = ESRandomAction.RandomOp.RANDOM_POSITION
			return a
		"group_add":
			var a := ESGroupAction.new()
			a.operation = ESGroupAction.GroupOp.ADD_TO_GROUP
			return a
		"group_remove":
			var a := ESGroupAction.new()
			a.operation = ESGroupAction.GroupOp.REMOVE_FROM_GROUP
			return a
		"state_set":
			var a := ESStateAction.new()
			a.operation = ESStateAction.StateOp.SET
			return a
		"state_clear":
			var a := ESStateAction.new()
			a.operation = ESStateAction.StateOp.CLEAR
			return a
		"prop_clamp":
			return ESClampAction.new()
		"wait":
			return ESWaitAction.new()
		"var_set":
			var a := ESVariableAction.new()
			a.operation = ESVariableAction.VariableOp.SET
			return a
		"var_add":
			var a := ESVariableAction.new()
			a.operation = ESVariableAction.VariableOp.ADD
			return a
		"var_subtract":
			var a := ESVariableAction.new()
			a.operation = ESVariableAction.VariableOp.SUBTRACT
			return a
		"var_multiply":
			var a := ESVariableAction.new()
			a.operation = ESVariableAction.VariableOp.MULTIPLY
			return a
		"var_toggle":
			var a := ESVariableAction.new()
			a.operation = ESVariableAction.VariableOp.TOGGLE
			return a
		"var_append":
			var a := ESVariableAction.new()
			a.operation = ESVariableAction.VariableOp.APPEND
			return a
		"var_remove":
			var a := ESVariableAction.new()
			a.operation = ESVariableAction.VariableOp.REMOVE
			return a
		"var_clear_array":
			var a := ESVariableAction.new()
			a.operation = ESVariableAction.VariableOp.CLEAR_ARRAY
			return a
		"scene_pause":
			var a := ESSceneAction.new()
			a.operation = ESSceneAction.SceneOp.PAUSE_TREE
			return a
		"scene_unpause":
			var a := ESSceneAction.new()
			a.operation = ESSceneAction.SceneOp.UNPAUSE_TREE
			return a
		"call_method":
			return ESCallMethodAction.new()
		"prop_divide":
			var a := ESSetPropertyAction.new()
			a.set_mode = ESSetPropertyAction.SetMode.DIVIDE
			return a
		"var_divide":
			var a := ESVariableAction.new()
			a.operation = ESVariableAction.VariableOp.DIVIDE
			return a
		"repeat":
			return ESRepeatAction.new()
		"math_op":
			return ESMathAction.new()
	return null


## Build editor UI for an existing action.
func _build_editor_ui(action: ESAction) -> void:
	var vbox := VBoxContainer.new()
	add_child(vbox)

	var label := Label.new()
	label.text = "Edit action properties:"
	vbox.add_child(label)

	var type_label := Label.new()
	type_label.text = "Type: %s" % action.get_summary()
	type_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(type_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	build_property_fields(vbox, action)
	_selected_action = action


## Build property fields for any action type.
func build_property_fields(container: VBoxContainer, action: ESAction) -> void:
	if action is ESMoveAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to move (leave empty for parent, or type $collider)")
		match action.move_type:
			ESMoveAction.MoveType.TRANSLATE, ESMoveAction.MoveType.SET_VELOCITY:
				_add_direction_dropdown(container, action)
				_add_float_field(container, "Speed:", action, "speed")
				_add_bool_field(container, "Use Delta Time:", action, "use_delta")
			ESMoveAction.MoveType.SET_POSITION:
				_add_float_field(container, "X:", action, "x")
				_add_float_field(container, "Y:", action, "y")
			ESMoveAction.MoveType.MOVE_TOWARD:
				_add_float_field(container, "Target X:", action, "x")
				_add_float_field(container, "Target Y:", action, "y")
				_add_float_field(container, "Speed:", action, "speed")
				_add_bool_field(container, "Use Delta Time:", action, "use_delta")
			ESMoveAction.MoveType.MOVE_TOWARD_NODE:
				_add_node_path_field(container, "Toward Node:", action, "toward_node_path",
					"Node to chase (e.g., ../Player, or $collider)")
				_add_float_field(container, "Speed:", action, "speed")
				_add_bool_field(container, "Use Delta Time:", action, "use_delta")

	elif action is ESKnockbackAction:
		_add_node_path_field(container, "Source Node:", action, "source_node_path",
			"Node pushing outward (leave empty for parent)")
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to knock back (type $collider for last collision)")
		_add_float_field(container, "Force:", action, "force")
		_add_bool_field(container, "Use Velocity (Physics):", action, "use_velocity")

	elif action is ESSetPropertyAction:
		_add_node_and_property_fields_action(container, action)
		_add_variant_value_field(container, "Value:", action, "value",
			str(action.target_path), action.property_name,
			"Value to set/add. Use {../Node:prop} for live values, e.g., Health: {../Player:health}")
		_add_enum_field(container, "Mode:", action, "set_mode",
			["Assign (=)", "Add (+=)", "Subtract (-=)", "Multiply (*=)", "Toggle (not)", "Divide (/=)"])
		_add_bool_field(container, "Use Deferred (for physics callbacks):", action, "use_deferred")

	elif action is ESEmitSignalAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node that emits the signal (leave empty for EventController)")
		_add_string_field(container, "Signal Name:", action, "signal_name",
			"Signal to emit (e.g., player_died, score_changed)")
		_add_string_array_field(container, "Arguments:", action, "arguments",
			"Signal arguments (comma-separated)")

	elif action is ESAnimationAction:
		_add_node_path_field(container, "Player Node:", action, "player_path",
			"AnimationPlayer or AnimatedSprite2D (leave empty to auto-find)",
			Callable(), ["AnimationPlayer", "AnimatedSprite2D", "AnimatedSprite3D"])
		_add_string_field(container, "Animation Name:", action, "animation_name",
			"Name of the animation to play")

	elif action is ESSceneAction:
		match action.operation:
			ESSceneAction.SceneOp.INSTANTIATE:
				_add_string_field(container, "Scene Path:", action, "scene_path",
					"res://path/to/scene.tscn")
				_add_node_path_field(container, "Parent Node:", action, "parent_path",
					"Where to add the instance (leave empty for scene root)")
				_add_node_path_field(container, "Spawn at Marker:", action, "spawn_at_node_path",
					"Marker2D node — spawns at its position/rotation (overrides below)",
					Callable(), ["Marker2D", "Marker3D"])
				_add_vector2_field(container, "Spawn Position:", action, "spawn_position")
				_add_bool_field(container, "Use Parent Position:", action, "use_parent_position")
			ESSceneAction.SceneOp.DESTROY, ESSceneAction.SceneOp.SHOW, ESSceneAction.SceneOp.HIDE:
				_add_node_path_field(container, "Target Node:", action, "destroy_target_path",
					"Node to target (leave empty for parent, or $collider)")
			ESSceneAction.SceneOp.CHANGE_SCENE:
				_add_string_field(container, "Scene Path:", action, "scene_path",
					"res://path/to/next_scene.tscn")
				_add_bool_field(container, "Use Deferred (for physics callbacks):", action, "use_deferred")
			ESSceneAction.SceneOp.PAUSE_TREE, ESSceneAction.SceneOp.UNPAUSE_TREE:
				pass  # No additional fields needed.

	elif action is ESSoundAction:
		_add_node_path_field(container, "Audio Player:", action, "player_path",
			"AudioStreamPlayer node (leave empty to auto-find)",
			Callable(), ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"])
		if action.operation == ESSoundAction.SoundOp.PLAY:
			_add_string_field(container, "Audio File:", action, "audio_path",
				"res://path/to/sound.ogg (optional)")
			_add_float_field(container, "Volume (dB):", action, "volume_db")

	elif action is ESPrintAction:
		_add_string_field(container, "Message:", action, "message",
			"Use {name}, {position}, {delta} as placeholders")
		_add_bool_field(container, "Show as Warning:", action, "as_warning")

	elif action is ESGravityAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to apply gravity to (leave empty for parent, or ../NodeName)",
			Callable(), ["CharacterBody2D", "CharacterBody3D"])
		_add_float_field(container, "Gravity:", action, "gravity")
		_add_float_field(container, "Max Fall Speed:", action, "max_fall_speed")
		_add_bool_field(container, "Call move_and_slide():", action, "call_move_and_slide")

	elif action is ESRotateAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to rotate (leave empty for parent, or $collider)")
		_add_enum_field(container, "Rotate Type:", action, "rotate_type",
			["Look At Mouse", "Look At Node", "Set Rotation", "Rotate By"])
		if action.rotate_type == ESRotateAction.RotateType.LOOK_AT_NODE:
			_add_node_path_field(container, "Face Node:", action, "look_at_node_path",
				"Node to face (e.g., ../Player)")
		if action.rotate_type == ESRotateAction.RotateType.SET_ROTATION or \
				action.rotate_type == ESRotateAction.RotateType.ROTATE_BY:
			_add_float_field(container, "Angle (degrees):", action, "angle_degrees")
		if action.rotate_type == ESRotateAction.RotateType.ROTATE_BY:
			_add_bool_field(container, "Use Delta Time:", action, "use_delta")
		_add_float_field(container, "Rotation Offset (°):", action, "rotation_offset_degrees")
		_add_float_field(container, "Smooth Speed (°/s, 0=instant):", action, "rotation_speed")

	elif action is ESPathfindingAction:
		_add_enum_field(container, "Operation:", action, "operation",
			["Set Target Node", "Set Target Position", "Move Along Path", "Stop"])
		_add_node_path_field(container, "Mover Node:", action, "target_path",
			"Node to move (leave empty for parent)")
		if action.operation == ESPathfindingAction.PathfindingOp.SET_TARGET_NODE:
			_add_node_path_field(container, "Destination Node:", action, "destination_node_path",
				"Node to navigate toward (e.g., ../Player)")
		if action.operation == ESPathfindingAction.PathfindingOp.SET_TARGET_POS:
			_add_float_field(container, "Destination X:", action, "destination_x")
			_add_float_field(container, "Destination Y:", action, "destination_y")
		if action.operation == ESPathfindingAction.PathfindingOp.MOVE_ALONG_PATH:
			_add_float_field(container, "Speed:", action, "speed")
			_add_float_field(container, "Arrival Distance:", action, "arrival_distance")

	elif action is ESCameraAction:
		_add_node_path_field(container, "Camera Node:", action, "camera_path",
			"Camera2D node (leave empty to auto-find)",
			Callable(), ["Camera2D", "Camera3D"])
		match action.operation:
			ESCameraAction.CameraOp.FOLLOW_TARGET:
				_add_node_path_field(container, "Follow Target:", action, "follow_target_path",
					"Node for camera to follow (leave empty for parent)")
				_add_float_field(container, "Follow Speed (0=instant):", action, "follow_speed")
			ESCameraAction.CameraOp.SET_ZOOM:
				_add_float_field(container, "Zoom Level:", action, "zoom_level")
			ESCameraAction.CameraOp.SHAKE:
				_add_float_field(container, "Shake Intensity (px):", action, "shake_intensity")
				_add_float_field(container, "Shake Duration (s):", action, "shake_duration")
			ESCameraAction.CameraOp.SET_OFFSET:
				_add_float_field(container, "Offset X:", action, "offset_x")
				_add_float_field(container, "Offset Y:", action, "offset_y")

	elif action is ESRandomAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to modify (leave empty for parent)")
		if action.operation != ESRandomAction.RandomOp.RANDOM_POSITION:
			_add_string_field(container, "Property Name:", action, "property_name",
				"e.g., speed, scale.x, health")
			_add_float_field(container, "Min Value:", action, "min_value")
			_add_float_field(container, "Max Value:", action, "max_value")
		else:
			_add_float_field(container, "Min X:", action, "min_x")
			_add_float_field(container, "Max X:", action, "max_x")
			_add_float_field(container, "Min Y:", action, "min_y")
			_add_float_field(container, "Max Y:", action, "max_y")

	elif action is ESGroupAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to add/remove (leave empty for parent, or $collider)")
		_add_string_field(container, "Group Name:", action, "group_name",
			"e.g., enemies, power_ups, active")

	elif action is ESStateAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to set state on (leave empty for parent)")
		_add_string_field(container, "State Name:", action, "state_name",
			"Metadata key for the state (e.g., state, phase, mode)")
		if action.operation == ESStateAction.StateOp.SET:
			_add_string_field(container, "State Value:", action, "state_value",
				"e.g., player_turn, phase_2, powered_up, game_over")

	elif action is ESClampAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to clamp (leave empty for parent, or $collider)")
		_add_string_field(container, "Property Name:", action, "property_name",
			"e.g., position.x, position.y, health, scale.x")
		_add_float_field(container, "Min Value:", action, "min_value")
		_add_float_field(container, "Max Value:", action, "max_value")

	elif action is ESWaitAction:
		_add_float_field(container, "Wait Time (seconds):", action, "wait_time")

	elif action is ESVariableAction:
		_add_string_field(container, "Variable Name:", action, "variable_name",
			"Name for this variable (e.g., score, health, level)")
		_add_enum_field(container, "Operation:", action, "operation",
			["Set", "Add", "Subtract", "Multiply", "Toggle", "Append", "Remove", "Clear Array", "Divide"])
		_add_enum_field(container, "Scope:", action, "scope",
			["Local (this controller)", "Global (survives scene changes)"])
		if action.operation not in [ESVariableAction.VariableOp.TOGGLE,
				ESVariableAction.VariableOp.CLEAR_ARRAY]:
			_add_string_field(container, "Value:", action, "value",
				"Value to set/add/subtract/multiply/divide/append/remove (number, string, or true/false)")

	elif action is ESCallMethodAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to call the method on (leave empty for parent, or $collider)")
		_add_string_field(container, "Method Name:", action, "method_name",
			"Name of the method to call (e.g., take_damage, die, queue_free)")
		_add_string_array_field(container, "Arguments:", action, "arguments",
			"Method arguments (comma-separated)")
		_add_bool_field(container, "Use Deferred:", action, "use_deferred")

	elif action is ESRepeatAction:
		_add_int_field(container, "Repeat Count:", action, "repeat_count")

	elif action is ESMathAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to apply math to (leave empty for parent)")
		_add_string_field(container, "Property Name:", action, "property_name",
			"e.g., speed, scale.x, health")
		_add_enum_field(container, "Operation:", action, "operation",
			["abs", "floor", "ceil", "round", "sqrt", "sin", "cos", "lerp"])
		if action.operation == ESMathAction.MathOp.LERP:
			_add_float_field(container, "Lerp Target:", action, "lerp_target")
			_add_float_field(container, "Lerp Weight (0–1):", action, "lerp_weight")


# -- Field Helpers (same pattern as condition_dialog.gd) --

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
	# Dot notation (e.g., velocity.x): parent property determines component type.
	var parent_prop := parts[0]
	if not (parent_prop in node):
		return TYPE_NIL
	var parent_val = node.get(parent_prop)
	# Vector2, Vector3, and Color components are always float.
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
	edit.text_changed.connect(func(new_text: String): obj.set(prop, new_text))
	hbox.add_child(edit)


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


func _add_float_field(container: VBoxContainer, label_text: String, obj: Object,
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
	spin.value = obj.get(prop)
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(func(val: float): obj.set(prop, val))
	hbox.add_child(spin)


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
	spin.value_changed.connect(func(val: float): obj.set(prop, int(val)))
	hbox.add_child(spin)


func _add_bool_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)
	var check := CheckBox.new()
	check.text = label_text
	check.button_pressed = obj.get(prop)
	check.toggled.connect(func(val: bool): obj.set(prop, val))
	hbox.add_child(check)


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
	option_btn.item_selected.connect(func(idx: int): obj.set(prop, idx))
	hbox.add_child(option_btn)


func _add_vector2_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	hbox.add_child(label)

	var current: Vector2 = obj.get(prop)

	var x_label := Label.new()
	x_label.text = "X:"
	hbox.add_child(x_label)
	var x_spin := SpinBox.new()
	x_spin.min_value = -99999
	x_spin.max_value = 99999
	x_spin.value = current.x
	x_spin.value_changed.connect(func(val: float):
		var v: Vector2 = obj.get(prop)
		v.x = val
		obj.set(prop, v)
	)
	hbox.add_child(x_spin)

	var y_label := Label.new()
	y_label.text = "Y:"
	hbox.add_child(y_label)
	var y_spin := SpinBox.new()
	y_spin.min_value = -99999
	y_spin.max_value = 99999
	y_spin.value = current.y
	y_spin.value_changed.connect(func(val: float):
		var v: Vector2 = obj.get(prop)
		v.y = val
		obj.set(prop, v)
	)
	hbox.add_child(y_spin)


func _add_string_array_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String, hint: String = "") -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	hbox.add_child(label)
	var edit := LineEdit.new()
	var arr: PackedStringArray = obj.get(prop)
	edit.text = ", ".join(arr)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.placeholder_text = hint
	edit.text_changed.connect(func(new_text: String):
		var parts := new_text.split(",")
		var result := PackedStringArray()
		for part in parts:
			var trimmed := part.strip_edges()
			if not trimmed.is_empty():
				result.append(trimmed)
		obj.set(prop, result)
	)
	hbox.add_child(edit)


## Add a direction dropdown for movement actions (TRANSLATE / SET_VELOCITY).
## Selecting a preset auto-fills the action's x and y properties.
func _add_direction_dropdown(container: VBoxContainer, action: ESMoveAction) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)

	var dir_label := Label.new()
	dir_label.text = "Direction:"
	dir_label.custom_minimum_size.x = 150
	hbox.add_child(dir_label)

	var dropdown := OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for dir_name in DIRECTION_PRESETS:
		dropdown.add_item(dir_name)
	hbox.add_child(dropdown)

	# Custom X/Y row (shown only when "Custom (X/Y)" is selected).
	var xy_row := HBoxContainer.new()
	container.add_child(xy_row)

	var x_lbl := Label.new()
	x_lbl.text = "X:"
	xy_row.add_child(x_lbl)

	var x_spin := SpinBox.new()
	x_spin.min_value = -99999.0
	x_spin.max_value = 99999.0
	x_spin.step = 0.1
	x_spin.value = action.x
	x_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	x_spin.value_changed.connect(func(val: float): action.x = val)
	xy_row.add_child(x_spin)

	var y_lbl := Label.new()
	y_lbl.text = "Y:"
	xy_row.add_child(y_lbl)

	var y_spin := SpinBox.new()
	y_spin.min_value = -99999.0
	y_spin.max_value = 99999.0
	y_spin.step = 0.1
	y_spin.value = action.y
	y_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	y_spin.value_changed.connect(func(val: float): action.y = val)
	xy_row.add_child(y_spin)

	# Determine which preset matches the current x/y (if any).
	var preset_names := DIRECTION_PRESETS.keys()
	var custom_idx := preset_names.size() - 1  # "Custom (X/Y)" is last.
	var initial_idx := custom_idx
	var current_dir := Vector2(action.x, action.y)
	for i in range(preset_names.size() - 1):
		var dir: Vector2 = DIRECTION_PRESETS[preset_names[i]]
		if current_dir.is_equal_approx(dir):
			initial_idx = i
			break
	dropdown.selected = initial_idx
	xy_row.visible = (initial_idx == custom_idx)

	dropdown.item_selected.connect(func(idx: int):
		var name_key: String = preset_names[idx]
		if name_key == "Custom (X/Y)":
			xy_row.visible = true
		else:
			var dir: Vector2 = DIRECTION_PRESETS[name_key]
			action.x = dir.x
			action.y = dir.y
			x_spin.value = dir.x
			y_spin.value = dir.y
			xy_row.visible = false
	)


## Build node path + property name fields for ESSetPropertyAction with
## a cascading property dropdown that updates when the node changes.
func _add_node_and_property_fields_action(container: VBoxContainer,
		action: ESSetPropertyAction) -> void:
	# Property dropdown — built here, populated after node is known.
	var prop_dropdown := OptionButton.new()
	var prop_custom_edit := LineEdit.new()

	_add_node_path_field(container, "Target Node:", action, "target_path",
		"Node to modify (leave empty for parent, or $collider)",
		func(new_path: String):
			_populate_property_dropdown(prop_dropdown, prop_custom_edit, new_path, action, "property_name")
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

	prop_custom_edit.placeholder_text = "e.g., position.x, visible, modulate.a"
	prop_custom_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prop_col.add_child(prop_custom_edit)

	# Initial population based on current node path.
	_populate_property_dropdown(prop_dropdown, prop_custom_edit,
		str(action.target_path), action, "property_name")


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
