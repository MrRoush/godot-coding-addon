@tool
extends VBoxContainer
## Main Event Sheet editor panel that appears in the Godot editor's bottom panel.
## Provides a visual interface for creating and editing events, conditions, and actions.

var editor_interface: EditorInterface = null
var undo_redo: EditorUndoRedoManager = null

var _current_controller: Node = null
var _current_sheet: ESEventSheet = null

# UI references.
var _toolbar: HBoxContainer
var _scroll: ScrollContainer
var _events_container: VBoxContainer
var _no_sheet_label: Label
var _sheet_name_edit: LineEdit

const _NO_SHEET_TEXT := "Select an EventController node to edit its Event Sheet.\n\nTo get started:\n1. Add an EventController node as a child of your game object\n2. Create a new EventSheet resource in the Inspector\n3. Click the EventController to open this editor"

# Preloaded dialog scripts.
const ConditionDialog := preload("res://addons/godot_event_sheet/editor/condition_dialog.gd")
const ActionDialog := preload("res://addons/godot_event_sheet/editor/action_dialog.gd")


func _ready() -> void:
	_build_ui()
	_refresh()


## Called by the plugin when an EventController is selected.
func edit_controller(controller: Node) -> void:
	_current_controller = controller
	if controller and "event_sheet" in controller:
		_current_sheet = controller.get("event_sheet") as ESEventSheet
	else:
		_current_sheet = null
	_refresh()


## Build the entire editor UI programmatically.
func _build_ui() -> void:
	name = "EventSheetEditor"
	custom_minimum_size = Vector2(0, 300)

	# -- Toolbar --
	_toolbar = HBoxContainer.new()
	_toolbar.add_theme_constant_override("separation", 8)
	add_child(_toolbar)

	# Sheet name.
	var name_label := Label.new()
	name_label.text = "Event Sheet:"
	_toolbar.add_child(name_label)

	_sheet_name_edit = LineEdit.new()
	_sheet_name_edit.placeholder_text = "Sheet Name"
	_sheet_name_edit.custom_minimum_size.x = 200
	_sheet_name_edit.text_submitted.connect(_on_sheet_name_changed)
	_toolbar.add_child(_sheet_name_edit)

	# Spacer.
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toolbar.add_child(spacer)

	# Add Event button.
	var add_event_btn := Button.new()
	add_event_btn.text = "+ Add Event"
	add_event_btn.tooltip_text = "Add a new event to the sheet"
	add_event_btn.pressed.connect(_on_add_event)
	_toolbar.add_child(add_event_btn)

	# Separator.
	var sep := HSeparator.new()
	add_child(sep)

	# -- No sheet label --
	_no_sheet_label = Label.new()
	_no_sheet_label.text = _NO_SHEET_TEXT
	_no_sheet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_no_sheet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_no_sheet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_no_sheet_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_no_sheet_label)

	# -- Scroll container for events --
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_scroll)

	_events_container = VBoxContainer.new()
	_events_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_events_container)


## Refresh the editor to reflect the current sheet state.
func _refresh() -> void:
	if not is_inside_tree():
		return

	var has_sheet: bool = _current_sheet != null

	_no_sheet_label.visible = not has_sheet
	_scroll.visible = has_sheet
	_toolbar.visible = has_sheet

	if not has_sheet:
		return

	_sheet_name_edit.text = _current_sheet.sheet_name

	# Clear existing event rows.
	for child in _events_container.get_children():
		child.queue_free()

	# Build event rows.
	for i in range(_current_sheet.events.size()):
		var event := _current_sheet.events[i] as ESEventItem
		if event:
			var row := _create_event_row(event, i)
			_events_container.add_child(row)


