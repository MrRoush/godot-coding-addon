class_name ESEventSheet
extends Resource
## The main Event Sheet resource that holds all events.
## Attach this to an EventController node to drive game logic visually.

## List of all events in this event sheet.
@export var events: Array[Resource] = []  # Array of ESEventItem

## Custom signal names defined in this event sheet.
## These signals will be registered on the EventController at runtime.
@export var custom_signals: PackedStringArray = PackedStringArray()

## Human-readable name for this event sheet.
@export var sheet_name: String = "New Event Sheet"

## Whether this sheet is enabled.
@export var enabled: bool = true


## Add a new event to the sheet and return it.
func add_event() -> Resource:
	var item := ESEventItem.new()
	item.event_name = "Event %d" % (events.size() + 1)
	events.append(item)
	emit_changed()
	return item


## Remove an event at the given index.
func remove_event(index: int) -> void:
	if index >= 0 and index < events.size():
		events.remove_at(index)
		emit_changed()


## Move an event from one index to another.
func move_event(from: int, to: int) -> void:
	if from >= 0 and from < events.size() and to >= 0 and to < events.size():
		var item := events[from]
		events.remove_at(from)
		events.insert(to, item)
		emit_changed()
