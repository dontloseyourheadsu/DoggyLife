extends CharacterBody3D

@onready var animated_dog_sprite: AnimatedSprite3D = $DogAnimations3D
@onready var movement_timer = Timer.new()
@onready var animation_timer = Timer.new()

var movement_speed = 2.0 # In 3D, coordinates are in meters, so 2.0 is a good walking speed
var current_direction = Vector3.ZERO
var is_moving = false

# Animation states
enum DogState {
	SITTING,
	WALKING,
	SCRATCHING
}

var current_state = DogState.SITTING
var last_collision_direction = Vector3.ZERO
var last_face_dir = "front" # Keep track of last direction for sits/scratches

# Scratch tracking
var scratch_count = 0
const MAX_SCRATCHES = 2

# Commanded walking state
var _command_active: bool = false
var _command_target: Vector3 = Vector3.INF
const _ARRIVAL_EPS := 0.25

# Signals for command progress
signal go_to_started(target_position: Vector3)
signal go_to_arrived(target_position: Vector3)
signal go_to_canceled(target_position: Vector3)

# Mapping from dog name to SpriteFrames path
const DOG_SPRITEFRAMES_MAP: Dictionary = {
	"dog-samoyed": "res://sprites/dogs/spriteframes/samoyed-dog.tres",
	"dog-beagle": "res://sprites/dogs/spriteframes/beagle-dog.tres",
	"dog-shiba": "res://sprites/dogs/spriteframes/shiba-dog.tres",
	"dog-spaniel": "res://sprites/dogs/spriteframes/spaniel-dog.tres",
}

# Get gravity from project settings
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready():
	# Ensure random values are different each run
	randomize()

	# Choose a dog SpriteFrames set based on owned dogs
	_apply_owned_dog_spriteframes()

	# Setup movement timer
	add_child(movement_timer)
	movement_timer.wait_time = randf_range(1.5, 3.5)
	movement_timer.timeout.connect(_on_movement_timer_timeout)
	movement_timer.start()
	
	# Setup animation timer
	add_child(animation_timer)
	animation_timer.wait_time = 0.8
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	
	# Start with a random sitting animation
	_start_sitting()

func _apply_owned_dog_spriteframes() -> void:
	if not animated_dog_sprite:
		return
	
	# Get owned dogs from player data
	var player_data := PlayerData.load_player_data()
	var owned_dogs: Array[String] = []
	
	for item_name in player_data.owned_items:
		if item_name.begins_with("dog-") and DOG_SPRITEFRAMES_MAP.has(item_name):
			owned_dogs.append(item_name)
	
	# If no owned dogs, fallback to samoyed
	if owned_dogs.is_empty():
		owned_dogs.append("dog-samoyed")
	
	# Pick a random owned dog
	var dog_name: String = owned_dogs[randi() % owned_dogs.size()]
	var path: String = DOG_SPRITEFRAMES_MAP[dog_name]
	var res: Resource = load(path)
	if res is SpriteFrames:
		animated_dog_sprite.sprite_frames = res
	else:
		push_warning("Failed to load dog SpriteFrames: %s" % path)

func play_anim(anim_name: String) -> void:
	if animated_dog_sprite and animated_dog_sprite.sprite_frames and animated_dog_sprite.sprite_frames.has_animation(anim_name):
		if animated_dog_sprite.animation != anim_name or not animated_dog_sprite.is_playing():
			animated_dog_sprite.play(anim_name)
	else:
		push_warning("Dog 3D animation not found: %s" % anim_name)

