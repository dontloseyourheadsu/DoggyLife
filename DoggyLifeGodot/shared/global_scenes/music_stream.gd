extends AudioStreamPlayer2D

func _ready() -> void:
	_load_and_apply()

func _apply_from_settings(settings: Resource) -> void:
	if playing != !settings.music_mute:
		playing = !settings.music_mute # If not muted, plays, else not play
	volume_db = settings.music_volume # Set the sound level in decibels

func _load_and_apply() -> void:
	# Load settings using the GlobalSettings script's static helper.
	# Assumes GlobalSettings.gd is available in the project and exposes load_settings().
	var settings := GlobalSettings.load_settings()
	_apply_from_settings(settings)
