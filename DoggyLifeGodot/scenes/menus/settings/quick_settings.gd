extends Control

@onready var volume_slider := $MarginContainer/VBoxContainer/Volume as HSlider
@onready var mute_checkbox := $MarginContainer/VBoxContainer/HBoxContainer/Mute as CheckBox

# Current working settings (modified in real-time)
var current_settings := GlobalSettings.new()

# Saved settings (the last saved state to disk)
var saved_settings := GlobalSettings.new()

func _ready():
	# Load the saved settings from disk
	saved_settings = GlobalSettings.load_settings()
	
	# Copy saved settings to current settings
	_copy_settings(saved_settings, current_settings)
	
	# Connect signals
	volume_slider.value_changed.connect(_on_volume_value_changed)
	mute_checkbox.toggled.connect(_on_check_box_toggled)
	
	# Set initial UI values from current settings
	volume_slider.value = current_settings.music_volume
	mute_checkbox.button_pressed = current_settings.music_mute
	
	# Apply current settings to the music stream
	_apply_settings_to_audio()

func _copy_settings(from: GlobalSettings, to: GlobalSettings) -> void:
	"""Copy settings from one GlobalSettings instance to another."""
	to.music_volume = from.music_volume
	to.music_mute = from.music_mute

func _apply_settings_to_audio() -> void:
	"""Apply current settings to the global MusicStream singleton."""
	if MusicStream:
		MusicStream._apply_from_settings(current_settings)

func _on_volume_value_changed(value: float) -> void:
	# Update current settings (not saved yet)
	current_settings.music_volume = value
	
	#Apply changes
	_apply_settings_to_audio()

func _on_check_box_toggled(toggled_on: bool) -> void:
	# Update current settings (not saved yet)
	current_settings.music_mute = toggled_on
	_apply_settings_to_audio()

func _on_button_pressed() -> void:
	# Back button - discard changes and revert to saved settings
	_copy_settings(saved_settings, current_settings)
	_apply_settings_to_audio()
	
	# Update UI to reflect reverted settings
	volume_slider.value = current_settings.music_volume
	mute_checkbox.button_pressed = current_settings.music_mute
	
	_go_home()

func _on_save_button_pressed() -> void:
	# Save current settings to disk
	GlobalSettings.save_settings(current_settings)
	
	# Update saved settings to match current
	_copy_settings(current_settings, saved_settings)
	
	# Apply to ensure audio is in sync
	_apply_settings_to_audio()
	
	# Go home
	_go_home()

func _go_home():
	# Load room scene
	var room_scene = load("res://scenes/room/room.tscn").instantiate()
	get_tree().root.add_child(room_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = room_scene
