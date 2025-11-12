extends RigidBody2D

# Replicates safe reset/throw pattern using physics integration flags
# Public API: request_throw(force), request_reset()

var _initial_local_pos: Vector2
var _needs_reset: bool = false
var _needs_throw: bool = false
var _pending_force: Vector2 = Vector2.ZERO

func _ready() -> void:
	_initial_local_pos = position
	freeze = true

func request_throw(force: Vector2) -> void:
	if _needs_throw or not freeze:
		return
	_pending_force = force
	_needs_throw = true

func request_reset() -> void:
	if freeze:
		return
	_needs_reset = true

func is_thrown() -> bool:
	return not freeze

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _needs_reset:
		# Restore transform locally
		state.transform.origin = _get_global_initial_pos()
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		set_deferred("freeze", true)
		_needs_reset = false
		_pending_force = Vector2.ZERO
		return
	if _needs_throw:
		# Unfreeze then apply impulse next frame
		set_deferred("freeze", false)
		call_deferred("_apply_pending_force")
		_needs_throw = false

func _get_global_initial_pos() -> Vector2:
	# Convert stored local back to global (in case Fisher moved)
	return (get_parent() as Node2D).to_global(_initial_local_pos)

func _apply_pending_force() -> void:
	if _pending_force != Vector2.ZERO:
		apply_central_impulse(_pending_force)
		_pending_force = Vector2.ZERO
