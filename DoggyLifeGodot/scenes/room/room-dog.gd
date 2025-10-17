extends CharacterBody2D

@onready var animated_dog_sprite: AnimatedSprite2D = $DogAnimations
@onready var movement_timer = Timer.new()
@onready var animation_timer = Timer.new()

var movement_speed = 50.0
var current_direction = Vector2.ZERO
var is_moving = false
var last_action_was_sit = false
var _scratch_escape_dir: Vector2 = Vector2.ZERO

# Animation states
enum DogState {
	SITTING,
	WALKING,
	SCRATCHING
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

	# Randomly choose a dog SpriteFrames set on load
	_apply_random_dog_spriteframes()

	# Connect custom collision signal handler
	self.connect("collided_with_wall", Callable(self, "_on_collided_with_wall"))

	# Setup movement timer (drives state changes)
	add_child(movement_timer)
	movement_timer.wait_time = randf_range(2.0, 5.0) # Random time between movements
	movement_timer.timeout.connect(_on_movement_timer_timeout)
	movement_timer.start()
	
	# Setup animation timer (used for minimum durations / scratching)
	add_child(animation_timer)
	animation_timer.wait_time = 0.8 # Minimum time for 4 frames at 5 FPS (4/5 = 0.8 seconds)
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	
	# Start with a random sitting animation
	_start_sitting()

# Emitted when the character registers a slide collision (first collision of the frame)
signal collided_with_wall(collision)

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
		# Check collisions and emit signal once per frame
		if get_slide_collision_count() > 0:
			var col = get_slide_collision(0)
			if col:
				emit_signal("collided_with_wall", col)

func _start_sitting():
	current_state = DogState.SITTING
	is_moving = false
	velocity = Vector2.ZERO

	# Choose random sitting animation and hold on its last frame for 1-4 seconds
	var sit_anim = available_sit_animations[randi() % available_sit_animations.size()]
	if animated_dog_sprite and animated_dog_sprite.sprite_frames and animated_dog_sprite.sprite_frames.has_animation(sit_anim):
		animated_dog_sprite.animation = sit_anim
		# Set last frame and stop to "hold" the pose
		var last_frame := animated_dog_sprite.sprite_frames.get_frame_count(sit_anim) - 1
		animated_dog_sprite.stop()
		animated_dog_sprite.frame = max(last_frame, 0)
	else:
		play_anim(sit_anim) # fallback

	# Sitting can't follow itself: next transition must be walking
	last_action_was_sit = true
	# Use movement timer for sit duration 1-4s
	movement_timer.wait_time = randf_range(1.0, 4.0)
	movement_timer.start()

func _start_walking():
	current_state = DogState.WALKING
	is_moving = true
	last_action_was_sit = false
	
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
	
	# Optional: enforce a short minimum walking duration
	animation_timer.wait_time = randf_range(0.8, 3.0)
	animation_timer.start()

func _start_walking_in_direction(dir: Vector2):
	current_state = DogState.WALKING
	is_moving = true
	last_action_was_sit = false
	# Pick cardinal direction from vector
	var d = dir
	if d.length() == 0:
		d = Vector2(1, 0)
	if abs(d.x) >= abs(d.y):
		current_direction = Vector2(sign(d.x), 0)
		if current_direction.x < 0:
			play_anim("walk-left")
		else:
			play_anim("walk-right")
	else:
		current_direction = Vector2(0, sign(d.y))
		if current_direction.y < 0:
			play_anim("walk-back")
		else:
			play_anim("walk-front")
	animation_timer.wait_time = randf_range(0.8, 3.0)
	animation_timer.start()

func _on_movement_timer_timeout():
	# Decide next state change, but don't allow sitting twice in a row
	if current_state == DogState.SITTING:
		# Must walk after sitting
		_start_walking()
	else:
		var action_choice = randi() % 2
		if last_action_was_sit or action_choice == 1:
			_start_walking()
		else:
			_start_sitting()
	# Schedule next change window
	movement_timer.wait_time = randf_range(1.0, 4.0)
	movement_timer.start()

var _scratch_count: int = 0

func _on_animation_timer_timeout():
	# Handle special cases that need a timed end independent of movement timer
	if current_state == DogState.SCRATCHING:
		# After scratching, try to scratch again if under limit, else walk away
		if _scratch_count < 2:
			current_state = DogState.WALKING
			is_moving = true
			velocity = Vector2.ZERO
			# Immediately check for another scratch on next collision
		else:
			var dir := _scratch_escape_dir
			_scratch_escape_dir = Vector2.ZERO
			_scratch_count = 0
			_start_walking_in_direction(dir)
			# Resume normal movement timer cadence
			movement_timer.wait_time = randf_range(1.0, 4.0)
			movement_timer.start()
		return
	# For other states, movement timer decides the next change
	pass

func _on_collided_with_wall(col):
	# Allow scratching up to two times in a row, 1/24 chance each time
	if current_state != DogState.WALKING and current_state != DogState.SCRATCHING:
		return
	if _scratch_count >= 2:
		_scratch_count = 0
		return
	if int(randi() % 24) != 0:
		_scratch_count = 0
		return
	# Enter scratching state
	current_state = DogState.SCRATCHING
	is_moving = false
	velocity = Vector2.ZERO
	_scratch_count += 1
	# Choose scratch animation based on collision normal if available, else previous walking direction
	var n: Vector2 = Vector2.ZERO
	if col and col.has_method("get_normal"):
		n = col.get_normal()
	elif current_direction.length() > 0:
		n = - current_direction.normalized()
	# Determine which way to look: left if wall is on left, right otherwise
	var use_left := false
	if abs(n.x) > abs(n.y):
		use_left = n.x > 0
	elif abs(n.y) > abs(n.x):
		use_left = current_direction.x <= 0
	else:
		# If ambiguous, fallback to previous walking direction
		use_left = current_direction.x <= 0
	play_anim("scratch-left" if use_left else "scratch-right")
	# Walk away from wall after a short scratching period
	_scratch_escape_dir = n # move along normal away from wall
	animation_timer.wait_time = randf_range(0.6, 1.5)
	animation_timer.start()
