extends Resource
class_name PlayerData

@export var coins: int = 0
const PLAYER_DATA_PATH = "user://player_data.tres"

static func load_player_data() -> PlayerData:
	if FileAccess.file_exists(PLAYER_DATA_PATH):
		return load(PLAYER_DATA_PATH) as PlayerData
	return PlayerData.new()

static func save_player_data(player_data: PlayerData) -> void:
	var err := ResourceSaver.save(player_data, PLAYER_DATA_PATH)
	if err != OK:
		push_error("Failed to save TileSelectionStore: %s" % err)

static func get_coins_count():
	var player_data = load_player_data()
	return player_data.coins
