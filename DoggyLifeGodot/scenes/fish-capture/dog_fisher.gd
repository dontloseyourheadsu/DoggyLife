extends CharacterBody2D

## Dog Fisher: State machine for idle and swimming states
## When in water, the dog swims at surface level with wave motion
## Player can control left/right movement with input mappings

enum State {
	IDLE,
	SWIMMING
}

@onready var dog_animations: AnimatedSprite2D = $DogAnimations
@onready var string_line: Line2D = $StringLine
@onready var string_tip: Polygon2D = $StringTip

var current_state: State = State.IDLE
var initial_position: Vector2 = Vector2.ZERO
var water_zone: Area2D = null
var facing: int = 1 # 1 = right, -1 = left (last horizontal direction)

# Trigger to make the dog walk right and fall into water when ball is thrown
var _fall_trigger_active: bool = false

# Chasing parameters
const GRAVITY: float = 980.0
const WALK_TO_WATER_SPEED: float = 90.0

# Swimming parameters
const SWIM_SPEED: float = 150.0
const WAVE_AMPLITUDE_PIXELS: float = 12.0 # vertical bob amplitude in pixels (2x stronger)
const WAVE_FREQUENCY: float = 9.0 # How fast the waves oscillate (3x more frequent)
const SUBMERGE_OFFSET_PIXELS: float = 10.0 # how deep (pixels) the dog sits below water top (half body-ish)
# Passive floating (when no input): lower amplitude and frequency
const PASSIVE_WAVE_AMPLITUDE_PIXELS: float = 4.0
const PASSIVE_WAVE_FREQUENCY: float = 7.0
var wave_time: float = 0.0
var surface_y: float = 0.0 # The y-position where dog swims at surface

# String (pixel rope) parameters
const STRING_LENGTH_PIXELS: float = 64.0
const STRING_SEGMENTS: int = 14
## Low constant water ripple (slower and subtler)
const WATER_WAVE_FREQ: float = 0.25 # Hz, gentle constant frequency
const WATER_CURVE_AMPLITUDE: float = 1.0 # pixels of lateral curve
const WATER_ENVELOPE_POWER: float = 1.0

## Damped spring controlling rope angle based on dog horizontal velocity
const ROPE_MAX_ANGLE_DEG: float = 24.0
const ROPE_VELOCITY_TO_ANGLE: float = 1.6 # scale of velocity->angle mapping
const ROPE_SPRING: float = 6.0
const ROPE_DAMPING: float = 6.5
const ROPE_MAX_ANGULAR_SPEED: float = 1.4 # rad/s cap for slow return

var water_time: float = 0.0
var rope_angle: float = 0.0
var rope_ang_vel: float = 0.0

func _ready() -> void:
	initial_position = global_position
	# Find the water zone in the scene
	_find_water_zone()
	# Set initial animation
	if dog_animations:
		dog_animations.play("sit-right")
	# Initialize string once
	_update_string(0.0)
	# Hide rope/tip unless swimming
	if is_instance_valid(string_line):
		string_line.visible = false
	if is_instance_valid(string_tip):
		string_tip.visible = false

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle_state(delta)
		State.SWIMMING:
			_process_swimming_state(delta)

	# Update rope angle dynamics (lags behind dog movement, then dampens)
	_update_rope_angle(delta)
	water_time += delta

	# Always update string after movement so it stays attached to the dog center
	_update_string(delta)
	
	move_and_slide()

func _process_idle_state(delta: float) -> void:
	# If already in water, transition
	if _is_in_water_zone():
		_fall_trigger_active = false
		_enter_swimming_state()
		return

	if _fall_trigger_active:
		# Walk right until we leave the floor and reach the water area; let gravity handle the fall
		velocity.x = WALK_TO_WATER_SPEED
		velocity.y += GRAVITY * delta
		facing = 1
		if dog_animations:
			dog_animations.play("walk-right")
		# If we reached water, switch state
		if _is_in_water_zone():
			_enter_swimming_state()
			_fall_trigger_active = false
	else:
		# Stay idle
		velocity = Vector2.ZERO
		if dog_animations:
			dog_animations.play("sit-right")

