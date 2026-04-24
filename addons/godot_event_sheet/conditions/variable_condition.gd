@tool
class_name ESVariableCondition
extends ESCondition
## Condition that compares an event-sheet variable stored on the
## EventController against a reference value.
##
## Variables are stored as metadata under `_es_var_{variable_name}` by the
## matching Variable action (variable_action.gd).  An unset variable is
## treated as `0` for numeric comparisons and `""` for equality checks.

enum CompareOp {
	EQUAL,         ## ==
	NOT_EQUAL,     ## !=
	GREATER,       ## >
	LESS,          ## <
	GREATER_EQUAL, ## >=
	LESS_EQUAL,    ## <=
	CONTAINS,      ## Array contains value
}

enum VariableScope {
	LOCAL,  ## Stored on the EventController (dies with the node/scene).
	GLOBAL, ## Stored in the ESGlobalVariables autoload (survives scene changes).
}

## Name of the variable to read (must match the Variable action's
## variable_name).
@export var variable_name: String = ""

## Whether to read from local (controller metadata) or global (autoload).
@export var scope: VariableScope = VariableScope.LOCAL

## The comparison operator to use.
@export_enum("Equal (==):0", "Not Equal (!=):1", "Greater Than (>):2", "Less Than (<):3", "Greater or Equal (>=):4", "Less or Equal (<=):5", "Contains (in / has):6") var compare_op: int = CompareOp.EQUAL

## The reference value to compare against.  Automatically converted to a
## matching type at runtime.
@export var compare_value: String = ""


func get_summary() -> String:
	var op_str: String
	match compare_op:
		CompareOp.EQUAL:         op_str = "=="
		CompareOp.NOT_EQUAL:     op_str = "!="
		CompareOp.GREATER:       op_str = ">"
		CompareOp.LESS:          op_str = "<"
		CompareOp.GREATER_EQUAL: op_str = ">="
		CompareOp.LESS_EQUAL:    op_str = "<="
		CompareOp.CONTAINS:      op_str = "contains"
	return "Variable '%s' %s %s" % [variable_name, op_str, compare_value]


func get_category() -> String:
	return "Variables"


func evaluate(controller: Node, _delta: float) -> bool:
	if variable_name.is_empty():
		return false

	var meta_key := &"_es_var_%s" % variable_name
	var current = null
	if scope == VariableScope.GLOBAL:
		var globals = controller.get_node_or_null("/root/ESGlobalVariables")
		if globals:
			current = globals.get_variable(str(meta_key), null)
	else:
		current = controller.get_meta(meta_key, null)

	# Determine types for comparison.
	var ref = _auto_convert(compare_value)

	# Handle CONTAINS check for arrays.
	if compare_op == CompareOp.CONTAINS:
		if current is Array:
			return current.has(ref)
		if current == null:
			return false
		# For non-array values, check equality.
		return current == ref

	# If the variable hasn't been set yet, use a sensible default.
	if current == null:
		if ref is float or ref is int:
			current = 0.0
		elif ref is bool:
			current = false
		else:
			current = ""

	# Numeric comparison when both sides are numbers.
	if (current is float or current is int) and (ref is float or ref is int):
		var a := float(current)
		var b := float(ref)
		match compare_op:
			CompareOp.EQUAL:         return is_equal_approx(a, b)
			CompareOp.NOT_EQUAL:     return not is_equal_approx(a, b)
			CompareOp.GREATER:       return a > b
			CompareOp.LESS:          return a < b
			CompareOp.GREATER_EQUAL: return a >= b
			CompareOp.LESS_EQUAL:    return a <= b

	# Fall back to string comparison.
	var a_str := str(current)
	var b_str := str(ref)
	match compare_op:
		CompareOp.EQUAL:         return a_str == b_str
		CompareOp.NOT_EQUAL:     return a_str != b_str
		CompareOp.GREATER:       return a_str > b_str
		CompareOp.LESS:          return a_str < b_str
		CompareOp.GREATER_EQUAL: return a_str >= b_str
		CompareOp.LESS_EQUAL:    return a_str <= b_str

	return false


## Auto-convert a string value to int, float, or bool when possible.
static func _auto_convert(val: String):
	if val == "true":
		return true
	if val == "false":
		return false
	if val.is_valid_int():
		return val.to_int()
	if val.is_valid_float():
		return val.to_float()
	return val
