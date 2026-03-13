extends Node
## Example: Timer events and property manipulation with the Event Sheet addon.
##
## This demonstrates periodic events using timers and how to read/modify
## node properties — useful for game mechanics like health bars, scoring,
## and visual effects.
##
## Scene Setup:
##   Sprite2D ("Player")
##     └── EventController  ← assign EventSheet here
##
## The Event Sheet configuration is equivalent to:
##   var timer := Timer.new()
##   func _ready():
##       timer.wait_time = 2.0
##       timer.timeout.connect(_on_timer)
##       add_child(timer)
##       timer.start()
##       print("Game started!")
##
##   func _on_timer():
##       rotation += 0.5
##       print("Rotated! Current rotation: ", rotation)
##
##   func _process(delta):
##       if position.x > 500:
##           position.x = 0


func create_timer_property_sheet() -> ESEventSheet:
	var sheet := ESEventSheet.new()
	sheet.sheet_name = "Timers & Properties"

	# --- Event 1: On Ready - print a welcome message ---
	var event_ready := ESEventItem.new()
	event_ready.event_name = "Game Start"

	var cond_ready := ESLifecycleCondition.new()
	cond_ready.lifecycle_type = ESLifecycleCondition.LifecycleType.READY
	event_ready.add_condition(cond_ready)

	var action_welcome := ESPrintAction.new()
	action_welcome.message = "Game started! {name} is at {position}"
	event_ready.add_action(action_welcome)

	sheet.events.append(event_ready)

	# --- Event 2: Every 2 seconds, rotate the sprite ---
	var event_timer := ESEventItem.new()
	event_timer.event_name = "Rotate Periodically"

	var cond_timer := ESTimerCondition.new()
	cond_timer.wait_time = 2.0
	cond_timer.one_shot = false
	event_timer.add_condition(cond_timer)

	# Action: Add to rotation.
	var action_rotate := ESSetPropertyAction.new()
	action_rotate.property_name = "rotation"
	action_rotate.value = "0.5"
	action_rotate.set_mode = ESSetPropertyAction.SetMode.ADD
	event_timer.add_action(action_rotate)

	# Action: Print debug info.
	var action_print := ESPrintAction.new()
	action_print.message = "Rotated! {name} at {position}"
	event_timer.add_action(action_print)

	sheet.events.append(event_timer)

	# --- Event 3: Wrap position when going off-screen ---
	var event_wrap := ESEventItem.new()
	event_wrap.event_name = "Wrap Position"

	# Condition: Check if position.x > 500.
	var cond_offscreen := ESPropertyCondition.new()
	cond_offscreen.property_name = "position.x"
	cond_offscreen.compare_op = ESPropertyCondition.CompareOp.GREATER
	cond_offscreen.compare_value = "500"
	event_wrap.add_condition(cond_offscreen)

	# Action: Reset position.x to 0.
	var action_reset := ESSetPropertyAction.new()
	action_reset.property_name = "position.x"
	action_reset.value = "0"
	action_reset.set_mode = ESSetPropertyAction.SetMode.SET
	event_wrap.add_action(action_reset)

	sheet.events.append(event_wrap)

	return sheet
