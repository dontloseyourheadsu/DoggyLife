extends Resource
class_name PlayerData

@export var coins: int = 0
@export var owned_items: Array[String] = []
const PLAYER_DATA_PATH = "user://player_data.tres"

static func load_player_data() -> PlayerData:
	if FileAccess.file_exists(PLAYER_DATA_PATH):
		var pd := load(PLAYER_DATA_PATH) as PlayerData
		# Backward compatibility: ensure new fields exist
		if pd.owned_items == null:
			pd.owned_items = []
		return pd
	var fresh := PlayerData.new()
	fresh.owned_items = []
	# Seed default ownership on fresh profile
	# Dogs: default samoyed
	fresh.owned_items.append("dog-samoyed")
	# Tiles: first 3 for floor and wall
	for i in range(3):
		fresh.owned_items.append("floor-tile-%d" % i)
		fresh.owned_items.append("wall-tile-%d" % i)
	# Items: none by default
	# Persist immediately so subsequent loads use the same defaults
	PlayerData.save_player_data(fresh)
	return fresh

static func save_player_data(player_data: PlayerData) -> void:
	var err := ResourceSaver.save(player_data, PLAYER_DATA_PATH)
	if err != OK:
		push_error("Failed to save TileSelectionStore: %s" % err)

static func get_coins_count():
	var player_data = load_player_data()
	return player_data.coins

# Convenience helpers
static func owns_item(item_name: String) -> bool:
	var player_data := load_player_data()
	return player_data.owned_items.has(item_name)

static func add_owned_item(item_name: String) -> void:
	var player_data := load_player_data()
	if not player_data.owned_items.has(item_name):
		player_data.owned_items.append(item_name)
		save_player_data(player_data)

static func spend_coins(amount: int) -> bool:
	var player_data := load_player_data()
	if amount < 0:
		return false
	if player_data.coins < amount:
		return false
	player_data.coins -= amount
	save_player_data(player_data)
	return true
