extends RigidBody2D

# Matches red_ball.gd pattern exactly
# Public API: request_throw(force), request_reset(), is_thrown()

var initial_position: Vector2 = Vector2(0, 0)
var _needs_reset: bool = false
var _pending_force: Vector2 = Vector2.ZERO
var _first_hit_applied: bool = false

# Water physics
var _in_water: bool = false
var _is_floating: bool = false
const BUOYANCY_FORCE: float = 150.0 # Upward force when in water (makes it float)
const WATER_DRAG: float = 0.95 # Drag coefficient in water (slows down movement)
const SINK_FORCE: float = 5.0 # Gradual downward force to sink slowly
const FLOAT_TIME: float = 2.0 # How long the ball floats before starting to sink
var _float_timer: float = 0.0

func _ready() -> void:
	# EXACTLY like red_ball: store global_position
	initial_position = global_position
	freeze = true
	# Enable contact monitoring for first-hit detection
	contact_monitor = true
	max_contacts_reported = 8
	
	# Connect to water zone signals
	var water_zone = get_node_or_null("../../WaterZone")
	if water_zone:
		water_zone.body_entered.connect(_on_water_entered)
		water_zone.body_exited.connect(_on_water_exited)

func request_throw(force: Vector2) -> void:
	if not freeze:
		return
	_pending_force = force
	_first_hit_applied = false
	# Call deferred to throw on next frame
	call_deferred("_throw_ball")

func request_reset() -> void:
	if freeze:
		return
	_needs_reset = true
	_in_water = false
	_is_floating = false
	_float_timer = 0.0
	_first_hit_applied = false

func is_thrown() -> bool:
	return not freeze

func _process(delta: float) -> void:
	# Track float time when in water and floating
	if _in_water and _is_floating and not freeze:
		_float_timer += delta

	# Fallback collision scan (some contacts might not appear inside _integrate_forces first frame)
	if not freeze and not _first_hit_applied:
		var bodies := get_colliding_bodies()
		for b in bodies:
			if b and b.has_method("mark_easy_capture"):
				print('[Ball] First fish hit (process) -> marking easy capture: ', b.name)
				b.call_deferred("mark_easy_capture")
				_first_hit_applied = true
				break

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
		return
	
	# Apply water physics when in water
	if _in_water and not freeze:
		# Apply drag to slow down the ball in water
		state.linear_velocity *= WATER_DRAG
		
		if _is_floating:
			# Float on surface for a while
			if _float_timer < FLOAT_TIME:
				# Strong upward force to keep ball at surface
				state.apply_central_force(Vector2(0, -BUOYANCY_FORCE))
				# Dampen vertical movement to stabilize at surface
				if abs(state.linear_velocity.y) > 5.0:
					state.linear_velocity.y *= 0.8
			else:
				# After float time, gradually sink
				state.apply_central_force(Vector2(0, SINK_FORCE))

	# Detect first collision with a fish this throw and mark it easy-capture
	if not freeze and not _first_hit_applied:
		var contact_count := state.get_contact_count()
		for i in range(contact_count):
			var collider := state.get_contact_collider_object(i)
			if collider and collider is Node:
				# Only act on fish that expose the API
				if collider.has_method("mark_easy_capture"):
					print('[Ball] First fish hit (integrate) -> marking easy capture: ', collider.name)
					collider.call_deferred("mark_easy_capture")
					_first_hit_applied = true
					break

func _on_water_entered(body: Node2D) -> void:
	if body == self:
		_in_water = true
		_is_floating = true
		_float_timer = 0.0
		# Reduce gravity effect when entering water
		gravity_scale = 0.1

func _on_water_exited(body: Node2D) -> void:
	if body == self:
		_in_water = false
		_is_floating = false
		_float_timer = 0.0
		# Restore normal gravity
		gravity_scale = 1.0

func _throw_ball() -> void:
	# EXACTLY like red_ball: unfreeze then apply impulse
	freeze = false
	apply_central_impulse(_pending_force)
