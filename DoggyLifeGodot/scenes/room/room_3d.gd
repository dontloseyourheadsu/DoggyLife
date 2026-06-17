extends Node3D

@onready var camera: Camera3D = $RoomCamera3D
@onready var stats_panel = $UI/SafePanel/DogStatsPanel

const CLICK_INDICATOR_SCENE = preload("res://scenes/room/props/click_indicator_3d.tscn")
const BALL_3D_SCENE = preload("res://scenes/room/props/ball_3d.tscn")
const DOG_SCENE = preload("res://scenes/room/dog/room_dog_3d.tscn")

var active_ball: RigidBody3D = null
var active_dogs: Array[CharacterBody3D] = []
var selected_dog: CharacterBody3D = null

func _ready() -> void:
	# Make sure the mouse mode is visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Load owned dogs from player data
	var player_data := PlayerData.load_player_data()
	var owned_dogs: Array[String] = []
	for item in player_data.owned_items:
		if item.begins_with("dog-"):
			owned_dogs.append(item)
			
	if owned_dogs.is_empty():
		owned_dogs.append("dog-samoyed")
		
	# Spawn all owned/unlocked dogs
	for i in range(owned_dogs.size()):
		var dog_key = owned_dogs[i]
		var dog_inst = DOG_SCENE.instantiate()
		dog_inst.dog_key = dog_key
		
		# Spread them out in the room
		var angle = i * (2.0 * PI / owned_dogs.size())
		var dist = randf_range(1.0, 2.5)
		dog_inst.global_position = Vector3(cos(angle) * dist, 0.1, sin(angle) * dist)
		
		add_child(dog_inst)
		active_dogs.append(dog_inst)
		
		dog_inst.dog_selected.connect(_on_dog_selected)
		
	# Set default selected dog to the first spawned dog
	if not active_dogs.is_empty():
		selected_dog = active_dogs[0]
		if camera:
			camera.target = selected_dog
		if stats_panel:
			stats_panel.display_dog(selected_dog)

func _on_dog_selected(dog_node: CharacterBody3D) -> void:
	selected_dog = dog_node
	if camera:
		camera.target = dog_node
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
			
			# Command only the last inspected dog to walk to the target position
			if selected_dog and is_instance_valid(selected_dog) and selected_dog.has_method("go_to_global_position"):
				selected_dog.go_to_global_position(target_pos)
				
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

