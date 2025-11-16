extends Sprite2D

## Fisher: controls arm throw animation only.
## External usage: call `trigger_throw(Vector2(x_force, y_force))` to animate arm.
## Emits throw_completed signal when arm animation finishes.
## Ball control is handled by the parent scene.

signal throw_completed

@onready var arm: Sprite2D = $Arm

var _arm_tween: Tween
var _throw_in_progress: bool = false

var _arm_start_pos: Vector2
var _arm_start_rot: float

func _ready() -> void:
	_arm_start_pos = arm.position
	_arm_start_rot = arm.rotation

## Public API ---------------------------------------------------------------
func trigger_throw(force: Vector2) -> void:
	# Ignore if animation ongoing or force zero
	if _throw_in_progress or force == Vector2.ZERO:
		return
	_throw_in_progress = true
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
	# Notify that arm animation is complete
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

## Public: reset arm to initial position ------------------------
func reset_arm() -> void:
	if _arm_tween and _arm_tween.is_valid():
		_arm_tween.kill()
	arm.rotation = _arm_start_rot
	arm.position = _arm_start_pos
	_throw_in_progress = false
