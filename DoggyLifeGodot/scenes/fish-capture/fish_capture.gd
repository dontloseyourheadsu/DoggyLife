extends Node2D

const FishRarityData = preload("res://scenes/fish-capture/fishes/fish_rarity_data.gd")

@onready var fish_container: Node2D = $Camera2D/Fishes
@onready var water_zone: Area2D = $Camera2D/WaterZone
@onready var background: TextureRect = $Camera2D/Background
@onready var fisher: Sprite2D = $Camera2D/Fisher
@onready var ball: RigidBody2D = $Camera2D/Ball
@onready var dog: CharacterBody2D = $Camera2D/Dog
@onready var throw_force_bar: TextureProgressBar = $Camera2D/ThrowForce
@onready var fight_force_bar: TextureProgressBar = $Camera2D/FightForce
@onready var fight_bar_indicator: TextureRect = $Camera2D/FightForce/CountBar
@onready var escaping_fish_tex: TextureRect = $Camera2D/FightForce/EscapingFish
@onready var score_summary: Node2D = $ScoreSummary

# Throw force calculation based on progress bar
const MIN_THROW_FORCE: Vector2 = Vector2(100, -50) # Minimum throw force (close distance)
const BASE_VERTICAL_FORCE: float = -100.0 # Base upward force for arc
var max_horizontal_force: float = 0.0 # Calculated based on water zone width

# Progress bar settings
const FORCE_BUILD_SPEED: float = 50.0 # How fast the bar fills per second
var is_charging: bool = false

@export var num_fish: int = 10 # Number of fish to spawn
@export var min_fish_speed: float = 80.0 # Minimum fish swim speed
@export var max_fish_speed: float = 140.0 # Maximum fish swim speed
@export var min_change_dir_interval: float = 1.5 # Min seconds between direction changes
@export var max_change_dir_interval: float = 3.0 # Max seconds between direction changes
@export var fish_swim_lower_percentage: float = 0.6 # Fish swim in lower 60% of water zone (leaving top 40% for dog)
const FISH_SCENE: String = "res://scenes/fish-capture/fishes/fish.tscn"

# Local (scene-scoped) capture stats
var _caught_fish_total: int = 0
var _caught_fish_counts: Dictionary = {}

# Fight (fish struggle) system state
const FIGHT_MAX_STEPS: int = 100
const FIGHT_GAIN_STEPS_PER_SEC: float = 30.0
const FIGHT_LOSS_STEPS_PER_SEC: float = 30.0
const FIGHT_OUTSIDE_LOSS_DELAY: float = 0.5
const FIGHT_INDICATOR_MOVE_SPEED: float = 50.0 # player controlled indicator speed (pixels/sec)
const FIGHT_FISH_BASE_SPEED: float = 30.0 # escaping fish speed
const FIGHT_FISH_ESCAPE_THRESHOLD: int = 0
const FIGHT_BAR_OFFSET_Y: float = 30.0 # Offset for visual alignment

var fight_active: bool = false
var fight_current_steps: float = 0.0
var fight_outside_timer: float = 0.0
var _fight_target_fish: RigidBody2D = null # actual fish biting
var _fight_fish_direction: float = 1.0 # 1 down, -1 up
var _fight_percentage_label: Label = null


func _ready() -> void:
	_calculate_max_throw_force()
	_spawn_fish()
	# Initialize throw force bar hidden until player starts charging
	throw_force_bar.value = throw_force_bar.min_value
	throw_force_bar.visible = false
	
	# Create percentage label for fight
	_fight_percentage_label = Label.new()
	_fight_percentage_label.visible = false
	# Add to Camera2D so it moves with camera, but not rotated with bar
	$Camera2D.add_child(_fight_percentage_label)
	
	if score_summary:
		score_summary.time_limit = 60.0 # 1 minute
		score_summary.auto_calculate_coins = false
		score_summary.game_over.connect(_on_game_over)
		score_summary.start_game()

func _on_game_over() -> void:
	# Disable interactions
	set_process_unhandled_input(false)
	set_process(false)
	# Stop fight
	_end_fight(true)

