@tool
## Common properties per node type, used by condition/action dialogs to
## populate a property-name dropdown instead of requiring students to type.

const COMMON_PROPERTIES := {
	"Node2D": [
		"position", "position.x", "position.y",
		"rotation", "rotation_degrees",
		"scale", "scale.x", "scale.y",
		"visible",
		"modulate", "modulate.r", "modulate.g", "modulate.b", "modulate.a",
		"self_modulate", "self_modulate.a",
		"z_index",
	],
	"Node3D": [
		"position", "position.x", "position.y", "position.z",
		"rotation", "rotation.x", "rotation.y", "rotation.z",
		"rotation_degrees",
		"scale", "scale.x", "scale.y", "scale.z",
		"visible",
	],
	"CharacterBody2D": [
		"velocity", "velocity.x", "velocity.y",
		"floor_max_angle",
		"floor_stop_on_slope",
		"floor_snap_length",
		"up_direction",
	],
	"RigidBody2D": [
		"linear_velocity", "linear_velocity.x", "linear_velocity.y",
		"angular_velocity",
		"mass",
		"gravity_scale",
		"freeze",
	],
	"Sprite2D": [
		"texture",
		"flip_h", "flip_v",
		"frame",
		"offset",
		"centered",
	],
	"AnimatedSprite2D": [
		"animation",
		"frame",
		"flip_h", "flip_v",
		"speed_scale",
		"playing",
		"centered",
		"offset",
	],
	"Label": [
		"text",
		"visible",
		"modulate.a",
	],
	"RichTextLabel": [
		"text",
		"bbcode_enabled",
		"visible",
		"modulate.a",
	],
	"ProgressBar": [
		"value",
		"min_value",
		"max_value",
		"visible",
	],
	"TextureProgressBar": [
		"value",
		"min_value",
		"max_value",
		"fill_mode",
		"visible",
		"modulate.a",
	],
	"TextureRect": [
		"visible",
		"modulate",
		"modulate.a",
		"texture",
	],
	"AudioStreamPlayer": [
		"playing",
		"volume_db",
		"pitch_scale",
		"autoplay",
		"bus",
	],
	"AudioStreamPlayer2D": [
		"playing",
		"volume_db",
		"pitch_scale",
		"autoplay",
		"max_distance",
	],
	"PointLight2D": [
		"energy",
		"color",
		"enabled",
		"texture_scale",
		"shadow_enabled",
	],
	"Camera2D": [
		"enabled",
		"zoom", "zoom.x", "zoom.y",
		"offset",
		"position_smoothing_enabled",
		"position_smoothing_speed",
	],
	"GPUParticles2D": [
		"emitting",
		"amount",
		"speed_scale",
		"lifetime",
		"one_shot",
		"explosiveness",
	],
	"Area2D": [
		"monitoring",
		"monitorable",
		"collision_layer",
		"collision_mask",
	],
	"Button": [
		"text",
		"disabled",
		"visible",
		"modulate.a",
	],
	"ColorRect": [
		"color",
		"visible",
		"modulate.a",
	],
	"Timer": [
		"wait_time",
		"one_shot",
		"autostart",
		"paused",
	],
	"CollisionShape2D": [
		"disabled",
	],
	"StaticBody2D": [
		"position", "position.x", "position.y",
		"rotation",
		"visible",
	],
	"AnimationPlayer": [
		"speed_scale",
		"current_animation",
		"autoplay",
		"active",
	],
	"AnimationTree": [
		"active",
		"speed_scale",
	],
	"Line2D": [
		"visible",
		"default_color",
		"width",
	],
	"PathFollow2D": [
		"progress",
		"progress_ratio",
		"h_offset",
		"v_offset",
		"loop",
	],
}


## Return common property names for the given node by checking from its most
## specific class up through the inheritance chain.
static func get_properties_for_node(node: Node) -> PackedStringArray:
	var result := PackedStringArray()
	if not node:
		return result

	var type_name := node.get_class()
	var seen := {}

	while not type_name.is_empty() and type_name != "Object":
		if COMMON_PROPERTIES.has(type_name) and not seen.has(type_name):
			for prop in COMMON_PROPERTIES[type_name]:
				if not result.has(prop):
					result.append(prop)
			seen[type_name] = true
		type_name = ClassDB.get_parent_class(type_name)

	return result


## Return @export variable names from the script attached to the node.
static func get_custom_exports(node: Node) -> PackedStringArray:
	var result := PackedStringArray()
	if not node:
		return result

	var script := node.get_script()
	if not script or not script.has_method("get_script_property_list"):
		return result

	for prop in script.get_script_property_list():
		var usage: int = prop["usage"]
		# PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR flags indicate @export.
		if (usage & PROPERTY_USAGE_STORAGE) and (usage & PROPERTY_USAGE_EDITOR):
			result.append(prop["name"])

	return result
