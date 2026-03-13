class_name ESSetPropertyAction
extends ESAction
## Action that sets a property on a target node.

enum SetMode {
	SET,       ## Set the property to the value
	ADD,       ## Add the value to the current property
	SUBTRACT,  ## Subtract the value from the current property
	MULTIPLY,  ## Multiply the current property by the value
	TOGGLE,    ## Toggle a boolean property
}

## Path to the target node. Leave empty to use the EventController's parent.
@export var target_path: NodePath = NodePath("")

## The property name to set (supports dot notation like "position.x").
@export var property_name: String = ""

## The value to set/add/subtract/multiply (as a string, auto-converted).
@export var value: String = ""

## How to apply the value to the property.
@export var set_mode: SetMode = SetMode.SET


func get_summary() -> String:
	var target := str(target_path) if not target_path.is_empty() else "parent"
	var mode_names := ["Set", "Add", "Subtract", "Multiply", "Toggle"]
	return "%s %s.%s = %s" % [mode_names[set_mode], target, property_name, value]


func get_category() -> String:
	return "Properties"


func execute(controller: Node, _delta: float) -> void:
	var target: Node = _resolve_target(controller)
	if not target or property_name.is_empty():
		return

	# Handle dot notation for nested properties.
	var parts := property_name.split(".")
	if parts.size() == 1:
		_set_simple_property(target, property_name)
	else:
		_set_nested_property(target, parts)


func _set_simple_property(target: Node, prop: String) -> void:
	if not prop in target:
		push_warning("EventSheet: Property '%s' not found on %s" % [prop, target.name])
		return

	var current = target.get(prop)
	var new_val = _compute_value(current)
	target.set(prop, new_val)


func _set_nested_property(target: Node, parts: PackedStringArray) -> void:
	# Navigate to the parent of the final property.
	var current: Variant = target
	for i in range(parts.size() - 1):
		if current is Object and parts[i] in current:
			current = current.get(parts[i])
		else:
			push_warning("EventSheet: Cannot navigate property path '%s'" % property_name)
			return

	var final_prop := parts[parts.size() - 1]

	if current is Vector2:
		var vec := current as Vector2
		var val := float(value)
		match final_prop:
			"x":
				vec.x = _compute_float(vec.x, val)
			"y":
				vec.y = _compute_float(vec.y, val)
			_:
				push_warning("EventSheet: Unknown Vector2 component '%s'" % final_prop)
				return
		# Set the full vector back on the parent.
		target.set(parts[0], vec)
	elif current is Vector3:
		var vec := current as Vector3
		var val := float(value)
		match final_prop:
			"x":
				vec.x = _compute_float(vec.x, val)
			"y":
				vec.y = _compute_float(vec.y, val)
			"z":
				vec.z = _compute_float(vec.z, val)
			_:
				push_warning("EventSheet: Unknown Vector3 component '%s'" % final_prop)
				return
		target.set(parts[0], vec)
	elif current is Color:
		var col := current as Color
		var val := float(value)
		match final_prop:
			"r": col.r = _compute_float(col.r, val)
			"g": col.g = _compute_float(col.g, val)
			"b": col.b = _compute_float(col.b, val)
			"a": col.a = _compute_float(col.a, val)
			_:
				push_warning("EventSheet: Unknown Color component '%s'" % final_prop)
				return
		target.set(parts[0], col)


func _compute_value(current: Variant) -> Variant:
	match set_mode:
		SetMode.TOGGLE:
			if current is bool:
				return not current
			return not bool(current)
		SetMode.SET:
			return _convert_to_type(value, typeof(current))
		SetMode.ADD:
			return current + _convert_to_type(value, typeof(current))
		SetMode.SUBTRACT:
			return current - _convert_to_type(value, typeof(current))
		SetMode.MULTIPLY:
			return current * _convert_to_type(value, typeof(current))
	return current


func _compute_float(current: float, val: float) -> float:
	match set_mode:
		SetMode.SET:
			return val
		SetMode.ADD:
			return current + val
		SetMode.SUBTRACT:
			return current - val
		SetMode.MULTIPLY:
			return current * val
		SetMode.TOGGLE:
			return 0.0 if current != 0.0 else 1.0
	return current


func _convert_to_type(val: String, target_type: int) -> Variant:
	match target_type:
		TYPE_INT:
			return int(val)
		TYPE_FLOAT:
			return float(val)
		TYPE_BOOL:
			return val.to_lower() == "true" or val == "1"
		TYPE_STRING:
			return val
		_:
			if val.is_valid_float():
				return float(val)
			if val.is_valid_int():
				return int(val)
			return val


func _resolve_target(controller: Node) -> Node:
	if target_path.is_empty():
		return controller.get_parent()
	return controller.get_node_or_null(target_path)
