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
var _chase_target: RigidBody3D = null
var push_velocity: Vector3 = Vector3.ZERO

# Signals for command progress
signal go_to_started(target_position: Vector3)
signal go_to_arrived(target_position: Vector3)
signal go_to_canceled(target_position: Vector3)

# Dog Selected Signal
signal dog_selected(dog_node: CharacterBody3D)

# Dog Care / Survival Stats (0.0 to 100.0)
var dog_name: String = "Sammy"
var dog_breed: String = "Samoyed"
var dog_key: String = ""
var weight: float = 1.0

var stat_hunger: float = 80.0
var stat_thirst: float = 85.0
var stat_hygiene: float = 90.0
var stat_energy: float = 100.0
var stat_affection: float = 75.0

# Decay/Recovery rates per second
const HUNGER_DECAY_RATE = 0.08
const THIRST_DECAY_RATE = 0.12
const HYGIENE_DECAY_RATE = 0.04
const ENERGY_DECAY_RATE_WALKING = 0.6
const ENERGY_RECOVERY_RATE_SITTING = 1.0
const AFFECTION_DECAY_RATE = 0.03

var is_exhausted: bool = false

# Mapping from dog name to SpriteFrames path
const DOG_SPRITEFRAMES_MAP: Dictionary = {
	"dog-samoyed": "res://sprites/dogs/spriteframes/samoyed-dog.tres",
	"dog-beagle": "res://sprites/dogs/spriteframes/beagle-dog.tres",
	"dog-shiba": "res://sprites/dogs/spriteframes/shiba-dog.tres",
	"dog-spaniel": "res://sprites/dogs/spriteframes/spaniel-dog.tres",
}

# Breed statistics configuration
const BREED_STATS = {
	"dog-samoyed": {
		"breed_name": "Samoyed",
		"display_name": "Sammy",
		"scale": 1.2,
		"speed": 2.0,
		"weight": 23.0
	},
	"dog-beagle": {
		"breed_name": "Beagle",
		"display_name": "Buddy",
		"scale": 0.8,
		"speed": 2.5,
		"weight": 12.0
	},
	"dog-shiba": {
		"breed_name": "Shiba Inu",
		"display_name": "Hiro",
		"scale": 0.95,
		"speed": 2.2,
		"weight": 10.0
	},
	"dog-spaniel": {
		"breed_name": "Cocker Spaniel",
		"display_name": "Charlie",
		"scale": 0.9,
		"speed": 1.8,
		"weight": 14.0
	}
}

# Get gravity from project settings
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready():
	add_to_group("dogs")
	# Ensure random values are different each run
	randomize()

	# Choose a dog SpriteFrames set based on owned dogs or dog_key
	if dog_key != "":
		initialize_breed(dog_key)
	else:
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
	
	# Randomize initial stats
	stat_hunger = randf_range(60.0, 90.0)
	stat_thirst = randf_range(60.0, 90.0)
	stat_hygiene = randf_range(70.0, 95.0)
	stat_energy = randf_range(80.0, 100.0)
	stat_affection = randf_range(60.0, 85.0)

	# Connect pickable input events
	input_ray_pickable = true
	input_event.connect(_on_input_event)

	# Start with a random sitting animation
	_start_sitting()

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		dog_selected.emit(self)

