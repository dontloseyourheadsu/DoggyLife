extends Node2D

# Typed container for initial ball state
class BallState:
	var pos: Vector2
	var freeze: bool

@onready var dogs_list: ItemList = $Camera2D/Container/VBoxContainer/ScrollContainer/DogsList
@onready var selection_container: Control = $Camera2D/Container
@onready var dog_body: Node = $Camera2D/Dog
@onready var dog_anim: AnimatedSprite2D = $Camera2D/Dog/DogAnimations

# Map item index -> dog key (e.g. "dog-samoyed")
var _index_to_dog: Array[String] = []

# -------- Minigame config --------
@export var difficulty_level: int = 2 # 1..5 typical; higher = harder
const MAX_ACTIVE_RED := 3
const MAX_ACTIVE_GOLDEN := 2

const LAYER_DOG := 1 << 0 # 1
const LAYER_WORLD := 1 << 1 # 2 (floor + side walls)
const LAYER_BALL := 1 << 2 # 4

const HALF_WIDTH := 640.0
const HALF_HEIGHT := 360.0

const TOP_SPAWN_Y := -426.0
const LEFT_WALL_X := -640.0
const RIGHT_WALL_X := 640.0

const ARROW_ICON_PATH := "res://scenes/catch-the-ball/images/icons/arrow-left.png"

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _arrow_tex: Texture2D

var _red_balls: Array[RigidBody2D] = []
var _golden_balls: Array[RigidBody2D] = []

# Book-keeping (keep Dictionary untyped; cast at access for Godot 4 compatibility)
var _initial_pos: Dictionary = {}
var _ball_type: Dictionary = {}
var _target_side: Dictionary = {}
var _initial_state: Dictionary = {}

func _ready() -> void:
	_rng.randomize()
	_arrow_tex = load(ARROW_ICON_PATH)
	_cache_balls()
	_enforce_collision_layers()
	_populate_owned_dogs_list()
	# Start spawning loops (fire-and-forget coroutines)
	_spawn_red_loop()
	_spawn_golden_loop()

func _cache_balls() -> void:
	_red_balls.clear()
	_golden_balls.clear()
	var normal := $Camera2D/NormalBallsContainer
	var special := $Camera2D/SpecialBallsContainer
	if normal:
		for n in normal.get_children():
			if n is RigidBody2D:
				_red_balls.append(n)
				_initial_pos[n] = (n as RigidBody2D).global_position
				var s := BallState.new()
				s.pos = (n as RigidBody2D).global_position
				s.freeze = (n as RigidBody2D).freeze
				_initial_state[n] = s
				_ball_type[n] = "red"
				n.freeze = true
				_connect_ball_signals(n)
	if special:
		for n in special.get_children():
			if n is RigidBody2D:
				_golden_balls.append(n)
				_initial_pos[n] = (n as RigidBody2D).global_position
				var s2 := BallState.new()
				s2.pos = (n as RigidBody2D).global_position
				s2.freeze = (n as RigidBody2D).freeze
				_initial_state[n] = s2
				_ball_type[n] = "golden"
				n.freeze = true
				_connect_ball_signals(n)

func _connect_ball_signals(b: RigidBody2D) -> void:
	if b == null:
		return
	b.contact_monitor = true
	b.max_contacts_reported = 8
	var cb := Callable(self, "_on_ball_body_shape_entered").bind(b)
	b.connect("body_shape_entered", cb)

func _get_world_bounds() -> Dictionary:
	var tr := $Camera2D/TextureRect
	if tr:
		return {
			"left": float(tr.offset_left),
			"right": float(tr.offset_right),
			"top": float(tr.offset_top),
			"bottom": float(tr.offset_bottom)
		}
	return {"left": - HALF_WIDTH, "right": HALF_WIDTH, "top": - HALF_HEIGHT, "bottom": HALF_HEIGHT}

func _enforce_collision_layers() -> void:
	# Dog should collide with world + balls
	if dog_body and dog_body is CollisionObject2D:
		var d := dog_body as CollisionObject2D
		d.collision_layer = LAYER_DOG
		# Dog should not collide with balls, only with world
		d.collision_mask = LAYER_WORLD
	# World limits on world layer only
	var ground := $Camera2D/GroundLimit as CollisionObject2D
	if ground:
		ground.collision_layer = LAYER_WORLD
		ground.collision_mask = LAYER_DOG | LAYER_BALL
	var leftw := $Camera2D/LeftWallLimit as CollisionObject2D
	if leftw:
		leftw.collision_layer = LAYER_WORLD
		leftw.collision_mask = LAYER_DOG | LAYER_BALL
	var rightw := $Camera2D/RightWallLimit as CollisionObject2D
	if rightw:
		rightw.collision_layer = LAYER_WORLD
		rightw.collision_mask = LAYER_DOG | LAYER_BALL
	# Balls on ball layer, colliding with world + dog
	for b in _red_balls + _golden_balls:
		b.collision_layer = LAYER_BALL
		# Balls should not collide with dog
		b.collision_mask = LAYER_WORLD

