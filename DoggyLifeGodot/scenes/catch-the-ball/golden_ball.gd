extends RigidBody2D

@export var is_left_side: bool = true

var difficulty: int = 1

var initial_position: Vector2 = Vector2(0, 0)
# A flag to tell _integrate_forces what to do
var _needs_reset: bool = false
var can_throw_ball: bool = true

# Signal to notify when caught by the dog
signal ball_caught(points: int)

func _ready() -> void:
	initial_position = global_position
	visible = false
	# Randomize difficulty level (1-5)
	difficulty = randi_range(1, 5)
	# Connect the timer timeout signal
	$Timer.timeout.connect(_on_timer_timeout)
	_throw_ball()

# 1. This is called *during* the physics step
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("wall"):
		# 2. Just set the flag. Don't try to change anything.
		_needs_reset = true
	elif body.is_in_group("catcher"):
		# Dog caught the golden ball! Award 2 points
		ball_caught.emit(2)
		_needs_reset = true

# 3. This is called automatically every physics frame
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# 4. We check our flag
	if _needs_reset:
		# 5. Reset to initial position (not random like red ball)
		state.transform.origin = initial_position
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		
		# 6. We can set node properties here, too.
		#    Freezing it ensures it stays put.
		set_deferred("freeze", true)
		set_deferred("visible", false)
		
		# 7. Unset the flag so this only runs once
		_needs_reset = false
		
		# 8. Start the timer before throwing the ball again
		call_deferred("_start_throw_timer")
		
		# 9. Randomize difficulty for next throw
		call_deferred("_randomize_difficulty")

func _randomize_difficulty() -> void:
	difficulty = randi_range(1, 5)

func _start_throw_timer() -> void:
	# Set the wait time based on difficulty level
	var min_wait: float
	var max_wait: float
	
	match difficulty:
		5:
			min_wait = 3.0
			max_wait = 5.0
		4:
			min_wait = 4.0
			max_wait = 6.0
		3:
			min_wait = 5.0
			max_wait = 7.0
		2:
			min_wait = 6.0
			max_wait = 8.0
		1:
			min_wait = 7.0
			max_wait = 9.0
		_:
			min_wait = 7.0
			max_wait = 9.0
	
	# Set a random wait time within the range
	var wait_time: float = randf_range(min_wait, max_wait)
	$Timer.wait_time = wait_time
	can_throw_ball = false
	$Timer.start()

func _on_timer_timeout() -> void:
	can_throw_ball = true
	_throw_ball()

func _throw_ball() -> void:
	# Only throw if allowed
	if not can_throw_ball:
		return
	
	# Make visible before throwing
	visible = true
	# This is now safe, as it runs on a new frame
	# after the reset is complete.
	freeze = false
	_apply_impulse_to_ball()

func _apply_impulse_to_ball() -> void:
	# Use the exposed variable to determine direction
	var impulse: Vector2 = Vector2(800, 0) if is_left_side else Vector2(-800, 0)
	apply_central_impulse(impulse)
