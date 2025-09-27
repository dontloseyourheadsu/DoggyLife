extends Resource

# Store for scene-scoped tile selection.
# Persists the selected floor tile index so other scripts (e.g., floor layer)
# can read it and apply the user's choice.

class_name TileSelectionStore

@export var selected_floor_tile_index: int = -1
@export var selected_wall_tile_index: int = -1

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