## Create a visual row for a single event.
func _create_event_row(event: ESEventItem, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.20, 0.25, 1.0) if index % 2 == 0 else Color(0.15, 0.17, 0.22, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	panel.add_child(main_vbox)

	# -- Event header --
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	main_vbox.add_child(header)

	# Enable checkbox.
	var enabled_check := CheckBox.new()
	enabled_check.button_pressed = event.enabled
	enabled_check.tooltip_text = "Enable/Disable this event"
	enabled_check.toggled.connect(func(toggled: bool):
		event.enabled = toggled
		_current_sheet.emit_changed()
	)
	header.add_child(enabled_check)

	# Event name.
	var name_edit := LineEdit.new()
	name_edit.text = event.event_name
	name_edit.placeholder_text = "Event Name"
	name_edit.custom_minimum_size.x = 200
	name_edit.text_submitted.connect(func(new_text: String):
		event.event_name = new_text
		_current_sheet.emit_changed()
	)
	header.add_child(name_edit)

	# Spacer.
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	# Move up button.
	var move_up_btn := Button.new()
	move_up_btn.text = "▲"
	move_up_btn.tooltip_text = "Move event up"
	move_up_btn.disabled = index == 0
	move_up_btn.pressed.connect(func():
		_current_sheet.move_event(index, index - 1)
		_refresh()
	)
	header.add_child(move_up_btn)

	# Move down button.
	var move_down_btn := Button.new()
	move_down_btn.text = "▼"
	move_down_btn.tooltip_text = "Move event down"
	move_down_btn.disabled = index >= _current_sheet.events.size() - 1
	move_down_btn.pressed.connect(func():
		_current_sheet.move_event(index, index + 1)
		_refresh()
	)
	header.add_child(move_down_btn)

	# Delete button.
	var delete_btn := Button.new()
	delete_btn.text = "✕"
	delete_btn.tooltip_text = "Delete this event"
	delete_btn.pressed.connect(func():
		_current_sheet.remove_event(index)
		_refresh()
	)
	header.add_child(delete_btn)

	# -- Conditions & Actions columns --
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	main_vbox.add_child(columns)

	# Conditions column.
	var cond_column := _create_conditions_column(event, index)
	cond_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(cond_column)

	# Vertical separator.
	var vsep := VSeparator.new()
	columns.add_child(vsep)

	# Actions column.
	var action_column := _create_actions_column(event, index)
	action_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(action_column)

	return panel


## Create the conditions column for an event.
func _create_conditions_column(event: ESEventItem, event_index: int) -> VBoxContainer:
	var vbox := VBoxContainer.new()

	# Header.
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var label := Label.new()
	label.text = "📋 Conditions (ALL must be true)"
	label.add_theme_font_size_override("font_size", 13)
	header.add_child(label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var add_btn := Button.new()
	add_btn.text = "+ Condition"
	add_btn.pressed.connect(func(): _show_condition_dialog(event))
	header.add_child(add_btn)

	# List conditions.
	for i in range(event.conditions.size()):
		var cond := event.conditions[i] as ESCondition
		if cond:
			var row := _create_condition_row(cond, event, i)
			vbox.add_child(row)

	if event.conditions.size() == 0:
		var empty := Label.new()
		empty.text = "  (no conditions - click + to add)"
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(empty)

	return vbox


## Create a row for a single condition.
func _create_condition_row(cond: ESCondition, event: ESEventItem, cond_index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	# Condition icon/type.
	var type_label := Label.new()
	type_label.text = "  ▸ "
	row.add_child(type_label)

	# Summary.
	var summary := Label.new()
	summary.text = cond.get_summary()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.clip_text = true
	row.add_child(summary)

	# Edit button.
	var edit_btn := Button.new()
	edit_btn.text = "✎"
	edit_btn.tooltip_text = "Edit condition"
	edit_btn.pressed.connect(func(): _show_condition_edit_dialog(cond, event, cond_index))
	row.add_child(edit_btn)

	# Delete button.
	var del_btn := Button.new()
	del_btn.text = "✕"
	del_btn.tooltip_text = "Remove condition"
	del_btn.pressed.connect(func():
		event.remove_condition(cond_index)
		_refresh()
	)
	row.add_child(del_btn)

	return row


## Create the actions column for an event.
func _create_actions_column(event: ESEventItem, event_index: int) -> VBoxContainer:
	var vbox := VBoxContainer.new()

	# Header.
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var label := Label.new()
	label.text = "⚡ Actions (executed in order)"
	label.add_theme_font_size_override("font_size", 13)
	header.add_child(label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var add_btn := Button.new()
	add_btn.text = "+ Action"
	add_btn.pressed.connect(func(): _show_action_dialog(event))
	header.add_child(add_btn)

	# List actions.
	for i in range(event.actions.size()):
		var action := event.actions[i] as ESAction
		if action:
			var row := _create_action_row(action, event, i)
			vbox.add_child(row)

	if event.actions.size() == 0:
		var empty := Label.new()
		empty.text = "  (no actions - click + to add)"
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(empty)

	return vbox


## Create a row for a single action.
func _create_action_row(action: ESAction, event: ESEventItem, action_index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	# Action icon.
	var type_label := Label.new()
	type_label.text = "  ▸ "
	row.add_child(type_label)

	# Summary.
	var summary := Label.new()
	summary.text = action.get_summary()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.clip_text = true
	row.add_child(summary)

	# Edit button.
	var edit_btn := Button.new()
	edit_btn.text = "✎"
	edit_btn.tooltip_text = "Edit action"
	edit_btn.pressed.connect(func(): _show_action_edit_dialog(action, event, action_index))
	row.add_child(edit_btn)

	# Delete button.
	var del_btn := Button.new()
	del_btn.text = "✕"
	del_btn.tooltip_text = "Remove action"
	del_btn.pressed.connect(func():
		event.remove_action(action_index)
		_refresh()
	)
	row.add_child(del_btn)

	return row


# -- Event Management --

func _on_add_event() -> void:
	if not _current_sheet:
		return
	_current_sheet.add_event()
	_refresh()


func _on_sheet_name_changed(new_name: String) -> void:
	if _current_sheet:
		_current_sheet.sheet_name = new_name
		_current_sheet.emit_changed()


# -- Condition Dialogs --

func _show_condition_dialog(event: ESEventItem) -> void:
	var dialog := ConditionDialog.create_picker()
	add_child(dialog)
	dialog.popup_centered(Vector2i(500, 400))
	dialog.confirmed.connect(func():
		var cond: ESCondition = dialog.get_selected_condition()
		if cond:
			event.add_condition(cond)
			_refresh()
	)


func _show_condition_edit_dialog(cond: ESCondition, event: ESEventItem, index: int) -> void:
	var dialog := ConditionDialog.create_editor(cond)
	add_child(dialog)
	dialog.popup_centered(Vector2i(500, 400))
	dialog.confirmed.connect(func():
		_current_sheet.emit_changed()
		_refresh()
	)


# -- Action Dialogs --

func _show_action_dialog(event: ESEventItem) -> void:
	var dialog := ActionDialog.create_picker()
	add_child(dialog)
	dialog.popup_centered(Vector2i(500, 400))
	dialog.confirmed.connect(func():
		var action: ESAction = dialog.get_selected_action()
		if action:
			event.add_action(action)
			_refresh()
	)


func _show_action_edit_dialog(action: ESAction, event: ESEventItem, index: int) -> void:
	var dialog := ActionDialog.create_editor(action)
	add_child(dialog)
	dialog.popup_centered(Vector2i(500, 400))
	dialog.confirmed.connect(func():
		_current_sheet.emit_changed()
		_refresh()
	)
