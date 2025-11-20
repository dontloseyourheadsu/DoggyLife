extends RigidBody2D

## Fish script: exposes available species textures and provides wandering swim behaviour
## Includes bite detection system based on distance and rarity

@export var speed: float = 60.0
@export var swim_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO) # Set by parent scene
@export var change_dir_interval: float = 3.5
@export var water_surface_y: float = 0.0 # Provided by spawner: Y position of actual water surface

var _time_accum: float = 0.0
var _direction: Vector2 = Vector2.RIGHT
var _current_texture_path: String = ""

# Bite system
var _is_biting: bool = false
var _is_pursuing_bait: bool = false # Fish is actively swimming towards bait
var _bait_target: Node2D = null
var _bait_check_timer: float = 0.0
const BAIT_CHECK_INTERVAL: float = 5.0 # Check every 3 seconds if fish notices bait
const MAX_DETECTION_DISTANCE: float = 250.0 # Max distance to notice bait (pixels)
const MIN_DETECTION_DISTANCE: float = 50.0 # Minimum distance for guaranteed detection
const BITE_REACH_DISTANCE: float = 15.0 # How close to get before actually biting
const PURSUIT_SPEED_MULTIPLIER: float = 1.3 # Swim faster when chasing bait

# Easy-capture state (first fish hit by ball)
var _easy_capture: bool = false

func _ready() -> void:
	# Pick an initial random direction
	randomize()
	_direction = _random_direction()
	_update_velocity()
	
	# Find bait in scene (StringTip node)
	_find_bait()

func _physics_process(delta: float) -> void:
	# Easy-capture behavior: float to surface and stop
	if _easy_capture:
		var target_surface_y := water_surface_y if water_surface_y != 0.0 else swim_bounds.position.y
		# Move upward until reaching surface; then stop and sleep
		if global_position.y > target_surface_y + 2.0:
			# Ascend straight up, kill horizontal movement
			linear_velocity = Vector2(0, -55.0) # a bit faster so player notices
			return
		else:
			# At surface: freeze fully
			linear_velocity = Vector2.ZERO
			freeze = true
			gravity_scale = 0.0
			set_deferred("sleeping", true)
			return

	# If biting, stay attached to bait
	if _is_biting and is_instance_valid(_bait_target):
		_stick_to_bait()
		return
	
	# If pursuing bait, swim towards it
	if _is_pursuing_bait and is_instance_valid(_bait_target):
		_pursue_bait()
		return
	
	# Normal swimming behavior
	_time_accum += delta
	if _time_accum >= change_dir_interval:
		_time_accum = 0.0
		_direction = _random_direction()
		_update_velocity()
	
	# Bait detection system - check every 3 seconds if fish notices bait
	_bait_check_timer += delta
	if _bait_check_timer >= BAIT_CHECK_INTERVAL:
		_bait_check_timer = 0.0
		_check_if_notices_bait()

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
			_current_texture_path = texture_path

func set_random_species() -> void:
	var species = list_species_paths()
	if species.size() == 0:
		return
	set_species(species[randi() % species.size()])

## Bite system methods

func _find_bait() -> void:
	# Search for the bait (StringTip) in the scene
	var scene_root = get_tree().current_scene
	if scene_root:
		_bait_target = _find_node_by_name(scene_root, "StringTip")
		if _bait_target:
			print("Fish found bait: ", _bait_target.name)

