@tool
extends ConfirmationDialog
## Dialog for picking a new condition type or editing an existing condition.

var _condition_list: ItemList
var _property_editor: VBoxContainer
var _selected_condition: ESCondition = null
var _editing_condition: ESCondition = null

# Condition type registry.
const CONDITION_TYPES := {
	"Input: Key/Action Pressed": "input_pressed",
	"Input: Key/Action Released": "input_released",
	"Input: Key/Action Held": "input_held",
	"Collision: Body Entered": "collision_body_entered",
	"Collision: Body Exited": "collision_body_exited",
	"Collision: Area Entered": "collision_area_entered",
	"Collision: Area Exited": "collision_area_exited",
	"Signal: Signal Received": "signal_received",
	"Property: Compare Value": "property_compare",
	"Timer: Repeating Timer": "timer_repeat",
	"Timer: One-Shot Delay": "timer_oneshot",
	"Lifecycle: On Ready": "lifecycle_ready",
	"Lifecycle: Every Frame": "lifecycle_process",
	"Lifecycle: Every Physics Frame": "lifecycle_physics",
}


## Create a picker dialog for selecting a new condition type.
static func create_picker() -> ConfirmationDialog:
	var dialog := preload("res://addons/godot_event_sheet/editor/condition_dialog.gd").new()
	dialog.title = "Add Condition"
	dialog._build_picker_ui()
	return dialog


## Create an editor dialog for modifying an existing condition.
static func create_editor(condition: ESCondition) -> ConfirmationDialog:
	var dialog := preload("res://addons/godot_event_sheet/editor/condition_dialog.gd").new()
	dialog.title = "Edit Condition"
	dialog._editing_condition = condition
	dialog._build_editor_ui(condition)
	return dialog


## Get the condition created/selected by the dialog.
func get_selected_condition() -> ESCondition:
	return _selected_condition


## Build the picker UI (list of condition types to choose from).
func _build_picker_ui() -> void:
	var vbox := VBoxContainer.new()
	add_child(vbox)

	var label := Label.new()
	label.text = "Select a condition type:"
	vbox.add_child(label)

	_condition_list = ItemList.new()
	_condition_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_condition_list.custom_minimum_size = Vector2(0, 250)
	vbox.add_child(_condition_list)

	# Property editor area (shown when a type is selected).
	_property_editor = VBoxContainer.new()
	vbox.add_child(_property_editor)

	# Populate list.
	var idx := 0
	for type_name in CONDITION_TYPES:
		_condition_list.add_item(type_name)
		idx += 1

	_condition_list.item_selected.connect(_on_condition_type_selected)


## When a condition type is selected, show its properties.
func _on_condition_type_selected(index: int) -> void:
	var type_name := _condition_list.get_item_text(index)
	var type_key: String = CONDITION_TYPES[type_name]

	# Clear previous properties.
	for child in _property_editor.get_children():
		child.queue_free()

	# Create the condition and show its properties.
	_selected_condition = _create_condition_from_key(type_key)
	if _selected_condition:
		_build_property_fields(_property_editor, _selected_condition)


## Create a condition resource from a type key.
func _create_condition_from_key(key: String) -> ESCondition:
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

	_build_property_fields(vbox, condition)
	_selected_condition = condition


## Build property input fields for any condition type.
func _build_property_fields(container: VBoxContainer, condition: ESCondition) -> void:
	if condition is ESInputCondition:
		_add_string_field(container, "Action or Key Name:", condition, "action_or_key",
			"Enter an input action (e.g., ui_up, ui_accept) or key name (e.g., W, Space, Up)")
		_add_enum_field(container, "Input Type:", condition, "input_type",
			["Just Pressed", "Just Released", "Is Held"])

	elif condition is ESCollisionCondition:
		_add_node_path_field(container, "Detector Node:", condition, "detector_path",
			"Path to the Area2D/Area3D node (leave empty for parent)")
		_add_string_field(container, "Filter Group:", condition, "filter_group",
			"Only trigger for nodes in this group (leave empty for all)")

	elif condition is ESSignalCondition:
		_add_node_path_field(container, "Source Node:", condition, "source_path",
			"Path to the node that emits the signal (leave empty for parent)")
		_add_string_field(container, "Signal Name:", condition, "signal_name",
			"The signal to listen for (e.g., health_changed)")

	elif condition is ESPropertyCondition:
		_add_node_path_field(container, "Target Node:", condition, "node_path",
			"Path to the node (leave empty for parent)")
		_add_string_field(container, "Property Name:", condition, "property_name",
			"Property to check (e.g., position.x, health, visible)")
		_add_enum_field(container, "Comparison:", condition, "compare_op",
			["== (Equal)", "!= (Not Equal)", "> (Greater)", "< (Less)", ">= (Greater/Equal)", "<= (Less/Equal)"])
		_add_string_field(container, "Compare Value:", condition, "compare_value",
			"Value to compare against")

	elif condition is ESTimerCondition:
		_add_float_field(container, "Wait Time (seconds):", condition, "wait_time")
		_add_bool_field(container, "One-Shot:", condition, "one_shot")

	elif condition is ESLifecycleCondition:
		_add_enum_field(container, "Event Type:", condition, "lifecycle_type",
			["On Ready (once)", "Every Frame", "Every Physics Frame"])


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
	edit.text_changed.connect(func(new_text: String):
		obj.set(prop, NodePath(new_text))
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