func _process_swimming_state(delta: float) -> void:
	# Check if we should exit water (shouldn't happen, but for reset)
	if not _is_in_water_zone():
		_enter_idle_state()
		return
	
	var input_direction: float = 0.0
	
	# Get horizontal input
	if Input.is_action_pressed("left_move"):
		input_direction = -1.0
	elif Input.is_action_pressed("right_move"):
		input_direction = 1.0
	
	# Set horizontal velocity
	velocity.x = input_direction * SWIM_SPEED

	# Decide facing from input when present
	if input_direction != 0:
		facing = -1 if input_direction < 0 else 1

	# Wave bob: active when moving (strong/fast), passive when idle (gentle/slow)
	wave_time += delta
	if input_direction != 0:
		var target_y = surface_y + sin(wave_time * WAVE_FREQUENCY) * WAVE_AMPLITUDE_PIXELS
		# Move toward target_y smoothly and do not use vertical velocity (no up/down swim control)
		global_position.y = lerp(global_position.y, target_y, 0.35)
		velocity.y = 0
	else:
		var passive_target_y = surface_y + sin(wave_time * PASSIVE_WAVE_FREQUENCY) * PASSIVE_WAVE_AMPLITUDE_PIXELS
		global_position.y = lerp(global_position.y, passive_target_y, 0.2)
		velocity.y = 0

	# In water: show a static swim pose, no walking animation
	_set_swim_pose()
	
	# Clamp position to stay in water zone
	_clamp_to_water_zone()

func _enter_swimming_state() -> void:
	current_state = State.SWIMMING
	wave_time = 0.0
	_fall_trigger_active = false
	velocity = Vector2.ZERO
	
	# Calculate surface level (top of water zone + half the dog's height to be half-submerged)
	if water_zone:
		var water_rect = _get_water_zone_rect()
		# Position dog a bit below the top edge of water zone (surface level + submerge)
		surface_y = water_rect.position.y + SUBMERGE_OFFSET_PIXELS * global_scale.y
		global_position.y = surface_y

	# Immediately switch to static swim pose
	_set_swim_pose()
	# Show rope and tip when swimming
	if is_instance_valid(string_line):
		string_line.visible = true
	if is_instance_valid(string_tip):
		string_tip.visible = true
	
	print("Dog entered swimming state")

func _enter_idle_state() -> void:
	current_state = State.IDLE
	velocity = Vector2.ZERO
	if dog_animations:
		dog_animations.play("sit-right")
	# Hide rope and tip outside of swimming
	if is_instance_valid(string_line):
		string_line.visible = false
	if is_instance_valid(string_tip):
		string_tip.visible = false
	print("Dog entered idle state")

func _is_in_water_zone() -> bool:
	if not water_zone:
		return false
	
	var water_rect = _get_water_zone_rect()
	return water_rect.has_point(global_position)

func _get_water_zone_rect() -> Rect2:
	if not water_zone:
		return Rect2()
	
	# Get the collision shape of the water zone
	var collision_shape = water_zone.get_node("CollisionShape2D")
	if not collision_shape or not collision_shape.shape:
		return Rect2()
	
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		return Rect2()
	
	# Calculate world rect from shape
	var shape_size = shape.size
	var water_global_pos = water_zone.global_position + collision_shape.position
	var rect_pos = water_global_pos - shape_size / 2
	
	return Rect2(rect_pos, shape_size)

func _clamp_to_water_zone() -> void:
	if not water_zone:
		return
	
	var water_rect = _get_water_zone_rect()
	
	# Clamp horizontal position to water zone bounds
	if global_position.x < water_rect.position.x:
		global_position.x = water_rect.position.x
		velocity.x = 0
	elif global_position.x > water_rect.position.x + water_rect.size.x:
		global_position.x = water_rect.position.x + water_rect.size.x
		velocity.x = 0
	
	# Keep dog near computed surface_y; allow full bob amplitude plus small margin
	var min_y = surface_y - (WAVE_AMPLITUDE_PIXELS + 2.0)
	var max_y = surface_y + (WAVE_AMPLITUDE_PIXELS + 2.0)
	
	if global_position.y < min_y:
		global_position.y = min_y
	elif global_position.y > max_y:
		global_position.y = max_y

