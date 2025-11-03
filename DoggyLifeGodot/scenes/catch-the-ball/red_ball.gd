extends RigidBody2D

var difficulty: int = 1

var initial_position: Vector2 = Vector2(0, 0)
# A flag to tell _integrate_forces what to do
var _needs_reset: bool = false
var can_throw_ball: bool = true

func _ready() -> void:
	initial_position = Vector2(0, global_position.y)
	# Connect the timer timeout signal
	$Timer.timeout.connect(_on_timer_timeout)
	_throw_ball()

# 1. This is called *during* the physics step
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("wall"):
		# 2. Just set the flag. Don't try to change anything.
		_needs_reset = true

# 3. This is called automatically every physics frame
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# 4. We check our flag
	if _needs_reset:
		# 5. Directly set the state. This is the "proper" way.
		#    We use state.transform.origin, which is the
		#    physics-engine-safe way to set global_position.
		var random_point: int = randi_range(50, 150)
		var random_inverse: int = randi_range(-2, 1)
		
		if random_inverse == 0:
			random_inverse = 1
		elif random_inverse == -2:
			random_inverse = -1
			
		var random_start_point: int = random_point * random_inverse
		
		state.transform.origin = Vector2(random_start_point, initial_position.y)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		
		# 6. We can set node properties here, too.
		#    Freezing it ensures it stays put.
		set_deferred("freeze", true)
		
		# 7. Unset the flag so this only runs once
		_needs_reset = false
		
		# 8. Start the timer before throwing the ball again
		call_deferred("_start_throw_timer")

func _start_throw_timer() -> void:
	# Set the wait time based on difficulty level
	var min_wait: float
	var max_wait: float
	
	match difficulty:
		3:
			min_wait = 3.0
			max_wait = 5.0
		2:
			min_wait = 4.0
			max_wait = 6.0
		1:
			min_wait = 5.0
			max_wait = 7.0
		_:
			min_wait = 5.0
			max_wait = 7.0
	
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
	
	# This is now safe, as it runs on a new frame
	# after the reset is complete.
	freeze = false
	_apply_random_impulse_to_ball()

func _apply_random_impulse_to_ball() -> void:
	var random_impulse: Vector2 = Vector2(-250, 0) if (position.x < 0) else Vector2(250, 0)

	apply_central_impulse(random_impulse)
