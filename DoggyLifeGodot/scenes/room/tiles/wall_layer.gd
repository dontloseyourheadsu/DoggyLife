extends ModifiableTileMapLayer

const WALL_TEXTURE_SOURCE_ID := 0
const BASE_WALL_ATLAS_COORDINATES := Vector2i(2, 0)

func _ready():
	var selected_wall_atlas := TileSelectionStore.get_selected_wall_atlas_coords(BASE_WALL_ATLAS_COORDINATES)
	replace_tiles(BASE_WALL_ATLAS_COORDINATES, selected_wall_atlas)

func replace_tiles(old_atlas: Vector2i, new_atlas: Vector2i):
	var used_cells = get_used_cells()
	for pos in used_cells:
		if get_cell_atlas_coords(pos) == old_atlas:
			set_cell(pos, WALL_TEXTURE_SOURCE_ID, new_atlas)