func _set_swim_pose() -> void:
	if not dog_animations:
		return
	# Choose left/right sit pose and stop playback so legs don't animate
	dog_animations.speed_scale = 0.0
	dog_animations.stop()
	if facing < 0:
		dog_animations.animation = "sit-left"
	else:
		dog_animations.animation = "sit-right"
	# Ensure first frame is displayed
	dog_animations.frame = 0

func _is_ball_thrown() -> bool:
	return false

func _find_water_zone() -> void:
	# Search for water zone in the scene tree
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	
	# Try to find WaterZone node
	water_zone = _find_node_by_name(scene_root, "WaterZone")
	
	if water_zone:
		print("Found WaterZone")
	else:
		print("Warning: WaterZone not found!")

func trigger_fall_to_water() -> void:
	# Public API: called by scene when ball is thrown to make the dog walk and fall into water
	if current_state == State.IDLE:
		_fall_trigger_active = true

func _find_node_by_name(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_name(child, node_name)
		if result:
			return result
	
	return null

## Public API for resetting dog position (called when ball is reset)
func reset_dog() -> void:
	global_position = initial_position
	velocity = Vector2.ZERO
	_enter_idle_state()

# --- Pixel string helpers ---
func _update_string(delta: float) -> void:
	if not is_instance_valid(string_line):
		return

	# Base from damped spring angle (bottom swings most)
	var base: Vector2 = Vector2(0, STRING_LENGTH_PIXELS).rotated(rope_angle)
	var normal: Vector2 = base.orthogonal().normalized()

	var points := PackedVector2Array()
	points.resize(STRING_SEGMENTS + 1)
	for i in range(STRING_SEGMENTS + 1):
		var t: float = float(i) / float(STRING_SEGMENTS)
		# Position along the straight rope
		var p: Vector2 = base * t
		# Gentle constant-frequency water ripple (no per-segment frequency/phase differences)
		var env: float = pow(t, WATER_ENVELOPE_POWER)
		var lateral: float = WATER_CURVE_AMPLITUDE * env * sin(water_time * TAU * WATER_WAVE_FREQ)
		p += normal * lateral
		# Pixel snap for crispness
		points[i] = Vector2(round(p.x), round(p.y))

	string_line.points = points
	# Always keep rope anchored at the Dog node origin
	string_line.position = Vector2.ZERO
	# Place 2x2 tip square at the bottom point
	if is_instance_valid(string_tip):
		var tip_pos: Vector2 = points[STRING_SEGMENTS]
		string_tip.position = Vector2(round(tip_pos.x), round(tip_pos.y))

func _update_rope_angle(delta: float) -> void:
	# Map dog horizontal velocity to a target rope angle when swimming; otherwise target 0
	var target_angle: float = 0.0
	if current_state == State.SWIMMING:
		var vel_ratio: float = 0.0
		if SWIM_SPEED != 0.0:
			vel_ratio = clamp(velocity.x / SWIM_SPEED, -1.0, 1.0)
		target_angle = deg_to_rad(ROPE_MAX_ANGLE_DEG) * vel_ratio * ROPE_VELOCITY_TO_ANGLE
	# Damped spring: theta'' = -k(theta - target) - c*theta'
	var acc: float = - ROPE_SPRING * (rope_angle - target_angle) - ROPE_DAMPING * rope_ang_vel
	rope_ang_vel += acc * delta
	# Cap angular speed to enforce slow, heavy water feel
	rope_ang_vel = clamp(rope_ang_vel, -ROPE_MAX_ANGULAR_SPEED, ROPE_MAX_ANGULAR_SPEED)
	rope_angle += rope_ang_vel * delta
