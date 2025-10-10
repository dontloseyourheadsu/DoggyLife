extends Control

@onready var volume_slider := $MarginContainer/VBoxContainer/Volume as HSlider
@onready var mute_checkbox := $MarginContainer/VBoxContainer/HBoxContainer/Mute as CheckBox  # Add this line
const AudioUtils = preload("res://shared/scripts/audio_utils.gd")

var global_settings := GlobalSettings.load_settings()

func _enter_tree():
	# This runs every time the node enters the scene tree
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_value_changed)
	if mute_checkbox:
		mute_checkbox.toggled.connect(_on_check_box_toggled)

func _exit_tree():
	# Clean up when leaving tree
	if volume_slider and volume_slider.value_changed.is_connected(_on_volume_value_changed):
		volume_slider.value_changed.disconnect(_on_volume_value_changed)
	if mute_checkbox and mute_checkbox.toggled.is_connected(_on_check_box_toggled):
		mute_checkbox.toggled.disconnect(_on_check_box_toggled)

func _ready():
	# Disconnect first to prevent duplicate connections
	if volume_slider.value_changed.is_connected(_on_volume_value_changed):
		volume_slider.value_changed.disconnect(_on_volume_value_changed)
	if mute_checkbox.toggled.is_connected(_on_check_box_toggled):
		mute_checkbox.toggled.disconnect(_on_check_box_toggled)
	
	# Then connect fresh
	volume_slider.value_changed.connect(_on_volume_value_changed)
	mute_checkbox.toggled.connect(_on_check_box_toggled)
	
	# Set initial values
	volume_slider.value = global_settings.music_volume
	mute_checkbox.button_pressed = global_settings.music_mute
	update_audio_settings()

func _on_volume_value_changed(value: float) -> void:
	global_settings.music_volume = value
	update_audio_settings()

func _on_check_box_toggled(toggled_on: bool) -> void:
	global_settings.music_mute = toggled_on
	update_audio_settings()

func _on_button_pressed() -> void:
	# Save settings before changing scene
	save_settings()
	
	# Load room scene
	var room_scene = load("res://scenes/room/room.tscn").instantiate()  # Godot 4 uses instantiate()
	get_tree().root.add_child(room_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = room_scene
	
func update_audio_settings() -> void:
	AudioUtils.apply_from_settings(global_settings)

func save_settings() -> void:
	# Correct saving method
	var error = ResourceSaver.save(global_settings, "user://global_settings.tres")
	if error != OK:
		push_error("Failed to save settings: %s" % error)