func _process(delta: float) -> void:
	if is_charging:
		# Build up throw force
		throw_force_bar.value = min(throw_force_bar.value + FORCE_BUILD_SPEED * delta, throw_force_bar.max_value)
	# Allow dog to auto-catch easy-capture (dead) fish near the string tip
	_check_dog_catch_easy_fish()

	# Fight phase handling
	if not fight_active:
		# Start fight if any fish is biting
		var biting = get_biting_fish()
		if biting.size() > 0:
			_start_fight(biting[0])
	else:
		_update_fight(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_left_click_pressed()
		else:
			_on_left_click_released()

func _calculate_max_throw_force() -> void:
	# Calculate the maximum throw force needed to reach the end of the water zone
	if not is_instance_valid(water_zone):
		push_error("WaterZone not found for force calculation")
		max_horizontal_force = 500.0 # Fallback
		return
	
	var collision_shape = water_zone.get_node("CollisionShape2D")
	if not collision_shape or not collision_shape.shape:
		push_error("WaterZone CollisionShape2D not found")
		max_horizontal_force = 500.0 # Fallback
		return
	
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		push_error("WaterZone shape is not a RectangleShape2D")
		max_horizontal_force = 500.0 # Fallback
		return
	
	# Calculate horizontal distance from ball to end of water zone
	var zone_pos = water_zone.global_position
	var shape_offset = collision_shape.position
	var shape_size = shape.size
	
	var water_zone_right = zone_pos.x + shape_offset.x + shape_size.x / 2.0
	var ball_start_x = ball.global_position.x
	var distance_to_end = water_zone_right - ball_start_x
	
	# Set max force to cover this distance (empirically tuned for physics)
	# Adjust this multiplier if needed based on testing
	max_horizontal_force = distance_to_end * 0.8

func _calculate_swim_bounds() -> Rect2:
	# Get WaterZone's actual collision shape bounds
	if not is_instance_valid(water_zone):
		push_error("WaterZone not found")
		return Rect2()
	
	var collision_shape = water_zone.get_node("CollisionShape2D")
	if not collision_shape or not collision_shape.shape:
		push_error("WaterZone CollisionShape2D not found")
		return Rect2()
	
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		push_error("WaterZone shape is not a RectangleShape2D")
		return Rect2()
	
	# Calculate global bounds from WaterZone position + CollisionShape offset + shape size
	var zone_pos = water_zone.global_position
	var shape_offset = collision_shape.position
	var shape_size = shape.size
	
	# Top-left corner of the full water zone rectangle
	var full_top_left = zone_pos + shape_offset - shape_size / 2.0
	
	# Restrict fish to swim in the lower portion (e.g., lower 60% for dog clearance)
	var restricted_height = shape_size.y * fish_swim_lower_percentage
	var vertical_offset = shape_size.y * (1.0 - fish_swim_lower_percentage)
	
	# Adjust top position down and reduce height
	var fish_top_left = full_top_left + Vector2(0, vertical_offset)
	var fish_size = Vector2(shape_size.x, restricted_height)
	
	return Rect2(fish_top_left, fish_size)

func _get_water_surface_y() -> float:
	# Top of the full WaterZone rectangle (water surface)
	if not is_instance_valid(water_zone):
		return 0.0
	var collision_shape = water_zone.get_node("CollisionShape2D")
	if not collision_shape or not collision_shape.shape:
		return 0.0
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		return 0.0
	var zone_pos = water_zone.global_position
	var shape_offset = collision_shape.position
	var shape_size = shape.size
	var full_top_left = zone_pos + shape_offset - shape_size / 2.0
	return full_top_left.y

func _spawn_fish() -> void:
	var swim_rect: Rect2 = _calculate_swim_bounds()
	
	if swim_rect.size == Vector2.ZERO:
		push_error("Failed to calculate swim bounds")
		return
	
	var fish_scene = load(FISH_SCENE)
	
	if not fish_scene:
		push_error("Failed to load fish scene")
		return
	
	# Spawn multiple fish
	var surface_y := _get_water_surface_y()
	for i in range(num_fish):
		var fish_instance: RigidBody2D = fish_scene.instantiate()
		fish_container.add_child(fish_instance)
		
		# Set random species
		fish_instance.set_random_species()
		
		# Set random speed (each fish has different speed)
		fish_instance.speed = randf_range(min_fish_speed, max_fish_speed)
		
		# Set random direction change interval (some fish change direction more frequently)
		fish_instance.change_dir_interval = randf_range(min_change_dir_interval, max_change_dir_interval)
		
		# Set swim bounds to WaterZone area
		fish_instance.swim_bounds = swim_rect
		# Provide water surface so fish can float there when needed
		fish_instance.water_surface_y = surface_y
		
		# Place fish initially inside bounds with random position
		var pos = Vector2(
			randf_range(swim_rect.position.x, swim_rect.position.x + swim_rect.size.x),
			randf_range(swim_rect.position.y, swim_rect.position.y + swim_rect.size.y)
		)
		fish_instance.global_position = pos

func _on_left_click_pressed() -> void:
	# Start charging the throw or reset if already thrown
	if not is_instance_valid(ball) or not is_instance_valid(fisher):
		return
	
	if ball.has_method("is_thrown") and ball.call("is_thrown"):
		# Ball already thrown - do nothing (prevent reset)
		return
	else:
		# Start charging
		is_charging = true
		throw_force_bar.value = throw_force_bar.min_value
		throw_force_bar.visible = true

func _on_left_click_released() -> void:
	# Release the throw with current force
	if not is_charging:
		return
	
	is_charging = false
	# Hide the bar immediately after releasing (throw will happen post animation)
	throw_force_bar.visible = false
	
	if not is_instance_valid(ball) or not is_instance_valid(fisher):
		return
	
	# Calculate throw force based on progress bar value
	var force_percentage = (throw_force_bar.value - throw_force_bar.min_value) / (throw_force_bar.max_value - throw_force_bar.min_value)
	var horizontal_force = lerp(MIN_THROW_FORCE.x, max_horizontal_force, force_percentage)
	var vertical_force = BASE_VERTICAL_FORCE # Keep vertical force constant for consistent arc
	
	var throw_force = Vector2(horizontal_force, vertical_force)
	
	# Trigger fisher arm animation, then throw ball
	if fisher.has_method("trigger_throw"):
		fisher.call("trigger_throw", throw_force)
		# Store throw force for when animation completes
		_pending_throw_force = throw_force
		# Connect to throw_completed signal to actually throw the ball
		if not fisher.is_connected("throw_completed", _on_fisher_throw_completed):
			fisher.connect("throw_completed", _on_fisher_throw_completed)

var _pending_throw_force: Vector2 = Vector2.ZERO

func _on_fisher_throw_completed() -> void:
	# Fisher arm animation complete, now throw the ball with stored force
	if is_instance_valid(ball) and ball.has_method("request_throw"):
		ball.call("request_throw", _pending_throw_force)
	# Also trigger the dog to walk and fall into water (no chasing the ball)
	if is_instance_valid(dog) and dog.has_method("trigger_fall_to_water"):
		dog.call("trigger_fall_to_water")

	# Cancel any active fight (ball throw resets context)
	_end_fight(true)

## ---------------- Fight (struggle) system ----------------
func _start_fight(fish: RigidBody2D) -> void:
	if not is_instance_valid(fight_force_bar):
		return
	fight_active = true
	_fight_target_fish = fish
	fight_current_steps = 0.0
	fight_outside_timer = 0.0
	_fight_fish_direction = 1.0
	# Show UI
	fight_force_bar.visible = true
	fight_force_bar.min_value = FIGHT_FISH_ESCAPE_THRESHOLD
	fight_force_bar.max_value = FIGHT_MAX_STEPS
	fight_current_steps = FIGHT_MAX_STEPS * 0.25 # Start at 25%
	fight_force_bar.value = fight_current_steps
	if is_instance_valid(_fight_percentage_label):
		_fight_percentage_label.visible = true
	
		# Align indicator & escaping fish starting positions centered
	if is_instance_valid(fight_bar_indicator) and is_instance_valid(escaping_fish_tex):
		var track_len = _get_fight_track_length()
		var center_x = track_len / 2.0
		# Set local X position (along the bar)
		fight_bar_indicator.position.x = center_x - (fight_bar_indicator.size.x * fight_bar_indicator.scale.x) / 2.0
		escaping_fish_tex.position.x = center_x - (escaping_fish_tex.size.x * escaping_fish_tex.scale.x) / 2.0
	print("[Fight] Started with fish", fish)

func _update_fight(delta: float) -> void:
	if not fight_active:
		return
	# Validate fish still biting; if not, end
	if not is_instance_valid(_fight_target_fish) or not _fight_target_fish.has_method("is_biting") or not _fight_target_fish.call("is_biting"):
		_end_fight(true)
		return

	# Get fish rarity for difficulty scaling
	var rarity = FishRarityData.Rarity.COMMON
	if _fight_target_fish.has_method("get_species_key"):
		var key = _fight_target_fish.call("get_species_key")
		rarity = FishRarityData.get_fish_rarity(key)
	
	# Difficulty multipliers based on rarity
	var speed_mult: float = 1.0
	var erratic_mult: float = 1.0
	match rarity:
		FishRarityData.Rarity.COMMON:
			speed_mult = 1.0
			erratic_mult = 1.0
		FishRarityData.Rarity.UNCOMMON:
			speed_mult = 1.3
			erratic_mult = 1.5
		FishRarityData.Rarity.RARE:
			speed_mult = 1.6
			erratic_mult = 2.5
		FishRarityData.Rarity.EXTRA_RARE:
			speed_mult = 2.0
			erratic_mult = 4.0

	var track_len = _get_fight_track_length()

	# Player control (indicator moves with gravity/input)
	if is_instance_valid(fight_bar_indicator):
		# Gravity pulls down (Local X decreases), holding Space/Right Click pulls up (Local X increases)
		# Wait! Rotated -90 deg:
		# Local X+ is Global Y- (UP)
		# Local X- is Global Y+ (DOWN)
		# So Gravity should DECREASE X. Input should INCREASE X.
		var move_dir: float = -1.0 # Default falling down (decreasing X)
		if Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			move_dir = 1.0 # Move up (increasing X)
			
		fight_bar_indicator.position.x += move_dir * FIGHT_INDICATOR_MOVE_SPEED * delta
		
		# Clamp indicator to bar bounds (Local X)
		var ind_w = fight_bar_indicator.size.x * fight_bar_indicator.scale.x
		fight_bar_indicator.position.x = clamp(fight_bar_indicator.position.x, 0.0, track_len - ind_w)

	# Escaping fish movement
	if is_instance_valid(escaping_fish_tex):
		# Random direction changes
		if randf() < 0.02 * erratic_mult:
			_fight_fish_direction = 1.0 if randf() > 0.5 else -1.0
			
		# Move fish (Local X)
		escaping_fish_tex.position.x += _fight_fish_direction * FIGHT_FISH_BASE_SPEED * speed_mult * delta
		
		# Clamp fish within visible bar area
		# If fish is rotated 90 degrees, its "width" along the track is its height
		var fish_w = escaping_fish_tex.size.x * escaping_fish_tex.scale.x
		if abs(escaping_fish_tex.rotation_degrees) > 80 and abs(escaping_fish_tex.rotation_degrees) < 100:
			fish_w = escaping_fish_tex.size.y * escaping_fish_tex.scale.y
		elif abs(escaping_fish_tex.rotation) > 1.4 and abs(escaping_fish_tex.rotation) < 1.7:
			fish_w = escaping_fish_tex.size.y * escaping_fish_tex.scale.y
			
		var min_x = 0.0
		var max_x = track_len - fish_w
		
		if escaping_fish_tex.position.x <= min_x:
			escaping_fish_tex.position.x = min_x
			_fight_fish_direction = 1.0 # Bounce up (increase X)
		elif escaping_fish_tex.position.x >= max_x:
			escaping_fish_tex.position.x = max_x
			_fight_fish_direction = -1.0 # Bounce down (decrease X)

	# Determine overlap (capture zone) - check if global rects intersect
	var in_zone: bool = false
	if is_instance_valid(escaping_fish_tex) and is_instance_valid(fight_bar_indicator):
		var fish_rect = escaping_fish_tex.get_global_rect()
		var ind_rect = fight_bar_indicator.get_global_rect()
		in_zone = fish_rect.intersects(ind_rect)

	if in_zone:
		fight_current_steps += FIGHT_GAIN_STEPS_PER_SEC * delta
		fight_outside_timer = 0.0
	else:
		fight_outside_timer += delta
		if fight_outside_timer >= FIGHT_OUTSIDE_LOSS_DELAY:
			fight_current_steps -= FIGHT_LOSS_STEPS_PER_SEC * delta

	fight_current_steps = clamp(fight_current_steps, float(FIGHT_FISH_ESCAPE_THRESHOLD), float(FIGHT_MAX_STEPS))
	if is_instance_valid(fight_force_bar):
		fight_force_bar.value = fight_current_steps

	# Update percentage label
	if is_instance_valid(_fight_percentage_label):
		var pct = clamp(int((fight_current_steps / float(FIGHT_MAX_STEPS)) * 100), 0, 100)
		_fight_percentage_label.text = str(pct) + "%"
		if is_instance_valid(fight_force_bar):
			# Position to the right of the bar
			_fight_percentage_label.global_position = fight_force_bar.global_position + Vector2(50, 0)

	# Capture success
	if fight_current_steps >= FIGHT_MAX_STEPS:
		# Mark fish captured: remove fish from scene
		if is_instance_valid(_fight_target_fish):
			var species_key := "unknown"
			if _fight_target_fish.has_method("get_species_key"):
				species_key = _fight_target_fish.call("get_species_key")
			if species_key != "":
				if not _caught_fish_counts.has(species_key):
					_caught_fish_counts[species_key] = 0
				_caught_fish_counts[species_key] += 1
				_caught_fish_total += 1
			
			# Award points and coins
			# rarity is already calculated above
			var points = FishRarityData.get_fish_points(rarity)
			var coins = max(1, int(float(points) / 10.0))
			
			if score_summary:
				score_summary.add_score(points)
				score_summary.add_coins(coins)
				
				# Add item to summary list
				var sprite = _fight_target_fish.get_node_or_null("Sprite2D")
				if sprite and sprite.texture:
					score_summary.add_caught_item(sprite.texture)

			_fight_target_fish.queue_free()
		print("[Fight] Fish captured!")
		_end_fight(false)
		return

	# Escape failure
	if fight_current_steps <= FIGHT_FISH_ESCAPE_THRESHOLD:
		if is_instance_valid(_fight_target_fish) and _fight_target_fish.has_method("release_from_bait"):
			_fight_target_fish.call("release_from_bait")
		print("[Fight] Fish escaped.")
		_end_fight(true)

func _get_fight_track_length() -> float:
	if not is_instance_valid(fight_force_bar):
		return 100.0
	var tex = fight_force_bar.texture_under
	if not tex:
		return 100.0
	# Return the width of the texture (which is the length of the bar)
	return float(tex.get_width())


func _end_fight(released: bool) -> void:
	if not fight_active:
		return
	fight_active = false
	_fight_target_fish = null
	fight_force_bar.visible = false
	fight_force_bar.value = 0
	if is_instance_valid(_fight_percentage_label):
		_fight_percentage_label.visible = false
	fight_current_steps = 0
	fight_outside_timer = 0
	# Reset UI positions to center for next time
	if is_instance_valid(fight_bar_indicator) and is_instance_valid(escaping_fish_tex):
		var center_y = fight_force_bar.global_position.y
		fight_bar_indicator.global_position.y = center_y
		escaping_fish_tex.global_position.y = center_y
	print("[Fight] Ended released=", released)

func _check_dog_catch_easy_fish() -> void:
	# Only capture fish that are in easy-capture state AND close to the dog/tip.
	if not is_instance_valid(dog) or not is_instance_valid(fish_container):
		return
	var tip := dog.get_node_or_null("StringTip") as Node2D
	if tip == null or not tip.visible:
		return
	var dog_pos := dog.global_position
	var tip_pos := tip.global_position
	var capture_radius := 140.0 # enlarged radius; still refined by AABB overlap below
	for f in fish_container.get_children():
		if f and f.has_method("is_easy_capture") and f.call("is_easy_capture"):
			# Use min distance between dog and tip to allow slight offset
			var d: float = min(dog_pos.distance_to(f.global_position), tip_pos.distance_to(f.global_position))
			var should_capture := d <= capture_radius

			# Additional AABB overlap test for physical contact (dog rectangle vs fish circle)
			if not should_capture:
				var dog_cs := dog.get_node_or_null("CollisionShape2D")
				var fish_cs := f.get_node_or_null("CollisionShape2D")
				if dog_cs and fish_cs and dog_cs.shape and fish_cs.shape:
					if dog_cs.shape is RectangleShape2D:
						var rect_shape: RectangleShape2D = dog_cs.shape
						var dog_scale: Vector2 = dog_cs.scale * dog.scale
						# When the dog sprite is flipped horizontally/vertically its scale components can be negative.
						# Construct a rect then normalize with .abs() to guarantee positive size and avoid Rect2 negative size warnings.
						var rect_size: Vector2 = rect_shape.size * dog_scale
						var dog_rect := Rect2(dog.global_position - rect_size * 0.5, rect_size).abs()
						var fish_radius := 16.0
						if fish_cs.shape is CircleShape2D:
							var circle_shape: CircleShape2D = fish_cs.shape
							# Use abs() in case fish is flipped producing negative scale.x
							fish_radius = abs(circle_shape.radius * fish_cs.scale.x)
						var fish_rect := Rect2(f.global_position - Vector2(fish_radius, fish_radius), Vector2(fish_radius * 2.0, fish_radius * 2.0)).abs()
						if dog_rect.intersects(fish_rect):
							should_capture = true

			if should_capture:
				var species_key := "unknown"
				if f.has_method("get_species_key"):
					species_key = f.call("get_species_key")
				if species_key != "":
						# Local tracking only (mini-game scoped)
						if not _caught_fish_counts.has(species_key):
							_caught_fish_counts[species_key] = 0
						_caught_fish_counts[species_key] += 1
						_caught_fish_total += 1
				
				# Award points and coins
				var rarity = FishRarityData.get_fish_rarity(species_key)
				var points = FishRarityData.get_fish_points(rarity)
				var coins = max(1, int(float(points) / 10.0))
				
				if score_summary:
					score_summary.add_score(points)
					score_summary.add_coins(coins)
					
					# Add item to summary list
					var sprite = f.get_node_or_null("Sprite2D")
					if sprite and sprite.texture:
						score_summary.add_caught_item(sprite.texture)

				# Robust disappearance: hide first, disable collisions, then queue_free()
				var cs2 := f.get_node_or_null("CollisionShape2D")
				if cs2:
					cs2.disabled = true
				var spr2 := f.get_node_or_null("Sprite2D")
				if spr2:
					spr2.visible = false
				f.freeze = true
				print("[Catch] Easy fish captured: ", species_key, " dist=", d)
				f.queue_free()


func get_caught_fish_total() -> int:
	return _caught_fish_total

func get_caught_fish_counts() -> Dictionary:
	return _caught_fish_counts

## Fish bite system utilities

## Get all fish currently biting the bait
func get_biting_fish() -> Array:
	var biting_fish: Array = []
	
	if not is_instance_valid(fish_container):
		return biting_fish
	
	for fish in fish_container.get_children():
		if fish.has_method("is_biting") and fish.call("is_biting"):
			biting_fish.append(fish)
	
	return biting_fish

## Release all fish from the bait
func release_all_fish() -> void:
	var biting_fish = get_biting_fish()
	
	for fish in biting_fish:
		if fish.has_method("release_from_bait"):
			fish.call("release_from_bait")
	
	if biting_fish.size() > 0:
		print("Released ", biting_fish.size(), " fish from bait")

## Check if any fish is biting
func has_fish_biting() -> bool:
	return get_biting_fish().size() > 0
