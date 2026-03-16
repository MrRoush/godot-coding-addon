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
			{"label": "UI: Button Pressed", "key": "ui_button_pressed"},
		]
	},
	{
		"label": "⏱ Lifecycle",
		"items": [
			{"label": "Lifecycle: Every Frame", "key": "lifecycle_process"},
			{"label": "Lifecycle: Every Physics Frame", "key": "lifecycle_physics"},
			{"label": "Lifecycle: On Ready (once)", "key": "lifecycle_ready"},
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
		"label": "📡 Signals & Properties",
		"items": [
			{"label": "Signal: Signal Received", "key": "signal_received"},
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
	"Lifecycle: On Ready": "lifecycle_ready",
	"Lifecycle: Every Frame": "lifecycle_process",
	"Lifecycle: Every Physics Frame": "lifecycle_physics",
	"Physics: Is On Floor": "physics_on_floor",
	"Physics: Is On Wall": "physics_on_wall",
	"Physics: Is On Ceiling": "physics_on_ceiling",
	"Physics: Is Moving": "physics_is_moving",
	"Physics: Is Stopped": "physics_is_stopped",
	"Physics: Is Falling": "physics_is_falling",
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
			["Just Pressed", "Just Released", "Is Held", "Any Key Pressed", "Any Key Released"])
		# Only show action/key field for specific key conditions.
		if condition.input_type < ESInputCondition.InputType.ANY_JUST_PRESSED:
			_add_string_field(container, "Action or Key Name:", condition, "action_or_key",
				"Enter an input action (e.g., ui_up, ui_accept) or key name (e.g., W, Space, Up)")

	elif condition is ESCollisionCondition:
		_add_node_path_field(container, "Detector Node:", condition, "detector_path",
			"Path to the Area2D/Area3D node (leave empty for parent)")
		_add_string_field(container, "Filter Group:", condition, "filter_group",
			"Only trigger for nodes in this group (leave empty for all)")

	elif condition is ESButtonCondition:
		_add_node_path_field(container, "Button Node:", condition, "button_path",
			"Path to the Button node to listen to (e.g., ../StartButton)")

	elif condition is ESSignalCondition:
		_add_node_path_field(container, "Source Node:", condition, "source_path",
			"Path to the node that emits the signal (leave empty for parent)")
		_add_string_field(container, "Signal Name:", condition, "signal_name",
			"The signal to listen for (e.g., health_changed)")

	elif condition is ESPropertyCondition:
		_add_node_and_property_fields_condition(container, condition)
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

	elif condition is ESPhysicsCondition:
		_add_node_path_field(container, "Target Node:", condition, "node_path",
			"Path to CharacterBody2D/3D (leave empty for parent)")
		_add_enum_field(container, "Physics Check:", condition, "physics_check",
			["Is On Floor", "Is On Wall", "Is On Ceiling", "Is Moving", "Is Stopped", "Is Falling"])


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
## Returns a Callable that, when called with a new path String, updates the field.
func _add_node_path_field(container: VBoxContainer, label_text: String, obj: Object,
		prop: String, hint: String = "", on_path_changed: Callable = Callable()) -> void:
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

		# Populate.
		var nodes := _get_scene_nodes()
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

	var common := PackedStringArray()
	var exports := PackedStringArray()
	if node:
		common = PropertyHints.get_properties_for_node(node)
		exports = PropertyHints.get_custom_exports(node)

	var current_prop: String = str(obj.get(prop))
	var selected_idx := 0
	var found_in_list := false

	var idx := 0
	for p in common:
		dropdown.add_item(p)
		if p == current_prop:
			selected_idx = idx
			found_in_list = true
		idx += 1

	if exports.size() > 0:
		if common.size() > 0:
			dropdown.add_separator()
			idx += 1
		for p in exports:
			dropdown.add_item(p)
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
		obj.set(prop, item_text)


## Walk the scene tree from the controller's owner and return node info entries.
func _get_scene_nodes() -> Array:
	var result := []
	if not _controller or not is_instance_valid(_controller):
		return result

	var scene_root: Node = _controller.owner if _controller.owner else _controller.get_parent()
	if not scene_root:
		return result

	_walk_scene_tree(scene_root, result)
	return result


func _walk_scene_tree(node: Node, result: Array) -> void:
	if not is_instance_valid(_controller):
		return
	if node == _controller:
		for child in node.get_children():
			_walk_scene_tree(child, result)
		return

	var path_to_node: NodePath = _controller.get_path_to(node)
	var type_name := node.get_class()
	result.append({
		"path": str(path_to_node),
		"display": "%s (%s)" % [str(path_to_node), type_name],
	})

	for child in node.get_children():
		_walk_scene_tree(child, result)
