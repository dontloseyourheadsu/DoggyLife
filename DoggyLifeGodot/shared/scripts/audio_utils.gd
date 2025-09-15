extends Node

# Utility for applying audio settings across scenes.
# Usage:
#   var settings := GlobalSettings.load_settings()
#   AudioUtils.apply_from_settings(settings)
# Or simply:
#   AudioUtils.load_and_apply()

class_name AudioUtils

static func apply_from_settings(settings: Resource) -> void:
	if settings == null:
		return
	# Expect settings has music_volume (0..1) and music_mute (bool)
	var volume_db := linear_to_db(settings.music_volume)
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, volume_db)
		AudioServer.set_bus_mute(master_idx, settings.music_mute)

static func load_and_apply() -> void:
	# Load settings using the GlobalSettings script's static helper.
	# Assumes GlobalSettings.gd is available in the project and exposes load_settings().
	var settings := GlobalSettings.load_settings()
	apply_from_settings(settings)
