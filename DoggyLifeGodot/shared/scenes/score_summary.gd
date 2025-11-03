extends Node2D

@export var points_per_coin: int = 5 # How many points = 1 coin
@export var time_limit: float = 20.0 # Time limit in seconds

@onready var score_display: Label = $ScoreDisplayContainer/ScoreDisplay
@onready var score_summary_container: Control = $ScoreSummaryContainer
@onready var summary_score_label: Label = $ScoreSummaryContainer/ScoreDisplay
@onready var summary_coins_label: Label = $ScoreSummaryContainer/CoinsDisplay

var score: int = 0
var coins_earned: int = 0

signal game_over() # Emitted when time is up

func _ready() -> void:
	# Hide summary container initially
	if score_summary_container:
		score_summary_container.visible = false
	
	# Initialize score display
	_update_score_display()

func start_game() -> void:
	"""Call this from the minigame to start the timer"""
	score = 0
	coins_earned = 0
	_update_score_display()
	
	# Create and start a timer for the time limit
	var timer := Timer.new()
	timer.name = "GameTimer"
	timer.wait_time = time_limit
	timer.one_shot = true
	timer.timeout.connect(_on_game_timer_timeout)
	add_child(timer)
	timer.start()

func add_score(points: int) -> void:
	"""Call this from the minigame whenever points are scored"""
	score += points
	_update_score_display()

func _update_score_display() -> void:
	if score_display:
		score_display.text = str(score)

func _on_game_timer_timeout() -> void:
	"""Called when the time limit is reached"""
	_calculate_coins()
	_show_summary()
	game_over.emit()

func _calculate_coins() -> void:
	"""Convert score to coins based on points_per_coin ratio"""
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
