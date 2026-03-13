@tool
extends ConfirmationDialog
## Dialog for picking a new action type or editing an existing action.

var _action_list: ItemList
var _property_editor: VBoxContainer
var _selected_action: ESAction = null
var _editing_action: ESAction = null

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

# Action type registry.
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
	"Debug: Print Message": "debug_print",
}


## Create a picker dialog for selecting a new action type.
static func create_picker() -> ConfirmationDialog:
	var dialog := preload("res://addons/godot_event_sheet/editor/action_dialog.gd").new()
	dialog.title = "Add Action"
	dialog._build_picker_ui()
	return dialog


## Create an editor dialog for modifying an existing action.
static func create_editor(action: ESAction) -> ConfirmationDialog:
	var dialog := preload("res://addons/godot_event_sheet/editor/action_dialog.gd").new()
	dialog.title = "Edit Action"
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

	_action_list = ItemList.new()
	_action_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_action_list.custom_minimum_size = Vector2(0, 250)
	vbox.add_child(_action_list)

	_property_editor = VBoxContainer.new()
	vbox.add_child(_property_editor)

	var idx := 0
	for type_name in ACTION_TYPES:
		_action_list.add_item(type_name)
		idx += 1

	_action_list.item_selected.connect(_on_action_type_selected)


## When an action type is selected, show its properties.
func _on_action_type_selected(index: int) -> void:
	var type_name := _action_list.get_item_text(index)
	var type_key: String = ACTION_TYPES[type_name]

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
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to modify (leave empty for parent, or $collider)")
		_add_string_field(container, "Property Name:", action, "property_name",
			"e.g., position.x, visible, modulate.a, scale.x")
		_add_string_field(container, "Value:", action, "value",
			"Value to set/add. Use {../Node:prop} for live values, e.g., Health: {../Player:health}")
		_add_enum_field(container, "Mode:", action, "set_mode",
			["Set", "Add", "Subtract", "Multiply", "Toggle"])

	elif action is ESEmitSignalAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node that emits the signal (leave empty for EventController)")
		_add_string_field(container, "Signal Name:", action, "signal_name",
			"Signal to emit (e.g., player_died, score_changed)")
		_add_string_array_field(container, "Arguments:", action, "arguments",
			"Signal arguments (comma-separated)")

	elif action is ESAnimationAction:
		_add_node_path_field(container, "Player Node:", action, "player_path",
			"AnimationPlayer or AnimatedSprite2D (leave empty to auto-find)")
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
					"Marker2D node — spawns at its position/rotation (overrides below)")
				_add_vector2_field(container, "Spawn Position:", action, "spawn_position")
				_add_bool_field(container, "Use Parent Position:", action, "use_parent_position")
			ESSceneAction.SceneOp.DESTROY, ESSceneAction.SceneOp.SHOW, ESSceneAction.SceneOp.HIDE:
				_add_node_path_field(container, "Target Node:", action, "destroy_target_path",
					"Node to target (leave empty for parent, or $collider)")
			ESSceneAction.SceneOp.CHANGE_SCENE:
				_add_string_field(container, "Scene Path:", action, "scene_path",
					"res://path/to/next_scene.tscn")

	elif action is ESSoundAction:
		_add_node_path_field(container, "Audio Player:", action, "player_path",
			"AudioStreamPlayer node (leave empty to auto-find)")
		if action.operation == ESSoundAction.SoundOp.PLAY:
			_add_string_field(container, "Audio File:", action, "audio_path",
				"res://path/to/sound.ogg (optional)")
			_add_float_field(container, "Volume (dB):", action, "volume_db")

	elif action is ESPrintAction:
		_add_string_field(container, "Message:", action, "message",
			"Use {name}, {position}, {delta} as placeholders")
		_add_bool_field(container, "Show as Warning:", action, "as_warning")


# -- Field Helpers (same pattern as condition_dialog.gd) --

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
	edit.text_changed.connect(func(new_text: String): obj.set(prop, NodePath(new_text)))
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
		var name_key := preset_names[idx]
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
