@tool
## Common properties per node type, used by condition/action dialogs to
## populate a property-name dropdown instead of requiring students to type.

const COMMON_PROPERTIES := {
	"Node2D": [
		{"label": "Position", "prop": "position"},
		{"label": "Position X", "prop": "position.x"},
		{"label": "Position Y", "prop": "position.y"},
		{"label": "Rotation (radians)", "prop": "rotation"},
		{"label": "Rotation (degrees)", "prop": "rotation_degrees"},
		{"label": "Scale", "prop": "scale"},
		{"label": "Scale X", "prop": "scale.x"},
		{"label": "Scale Y", "prop": "scale.y"},
		{"label": "Visible", "prop": "visible"},
		{"label": "Color Tint", "prop": "modulate"},
		{"label": "Color Tint - Red", "prop": "modulate.r"},
		{"label": "Color Tint - Green", "prop": "modulate.g"},
		{"label": "Color Tint - Blue", "prop": "modulate.b"},
		{"label": "Opacity (Alpha)", "prop": "modulate.a"},
		{"label": "Self Color Tint", "prop": "self_modulate"},
		{"label": "Self Opacity (Alpha)", "prop": "self_modulate.a"},
		{"label": "Z-Index (Draw Order)", "prop": "z_index"},
	],
	"Node3D": [
		{"label": "Position", "prop": "position"},
		{"label": "Position X", "prop": "position.x"},
		{"label": "Position Y", "prop": "position.y"},
		{"label": "Position Z", "prop": "position.z"},
		{"label": "Rotation (radians)", "prop": "rotation"},
		{"label": "Rotation X", "prop": "rotation.x"},
		{"label": "Rotation Y", "prop": "rotation.y"},
		{"label": "Rotation Z", "prop": "rotation.z"},
		{"label": "Rotation (degrees)", "prop": "rotation_degrees"},
		{"label": "Scale", "prop": "scale"},
		{"label": "Scale X", "prop": "scale.x"},
		{"label": "Scale Y", "prop": "scale.y"},
		{"label": "Scale Z", "prop": "scale.z"},
		{"label": "Visible", "prop": "visible"},
	],
	"CharacterBody2D": [
		{"label": "Velocity", "prop": "velocity"},
		{"label": "Velocity X (Horizontal)", "prop": "velocity.x"},
		{"label": "Velocity Y (Vertical)", "prop": "velocity.y"},
		{"label": "Max Floor Angle", "prop": "floor_max_angle"},
		{"label": "Stop on Slope", "prop": "floor_stop_on_slope"},
		{"label": "Floor Snap Length", "prop": "floor_snap_length"},
		{"label": "Up Direction", "prop": "up_direction"},
	],
	"RigidBody2D": [
		{"label": "Linear Velocity", "prop": "linear_velocity"},
		{"label": "Linear Velocity X", "prop": "linear_velocity.x"},
		{"label": "Linear Velocity Y", "prop": "linear_velocity.y"},
		{"label": "Spin Speed", "prop": "angular_velocity"},
		{"label": "Mass", "prop": "mass"},
		{"label": "Gravity Multiplier", "prop": "gravity_scale"},
		{"label": "Frozen (No Physics)", "prop": "freeze"},
	],
	"Sprite2D": [
		{"label": "Texture Image", "prop": "texture"},
		{"label": "Flip Horizontally", "prop": "flip_h"},
		{"label": "Flip Vertically", "prop": "flip_v"},
		{"label": "Current Frame", "prop": "frame"},
		{"label": "Offset", "prop": "offset"},
		{"label": "Centered", "prop": "centered"},
	],
	"AnimatedSprite2D": [
		{"label": "Current Animation", "prop": "animation"},
		{"label": "Current Frame", "prop": "frame"},
		{"label": "Flip Horizontally", "prop": "flip_h"},
		{"label": "Flip Vertically", "prop": "flip_v"},
		{"label": "Playback Speed", "prop": "speed_scale"},
		{"label": "Is Playing", "prop": "playing"},
		{"label": "Centered", "prop": "centered"},
		{"label": "Offset", "prop": "offset"},
	],
	"Label": [
		{"label": "Text Content", "prop": "text"},
		{"label": "Visible", "prop": "visible"},
		{"label": "Opacity (Alpha)", "prop": "modulate.a"},
	],
	"RichTextLabel": [
		{"label": "Text Content", "prop": "text"},
		{"label": "Enable BBCode Formatting", "prop": "bbcode_enabled"},
		{"label": "Visible", "prop": "visible"},
		{"label": "Opacity (Alpha)", "prop": "modulate.a"},
	],
	"ProgressBar": [
		{"label": "Current Value", "prop": "value"},
		{"label": "Minimum Value", "prop": "min_value"},
		{"label": "Maximum Value", "prop": "max_value"},
		{"label": "Visible", "prop": "visible"},
	],
	"TextureProgressBar": [
		{"label": "Current Value", "prop": "value"},
		{"label": "Minimum Value", "prop": "min_value"},
		{"label": "Maximum Value", "prop": "max_value"},
		{"label": "Fill Direction", "prop": "fill_mode"},
		{"label": "Visible", "prop": "visible"},
		{"label": "Opacity (Alpha)", "prop": "modulate.a"},
	],
	"TextureRect": [
		{"label": "Visible", "prop": "visible"},
		{"label": "Color Tint", "prop": "modulate"},
		{"label": "Opacity (Alpha)", "prop": "modulate.a"},
		{"label": "Texture Image", "prop": "texture"},
	],
	"AudioStreamPlayer": [
		{"label": "Is Playing", "prop": "playing"},
		{"label": "Volume (dB)", "prop": "volume_db"},
		{"label": "Pitch", "prop": "pitch_scale"},
		{"label": "Auto-Play on Start", "prop": "autoplay"},
		{"label": "Audio Bus", "prop": "bus"},
	],
	"AudioStreamPlayer2D": [
		{"label": "Is Playing", "prop": "playing"},
		{"label": "Volume (dB)", "prop": "volume_db"},
		{"label": "Pitch", "prop": "pitch_scale"},
		{"label": "Auto-Play on Start", "prop": "autoplay"},
		{"label": "Max Audible Distance", "prop": "max_distance"},
	],
	"PointLight2D": [
		{"label": "Light Energy (Brightness)", "prop": "energy"},
		{"label": "Light Color", "prop": "color"},
		{"label": "Light Enabled", "prop": "enabled"},
		{"label": "Light Radius", "prop": "texture_scale"},
		{"label": "Cast Shadows", "prop": "shadow_enabled"},
	],
	"Camera2D": [
		{"label": "Is Active Camera", "prop": "enabled"},
		{"label": "Zoom", "prop": "zoom"},
		{"label": "Zoom X", "prop": "zoom.x"},
		{"label": "Zoom Y", "prop": "zoom.y"},
		{"label": "Camera Offset", "prop": "offset"},
		{"label": "Smooth Camera Movement", "prop": "position_smoothing_enabled"},
		{"label": "Camera Smoothing Speed", "prop": "position_smoothing_speed"},
	],
	"GPUParticles2D": [
		{"label": "Emitting Particles", "prop": "emitting"},
		{"label": "Particle Count", "prop": "amount"},
		{"label": "Speed Multiplier", "prop": "speed_scale"},
		{"label": "Particle Lifetime", "prop": "lifetime"},
		{"label": "One-Shot Mode", "prop": "one_shot"},
		{"label": "Burst Amount", "prop": "explosiveness"},
	],
	"Area2D": [
		{"label": "Detect Overlaps", "prop": "monitoring"},
		{"label": "Can Be Detected", "prop": "monitorable"},
		{"label": "Collision Layer", "prop": "collision_layer"},
		{"label": "Collision Mask", "prop": "collision_mask"},
	],
	"Button": [
		{"label": "Button Text", "prop": "text"},
		{"label": "Disabled", "prop": "disabled"},
		{"label": "Visible", "prop": "visible"},
		{"label": "Opacity (Alpha)", "prop": "modulate.a"},
	],
	"ColorRect": [
		{"label": "Fill Color", "prop": "color"},
		{"label": "Visible", "prop": "visible"},
		{"label": "Opacity (Alpha)", "prop": "modulate.a"},
	],
	"Timer": [
		{"label": "Wait Time (seconds)", "prop": "wait_time"},
		{"label": "Fire Once Only", "prop": "one_shot"},
		{"label": "Start Automatically", "prop": "autostart"},
		{"label": "Paused", "prop": "paused"},
	],
	"CollisionShape2D": [
		{"label": "Disabled", "prop": "disabled"},
	],
	"StaticBody2D": [
		{"label": "Position", "prop": "position"},
		{"label": "Position X", "prop": "position.x"},
		{"label": "Position Y", "prop": "position.y"},
		{"label": "Rotation", "prop": "rotation"},
		{"label": "Visible", "prop": "visible"},
	],
	"AnimationPlayer": [
		{"label": "Playback Speed", "prop": "speed_scale"},
		{"label": "Current Animation", "prop": "current_animation"},
		{"label": "Auto-Play on Start", "prop": "autoplay"},
		{"label": "Active", "prop": "active"},
	],
	"AnimationTree": [
		{"label": "Active", "prop": "active"},
		{"label": "Playback Speed", "prop": "speed_scale"},
	],
	"Line2D": [
		{"label": "Visible", "prop": "visible"},
		{"label": "Line Color", "prop": "default_color"},
		{"label": "Line Width", "prop": "width"},
	],
	"PathFollow2D": [
		{"label": "Distance Along Path", "prop": "progress"},
		{"label": "Progress (0-1)", "prop": "progress_ratio"},
		{"label": "Horizontal Offset", "prop": "h_offset"},
		{"label": "Vertical Offset", "prop": "v_offset"},
		{"label": "Loop", "prop": "loop"},
	],
}


## Return common property hint dictionaries ({"label": ..., "prop": ...}) for
## the given node by checking from its most specific class up through the
## inheritance chain.
static func get_properties_for_node(node: Node) -> Array:
	var result: Array = []
	if not node:
		return result

	var type_name := node.get_class()
	var seen := {}
	var seen_props := {}

	while not type_name.is_empty() and type_name != "Object":
		if COMMON_PROPERTIES.has(type_name) and not seen.has(type_name):
			for item in COMMON_PROPERTIES[type_name]:
				if not seen_props.has(item["prop"]):
					result.append(item)
					seen_props[item["prop"]] = true
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
