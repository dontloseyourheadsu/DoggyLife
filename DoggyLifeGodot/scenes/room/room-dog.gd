extends CharacterBody2D

@onready var animated_dog_sprite: AnimatedSprite2D = $DogAnimations
@onready var movement_timer = Timer.new()
@onready var animation_timer = Timer.new()

var movement_speed = 25.0 # Reduced from 50.0 for smaller movements
var current_direction = Vector2.ZERO
var is_moving = false

# Animation states
enum DogState {
	SITTING,
	WALKING,
	SCRATCHING
}

var current_state = DogState.SITTING
var last_collision_direction = Vector2.ZERO # Track last collision direction
var available_walk_animations = ["walk-front", "walk-back", "walk-left", "walk-right"]
var available_sit_animations = ["sit-front", "sit-left", "sit-right"]
var available_scratch_animations = ["scratch-left", "scratch-right"]

# Scratch tracking
var scratch_count = 0
const MAX_SCRATCHES = 2

# Mapping from dog name to SpriteFrames path
const DOG_SPRITEFRAMES_MAP: Dictionary = {
	"dog-samoyed": "res://sprites/dogs/spriteframes/samoyed-dog.tres",
	"dog-beagle": "res://sprites/dogs/spriteframes/beagle-dog.tres",
	"dog-shiba": "res://sprites/dogs/spriteframes/shiba-dog.tres",
	"dog-spaniel": "res://sprites/dogs/spriteframes/spaniel-dog.tres",
}

func _ready():
	# Ensure random values are different each run
	randomize()

	# Place the dog in the high z band so it never goes behind the base floor.
	# Use absolute z to decouple from parent TileMap's z.
	z_as_relative = false
	z_index = 1000

	# Choose a dog SpriteFrames set based on owned dogs
	_apply_owned_dog_spriteframes()

	# Setup movement timer
	add_child(movement_timer)
	movement_timer.wait_time = randf_range(1.5, 3.5) # Reduced from 2.0-5.0 for shorter walks
	movement_timer.timeout.connect(_on_movement_timer_timeout)
	movement_timer.start()
	
	# Setup animation timer
	add_child(animation_timer)
	animation_timer.wait_time = 0.8 # Minimum time for 4 frames at 5 FPS (4/5 = 0.8 seconds)
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	
	# Start with a random sitting animation
	_start_sitting()

	# Initial z-order update for floor items relative to the dog
	_update_floor_items_z()

func _apply_owned_dog_spriteframes() -> void:
	if not animated_dog_sprite:
		return
	
	# Get owned dogs from player data
	var player_data := PlayerData.load_player_data()
	var owned_dogs: Array[String] = []
	
	for item_name in player_data.owned_items:
		if item_name.begins_with("dog-") and DOG_SPRITEFRAMES_MAP.has(item_name):
			owned_dogs.append(item_name)
	
	# If no owned dogs (should never happen per game design), throw exception
	if owned_dogs.is_empty():
		push_error("GAME DESIGN ERROR: Player has no owned dogs! This should never happen.")
		return
	
	# Pick a random owned dog
	var dog_name: String = owned_dogs[randi() % owned_dogs.size()]
	var path: String = DOG_SPRITEFRAMES_MAP[dog_name]
	var res: Resource = load(path)
	if res is SpriteFrames:
		animated_dog_sprite.sprite_frames = res
	else:
		push_warning("Failed to load dog SpriteFrames: %s" % path)

func play_anim(anim_name: String) -> void:
	# Safely play an animation if it exists, otherwise warn once
	if animated_dog_sprite and animated_dog_sprite.sprite_frames and animated_dog_sprite.sprite_frames.has_animation(anim_name):
		animated_dog_sprite.play(anim_name)
	else:
		push_warning("Dog animation not found or sprite missing: %s" % anim_name)

func _physics_process(_delta):
	if is_moving:
		velocity = current_direction * movement_speed
		move_and_slide()
		
		# Check for collision
		if get_slide_collision_count() > 0:
			_handle_collision()
		
		# Update z-order of floor items when the dog moves
		_update_floor_items_z()

func _handle_collision():
	# Stop moving
	is_moving = false
	velocity = Vector2.ZERO
	
	# Store the collision direction
	last_collision_direction = current_direction
	
	# Decide whether to scratch or change direction
	# 25% chance to scratch if we haven't reached max scratches (reduced from 50%)
	if scratch_count < MAX_SCRATCHES and randi() % 4 == 0:
		_start_scratching()
	else:
		# Walk away in a different direction (not the collision direction)
		_start_walking_away_from_collision()
	
	# Cancel current movement timer and restart
	movement_timer.stop()
	movement_timer.wait_time = randf_range(1.0, 4.0)
	movement_timer.start()

