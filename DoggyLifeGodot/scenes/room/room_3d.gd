extends Node3D

@onready var room_dog: CharacterBody3D = $RoomDog3D
@onready var camera: Camera3D = $RoomCamera3D

const CLICK_INDICATOR_SCENE = preload("res://scenes/room/click_indicator_3d.tscn")

func _ready() -> void:
	# Make sure the mouse mode is visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)

func _handle_click(mouse_pos: Vector2) -> void:
	if not camera:
		return
		
	# Perform raycast mathematically intersecting with the Y=0 plane.
	# This avoids colliding with the dog or walls and gives perfect 1-to-1 floor mapping.
	var origin = camera.project_ray_origin(mouse_pos)
	var normal = camera.project_ray_normal(mouse_pos)
	
	if not is_zero_approx(normal.y):
		var t = -origin.y / normal.y
		if t >= 0.0:
			var target_pos = origin + t * normal
			
			# Constrain dog targets to be inside the boundary walls (-10 to 10 grid)
			target_pos.x = clamp(target_pos.x, -9.5, 9.5)
			target_pos.z = clamp(target_pos.z, -9.5, 9.5)
			
			# Command the dog to walk to the target position
			if room_dog and room_dog.has_method("go_to_global_position"):
				room_dog.go_to_global_position(target_pos)
				
				# Spawn visual click indicator
				var indicator = CLICK_INDICATOR_SCENE.instantiate()
				add_child(indicator)
				# Offset Y slightly to prevent Z-fighting with the floor mesh
				indicator.global_position = Vector3(target_pos.x, 0.02, target_pos.z)
