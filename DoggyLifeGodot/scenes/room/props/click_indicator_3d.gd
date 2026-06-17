extends MeshInstance3D

var time_elapsed: float = 0.0
var duration: float = 0.5 # Duration of the click animation in seconds

func _ready() -> void:
	# Duplicate the material so each click indicator has its own independent animation state
	if material_override:
		material_override = material_override.duplicate()

func _process(delta: float) -> void:
	time_elapsed += delta
	var t = time_elapsed / duration
	if t >= 1.0:
		queue_free()
		return
	
	# Expand the ring and fade it out
	var current_radius = lerp(0.05, 0.45, t)
	var current_alpha = lerp(1.0, 0.0, t)
	
	if material_override is ShaderMaterial:
		material_override.set_shader_parameter("radius", current_radius)
		# Update color and transparency
		var base_color = Color(0.3, 0.7, 1.0, current_alpha)
		material_override.set_shader_parameter("color", base_color)