func _start_sitting():
	current_state = DogState.SITTING
	is_moving = false
	velocity = Vector2.ZERO
	scratch_count = 0 # Reset scratch count when sitting
	
	# Play random sitting animation
	var sit_anim = available_sit_animations[randi() % available_sit_animations.size()]
	play_anim(sit_anim)
	
	# Start animation timer to ensure animation plays for at least 0.8 seconds
	animation_timer.wait_time = randf_range(0.8, 2.0)
	animation_timer.start()

func _start_walking():
	current_state = DogState.WALKING
	is_moving = true
	
	# Choose random direction and corresponding animation
	var direction_choice = randi() % 4
	match direction_choice:
		0: # Front (down)
			current_direction = Vector2(0, 1)
			play_anim("walk-front")
		1: # Back (up)
			current_direction = Vector2(0, -1)
			play_anim("walk-back")
		2: # Left
			current_direction = Vector2(-1, 0)
			play_anim("walk-left")
		3: # Right
			current_direction = Vector2(1, 0)
			play_anim("walk-right")
	
	# Start animation timer to ensure animation plays for at least 0.8 seconds
	animation_timer.wait_time = randf_range(0.6, 2.0) # Reduced max from 3.0 to 2.0
	animation_timer.start()

func _start_walking_away_from_collision():
	"""Walk in a direction different from the last collision direction."""
	current_state = DogState.WALKING
	is_moving = true
	
	# Get all possible directions
	var directions = [
		Vector2(0, 1), # Front (down)
		Vector2(0, -1), # Back (up)
		Vector2(-1, 0), # Left
		Vector2(1, 0), # Right
	]
	
	# Filter out the collision direction and its immediate opposite would still hit
	# Instead, prefer perpendicular directions or opposite
	var valid_directions = []
	for dir in directions:
		# Avoid walking in the same direction as collision
		if dir.dot(last_collision_direction) <= 0: # Not in same direction
			valid_directions.append(dir)
	
	# If we somehow have no valid directions, use all
	if valid_directions.is_empty():
		valid_directions = directions
	
	# Pick a random valid direction
	var chosen_dir = valid_directions[randi() % valid_directions.size()]
	current_direction = chosen_dir
	
	# Set corresponding animation
	if chosen_dir == Vector2(0, 1):
		play_anim("walk-front")
	elif chosen_dir == Vector2(0, -1):
		play_anim("walk-back")
	elif chosen_dir == Vector2(-1, 0):
		play_anim("walk-left")
	elif chosen_dir == Vector2(1, 0):
		play_anim("walk-right")
	
	# Start animation timer
	animation_timer.wait_time = randf_range(0.6, 2.0) # Reduced max from 3.0 to 2.0
	animation_timer.start()

func _start_scratching():
	current_state = DogState.SCRATCHING
	is_moving = false
	velocity = Vector2.ZERO
	scratch_count += 1
	
	# Play random scratching animation
	var scratch_anim = available_scratch_animations[randi() % available_scratch_animations.size()]
	play_anim(scratch_anim)
	
	# Scratch animation should play for a reasonable time
	animation_timer.wait_time = randf_range(1.0, 1.5)
	animation_timer.start()
	
	# After scratching, walk away in a safe direction
	# Use async to wait for scratch animation to complete
	await get_tree().create_timer(animation_timer.wait_time).timeout
	
	# After each scratch (not just after MAX_SCRATCHES), walk away
	if scratch_count >= MAX_SCRATCHES:
		scratch_count = 0 # Reset for next collision session
	
	_start_walking_away_from_collision()

func _on_movement_timer_timeout():
	# Decide whether to sit, walk, or scratch
	# 45% sit, 50% walk, 5% scratch (reduced scratch frequency)
	var action_choice = randi() % 100

	if action_choice < 45:
		_start_sitting()
	elif action_choice < 95:
		_start_walking()
	else:
		_start_scratching()
	
	# Set next movement timer
	movement_timer.wait_time = randf_range(0.8, 3.0) # Reduced from 1.0-4.0 for quicker state changes
	movement_timer.start()

func _on_animation_timer_timeout():
	# Animation has played long enough, we can change state
	# The movement timer will handle the actual state change
	pass

# Inform the FloorItemsLayer to update per-tile z-indexing relative to the dog
func _update_floor_items_z() -> void:
	var camera2d := get_parent() # FloorLayer
	if camera2d and camera2d.get_parent():
		var floor_items_layer := camera2d.get_parent().get_node_or_null("FloorItemsLayer")
		if floor_items_layer and floor_items_layer.has_method("update_z_order_relative_to"):
			# Pass global position adjusted by half the sprite's height (approx feet)
			var adjusted_pos := global_position
			if animated_dog_sprite and animated_dog_sprite.sprite_frames:
				var anim_name := animated_dog_sprite.animation
				var frame := animated_dog_sprite.frame
				var tex: Texture2D = animated_dog_sprite.sprite_frames.get_frame_texture(anim_name, frame)
				if tex:
					adjusted_pos += Vector2(0, tex.get_size().y * 2)
			floor_items_layer.update_z_order_relative_to(adjusted_pos)
