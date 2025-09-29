extends TileMapLayer

const FLOOR_TEXTURE_SOURCE_ID := 2
const BASE_FLOOR_ATLAS_COORDINATES := Vector2i(2, 0)
const DELIMITER_ATLAS_COORDINATES := Vector2i(39, 0)
const TileSelectionStore = preload("res://scenes/room/tiles/tile_selection_store.gd")

func _ready():
	var selected_atlas := TileSelectionStore.get_selected_floor_atlas_coords(Vector2i(37, 0))
	# If no selection saved yet, fall back to 37,0 to preserve previous behavior.
	replace_tiles(BASE_FLOOR_ATLAS_COORDINATES, selected_atlas)
	fill_with_delimiter_tiles()

func replace_tiles(old_atlas: Vector2i, new_atlas: Vector2i):
	var used_cells = get_used_cells()
	for pos in used_cells:
		if get_cell_atlas_coords(pos) == old_atlas:
			set_cell(pos, FLOOR_TEXTURE_SOURCE_ID, new_atlas)

func fill_with_delimiter_tiles():
	var filled_tiles := get_used_cells()
	for filled_tile: Vector2i in filled_tiles:
		var neighboring_tiles := get_surrounding_cells(filled_tile)
		for neighbor_coordinates: Vector2i in neighboring_tiles:
			if get_cell_source_id(neighbor_coordinates) == -1:
				set_cell(neighbor_coordinates, FLOOR_TEXTURE_SOURCE_ID, DELIMITER_ATLAS_COORDINATES)
