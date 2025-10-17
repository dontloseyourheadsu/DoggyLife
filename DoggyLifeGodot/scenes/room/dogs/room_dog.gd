extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $WhiteDogAnimations
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

func _ready():
	# Ensure random values are different each run
	randomize()

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

func play_anim(anim_name: String) -> void:
	# Safely play an animation if it exists, otherwise warn once
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	else:
		push_warning("Dog animation not found or sprite missing: %s" % anim_name)

func _physics_process(_delta):
	if is_moving:
		velocity = current_direction * movement_speed
		move_and_slide()

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