func _approx_ball_max_dim(rb: RigidBody2D) -> float:
	var max_dim := 32.0
	if rb == null:
		return max_dim
	var s := rb.get_node_or_null("Sprite2D") as Sprite2D
	if s and s.texture:
		var tex_size := s.texture.get_size()
		var scale := s.scale
		var w: float = float(tex_size.x) * abs(scale.x)
		var h: float = float(tex_size.y) * abs(scale.y)
		max_dim = max(w, h)
	else:
		var cs := rb.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if cs and cs.shape is CircleShape2D:
			var r := (cs.shape as CircleShape2D).radius
			var sc := cs.scale
			max_dim = 2.0 * r * max(abs(sc.x), abs(sc.y))
	return max_dim

func _active_count(arr: Array[RigidBody2D]) -> int:
	var c := 0
	for b in arr:
		if not b.freeze:
			c += 1
	return c

func _choose_available(arr: Array[RigidBody2D]) -> RigidBody2D:
	for b in arr:
		if b.freeze:
			return b
	return null

func _red_spawn_delay_range() -> Vector2:
	var d := float(clamp(difficulty_level, 1, 5))
	# Higher difficulty -> shorter delay
	return Vector2(3.6 / d, 2.0 / d).abs() # we will sort below

func _golden_spawn_delay_range() -> Vector2:
	var d := float(clamp(difficulty_level, 1, 5))
	return Vector2(8.0 / d, 4.5 / d).abs()

func _sorted_range(v: Vector2) -> Vector2:
	if v.x < v.y:
		return v
	else:
		return Vector2(v.y, v.x)

func _rand_delay(min_t: float, max_t: float) -> float:
	return _rng.randf_range(min_t, max_t)

func _spawn_red_loop() -> void:
	await get_tree().process_frame
	while is_inside_tree():
		var delay_rng := _sorted_range(_red_spawn_delay_range())
		var wait_time := _rand_delay(delay_rng.x, delay_rng.y)
		await get_tree().create_timer(wait_time).timeout
		if _active_count(_red_balls) >= MAX_ACTIVE_RED:
			continue
		var rb := _choose_available(_red_balls)
		if rb == null:
			continue
		var side := "left"
		if _rng.randf() >= 0.5:
			side = "right"
		var x_offset := _rng.randf_range(40.0, 140.0)
		var spawn_x := -x_offset
		if side != "left":
			spawn_x = x_offset
		var bounds := _get_world_bounds()
		var top_y := float(bounds["top"])
		# Arrow twinkle just inside visible top
		await _twinkle_arrow_red(Vector2(spawn_x, top_y + 16.0))
		# Spawn slightly above top so it falls in
		var spawn_pos := Vector2(spawn_x, top_y - 10.0)
		_launch_red_ball(rb, side, spawn_pos)

func _spawn_golden_loop() -> void:
	await get_tree().process_frame
	while is_inside_tree():
		var delay_rng := _sorted_range(_golden_spawn_delay_range())
		var wait_time := _rand_delay(delay_rng.x, delay_rng.y)
		await get_tree().create_timer(wait_time).timeout
		if _active_count(_golden_balls) >= MAX_ACTIVE_GOLDEN:
			continue
		var gb := _choose_available(_golden_balls)
		if gb == null:
			continue
		var side := "left"
		if _rng.randf() >= 0.5:
			side = "right"
		# Use TextureRect bounds; spawn between 0%-30% of height (near top)
		var bounds := _get_world_bounds()
		var top_y := float(bounds["top"])
		var bottom_y := float(bounds["bottom"])
		var min_y := top_y + 0.0
		var max_y := top_y + 0.3 * (bottom_y - top_y)
		var spawn_y := _rng.randf_range(min_y, max_y)
		var left_x := float(bounds["left"])
		var right_x := float(bounds["right"])
		var spawn_x := left_x + 10.0
		if side != "left":
			spawn_x = right_x - 10.0
		var spawn_pos := Vector2(spawn_x, spawn_y)
		await _twinkle_arrow_golden(side, spawn_y)
		_launch_golden_ball(gb, side, spawn_pos)

