extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(0.0, 4.5, 6.0) # Angle camera down and set distance
@export var lerp_speed: float = 4.0

func _ready() -> void:
	# Face downward at a fixed angle (e.g. -35 degrees)
	rotation_degrees = Vector3(-35.0, 0.0, 0.0)
	
	if target:
		global_position = target.global_position + offset

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
		
	# Smoothly interpolate position towards target + offset
	var target_pos = target.global_position + offset
	global_position = global_position.lerp(target_pos, lerp_speed * delta)
