class_name ESEventController
extends Node
## Runtime controller that evaluates an EventSheet's conditions and executes actions.
##
## Add this node as a child of any game object (e.g., CharacterBody2D, Area2D, Sprite2D).
## Assign an EventSheet resource, and the controller will automatically:
## - Register custom signals
## - Connect collision signals
## - Connect signal listeners
## - Create timers
## - Evaluate conditions every frame and execute matching actions
##
## This is the main node students interact with to add visual logic to their game objects.

## The EventSheet resource containing all events.
@export var event_sheet: ESEventSheet = null

## If true, print debug messages when events fire.
@export var debug_mode: bool = false

# Internal tracking.
var _process_events: Array = []
var _physics_events: Array = []
var _ready_events: Array = []
var _signal_events: Array = []  # Events triggered by signals/collisions/timers
var _initialized: bool = false


func _ready() -> void:
	if not event_sheet:
		if debug_mode:
			push_warning("EventSheet: No valid EventSheet assigned to %s" % name)
		return

	_setup_custom_signals()
	_categorize_events()
	_setup_connections()

	# Fire ready events.
	for cond in _get_all_conditions():
		if cond is ESLifecycleCondition:
			cond._on_ready()

	_initialized = true

	# Evaluate ready events immediately.
	_evaluate_events(_ready_events, 0.0)


func _process(delta: float) -> void:
	if not _initialized:
		return
	_evaluate_events(_process_events, delta)
	# Also check signal/collision/timer events during process.
	_evaluate_events(_signal_events, delta)
	_track_key_states()


func _physics_process(delta: float) -> void:
	if not _initialized:
		return
	_evaluate_events(_physics_events, delta)


## Register custom signals defined in the event sheet.
func _setup_custom_signals() -> void:
	var sheet := event_sheet as ESEventSheet
	for sig_name in sheet.custom_signals:
		if not has_user_signal(sig_name):
			add_user_signal(sig_name)
			if debug_mode:
				print("EventSheet: Registered custom signal '%s'" % sig_name)


## Sort events into categories based on their conditions.
func _categorize_events() -> void:
	var sheet := event_sheet as ESEventSheet
	if not sheet.enabled:
		return

	for event_res in sheet.events:
		var event := event_res as ESEventItem
		if not event or not event.enabled:
			continue

		var category := _determine_event_category(event)
		match category:
			"ready":
				_ready_events.append(event)
			"physics":
				_physics_events.append(event)
			"signal":
				_signal_events.append(event)
			_:
				_process_events.append(event)


## Determine which update loop an event belongs in.
func _determine_event_category(event: ESEventItem) -> String:
	for cond_res in event.conditions:
		var cond := cond_res as ESCondition
		if not cond:
			continue
		if cond is ESLifecycleCondition:
			match cond.lifecycle_type:
				ESLifecycleCondition.LifecycleType.READY:
					return "ready"
				ESLifecycleCondition.LifecycleType.PHYSICS_PROCESS:
					return "physics"
		# Signal, collision, timer, and button conditions are evaluated in _process.
		if cond is ESSignalCondition or cond is ESCollisionCondition \
				or cond is ESTimerCondition or cond is ESButtonCondition:
			return "signal"
	return "process"


## Set up all signal connections, collision listeners, and timers.
func _setup_connections() -> void:
	var sheet := event_sheet as ESEventSheet

	for event_res in sheet.events:
		var event := event_res as ESEventItem
		if not event or not event.enabled:
			continue

		for cond_res in event.conditions:
			var cond := cond_res as ESCondition
			if not cond:
				continue

			if cond is ESCollisionCondition:
				_connect_collision(cond)
			elif cond is ESSignalCondition:
				_connect_signal_condition(cond)
			elif cond is ESTimerCondition:
				_setup_timer(cond)
			elif cond is ESButtonCondition:
				_connect_button(cond)


## Connect collision signals from the detector node.
func _connect_collision(cond: ESCollisionCondition) -> void:
	var detector: Node
	if cond.detector_path.is_empty():
		detector = get_parent()
	else:
		detector = get_node_or_null(cond.detector_path)

	if not detector:
		push_warning("EventSheet: Collision detector node not found.")
		return

	# IS_OVERLAPPING connects both entered and exited to track overlapping nodes.
	if cond.collision_type == ESCollisionCondition.CollisionType.IS_OVERLAPPING:
		for sig_name in ["body_entered", "body_exited"]:
			if detector.has_signal(sig_name):
				var callback: Callable
				if sig_name == "body_entered":
					callback = cond._on_overlap_entered
				else:
					callback = cond._on_overlap_exited
				if not detector.is_connected(sig_name, callback):
					detector.connect(sig_name, callback)
					if debug_mode:
						print("EventSheet: Connected '%s' on %s (IS_OVERLAPPING)" % [sig_name, detector.name])
		return

	var signal_name: String
	match cond.collision_type:
		ESCollisionCondition.CollisionType.BODY_ENTERED:
			signal_name = "body_entered"
		ESCollisionCondition.CollisionType.BODY_EXITED:
			signal_name = "body_exited"
		ESCollisionCondition.CollisionType.AREA_ENTERED:
			signal_name = "area_entered"
		ESCollisionCondition.CollisionType.AREA_EXITED:
			signal_name = "area_exited"

	if detector.has_signal(signal_name):
		if not detector.is_connected(signal_name, cond._on_collision):
			detector.connect(signal_name, cond._on_collision)
			if debug_mode:
				print("EventSheet: Connected '%s' on %s" % [signal_name, detector.name])
	else:
		push_warning("EventSheet: Node '%s' does not have signal '%s'. Make sure it's an Area2D, Area3D, or similar." % [detector.name, signal_name])


