@tool
class_name ESNodeCountCondition
extends ESCondition
## Condition that checks how many nodes belong to a given group.
## Useful for game-over / level-complete detection.
##
## Common patterns:
##   - Breakout:  "When nodes in group 'bricks' == 0 → Change scene to win screen."
##   - Space Shooter: "When nodes in group 'enemies' == 0 → Spawn next wave."
##   - Collectables:  "When nodes in group 'coins' == 0 → Open exit door."

enum CountCompare {
	EQUAL,         ## count == value
	NOT_EQUAL,     ## count != value
	GREATER,       ## count >  value
	LESS,          ## count <  value
	GREATER_EQUAL, ## count >= value
	LESS_EQUAL,    ## count <= value
}

## The group name to count nodes in.
@export var group_name: String = ""

## The comparison operator.
@export_enum("Equal (==):0", "Not Equal (!=):1", "Greater Than (>):2", "Less Than (<):3", "Greater or Equal (>=):4", "Less or Equal (<=):5") var compare_op: int = CountCompare.EQUAL

## The value to compare the node count against.
@export var compare_value: int = 0


func get_summary() -> String:
	var op_str: String
	match compare_op:
		CountCompare.EQUAL:         op_str = "=="
		CountCompare.NOT_EQUAL:     op_str = "!="
		CountCompare.GREATER:       op_str = ">"
		CountCompare.LESS:          op_str = "<"
		CountCompare.GREATER_EQUAL: op_str = ">="
		CountCompare.LESS_EQUAL:    op_str = "<="
		_:                          op_str = "?"
	return "Nodes in group '%s' %s %d" % [group_name, op_str, compare_value]


func get_category() -> String:
	return "Utility"


func evaluate(controller: Node, _delta: float) -> bool:
	if group_name.is_empty():
		push_warning("EventSheet: Node Count condition – no group name specified.")
		return false

	var tree := controller.get_tree()
	if not tree:
		return false

	var count: int = tree.get_nodes_in_group(group_name).size()

	match compare_op:
		CountCompare.EQUAL:
			return count == compare_value
		CountCompare.NOT_EQUAL:
			return count != compare_value
		CountCompare.GREATER:
			return count > compare_value
		CountCompare.LESS:
			return count < compare_value
		CountCompare.GREATER_EQUAL:
			return count >= compare_value
		CountCompare.LESS_EQUAL:
			return count <= compare_value
	return false
