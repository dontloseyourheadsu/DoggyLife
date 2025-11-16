extends RigidBody2D

# Matches red_ball.gd pattern exactly
# Public API: request_throw(force), request_reset(), is_thrown()

var initial_position: Vector2 = Vector2(0, 0)
var _needs_reset: bool = false
var _pending_force: Vector2 = Vector2.ZERO

func _ready() -> void:
	# EXACTLY like red_ball: store global_position
	initial_position = global_position
	freeze = true

func request_throw(force: Vector2) -> void:
	if not freeze:
		return
	_pending_force = force
	# Call deferred to throw on next frame
	call_deferred("_throw_ball")

func request_reset() -> void:
	if freeze:
		return
	_needs_reset = true

func is_thrown() -> bool:
	return not freeze

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# EXACTLY like red_ball pattern
	if _needs_reset:
		# Set state.transform.origin directly to initial_position
		state.transform.origin = initial_position
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		set_deferred("freeze", true)
		_needs_reset = false
		_pending_force = Vector2.ZERO

func _throw_ball() -> void:
	# EXACTLY like red_ball: unfreeze then apply impulse
	freeze = false
	apply_central_impulse(_pending_force)
