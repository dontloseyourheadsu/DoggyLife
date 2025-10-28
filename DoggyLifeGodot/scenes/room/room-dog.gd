extends CharacterBody2D

@onready var animated_dog_sprite: AnimatedSprite2D = $DogAnimations
@onready var movement_timer = Timer.new()
@onready var animation_timer = Timer.new()

var movement_speed = 50.0
var current_direction = Vector2.ZERO
var is_moving = false

# Animation states
enum DogState {
	SITTING,
	WALKING
}

var current_state = DogState.SITTING
var available_walk_animations = ["walk-front", "walk-back", "walk-left", "walk-right"]
var available_sit_animations = ["sit-front", "sit-left", "sit-right"]
var available_scratch_animations = ["scratch-left", "scratch-right"]

# Paths to available dog SpriteFrames (breeds)
const DOG_SPRITEFRAMES_PATHS: Array[String] = [
	"res://sprites/dogs/spriteframes/samoyed-dog.tres",
	"res://sprites/dogs/spriteframes/beagle-dog.tres",
	"res://sprites/dogs/spriteframes/shiba-dog.tres",
	"res://sprites/dogs/spriteframes/spaniel-dog.tres",
]

func _ready():
	# Ensure random values are different each run
	randomize()

	# Place the dog in the high z band so it never goes behind the base floor.
	# Use absolute z to decouple from parent TileMap's z.
	z_as_relative = false
	z_index = 1000

	# Randomly choose a dog SpriteFrames set on load
	_apply_random_dog_spriteframes()

	# Setup movement timer
	add_child(movement_timer)
	movement_timer.wait_time = randf_range(2.0, 5.0) # Random time between movements
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

func _apply_random_dog_spriteframes() -> void:
	if not animated_dog_sprite:
		return
	if DOG_SPRITEFRAMES_PATHS.is_empty():
		return
	var idx := int(randi() % DOG_SPRITEFRAMES_PATHS.size())
	var path: String = DOG_SPRITEFRAMES_PATHS[idx]
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
		# Update z-order of floor items when the dog moves
		_update_floor_items_z()

func _start_sitting():
	current_state = DogState.SITTING
	is_moving = false
	velocity = Vector2.ZERO
	
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
	animation_timer.wait_time = randf_range(0.8, 3.0)
	animation_timer.start()

func _on_movement_timer_timeout():
	# Decide whether to sit or walk
	var action_choice = randi() % 2
	
	if action_choice == 0:
		_start_sitting()
	else:
		_start_walking()
	
	# Set next movement timer
	movement_timer.wait_time = randf_range(1.0, 4.0)
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
