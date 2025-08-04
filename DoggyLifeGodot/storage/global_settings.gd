extends Resource
class_name GlobalSettings

@export var music_volume: float = 0.8
@export var music_mute: bool = false

static func load_settings() -> GlobalSettings:
	var path = "user://global_settings.tres"
	if FileAccess.file_exists(path):
		return load(path) as GlobalSettings
	return GlobalSettings.new()
