extends ModifiableTileMapLayer
class_name FloorItemsLayer

# Dynamically adjusts each floor item tile's z_index relative to the dog
# in the isometric diamond-down layout using tile-coordinate deltas.
# Rule:
# - Consider the dog "in front" of a tile when (dx >= 0 and dy >= 0) and not both 0,
#   where dx,dy are dog_tile - tile_coords.
# - The z separation equals max(dx, dy) when in front.
# - Otherwise the dog is "behind"; the tile draws above the dog by
#   max(abs(dx), abs(dy)), with a minimum of 1 (so (0,0) still shows tile above dog).

const BASE_HIGH_Z := 1000

var _dog_global_position: Vector2 = Vector2.INF
var _dog_tile: Vector2i = Vector2i(2147483647, 2147483647)
const TileSelectionStoreRes = preload("res://scenes/room/tiles/tile_selection_store.gd")

# Public API: update z-ordering reference using the dog's global position
func update_z_order_relative_to(dog_global_position: Vector2) -> void:
	if _dog_global_position == dog_global_position:
		return
	_dog_global_position = dog_global_position
	# Compute the dog's tile in this TileMap's coordinates
	var local_pos: Vector2 = to_local(_dog_global_position)
	_dog_tile = local_to_map(local_pos)
	# Trigger runtime data refresh for all visible tiles
	notify_runtime_tile_data_update()

# Always allow runtime update so we can set per-tile z on demand
func _use_tile_data_runtime_update(_coords: Vector2i) -> bool:
	return true

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	# First, let base class apply any queued visual mods (e.g., modulate)
	super._tile_data_runtime_update(coords, tile_data)
	# Compute tile delta in map coordinates relative to the dog
	var dx: int = _dog_tile.x - coords.x
	var dy: int = _dog_tile.y - coords.y

	# In front quadrant: dx>=0, dy>=0 and not both zero
	var front: bool = (dx >= 0 and dy >= 0) and not (dx == 0 and dy == 0)
	if front:
		var k_front: int = max(dx, dy)
		# Place tile below dog by k_front layers (still within high band)
		tile_data.z_index = BASE_HIGH_Z - k_front
	else:
		var k_behind: int = max(abs(dx), abs(dy))
		if k_behind < 1:
			k_behind = 1
		# Place tile above dog by k_behind layers
		tile_data.z_index = BASE_HIGH_Z + k_behind
