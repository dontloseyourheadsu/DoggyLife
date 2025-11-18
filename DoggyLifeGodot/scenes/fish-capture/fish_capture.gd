extends Node2D

@onready var fish_container: Node2D = $Camera2D/Fishes
@onready var water_zone: Area2D = $Camera2D/WaterZone
@onready var background: TextureRect = $Camera2D/Background
@onready var fisher: Sprite2D = $Camera2D/Fisher
@onready var ball: RigidBody2D = $Camera2D/Ball
@onready var dog: CharacterBody2D = $Camera2D/Dog
@onready var throw_force_bar: TextureProgressBar = $Camera2D/ThrowForce

# Throw force calculation based on progress bar
const MIN_THROW_FORCE: Vector2 = Vector2(100, -50) # Minimum throw force (close distance)
const BASE_VERTICAL_FORCE: float = -100.0 # Base upward force for arc
var max_horizontal_force: float = 0.0 # Calculated based on water zone width

# Progress bar settings
const FORCE_BUILD_SPEED: float = 50.0 # How fast the bar fills per second
var is_charging: bool = false

@export var num_fish: int = 10 # Number of fish to spawn
@export var min_fish_speed: float = 80.0 # Minimum fish swim speed
@export var max_fish_speed: float = 140.0 # Maximum fish swim speed
@export var min_change_dir_interval: float = 1.5 # Min seconds between direction changes
@export var max_change_dir_interval: float = 3.0 # Max seconds between direction changes
@export var fish_swim_lower_percentage: float = 0.6 # Fish swim in lower 60% of water zone (leaving top 40% for dog)
const FISH_SCENE: String = "res://scenes/fish-capture/fishes/fish.tscn"

func _ready() -> void:
	_calculate_max_throw_force()
	_spawn_fish()
	throw_force_bar.value = throw_force_bar.min_value

func _process(delta: float) -> void:
	if is_charging:
		# Build up throw force
		throw_force_bar.value = min(throw_force_bar.value + FORCE_BUILD_SPEED * delta, throw_force_bar.max_value)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_left_click_pressed()
		else:
			_on_left_click_released()

func _calculate_max_throw_force() -> void:
	# Calculate the maximum throw force needed to reach the end of the water zone
	if not is_instance_valid(water_zone):
		push_error("WaterZone not found for force calculation")
		max_horizontal_force = 500.0 # Fallback
		return
	
	var collision_shape = water_zone.get_node("CollisionShape2D")
	if not collision_shape or not collision_shape.shape:
		push_error("WaterZone CollisionShape2D not found")
		max_horizontal_force = 500.0 # Fallback
		return
	
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		push_error("WaterZone shape is not a RectangleShape2D")
		max_horizontal_force = 500.0 # Fallback
		return
	
	# Calculate horizontal distance from ball to end of water zone
	var zone_pos = water_zone.global_position
	var shape_offset = collision_shape.position
	var shape_size = shape.size
	
	var water_zone_right = zone_pos.x + shape_offset.x + shape_size.x / 2.0
	var ball_start_x = ball.global_position.x
	var distance_to_end = water_zone_right - ball_start_x
	
	# Set max force to cover this distance (empirically tuned for physics)
	# Adjust this multiplier if needed based on testing
	max_horizontal_force = distance_to_end * 0.8

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

func _on_left_click_pressed() -> void:
	# Start charging the throw or reset if already thrown
	if not is_instance_valid(ball) or not is_instance_valid(fisher):
		return
	
	if ball.has_method("is_thrown") and ball.call("is_thrown"):
		# Ball already thrown - reset everything
		if ball.has_method("request_reset"):
			ball.call("request_reset")
		if fisher.has_method("reset_arm"):
			fisher.call("reset_arm")
		if is_instance_valid(dog) and dog.has_method("reset_dog"):
			dog.call("reset_dog")
		throw_force_bar.value = throw_force_bar.min_value
		is_charging = false
	else:
		# Start charging
		is_charging = true
		throw_force_bar.value = throw_force_bar.min_value

func _on_left_click_released() -> void:
	# Release the throw with current force
	if not is_charging:
		return
	
	is_charging = false
	
	if not is_instance_valid(ball) or not is_instance_valid(fisher):
		return
	
	# Calculate throw force based on progress bar value
	var force_percentage = (throw_force_bar.value - throw_force_bar.min_value) / (throw_force_bar.max_value - throw_force_bar.min_value)
	var horizontal_force = lerp(MIN_THROW_FORCE.x, max_horizontal_force, force_percentage)
	var vertical_force = BASE_VERTICAL_FORCE # Keep vertical force constant for consistent arc
	
	var throw_force = Vector2(horizontal_force, vertical_force)
	
	# Trigger fisher arm animation, then throw ball
	if fisher.has_method("trigger_throw"):
		fisher.call("trigger_throw", throw_force)
		# Store throw force for when animation completes
		_pending_throw_force = throw_force
		# Connect to throw_completed signal to actually throw the ball
		if not fisher.is_connected("throw_completed", _on_fisher_throw_completed):
			fisher.connect("throw_completed", _on_fisher_throw_completed)

var _pending_throw_force: Vector2 = Vector2.ZERO

func _on_fisher_throw_completed() -> void:
	# Fisher arm animation complete, now throw the ball with stored force
	if is_instance_valid(ball) and ball.has_method("request_throw"):
		ball.call("request_throw", _pending_throw_force)
	# Also trigger the dog to walk and fall into water (no chasing the ball)
	if is_instance_valid(dog) and dog.has_method("trigger_fall_to_water"):
		dog.call("trigger_fall_to_water")

## Fish bite system utilities

## Get all fish currently biting the bait
func get_biting_fish() -> Array:
	var biting_fish: Array = []
	
	if not is_instance_valid(fish_container):
		return biting_fish
	
	for fish in fish_container.get_children():
		if fish.has_method("is_biting") and fish.call("is_biting"):
			biting_fish.append(fish)
	
	return biting_fish

## Release all fish from the bait
func release_all_fish() -> void:
	var biting_fish = get_biting_fish()
	
	for fish in biting_fish:
		if fish.has_method("release_from_bait"):
			fish.call("release_from_bait")
	
	if biting_fish.size() > 0:
		print("Released ", biting_fish.size(), " fish from bait")

## Check if any fish is biting
func has_fish_biting() -> bool:
	return get_biting_fish().size() > 0