func _twinkle_arrow_red(at_pos: Vector2) -> void:
	if _arrow_tex == null:
		return
	var s := Sprite2D.new()
	s.texture = _arrow_tex
	s.position = at_pos
	s.rotation = - PI * 0.5 # point down
	s.modulate = Color(1, 0, 0, 0.6)
	s.z_as_relative = false
	s.z_index = 4096
	s.scale = Vector2(3, 3)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Camera2D.add_child(s)
	for i in 3:
		s.visible = true
		await get_tree().create_timer(0.18).timeout
		s.visible = false
		await get_tree().create_timer(0.12).timeout
	s.queue_free()

func _twinkle_arrow_golden(side: String, y: float) -> void:
	if _arrow_tex == null:
		return
	var s := Sprite2D.new()
	s.texture = _arrow_tex
	var bounds := _get_world_bounds()
	var px := float(bounds["left"]) + 24.0
	if side != "left":
		px = float(bounds["right"]) - 24.0
	s.position = Vector2(px, y)
	s.modulate = Color(1.0, 0.84, 0.0, 0.65) # golden tint
	s.flip_h = (side == "left") # from left wall point right
	s.z_as_relative = false
	s.z_index = 4096
	s.scale = Vector2(3, 3)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Camera2D.add_child(s)
	for i in 3:
		s.visible = true
		await get_tree().create_timer(0.14).timeout
		s.visible = false
		await get_tree().create_timer(0.10).timeout
	s.queue_free()

func _launch_red_ball(rb: RigidBody2D, side: String, pos: Vector2) -> void:
	rb.global_position = pos
	rb.linear_velocity = Vector2.ZERO
	rb.angular_velocity = 0.0
	rb.freeze = false
	# Velocity: ensure at least one bounce then reach chosen wall, then continue to opposite wall
	var base_x := _rng.randf_range(220.0, 320.0)
	if side == "left":
		base_x *= -1.0
	var base_y := _rng.randf_range(120.0, 180.0) # downward
	rb.linear_velocity = Vector2(base_x, base_y)
	rb.apply_torque_impulse(_rng.randf_range(-2.0, 2.0))
	# Target: the closest wall in the direction of travel (matches chosen side)
	_target_side[rb] = side

func _launch_golden_ball(gb: RigidBody2D, side: String, pos: Vector2) -> void:
	gb.global_position = pos
	gb.linear_velocity = Vector2.ZERO
	gb.angular_velocity = 0.0
	gb.freeze = false
	var sx := 1.0
	if side != "left":
		sx = -1.0
	# Fast travel across, one bounce on floor
	var vx := _rng.randf_range(850.0, 1100.0) * sx
	var vy := _rng.randf_range(280.0, 360.0)
	gb.linear_velocity = Vector2(vx, vy)
	gb.apply_torque_impulse(_rng.randf_range(-3.0, 3.0))
	var gt_side := "right"
	if side != "left":
		gt_side = "left"
	_target_side[gb] = gt_side

func _physics_process(_delta: float) -> void:
	# Despawn logic when reaching target side wall
	for b in _target_side.keys().duplicate():
		if b is RigidBody2D:
			var rb := b as RigidBody2D
			if rb.freeze:
				continue
			var target: String = String(_target_side.get(rb, ""))
			var x := rb.global_position.x
			var bounds := _get_world_bounds()
			var left_x := float(bounds["left"]) + 0.0
			var right_x := float(bounds["right"]) + 0.0
			# Consider proximity to wall plane and post-bounce horizontal velocity direction
			if target == "left":
				if x <= left_x + 30.0 and rb.linear_velocity.x >= 0.0:
					var typ_l: String = "?"
					if _ball_type.has(rb):
						typ_l = _ball_type[rb]
					print("[DEBUG] Proximity fallback: ", rb.name, " (", typ_l, ") reached LEFT target. pos=", rb.global_position, " vel=", rb.linear_velocity)
					_despawn(rb)
			elif target == "right":
				if x >= right_x - 30.0 and rb.linear_velocity.x <= 0.0:
					var typ_r: String = "?"
					if _ball_type.has(rb):
						typ_r = _ball_type[rb]
					print("[DEBUG] Proximity fallback: ", rb.name, " (", typ_r, ") reached RIGHT target. pos=", rb.global_position, " vel=", rb.linear_velocity)
					_despawn(rb)

func _despawn(rb: RigidBody2D) -> void:
	# Return to freeze state and reset position as requested
	if rb == null:
		return
	if rb.freeze:
		return
	if not _target_side.has(rb):
		return
	rb.freeze = true
	rb.linear_velocity = Vector2.ZERO
	rb.angular_velocity = 0.0
	# Ensure physics freeze applies before teleporting off-camera
	await get_tree().physics_frame
	# Restore initial stored state (position is guaranteed off-camera by scene setup)
	if _initial_state.has(rb):
		var st: BallState = _initial_state.get(rb) as BallState
		rb.global_position = st.pos
		rb.freeze = st.freeze # keep frozen until next spawn
	_target_side.erase(rb)

