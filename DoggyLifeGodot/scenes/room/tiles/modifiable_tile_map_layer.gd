extends TileMapLayer
class_name ModifiableTileMapLayer

# Stores per-tile modification functions to be applied at runtime
var _tile_modifications: Dictionary = {}
var _erase_queue: Array[Vector2i] = []
var _erase_scheduled: bool = false

## Public API: set per-tile modulate color
func set_tile_modulate(coords: Vector2i, color: Color) -> void:
	_tile_modifications[coords] = func(tile_data: TileData):
		tile_data.modulate = color
	# Request runtime tile data refresh (whole map; fast enough for hover)
	notify_runtime_tile_data_update()

## Public API: clear modulate for a specific tile
func clear_tile_modulate(coords: Vector2i) -> void:
	# Apply identity modulate for one frame to force reset, then erase
	_tile_modifications[coords] = func(tile_data: TileData):
		tile_data.modulate = Color(1, 1, 1, 1)
	notify_runtime_tile_data_update()
	_schedule_erase_after_frame(coords)

## Public API: clear all runtime modifications (safety/reset)
func clear_all_modulates() -> void:
	if _tile_modifications.size() > 0:
		_tile_modifications.clear()
		notify_runtime_tile_data_update()

## Tell Godot which tiles require runtime updates
func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return _tile_modifications.has(coords)

## Apply the actual per-tile visual changes
func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	if _tile_modifications.has(coords):
		var modification_func: Callable = _tile_modifications[coords]
		modification_func.call(tile_data)

func _schedule_erase_after_frame(coords: Vector2i) -> void:
	_erase_queue.append(coords)
	if _erase_scheduled:
		return
	_erase_scheduled = true
	# Wait one frame so the identity modulate is applied, then erase the entry
	await get_tree().process_frame
	for c in _erase_queue:
		_tile_modifications.erase(c)
	_erase_queue.clear()
	_erase_scheduled = false
	notify_runtime_tile_data_update()