## Connect a signal condition to the source node.
func _connect_signal_condition(cond: ESSignalCondition) -> void:
	var source: Node
	if cond.source_path.is_empty():
		source = get_parent()
	else:
		source = get_node_or_null(cond.source_path)

	if not source:
		push_warning("EventSheet: Signal source node not found for '%s'." % cond.signal_name)
		return

	if cond.signal_name.is_empty():
		push_warning("EventSheet: Signal condition has no signal name.")
		return

	# Add user signal if it doesn't exist.
	if not source.has_signal(cond.signal_name):
		source.add_user_signal(cond.signal_name)

	if not source.is_connected(cond.signal_name, cond._on_signal_received):
		source.connect(cond.signal_name, cond._on_signal_received)
		if debug_mode:
			print("EventSheet: Listening for signal '%s' on %s" % [cond.signal_name, source.name])


## Create a Timer for a timer condition.
func _setup_timer(cond: ESTimerCondition) -> void:
	var timer := Timer.new()
	timer.wait_time = cond.wait_time
	timer.one_shot = cond.one_shot
	timer.autostart = true
	timer.timeout.connect(cond._on_timer_timeout)
	add_child(timer)
	cond._timer = timer
	if debug_mode:
		print("EventSheet: Created timer (%.1fs, one_shot=%s)" % [cond.wait_time, cond.one_shot])


## Connect a Button node's "pressed" signal to the button condition.
func _connect_button(cond: ESButtonCondition) -> void:
	if cond.button_path.is_empty():
		push_warning("EventSheet: Button condition has no button path specified.")
		return
	var button := get_node_or_null(cond.button_path)
	if not button:
		push_warning("EventSheet: Button not found at path: %s" % cond.button_path)
		return
	if not button.has_signal("pressed"):
		push_warning("EventSheet: Node at '%s' does not have a 'pressed' signal." % cond.button_path)
		return
	if not button.is_connected("pressed", cond._on_button_pressed):
		button.connect("pressed", cond._on_button_pressed)
		if debug_mode:
			print("EventSheet: Connected button 'pressed' on %s" % button.name)


## Evaluate a list of events and execute actions for those whose conditions pass.
func _evaluate_events(events: Array, delta: float) -> void:
	for event_res in events:
		var event := event_res as ESEventItem
		if not event or not event.enabled:
			continue

		# All conditions must be true (AND logic).
		var all_pass := true
		for cond_res in event.conditions:
			var cond := cond_res as ESCondition
			if not cond:
				continue
			if not cond.evaluate(self, delta):
				all_pass = false
				break

		if all_pass and event.conditions.size() > 0:
			# Store the colliding node (if any) so actions can reference it via "$collider".
			for cond_res in event.conditions:
				if cond_res is ESCollisionCondition:
					var coll_cond := cond_res as ESCollisionCondition
					if coll_cond.colliding_node:
						set_meta(&"_es_last_collided_node", coll_cond.colliding_node)
					break
			if debug_mode:
				print("EventSheet: Event '%s' triggered!" % event.event_name)
			_execute_actions(event, delta)


## Execute all actions in an event.
func _execute_actions(event: ESEventItem, delta: float) -> void:
	for action_res in event.actions:
		var action := action_res as ESAction
		if action:
			action.execute(self, delta)


## Track key states for JUST_PRESSED/JUST_RELEASED detection with raw keys.
func _track_key_states() -> void:
	# This is called at the end of _process to update "previous frame" states
	# for conditions that track key transitions.
	var sheet := event_sheet as ESEventSheet
	if not sheet:
		return
	for event_res in sheet.events:
		var event := event_res as ESEventItem
		if not event:
			continue
		for cond_res in event.conditions:
			if cond_res is ESInputCondition:
				var cond := cond_res as ESInputCondition
				if not cond.action_or_key.is_empty() and not InputMap.has_action(cond.action_or_key):
					var keycode := OS.find_keycode_from_string(cond.action_or_key)
					if keycode != KEY_NONE:
						set_meta("_es_prev_key_%d" % keycode, Input.is_key_pressed(keycode))


## Get all conditions from all events (utility).
func _get_all_conditions() -> Array:
	var result: Array = []
	var sheet := event_sheet as ESEventSheet
	for event_res in sheet.events:
		var event := event_res as ESEventItem
		if event:
			for cond in event.conditions:
				result.append(cond)
	return result