func _find_node_by_name(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var result = _find_node_by_name(child, node_name)
		if result:
			return result
	return null

func _check_if_notices_bait() -> void:
	# Don't check if already pursuing/biting or no bait available
	if _is_biting or _is_pursuing_bait or not is_instance_valid(_bait_target):
		return
	
	# Check if bait is visible (dog is swimming)
	if not _bait_target.visible:
		return
	
	# Check if another fish already caught the bait
	if _is_bait_occupied():
		return
	
	# Calculate distance to bait
	var distance = global_position.distance_to(_bait_target.global_position)
	
	# Too far to notice
	if distance > MAX_DETECTION_DISTANCE:
		return
	
	# Calculate distance-based probability multiplier
	# Closer = higher chance (1.0 at MIN_DETECTION_DISTANCE, decreasing to 0.0 at MAX_DETECTION_DISTANCE)
	var distance_factor = clamp(1.0 - (distance - MIN_DETECTION_DISTANCE) / (MAX_DETECTION_DISTANCE - MIN_DETECTION_DISTANCE), 0.0, 1.0)
	
	# Get base probability from rarity
	var fish_rarity_data = preload("res://scenes/fish-capture/fishes/fish_rarity_data.gd")
	var base_probability = fish_rarity_data.get_base_bite_probability(_current_texture_path)
	
	# Final probability combines distance and rarity
	var final_probability = base_probability * distance_factor
	
	# Roll to see if fish notices the bait
	if randf() < final_probability:
		_start_pursuing_bait()

func _is_bait_occupied() -> bool:
	# Check if any other fish in scene is already biting
	var scene_root = get_tree().current_scene
	var fish_container = scene_root.get_node_or_null("Camera2D/Fishes")
	if not fish_container:
		return false
	
	for fish in fish_container.get_children():
		if fish != self and fish.has_method("is_biting") and fish.call("is_biting"):
			return true
	
	return false

func _start_pursuing_bait() -> void:
	_is_pursuing_bait = true
	
	var species_name = "Unknown"
	if _current_texture_path != "":
		species_name = _current_texture_path.get_file().get_basename()
	
	var fish_rarity_data = preload("res://scenes/fish-capture/fishes/fish_rarity_data.gd")
	var rarity = fish_rarity_data.get_fish_rarity(_current_texture_path)
	var rarity_name = fish_rarity_data.get_rarity_name(rarity)
	
	print("👀 ", species_name, " (", rarity_name, ") noticed the bait and is swimming towards it!")

func _pursue_bait() -> void:
	if not is_instance_valid(_bait_target):
		_stop_pursuing()
		return
	
	# Check if another fish already caught it
	if _is_bait_occupied():
		_stop_pursuing()
		return
	
	# Calculate direction to bait
	var to_bait = _bait_target.global_position - global_position
	var distance = to_bait.length()
	
	# If close enough, bite!
	if distance <= BITE_REACH_DISTANCE:
		_bite_bait()
		return
	
	# Swim towards bait with increased speed
	_direction = to_bait.normalized()
	linear_velocity = _direction * speed * PURSUIT_SPEED_MULTIPLIER
	
	# Update sprite facing
	var sprite := get_node_or_null("Sprite2D")
	if sprite:
		sprite.flip_h = _direction.x < 0

func _bite_bait() -> void:
	if _is_biting:
		return
	
	_is_biting = true
	
	# Get fish species name for logging
	var species_name = "Unknown"
	if _current_texture_path != "":
		species_name = _current_texture_path.get_file().get_basename()
	
	# Get rarity info
	var fish_rarity_data = preload("res://scenes/fish-capture/fishes/fish_rarity_data.gd")
	var rarity = fish_rarity_data.get_fish_rarity(_current_texture_path)
	var rarity_name = fish_rarity_data.get_rarity_name(rarity)
	
	print("🎣 Fish bit the bait! Species: ", species_name, " (", rarity_name, ")")
	
	# Stop swimming - freeze physics
	freeze = true
	linear_velocity = Vector2.ZERO
	gravity_scale = 0.0

func _stick_to_bait() -> void:
	# Manually position fish at bait location
	if is_instance_valid(_bait_target):
		global_position = _bait_target.global_position
		linear_velocity = Vector2.ZERO
		
		# Keep fish oriented toward bait direction
		var sprite := get_node_or_null("Sprite2D")
		if sprite:
			# Flip sprite to face the direction of movement/attachment
			sprite.flip_h = false

func _stop_pursuing() -> void:
	if not _is_pursuing_bait:
		return
	
	_is_pursuing_bait = false
	_direction = _random_direction()
	_update_velocity()
	
	print("Fish stopped pursuing bait")

## Public API to release fish from bait
func release_from_bait() -> void:
	if not _is_biting:
		return
	
	_is_biting = false
	
	# Resume normal swimming
	freeze = false
	gravity_scale = 0.0
	_direction = _random_direction()
	_update_velocity()
	
	print("Fish released from bait")

## Check if this fish is currently biting
func is_biting() -> bool:
	return _is_biting

## Check if this fish is pursuing the bait
func is_pursuing() -> bool:
	return _is_pursuing_bait

## Stop this fish from pursuing (called when another fish catches bait)
func stop_pursuing() -> void:
	_is_pursuing_bait = false

# --- Easy-capture public helpers -------------------------------------------
func mark_easy_capture() -> void:
	if _easy_capture:
		return
	# Stop AI/bite/pursuit and float up
	_is_biting = false
	_is_pursuing_bait = false
	_easy_capture = true
	# Neutralize current movement immediately
	linear_velocity = Vector2.ZERO
	gravity_scale = 0.0
	speed = 0.0
	set_deferred("sleeping", false)
	# Flip to a neutral pose (optional: could rotate or change sprite modulate)
	_direction = Vector2.ZERO
	var sprite := get_node_or_null("Sprite2D")
	if sprite:
		sprite.flip_h = false
	print('[EasyCapture] Fish marked. pos=', global_position, ' surface_y=', water_surface_y)

func is_easy_capture() -> bool:
	return _easy_capture

func get_species_key() -> String:
	return _current_texture_path

func is_catchable() -> bool:
	# Fish can be caught if it's either marked easy-capture or currently biting the bait.
	return _easy_capture or _is_biting
