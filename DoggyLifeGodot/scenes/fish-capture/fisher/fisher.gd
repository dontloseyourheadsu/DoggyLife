extends Sprite2D

## Fisher: controls arm throw animation and launches the ball.
## External usage: call `trigger_throw(Vector2(x_force, y_force))` from another scene.
## The ball starts frozen; on trigger we animate the arm, unfreeze the ball safely,
## and apply the impulse on the next frame to avoid physics-loop issues.

signal throw_completed

@onready var arm: Sprite2D = $Arm
@onready var ball: RigidBody2D = $Ball

var _arm_tween: Tween
var _throw_in_progress: bool = false
var _pending_force: Vector2 = Vector2.ZERO

var _arm_start_pos: Vector2
var _arm_start_rot: float
var _ball_start_local_pos: Vector2

func _ready() -> void:
	_arm_start_pos = arm.position
	_arm_start_rot = arm.rotation
	_ball_start_local_pos = ball.position
	# Ensure ball starts frozen so it won't move until commanded.
	ball.freeze = true

## Public API ---------------------------------------------------------------
func trigger_throw(force: Vector2) -> void:
	# Ignore if animation ongoing or force zero or ball already thrown.
	if _throw_in_progress or force == Vector2.ZERO:
		return
	if ball.has_method("is_thrown") and ball.call("is_thrown"):
		return
	_throw_in_progress = true
	_pending_force = force
	_animate_arm_forward()

## Internal helpers ---------------------------------------------------------
func _animate_arm_forward() -> void:
	if _arm_tween and _arm_tween.is_valid():
		_arm_tween.kill()
	_arm_tween = create_tween()
	# Rotate to 0 radians (pointing right) and move x to 0.
	_arm_tween.tween_property(arm, "rotation", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_arm_tween.parallel().tween_property(arm, "position", Vector2(0, _arm_start_pos.y), 0.25)
	_arm_tween.tween_callback(Callable(self, "_on_arm_forward_finished"))

func _on_arm_forward_finished() -> void:
	_apply_force_to_ball()

func _apply_force_to_ball() -> void:
	# Delegate to ball script for physics-safe throw pattern.
	if is_instance_valid(ball) and ball.has_method("request_throw"):
		ball.call("request_throw", _pending_force)
	emit_signal("throw_completed")
	_reset_arm()

func _do_impulse() -> void:
	# Legacy; kept in case of external calls. Now delegated.
	if not is_instance_valid(ball):
		_finish_throw()
		return
	if ball.has_method("request_throw"):
		ball.call("request_throw", _pending_force)
	emit_signal("throw_completed")
	_reset_arm()

func _reset_arm() -> void:
	if _arm_tween and _arm_tween.is_valid():
		_arm_tween.kill()
	_arm_tween = create_tween()
	_arm_tween.tween_property(arm, "rotation", _arm_start_rot, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_arm_tween.parallel().tween_property(arm, "position", _arm_start_pos, 0.2)
	_arm_tween.tween_callback(Callable(self, "_finish_throw"))

func _finish_throw() -> void:
	_throw_in_progress = false
	_pending_force = Vector2.ZERO

## Optional utility: manually refreeze the ball (e.g., after it lands) --------
func refreeze_ball() -> void:
	# Use deferred to avoid changing during physics step, mirroring safe pattern.
	if is_instance_valid(ball):
		ball.set_deferred("freeze", true)

## Public: has the ball been thrown (i.e., currently not frozen)? --------------
func is_ball_thrown() -> bool:
	if not is_instance_valid(ball):
		return false
	if ball.has_method("is_thrown"):
		return ball.call("is_thrown")
	return not ball.freeze

## Public: reset the ball safely back to start position ------------------------
func reset_ball() -> void:
	if not is_instance_valid(ball):
		return
	if _arm_tween and _arm_tween.is_valid():
		_arm_tween.kill()
	arm.rotation = _arm_start_rot
	arm.position = _arm_start_pos
	_pending_force = Vector2.ZERO
	_throw_in_progress = false
	if ball.has_method("request_reset"):
		ball.call("request_reset")
	else:
		ball.set_deferred("freeze", true)
		call_deferred("_do_reset_ball")

func _do_reset_ball() -> void:
	if not is_instance_valid(ball):
		return
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0.0
	ball.rotation = 0.0
	# Restore local position relative to Fisher, so the reset follows Fisher movement.
	ball.position = _ball_start_local_pos
