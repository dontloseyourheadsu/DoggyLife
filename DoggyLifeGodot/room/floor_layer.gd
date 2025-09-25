extends TileMapLayer

const TEXTURE_SOURCE_ID = 2
const TEXTURE_ATLAS_COORDINATES = Vector2i(39, 0)

func _ready():
	var filled_tiles := get_used_cells()
	for filled_tile: Vector2i in filled_tiles:
		var neighboring_tiles := get_surrounding_cells(filled_tile)
		for neighborCoordinates: Vector2i in neighboring_tiles:
			if get_cell_source_id(neighborCoordinates) == -1:
				set_cell(neighborCoordinates, TEXTURE_SOURCE_ID, TEXTURE_ATLAS_COORDINATES)
