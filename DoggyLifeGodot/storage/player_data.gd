extends Resource
class_name PlayerData

@export var coins: int = 0
@export var owned_items: Array[String] = []
@export var food_stock: float = 100.0
@export var dog_bowls: Dictionary = {}
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
		if not ("food_stock" in pd) or pd.food_stock == null:
			pd.food_stock = 100.0
			needs_save = true
		if not ("dog_bowls" in pd) or pd.dog_bowls == null:
			pd.dog_bowls = {}
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
		owned_dogs.append(all_dogs[0])
		owned_dogs.append(all_dogs[1])
		needs_save = true
		
	# Ensure every owned dog has a bowl configuration
	for dog_key in owned_dogs:
		if not pd.dog_bowls.has(dog_key):
			pd.dog_bowls[dog_key] = {"type": "basic", "capacity": 100.0, "fullness": 100.0}
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

static func get_food_stock() -> float:
	var player_data := load_player_data()
	return player_data.food_stock

static func add_food_stock(amount: float) -> void:
	var player_data := load_player_data()
	player_data.food_stock += amount
	save_player_data(player_data)

static func consume_food_stock(amount: float) -> bool:
	var player_data := load_player_data()
	if player_data.food_stock >= amount:
		player_data.food_stock -= amount
		save_player_data(player_data)
		return true
	return false

static func get_dog_bowl(dog_key: String) -> Dictionary:
	var player_data := load_player_data()
	if player_data.dog_bowls.has(dog_key):
		return player_data.dog_bowls[dog_key]
	return {"type": "basic", "capacity": 100.0, "fullness": 100.0}

static func save_dog_bowl(dog_key: String, bowl_data: Dictionary) -> void:
	var player_data := load_player_data()
	player_data.dog_bowls[dog_key] = bowl_data
	save_player_data(player_data)
