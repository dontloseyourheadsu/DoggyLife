extends RigidBody2D

var difficulty: int = 1

var initial_position: Vector2 = Vector2(0,0)
# A flag to tell _integrate_forces what to do
var _needs_reset: bool = false

func _ready() -> void:
	initial_position = global_position
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
		state.transform.origin = initial_position
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		
		# 6. We can set node properties here, too.
		#    Freezing it ensures it stays put.
		freeze = true
		
		# 7. Unset the flag so this only runs once
		_needs_reset = false
		
		# 8. NOW we defer the _throw_ball,
		#    so it runs on the next IDLE frame,
		#    safely outside the physics step.
		call_deferred("_throw_ball")

func _throw_ball() -> void:
	# This is now safe, as it runs on a new frame
	# after the reset is complete.
	freeze = false 
	_apply_random_impulse_to_ball()

func _apply_random_impulse_to_ball() -> void:
	var random_impulse := Vector2(randf_range(-400.0, 400.0), 0)

	# Ensure it's not zero
	if random_impulse.x == 0:
		random_impulse.x = 200.0

	apply_central_impulse(random_impulse)
