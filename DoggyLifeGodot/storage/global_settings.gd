extends Resource
class_name GlobalSettings

@export var music_volume: float = 0.8
@export var music_mute: bool = false
const path = "user://global_settings.tres"

static func load_settings() -> GlobalSettings:
	if FileAccess.file_exists(path):
		return load(path) as GlobalSettings
	return GlobalSettings.new()

static func save_settings(settings: GlobalSettings) -> void:
	ResourceSaver.save(settings, path)
