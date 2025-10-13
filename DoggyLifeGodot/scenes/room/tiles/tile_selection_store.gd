extends Resource

# Store for scene-scoped tile selection.
# Persists the selected floor tile index so other scripts (e.g., floor layer)
# can read it and apply the user's choice.

class_name TileSelectionStore

@export var selected_floor_tile_index: int = -1
@export var selected_wall_tile_index: int = -1

# Persisted placed items
# Floor items: { "item-name": { "primary": Vector2i, "rotation": int } }
# Wall items:  { "item-name": { "coords": Vector2i } }
@export var placed_floor_items: Dictionary = {}
@export var placed_wall_items: Dictionary = {}

const STORE_PATH := "user://tile_selection_store.tres"

static func load_store() -> TileSelectionStore:
	if FileAccess.file_exists(STORE_PATH):
		var res := load(STORE_PATH)
		if res is TileSelectionStore:
			return res
	return TileSelectionStore.new()

static func save_store(store: TileSelectionStore) -> void:
	var err := ResourceSaver.save(store, STORE_PATH)
	if err != OK:
		push_error("Failed to save TileSelectionStore: %s" % err)

static func set_selected_floor_tile_index(index: int) -> void:
	var store := load_store()
	store.selected_floor_tile_index = index
	save_store(store)

static func get_selected_floor_tile_index(default_index: int = -1) -> int:
	var store := load_store()
	if store.selected_floor_tile_index >= 0:
		return store.selected_floor_tile_index
	return default_index

static func get_selected_floor_atlas_coords(default_coords: Vector2i = Vector2i(37, 0)) -> Vector2i:
	# Our floor tiles atlas is a 1-row strip; the x coordinate equals the tile index.
	var idx := get_selected_floor_tile_index(-1)
	if idx >= 0:
		return Vector2i(idx, 0)
	return default_coords

# --- Wall selection helpers ---
static func set_selected_wall_tile_index(index: int) -> void:
	var store := load_store()
	store.selected_wall_tile_index = index
	save_store(store)

static func get_selected_wall_tile_index(default_index: int = -1) -> int:
	var store := load_store()
	if store.selected_wall_tile_index >= 0:
		return store.selected_wall_tile_index
	return default_index

static func get_selected_wall_atlas_coords(default_coords: Vector2i = Vector2i(1, 0)) -> Vector2i:
	var idx := get_selected_wall_tile_index(-1)
	if idx >= 0:
		return Vector2i(idx, 0)
	return default_coords

# ===================== PLACED ITEMS PERSISTENCE =====================
# --- Floor items ---
static func set_placed_floor_item(item_name: String, primary: Vector2i, rotation: int) -> void:
	var store := load_store()
	if store.placed_floor_items == null:
		store.placed_floor_items = {}
	store.placed_floor_items[item_name] = {
		"primary": primary,
		"rotation": rotation
	}
	save_store(store)

static func remove_placed_floor_item(item_name: String) -> void:
	var store := load_store()
	if store.placed_floor_items != null and store.placed_floor_items.has(item_name):
		store.placed_floor_items.erase(item_name)
		save_store(store)

static func get_all_placed_floor_items() -> Dictionary:
	var store := load_store()
	return store.placed_floor_items if store.placed_floor_items != null else {}

# --- Wall items ---
static func set_placed_wall_item(item_name: String, coords: Vector2i) -> void:
	var store := load_store()
	if store.placed_wall_items == null:
		store.placed_wall_items = {}
	store.placed_wall_items[item_name] = {
		"coords": coords
	}
	save_store(store)

static func remove_placed_wall_item(item_name: String) -> void:
	var store := load_store()
	if store.placed_wall_items != null and store.placed_wall_items.has(item_name):
		store.placed_wall_items.erase(item_name)
		save_store(store)

static func get_all_placed_wall_items() -> Dictionary:
	var store := load_store()
	return store.placed_wall_items if store.placed_wall_items != null else {}
