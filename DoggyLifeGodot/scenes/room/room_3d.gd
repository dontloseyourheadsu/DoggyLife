extends Node3D

@onready var room_dog: CharacterBody3D = $RoomDog3D
@onready var camera: Camera3D = $RoomCamera3D
@onready var stats_panel = $UI/SafePanel/DogStatsPanel

const CLICK_INDICATOR_SCENE = preload("res://scenes/room/click_indicator_3d.tscn")
const BALL_3D_SCENE = preload("res://scenes/room/ball_3d.tscn")

var active_ball: RigidBody3D = null

func _ready() -> void:
	# Make sure the mouse mode is visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Connect to all dogs in the room
	for child in get_children():
		if child.has_signal("dog_selected"):
			child.dog_selected.connect(_on_dog_selected)

func _on_dog_selected(dog_node: CharacterBody3D) -> void:
	if stats_panel:
		stats_panel.display_dog(dog_node)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(event.position)

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
			
			# Constrain dog targets to be inside the smaller boundary walls (-6 to 6 grid)
			target_pos.x = clamp(target_pos.x, -5.5, 5.5)
			target_pos.z = clamp(target_pos.z, -5.5, 5.5)
			
			# Command the dog to walk to the target position
			if room_dog and room_dog.has_method("go_to_global_position"):
				room_dog.go_to_global_position(target_pos)
				
				# Spawn visual click indicator
				var indicator = CLICK_INDICATOR_SCENE.instantiate()
				add_child(indicator)
				# Offset Y slightly to prevent Z-fighting with the floor mesh
				indicator.global_position = Vector3(target_pos.x, 0.02, target_pos.z)

func _handle_right_click(mouse_pos: Vector2) -> void:
	if not camera:
		return
		
	var origin = camera.project_ray_origin(mouse_pos)
	var normal = camera.project_ray_normal(mouse_pos)
	
	if not is_zero_approx(normal.y):
		var t = -origin.y / normal.y
		if t >= 0.0:
			var target_pos = origin + t * normal
			
			# Constrain ball targets to be inside the smaller boundary walls (-6 to 6 grid)
			target_pos.x = clamp(target_pos.x, -5.5, 5.5)
			target_pos.z = clamp(target_pos.z, -5.5, 5.5)
			target_pos.y = 0.0
			
			# Remove old ball if any
			if is_instance_valid(active_ball):
				active_ball.queue_free()
				
			# Spawn new ball
			var ball = BALL_3D_SCENE.instantiate()
			add_child(ball)
			active_ball = ball
			
			# Spawn slightly in front of camera
			var spawn_pos = origin + normal * 0.5
			ball.global_position = spawn_pos
			
			# Calculate initial velocity using kinematic equation:
			# target_pos = spawn_pos + velocity * T + 0.5 * gravity * T^2
			var T = 0.6 # time of flight in seconds
			var gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
			
			var dist = target_pos - spawn_pos
			var velocity_xz = Vector3(dist.x, 0, dist.z) / T
			var velocity_y = (dist.y + 0.5 * gravity * T * T) / T
			
			ball.linear_velocity = Vector3(velocity_xz.x, velocity_y, velocity_xz.z)
			
			# Command the dog to chase the ball
			if room_dog and room_dog.has_method("chase_ball"):
				room_dog.chase_ball(ball)