func _process(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if _command_active:
		# Calculate direction on XZ plane only
		var target_xz: Vector3 = Vector3(_command_target.x, global_position.y, _command_target.z)
		var to_target: Vector3 = target_xz - global_position
		
		if to_target.length() <= _ARRIVAL_EPS:
			# Arrived
			_command_active = false
			is_moving = false
			velocity.x = 0.0
			velocity.z = 0.0
			_start_sitting()
			
			# Resume autonomous timer cycle
			if movement_timer:
				movement_timer.wait_time = randf_range(0.8, 3.0)
				movement_timer.start()
			go_to_arrived.emit(_command_target)
		else:
			var dir: Vector3 = to_target.normalized()
			is_moving = true
			current_direction = dir
			velocity.x = dir.x * movement_speed
			velocity.z = dir.z * movement_speed

			_update_sprite_animation()
			move_and_slide()

			if get_slide_collision_count() > 0:
				_command_active = false
				go_to_canceled.emit(_command_target)
				_handle_collision()
	elif is_moving:
		velocity.x = current_direction.x * movement_speed
		velocity.z = current_direction.z * movement_speed
		
		_update_sprite_animation()
		move_and_slide()
		
		if get_slide_collision_count() > 0:
			_handle_collision()
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()

func _update_sprite_animation() -> void:
	var move_vec: Vector3 = velocity
	move_vec.y = 0.0
	if move_vec.is_zero_approx():
		return

	# Fallback to world axes if camera is not available
	var cam_forward: Vector3 = Vector3.FORWARD
	var cam_right: Vector3 = Vector3.RIGHT
	var camera: Camera3D = get_viewport().get_camera_3d()
	
	if camera:
		# Extract camera's flat XZ direction vectors
		cam_forward = -camera.global_transform.basis.z
		cam_forward.y = 0.0
		if cam_forward.is_zero_approx():
			cam_forward = Vector3.FORWARD
		else:
			cam_forward = cam_forward.normalized()

		cam_right = camera.global_transform.basis.x
		cam_right.y = 0.0
		if cam_right.is_zero_approx():
			cam_right = Vector3.RIGHT
		else:
			cam_right = cam_right.normalized()

	# Project velocity onto camera coordinates
	var right_dot = move_vec.dot(cam_right)
	var forward_dot = move_vec.dot(cam_forward)

	# Decide which animation to play based on dominant axis of motion relative to camera view
	if abs(right_dot) > abs(forward_dot):
		if right_dot > 0.0:
			play_anim("walk-right")
			last_face_dir = "right"
		else:
			play_anim("walk-left")
			last_face_dir = "left"
	else:
		if forward_dot > 0.0:
			# Moving away from camera (forward in world space, up/back on screen)
			play_anim("walk-back")
			last_face_dir = "back"
		else:
			# Moving towards camera (backward in world space, down/front on screen)
			play_anim("walk-front")
			last_face_dir = "front"

func _handle_collision():
	is_moving = false
	velocity.x = 0.0
	velocity.z = 0.0
	
	last_collision_direction = current_direction
	
	# 25% chance to scratch on collision
	if scratch_count < MAX_SCRATCHES and randi() % 4 == 0:
		_start_scratching()
	else:
		_start_walking_away_from_collision()
	
	movement_timer.stop()
	movement_timer.wait_time = randf_range(1.0, 4.0)
	movement_timer.start()

func _start_sitting():
	current_state = DogState.SITTING
	is_moving = false
	velocity.x = 0.0
	velocity.z = 0.0
	scratch_count = 0
	
	# Select sitting animation based on last face direction
	match last_face_dir:
		"left":
			play_anim("sit-left")
		"right":
			play_anim("sit-right")
		_:
			play_anim("sit-front")
	
	animation_timer.wait_time = randf_range(0.8, 2.0)
	animation_timer.start()

func _start_walking():
	current_state = DogState.WALKING
	is_moving = true
	
	# Pick a random 3D direction vector on XZ plane
	var angle = randf_range(0, 2 * PI)
	current_direction = Vector3(cos(angle), 0, sin(angle)).normalized()
	
	animation_timer.wait_time = randf_range(0.6, 2.0)
	animation_timer.start()

func _start_walking_away_from_collision():
	current_state = DogState.WALKING
	is_moving = true
	
	# Default fallback direction
	var new_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	
	# If we collided, walk away from the obstacle normal
	if get_slide_collision_count() > 0:
		var normal: Vector3 = get_slide_collision(0).get_normal()
		var normal_xz: Vector3 = Vector3(normal.x, 0.0, normal.z)
		if not normal_xz.is_zero_approx():
			# Add random angle offset so dog doesn't bounce straight back
			var angle = randf_range(-PI / 3.0, PI / 3.0)
			new_dir = normal_xz.rotated(Vector3.UP, angle).normalized()
			
	current_direction = new_dir
	
	animation_timer.wait_time = randf_range(0.6, 2.0)
	animation_timer.start()

func _start_scratching():
	current_state = DogState.SCRATCHING
	is_moving = false
	velocity.x = 0.0
	velocity.z = 0.0
	scratch_count += 1
	
	# Select scratching animation based on last face direction
	if last_face_dir == "left":
		play_anim("scratch-left")
	else:
		play_anim("scratch-right")
	
	animation_timer.wait_time = randf_range(1.0, 1.5)
	animation_timer.start()
	
	# Resume walking after scratch animation completes
	await get_tree().create_timer(animation_timer.wait_time).timeout
	if current_state == DogState.SCRATCHING:
		if scratch_count >= MAX_SCRATCHES:
			scratch_count = 0
		_start_walking_away_from_collision()

func _on_movement_timer_timeout():
	if _command_active:
		return

	var action_choice = randi() % 100
	if action_choice < 45:
		_start_sitting()
	elif action_choice < 95:
		_start_walking()
	else:
		_start_scratching()
	
	movement_timer.wait_time = randf_range(0.8, 3.0)
	movement_timer.start()

func _on_animation_timer_timeout():
	pass

# =============== Public API ===============
func go_to_global_position(target: Vector3) -> void:
	"""Command the dog to walk towards the given global 3D position on XZ plane."""
	_command_target = target
	_command_active = true
	current_state = DogState.WALKING
	is_moving = true
	if movement_timer:
		movement_timer.stop()
	if animation_timer:
		animation_timer.stop()
	go_to_started.emit(target)

func cancel_command() -> void:
	_command_active = false
	_command_target = Vector3.INF
