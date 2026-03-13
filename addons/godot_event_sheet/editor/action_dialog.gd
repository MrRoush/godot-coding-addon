@tool
extends ConfirmationDialog
## Dialog for picking a new action type or editing an existing action.

var _action_list: ItemList
var _property_editor: VBoxContainer
var _selected_action: ESAction = null
var _editing_action: ESAction = null

# Action type registry.
const ACTION_TYPES := {
	"Movement: Translate (Move)": "move_translate",
	"Movement: Set Position": "move_set_position",
	"Movement: Move Toward": "move_toward",
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
			"Node to move (leave empty for parent)")
		_add_float_field(container, "X:", action, "x")
		_add_float_field(container, "Y:", action, "y")
		_add_float_field(container, "Speed:", action, "speed")
		_add_bool_field(container, "Use Delta Time:", action, "use_delta")

	elif action is ESSetPropertyAction:
		_add_node_path_field(container, "Target Node:", action, "target_path",
			"Node to modify (leave empty for parent)")
		_add_string_field(container, "Property Name:", action, "property_name",
			"e.g., position.x, visible, modulate.a, scale.x")
		_add_string_field(container, "Value:", action, "value",
			"Value to set/add/subtract/multiply")
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
		if action.operation == ESSceneAction.SceneOp.INSTANTIATE:
			_add_string_field(container, "Scene Path:", action, "scene_path",
				"res://path/to/scene.tscn")
			_add_node_path_field(container, "Parent Node:", action, "parent_path",
				"Where to add the instance (leave empty for scene root)")
			_add_vector2_field(container, "Spawn Position:", action, "spawn_position")
			_add_bool_field(container, "Use Parent Position:", action, "use_parent_position")
		else:
			_add_node_path_field(container, "Destroy Target:", action, "destroy_target_path",
				"Node to destroy (leave empty for parent)")

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
