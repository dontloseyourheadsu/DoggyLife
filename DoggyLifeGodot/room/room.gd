extends Node2D

@onready var pause_button := $Camera2D/PauseButton as Button

func _ready():
	# Connect the pause button signal
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)

func _on_pause_button_pressed() -> void:
	# Load settings scene
	var settings_scene = load("res://menus/settings/quick_settings.tscn").instantiate()
	get_tree().root.add_child(settings_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = settings_scene
