extends Resource
class_name PlayerData

@export var coins: int = 0
@export var owned_items: Array[String] = []
const PLAYER_DATA_PATH = "user://player_data.tres"

static func load_player_data() -> PlayerData:
	var pd: PlayerData
	var needs_save := false
	
	if FileAccess.file_exists(PLAYER_DATA_PATH):
		pd = load(PLAYER_DATA_PATH) as PlayerData
		# Backward compatibility: ensure new fields exist
		if pd.owned_items == null:
			pd.owned_items = []
			needs_save = true
	else:
		pd = PlayerData.new()
		pd.owned_items = []
		# Tiles: first 3 for floor and wall
		for i in range(3):
			pd.owned_items.append("floor-tile-%d" % i)
			pd.owned_items.append("wall-tile-%d" % i)
		# Items: shelf and window by default
		pd.owned_items.append("shelf-sprite")
		pd.owned_items.append("window-sprite")
		needs_save = true
		
	# Check if the player has any dogs stored to their account
	var owned_dogs: Array[String] = []
	for item in pd.owned_items:
		if item.begins_with("dog-"):
			owned_dogs.append(item)
			
	if owned_dogs.is_empty():
		randomize()
		var all_dogs := ["dog-samoyed", "dog-beagle", "dog-shiba", "dog-spaniel"]
		all_dogs.shuffle()
		pd.owned_items.append(all_dogs[0])
		pd.owned_items.append(all_dogs[1])
		needs_save = true
		
	if needs_save:
		PlayerData.save_player_data(pd)
		
	return pd

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
