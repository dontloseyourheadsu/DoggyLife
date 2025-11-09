extends RigidBody2D

## Fish script: exposes available species textures and provides wandering swim behaviour

@export var speed: float = 60.0
@export var swim_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO) # Set by parent scene
@export var change_dir_interval: float = 3.5

var _time_accum: float = 0.0
var _direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Pick an initial random direction
	randomize()
	_direction = _random_direction()
	_update_velocity()

func _physics_process(delta: float) -> void:
	_time_accum += delta
	if _time_accum >= change_dir_interval:
		_time_accum = 0.0
		_direction = _random_direction()
		_update_velocity()

	# Boundary handling: if leaving swim_bounds, nudge back & flip direction component
	if swim_bounds.size != Vector2.ZERO:
		var pos: Vector2 = global_position
		var changed := false
		if pos.x < swim_bounds.position.x:
			pos.x = swim_bounds.position.x
			_direction.x = abs(_direction.x)
			changed = true
		elif pos.x > swim_bounds.position.x + swim_bounds.size.x:
			pos.x = swim_bounds.position.x + swim_bounds.size.x
			_direction.x = - abs(_direction.x)
			changed = true
		if pos.y < swim_bounds.position.y:
			pos.y = swim_bounds.position.y
			_direction.y = abs(_direction.y)
			changed = true
		elif pos.y > swim_bounds.position.y + swim_bounds.size.y:
			pos.y = swim_bounds.position.y + swim_bounds.size.y
			_direction.y = - abs(_direction.y)
			changed = true
		if changed:
			global_position = pos
			_update_velocity(true)

func _update_velocity(force: bool = false) -> void:
	linear_velocity = _direction.normalized() * speed
	# Flip sprite based on horizontal direction
	var sprite := get_node_or_null("Sprite2D")
	if sprite:
		# Facing right = not flipped, left = flipped
		sprite.flip_h = _direction.x < 0
	if force:
		# ensure physics server updates immediately
		pass

func _random_direction() -> Vector2:
	var v = Vector2(randf_range(-1.0, 1.0), randf_range(-0.4, 0.4)) # limit vertical variation so fish mainly swim horizontally
	if v.length() < 0.2:
		v = Vector2(sign(v.x) if v.x != 0 else 1, 0) # ensure some movement
	return v.normalized()

## Species utilities
static func list_species_paths() -> Array:
	# Scans fish image folders for non-outline pngs
	var roots = ["res://scenes/fish-capture/fishes/images/fresh_water", "res://scenes/fish-capture/fishes/images/salt_water"]
	var result: Array = []
	for root in roots:
		var dir := DirAccess.open(root)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with(".png") and not file_name.contains("_outline"):
					result.append(root + "/" + file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
	return result

func set_species(texture_path: String) -> void:
	var sprite := get_node_or_null("Sprite2D")
	if sprite and texture_path != "":
		var tex := load(texture_path)
		if tex:
			sprite.texture = tex

func set_random_species() -> void:
	var species = list_species_paths()
	if species.size() == 0:
		return
	set_species(species[randi() % species.size()])