func initialize_breed(key: String) -> void:
	dog_key = key
	if not BREED_STATS.has(key):
		push_warning("Unknown dog key: %s" % key)
		return
		
	var stats = BREED_STATS[key]
	dog_breed = stats["breed_name"]
	dog_name = stats["display_name"]
	movement_speed = stats["speed"]
	weight = stats["weight"]
	
	# Apply scale to the character body
	var s = stats["scale"]
	scale = Vector3(s, s, s)
	
	# Apply SpriteFrames
	var path: String = DOG_SPRITEFRAMES_MAP.get(key, "")
	if path != "":
		var res: Resource = load(path)
		if res is SpriteFrames:
			if animated_dog_sprite:
				animated_dog_sprite.sprite_frames = res
		else:
			push_warning("Failed to load SpriteFrames: %s" % path)

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
	var key: String = owned_dogs[randi() % owned_dogs.size()]
	initialize_breed(key)

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
	var vy = velocity.y
	if not is_on_floor():
		vy -= gravity * delta
	else:
		vy = 0.0

	# Update survival stats dynamically
	stat_hunger = clamp(stat_hunger - HUNGER_DECAY_RATE * delta, 0.0, 100.0)
	stat_thirst = clamp(stat_thirst - THIRST_DECAY_RATE * delta, 0.0, 100.0)
	stat_hygiene = clamp(stat_hygiene - HYGIENE_DECAY_RATE * delta, 0.0, 100.0)
	stat_affection = clamp(stat_affection - AFFECTION_DECAY_RATE * delta, 0.0, 100.0)

	if current_state == DogState.WALKING and is_moving:
		stat_energy = clamp(stat_energy - ENERGY_DECAY_RATE_WALKING * delta, 0.0, 100.0)
		if stat_energy <= 0.0:
			is_exhausted = true
			_command_active = false
			_chase_target = null
			_start_sitting()
	else:
		stat_energy = clamp(stat_energy + ENERGY_RECOVERY_RATE_SITTING * delta, 0.0, 100.0)
		if is_exhausted and stat_energy >= 30.0:
			is_exhausted = false

	# Calculate desired horizontal velocity
	var move_vel = Vector3.ZERO
	var wall_collision_check = false
	var command_check = false

	if _chase_target:
		if not is_instance_valid(_chase_target):
			_chase_target = null
			is_moving = false
			_start_sitting()
			if movement_timer:
				movement_timer.wait_time = randf_range(0.8, 3.0)
				movement_timer.start()
		else:
			var target_xz: Vector3 = Vector3(_chase_target.global_position.x, global_position.y, _chase_target.global_position.z)
			var to_target: Vector3 = target_xz - global_position
			var to_target_3d: Vector3 = _chase_target.global_position - global_position
			if to_target_3d.length() <= 0.6:
				# Pick up the ball!
				if is_instance_valid(_chase_target):
					_chase_target.queue_free()
				_chase_target = null
				is_moving = false
				_start_sitting()
				if movement_timer:
					movement_timer.wait_time = randf_range(0.8, 3.0)
					movement_timer.start()
			else:
				var dir: Vector3 = to_target.normalized()
				is_moving = true
				current_direction = dir
				move_vel = dir * (movement_speed * 1.5)
	elif _command_active:
		var target_xz: Vector3 = Vector3(_command_target.x, global_position.y, _command_target.z)
		var to_target: Vector3 = target_xz - global_position
		if to_target.length() <= _ARRIVAL_EPS:
			_command_active = false
			is_moving = false
			_start_sitting()
			if movement_timer:
				movement_timer.wait_time = randf_range(0.8, 3.0)
				movement_timer.start()
			go_to_arrived.emit(_command_target)
		else:
			var dir: Vector3 = to_target.normalized()
			is_moving = true
			current_direction = dir
			move_vel = dir * movement_speed
			wall_collision_check = true
			command_check = true
	elif is_moving:
		move_vel = current_direction * movement_speed
		wall_collision_check = true

	# Combine movement velocity, push velocity, and gravity
	velocity = move_vel + push_velocity
	velocity.y = vy

	# Decay push velocity
	push_velocity = push_velocity.move_toward(Vector3.ZERO, delta * 10.0)

	# Update animations and move
	if is_moving or not push_velocity.is_zero_approx():
		_update_sprite_animation()
	
	move_and_slide()

	# Handle collisions
	var collided_with_wall = is_on_wall()
	
	# Process slide collisions for dog-to-dog pushes
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("dogs") and collider != self:
			var normal = collision.get_normal()
			var push_dir = Vector3(normal.x, 0.0, normal.z).normalized()
			if push_dir.is_zero_approx():
				push_dir = (global_position - collider.global_position)
				push_dir.y = 0.0
				push_dir = push_dir.normalized()
			
			# Lighter dogs (low weight) get pushed further than heavier ones (high weight)
			# Weight ratio: other weight / our weight
			var force_magnitude = 5.0 * (collider.weight / weight)
			push_velocity = push_dir * force_magnitude

	if wall_collision_check and collided_with_wall:
		if command_check:
			_command_active = false
			go_to_canceled.emit(_command_target)
		_handle_collision()

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
	var wall_normal := Vector3.ZERO
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()
		if abs(normal.y) < 0.707:
			wall_normal = normal
			break
			
	if not wall_normal.is_zero_approx():
		var normal_xz: Vector3 = Vector3(wall_normal.x, 0.0, wall_normal.z)
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
	
	# Lose hygiene immediately from scratching!
	stat_hygiene = clamp(stat_hygiene - 3.0, 0.0, 100.0)
	
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
	if _command_active or _chase_target:
		return

	if is_exhausted:
		_start_sitting()
		movement_timer.wait_time = randf_range(0.8, 3.0)
		movement_timer.start()
		return

	var action_choice = randi() % 100
	if current_state == DogState.SITTING:
		# Prevent consecutive sitting. Choose between walking (90%) and scratching (10%)
		if action_choice < 90:
			_start_walking()
		else:
			_start_scratching()
	else:
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
	if is_exhausted:
		return
	_chase_target = null
	_command_target = target
	_command_active = true
	current_state = DogState.WALKING
	is_moving = true
	if movement_timer:
		movement_timer.stop()
	if animation_timer:
		animation_timer.stop()
	go_to_started.emit(target)

func chase_ball(ball: RigidBody3D) -> void:
	"""Command the dog to chase the thrown 3D ball."""
	if is_exhausted:
		return
	_chase_target = ball
	_command_active = false
	_command_target = Vector3.INF
	current_state = DogState.WALKING
	is_moving = true
	if movement_timer:
		movement_timer.stop()
	if animation_timer:
		animation_timer.stop()

func cancel_command() -> void:
	_command_active = false
	_command_target = Vector3.INF
	_chase_target = null
