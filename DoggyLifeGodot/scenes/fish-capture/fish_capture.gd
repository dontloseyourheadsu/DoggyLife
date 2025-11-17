extends Node2D

@onready var fish_container: Node2D = $Camera2D/Fishes
@onready var water_zone: Area2D = $Camera2D/WaterZone
@onready var background: TextureRect = $Camera2D/Background
@onready var fisher: Sprite2D = $Camera2D/Fisher
@onready var ball: RigidBody2D = $Camera2D/Ball
@onready var dog: CharacterBody2D = $Camera2D/Dog

# Fisher is scaled 6x, so forces need to be smaller for visible arc
const THROW_FORCE: Vector2 = Vector2(500, -100) # Adjusted for 6x scale

@export var num_fish: int = 10 # Number of fish to spawn
@export var min_fish_speed: float = 80.0 # Minimum fish swim speed
@export var max_fish_speed: float = 140.0 # Maximum fish swim speed
@export var min_change_dir_interval: float = 1.5 # Min seconds between direction changes
@export var max_change_dir_interval: float = 3.0 # Max seconds between direction changes
@export var fish_swim_lower_percentage: float = 0.6 # Fish swim in lower 60% of water zone (leaving top 40% for dog)
const FISH_SCENE: String = "res://scenes/fish-capture/fishes/fish.tscn"

func _ready() -> void:
	_spawn_fish()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_left_click()

func _calculate_swim_bounds() -> Rect2:
	# Get WaterZone's actual collision shape bounds
	if not is_instance_valid(water_zone):
		push_error("WaterZone not found")
		return Rect2()
	
	var collision_shape = water_zone.get_node("CollisionShape2D")
	if not collision_shape or not collision_shape.shape:
		push_error("WaterZone CollisionShape2D not found")
		return Rect2()
	
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		push_error("WaterZone shape is not a RectangleShape2D")
		return Rect2()
	
	# Calculate global bounds from WaterZone position + CollisionShape offset + shape size
	var zone_pos = water_zone.global_position
	var shape_offset = collision_shape.position
	var shape_size = shape.size
	
	# Top-left corner of the full water zone rectangle
	var full_top_left = zone_pos + shape_offset - shape_size / 2.0
	
	# Restrict fish to swim in the lower portion (e.g., lower 60% for dog clearance)
	var restricted_height = shape_size.y * fish_swim_lower_percentage
	var vertical_offset = shape_size.y * (1.0 - fish_swim_lower_percentage)
	
	# Adjust top position down and reduce height
	var fish_top_left = full_top_left + Vector2(0, vertical_offset)
	var fish_size = Vector2(shape_size.x, restricted_height)
	
	return Rect2(fish_top_left, fish_size)

func _spawn_fish() -> void:
	var swim_rect: Rect2 = _calculate_swim_bounds()
	
	if swim_rect.size == Vector2.ZERO:
		push_error("Failed to calculate swim bounds")
		return
	
	var fish_scene = load(FISH_SCENE)
	
	if not fish_scene:
		push_error("Failed to load fish scene")
		return
	
	# Spawn multiple fish
	for i in range(num_fish):
		var fish_instance: RigidBody2D = fish_scene.instantiate()
		fish_container.add_child(fish_instance)
		
		# Set random species
		fish_instance.set_random_species()
		
		# Set random speed (each fish has different speed)
		fish_instance.speed = randf_range(min_fish_speed, max_fish_speed)
		
		# Set random direction change interval (some fish change direction more frequently)
		fish_instance.change_dir_interval = randf_range(min_change_dir_interval, max_change_dir_interval)
		
		# Set swim bounds to WaterZone area
		fish_instance.swim_bounds = swim_rect
		
		# Place fish initially inside bounds with random position
		var pos = Vector2(
			randf_range(swim_rect.position.x, swim_rect.position.x + swim_rect.size.x),
			randf_range(swim_rect.position.y, swim_rect.position.y + swim_rect.size.y)
		)
		fish_instance.global_position = pos

func _on_left_click() -> void:
	if not is_instance_valid(ball) or not is_instance_valid(fisher):
		return
	# Toggle behavior: if ball not thrown, throw with fisher animation; else reset.
	if ball.has_method("is_thrown") and ball.call("is_thrown"):
		# Reset ball
		if ball.has_method("request_reset"):
			ball.call("request_reset")
		# Reset fisher arm animation
		if fisher.has_method("reset_arm"):
			fisher.call("reset_arm")
		# Reset dog position and state
		if is_instance_valid(dog) and dog.has_method("reset_dog"):
			dog.call("reset_dog")
	else:
		# Trigger fisher arm animation, then throw ball
		if fisher.has_method("trigger_throw"):
			fisher.call("trigger_throw", THROW_FORCE)
			# Connect to throw_completed signal to actually throw the ball
			if not fisher.is_connected("throw_completed", _on_fisher_throw_completed):
				fisher.connect("throw_completed", _on_fisher_throw_completed)

func _on_fisher_throw_completed() -> void:
	# Fisher arm animation complete, now throw the ball
	if is_instance_valid(ball) and ball.has_method("request_throw"):
		ball.call("request_throw", THROW_FORCE)
	# Also trigger the dog to walk and fall into water (no chasing the ball)
	if is_instance_valid(dog) and dog.has_method("trigger_fall_to_water"):
		dog.call("trigger_fall_to_water")