func _on_ball_body_shape_entered(_body_rid, other: Node, _body_shape_index: int, _local_shape_index: int, ball: RigidBody2D) -> void:
	if ball == null or other == null:
		return
	if ball.freeze:
		return
	if not _target_side.has(ball):
		return
	var target: String = String(_target_side.get(ball, ""))
	# Detect which wall we hit by name.
	if other.name == "LeftWallLimit" and target == "left":
		var typ_l: String = "?"
		if _ball_type.has(ball):
			typ_l = _ball_type[ball]
		print("[DEBUG] Target hit by ", ball.name, " (", typ_l, ") at LEFT wall. pos=", ball.global_position, " vel=", ball.linear_velocity)
		_despawn(ball)
	elif other.name == "RightWallLimit" and target == "right":
		var typ_r: String = "?"
		if _ball_type.has(ball):
			typ_r = _ball_type[ball]
		print("[DEBUG] Target hit by ", ball.name, " (", typ_r, ") at RIGHT wall. pos=", ball.global_position, " vel=", ball.linear_velocity)
		_despawn(ball)

func _populate_owned_dogs_list() -> void:
	if dogs_list == null:
		return
	# Ensure icons show at 32x32
	dogs_list.fixed_icon_size = Vector2i(32, 32)
	dogs_list.clear()
	_index_to_dog.clear()

	var pd: PlayerData = PlayerData.load_player_data()
	if pd == null:
		return

	# Collect owned dog keys like "dog-samoyed"
	var dog_keys: Array[String] = []
	for item_name in pd.owned_items:
		if typeof(item_name) == TYPE_STRING and item_name.begins_with("dog-"):
			dog_keys.append(item_name)

	# Sort by name for stable order
	dog_keys.sort()

	for dog_key in dog_keys:
		var breed := _dog_key_to_breed(dog_key)
		var display := _display_name_from_breed(breed)
		var icon := _make_dog_icon_texture(breed)
		var idx := dogs_list.get_item_count()
		dogs_list.add_item(display, icon)
		dogs_list.set_item_metadata(idx, dog_key)
		_index_to_dog.append(dog_key)

func _dog_key_to_breed(dog_key: String) -> String:
	# dog_key format: "dog-<breed>"
	if dog_key.begins_with("dog-"):
		return dog_key.substr(4)
	return dog_key

func _display_name_from_breed(breed: String) -> String:
	if breed == "":
		return "Unknown"
	# Replace dashes with spaces and capitalize words
	var parts := breed.split("-")
	for i in parts.size():
		var p: String = parts[i]
		if p.length() > 0:
			parts[i] = p.left(1).to_upper() + p.substr(1)
	return " ".join(parts)

func _make_dog_icon_texture(breed: String) -> Texture2D:
	# Prefer static image first 32x32
	var image_path := "res://sprites/dogs/images/%s-dog.png" % breed
	var tex: Texture2D = load(image_path)
	if tex != null:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, 0, 32, 32)
		return at
	# Fallback to first frame of spriteframes
	var frames: SpriteFrames = load("res://sprites/dogs/spriteframes/%s-dog.tres" % breed)
	if frames != null:
		var anims := frames.get_animation_names()
		if anims.size() > 0:
			var a := anims[0]
			var icon_tex := frames.get_frame_texture(a, 0)
			if icon_tex != null:
				return icon_tex
	return null

func _on_dogs_list_item_selected(index: int) -> void:
	if dogs_list == null or dog_anim == null or dog_body == null:
		return
	# Resolve selection to dog key
	var dog_key: String = ""
	if index >= 0 and index < dogs_list.get_item_count():
		var meta = dogs_list.get_item_metadata(index)
		if typeof(meta) == TYPE_STRING:
			dog_key = String(meta)
	if dog_key == "" and index >= 0 and index < _index_to_dog.size():
		dog_key = _index_to_dog[index]
	if dog_key == "":
		return

	var breed := _dog_key_to_breed(dog_key)
	# Load the corresponding SpriteFrames resource for the AnimatedSprite2D
	var frames: SpriteFrames = load("res://sprites/dogs/spriteframes/%s-dog.tres" % breed)
	if frames == null:
		return
	dog_anim.sprite_frames = frames

	# Reveal the dog and hide selection UI
	dog_body.visible = true
	if selection_container != null:
		selection_container.visible = false
