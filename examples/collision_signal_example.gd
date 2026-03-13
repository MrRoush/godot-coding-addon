extends Node
## Example: Collision detection and signal communication with the Event Sheet addon.
##
## This demonstrates how to set up collision detection and use signals to
## communicate between nodes — two critical requirements for game development.
##
## Scene Setup Required:
##   Area2D ("Player")
##     ├── Sprite2D
##     ├── CollisionShape2D
##     └── EventController  ← assign EventSheet here
##
##   Area2D ("Coin") (in group "coins")
##     ├── Sprite2D
##     └── CollisionShape2D
##
## The Event Sheet configuration is equivalent to:
##   signal coin_collected
##   var score: int = 0
##
##   func _ready():
##       area_entered.connect(_on_area_entered)
##
##   func _on_area_entered(area):
##       if area.is_in_group("coins"):
##           score += 1
##           print("Coin collected! Score: ", score)
##           area.queue_free()
##           emit_signal("coin_collected")


func create_collision_sheet() -> ESEventSheet:
	var sheet := ESEventSheet.new()
	sheet.sheet_name = "Collision & Signals"

	# Register a custom signal for other nodes to listen to.
	sheet.custom_signals.append("coin_collected")

	# --- Event 1: When a coin enters the player area ---
	var event_coin := ESEventItem.new()
	event_coin.event_name = "Collect Coin"

	# Condition: Area entered by something in "coins" group.
	var cond_collision := ESCollisionCondition.new()
	cond_collision.collision_type = ESCollisionCondition.CollisionType.AREA_ENTERED
	cond_collision.filter_group = "coins"
	event_coin.add_condition(cond_collision)

	# Action 1: Print a debug message.
	var action_print := ESPrintAction.new()
	action_print.message = "Coin collected by {name}!"
	event_coin.add_action(action_print)

	# Action 2: Emit the coin_collected signal so other nodes can respond.
	var action_signal := ESEmitSignalAction.new()
	action_signal.signal_name = "coin_collected"
	event_coin.add_action(action_signal)

	sheet.events.append(event_coin)

	# --- Event 2: Listen for coin_collected signal on self ---
	var event_score := ESEventItem.new()
	event_score.event_name = "Update Score Display"

	# Condition: Listen for coin_collected on the EventController.
	var cond_signal := ESSignalCondition.new()
	cond_signal.signal_name = "coin_collected"
	# Empty source_path means "listen on parent", but we could also
	# set it to a specific node path.
	event_score.add_condition(cond_signal)

	# Action: Print updated score.
	var action_score_print := ESPrintAction.new()
	action_score_print.message = "Score updated!"
	event_score.add_action(action_score_print)

	sheet.events.append(event_score)

	return sheet
