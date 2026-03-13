@tool
extends EditorPlugin
## Main plugin entry point for the Godot Event Sheet addon.
## Registers custom types, adds the Event Sheet editor panel,
## and manages the addon lifecycle.

const EventController := preload("res://addons/godot_event_sheet/runtime/event_controller.gd")
const EventSheetEditor := preload("res://addons/godot_event_sheet/editor/event_sheet_editor.gd")

var _editor_panel: Control = null


func _enter_tree() -> void:
	# Register custom resource types so they appear in the inspector.
	add_custom_type(
		"EventSheet",
		"Resource",
		preload("res://addons/godot_event_sheet/core/event_sheet.gd"),
		preload("res://addons/godot_event_sheet/icons/icon.svg")
	)
	add_custom_type(
		"EventController",
		"Node",
		EventController,
		preload("res://addons/godot_event_sheet/icons/icon.svg")
	)

	# Create and add the bottom panel editor.
	_editor_panel = EventSheetEditor.new()
	_editor_panel.editor_interface = get_editor_interface()
	_editor_panel.undo_redo = get_undo_redo()
	add_control_to_bottom_panel(_editor_panel, "Event Sheet")


func _exit_tree() -> void:
	if _editor_panel:
		remove_control_from_bottom_panel(_editor_panel)
		_editor_panel.queue_free()
		_editor_panel = null

	remove_custom_type("EventSheet")
	remove_custom_type("EventController")


func _handles(object: Object) -> bool:
	if object is Node:
		var script := object.get_script()
		if script == EventController:
			return true
	return false


func _edit(object: Object) -> void:
	if object is Node and _editor_panel:
		_editor_panel.edit_controller(object)


func _make_visible(visible: bool) -> void:
	if _editor_panel:
		_editor_panel.visible = visible
