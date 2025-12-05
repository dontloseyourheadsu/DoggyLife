extends Node2D

@export var points_per_coin: int = 5 # How many points = 1 coin
@export var time_limit: float = 20.0 # Time limit in seconds
@export var auto_calculate_coins: bool = true # If true, coins = score / points_per_coin

@onready var score_display: Label = $ScoreDisplayContainer/ScoreDisplay
@onready var score_summary_container: Control = $ScoreSummaryContainer
@onready var summary_score_label: Label = $ScoreSummaryContainer/ScoreDisplay
@onready var summary_coins_label: Label = $ScoreSummaryContainer/CoinsDisplay
@onready var caught_items_grid: GridContainer = $ScoreSummaryContainer/CaughtItemsScroll/CaughtItemsGrid
@onready var time_display: Label = $TimeDisplayContainer/TimeDisplay

var score: int = 0
var coins_earned: int = 0
var _game_timer: Timer

signal game_over() # Emitted when time is up

func _ready() -> void:
	# Hide summary container initially
	if score_summary_container:
		score_summary_container.visible = false
	
	# Initialize score display
	_update_score_display()
	set_process(false)

func _process(_delta: float) -> void:
	if is_instance_valid(_game_timer) and not _game_timer.is_stopped():
		_update_time_display()

func start_game() -> void:
	"""Call this from the minigame to start the timer"""
	score = 0
	coins_earned = 0
	_update_score_display()
	
	# Clear caught items
	if caught_items_grid:
		for child in caught_items_grid.get_children():
			child.queue_free()
	
	# Create and start a timer for the time limit
	if is_instance_valid(_game_timer):
		_game_timer.queue_free()
	
	_game_timer = Timer.new()
	_game_timer.name = "GameTimer"
	_game_timer.wait_time = time_limit
	_game_timer.one_shot = true
	_game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(_game_timer)
	_game_timer.start()
	
	set_process(true)
	_update_time_display()

func _update_time_display() -> void:
	if time_display and is_instance_valid(_game_timer):
		var time_left = int(_game_timer.time_left)
		var minutes = time_left / 60
		var seconds = time_left % 60
		time_display.text = "%02d:%02d" % [minutes, seconds]

func add_score(points: int) -> void:
	"""Call this from the minigame whenever points are scored"""
	score += points
	_update_score_display()

func add_coins(amount: int) -> void:
	coins_earned += amount

func add_caught_item(texture: Texture2D) -> void:
	if caught_items_grid:
		var tex_rect := TextureRect.new()
		tex_rect.texture = texture
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.custom_minimum_size = Vector2(32, 32)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		caught_items_grid.add_child(tex_rect)

func _update_score_display() -> void:
	if score_display:
		score_display.text = str(score)

func _on_game_timer_timeout() -> void:
	"""Called when the time limit is reached"""
	set_process(false)
	_calculate_coins()
	_show_summary()
	game_over.emit()

func _calculate_coins() -> void:
	"""Convert score to coins based on points_per_coin ratio"""
	if auto_calculate_coins:
		coins_earned = score / points_per_coin

func _show_summary() -> void:
	"""Display the score summary container"""
	if score_summary_container:
		score_summary_container.visible = true
	
	# Update summary labels
	if summary_score_label:
		summary_score_label.text = "Score: %d" % score
	if summary_coins_label:
		summary_coins_label.text = "Coins Earned: %d" % coins_earned

func _on_go_home_button_pressed() -> void:
	# Save coins to player data
	var player_data := PlayerData.load_player_data()
	player_data.coins += coins_earned
	PlayerData.save_player_data(player_data)
	
	# Go to room scene
	var room_scene = load("res://scenes/room/room.tscn").instantiate()
	get_tree().root.add_child(room_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = room_scene
