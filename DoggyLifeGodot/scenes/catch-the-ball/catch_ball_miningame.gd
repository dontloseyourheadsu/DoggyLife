extends Node2D

@onready var dogs_list: ItemList = $Camera2D/Container/VBoxContainer/ScrollContainer/DogsList
@onready var selection_container: Control = $Camera2D/Container
@onready var dog_body: CharacterBody2D = $Camera2D/Dog
@onready var dog_anim: AnimatedSprite2D = $Camera2D/Dog/DogAnimations
@onready var normal_balls_container: Node2D = $Camera2D/NormalBallsContainer
@onready var special_balls_container: Node2D = $Camera2D/SpecialBallsContainer
@onready var left_wall_limit: StaticBody2D = $Camera2D/LeftWallLimit
@onready var right_wall_limit: StaticBody2D = $Camera2D/RightWallLimit
@onready var red_ball: RigidBody2D = $Camera2D/NormalBallsContainer/RedBall
@onready var red_ball_2: RigidBody2D = $Camera2D/NormalBallsContainer/RedBall2
@onready var red_ball_3: RigidBody2D = $Camera2D/NormalBallsContainer/RedBall3
@onready var score_summary: Node2D = $Camera2D/ScoreSummary

# Map item index -> dog key (e.g. "dog-samoyed")
var _index_to_dog: Array[String] = []
var game_active: bool = false

func _ready() -> void:
	_populate_owned_dogs_list()
	_connect_ball_signals()
	
	# Connect to game_over signal from score_summary
	if score_summary:
		score_summary.game_over.connect(_on_game_over)

func _connect_ball_signals() -> void:
	# Connect all ball signals to the score handler
	if red_ball:
		red_ball.ball_caught.connect(_on_ball_caught)
	if red_ball_2:
		red_ball_2.ball_caught.connect(_on_ball_caught)
	if red_ball_3:
		red_ball_3.ball_caught.connect(_on_ball_caught)
	
	# Connect golden balls
	var right_golden_ball = $Camera2D/SpecialBallsContainer/RightGoldenBall
	var left_golden_ball = $Camera2D/SpecialBallsContainer/LeftGoldenBall
	if right_golden_ball:
		right_golden_ball.ball_caught.connect(_on_ball_caught)
	if left_golden_ball:
		left_golden_ball.ball_caught.connect(_on_ball_caught)

func _on_ball_caught(points: int) -> void:
	# Only count points if the game is active
	if game_active and score_summary:
		score_summary.add_score(points)

func _on_game_over() -> void:
	"""Called when the score_summary emits game_over signal"""
	game_active = false
	
	# Disable dog controls
	if dog_body:
		dog_body.set_physics_process(false)
	
	# Stop all balls from being thrown/moving
	_stop_all_balls()

func _stop_all_balls() -> void:
	"""Freeze all balls and stop their timers"""
	# Stop normal balls
	for ball in normal_balls_container.get_children():
		if ball is RigidBody2D:
			ball.freeze = true
			ball.can_throw_ball = false
			# Stop their timers
			var timer = ball.get_node_or_null("Timer")
			if timer:
				timer.stop()
	
	# Stop special balls
	for ball in special_balls_container.get_children():
		if ball is RigidBody2D:
			ball.freeze = true
			ball.can_throw_ball = false
			# Stop their timers
			var timer = ball.get_node_or_null("Timer")
			if timer:
				timer.stop()

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
	
	# Start the game now that a dog has been selected
	game_active = true
	if score_summary:
		score_summary.start_game()
