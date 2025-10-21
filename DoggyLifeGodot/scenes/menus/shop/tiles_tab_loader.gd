# Helper for populating the Tiles tab (floor and wall tiles)
# Usage: TilesTabLoader.populate(grid, player_data, floor_tiles_path, wall_tiles_path, tile_size, wall_tile_height, add_entry)
# - grid: GridContainer where entries will be added
# - player_data: script/object exposing owns_item(name: String) and add_owned_item(name: String)
# - floor_tiles_path, wall_tiles_path: paths to the tiles spritesheets
# - tile_size: int size of the tile width/height (floor) in pixels
# - wall_tile_height: int height of the wall tile graphic in pixels
# - add_entry: Callable(name: String, texture: Texture2D) to add entries to the grid

static func populate(_grid: GridContainer, player_data, floor_tiles_path: String, wall_tiles_path: String, tile_size: int, wall_tile_height: int, add_entry: Callable) -> void:
	# Floor tiles
	var floor_texture := load(floor_tiles_path) as Texture2D
	if floor_texture != null:
		var image := floor_texture.get_image()
		if image != null:
			var image_width: int = image.get_width()
			var tile_count: int = int(floor(float(image_width) / float(tile_size)))
			var usable_tile_count: int = int(max(tile_count - 1, 0))
			_ensure_default_owned_tiles(player_data, "floor", usable_tile_count)
			for i in range(usable_tile_count):
				var tile_image := Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
				tile_image.blit_rect(image, Rect2i(i * tile_size, 0, tile_size, tile_size), Vector2i(0, 0))
				var tile_texture := ImageTexture.create_from_image(tile_image)
				var item_name := "floor-tile-%d" % i
				if not player_data.owns_item(item_name):
					add_entry.call(item_name, tile_texture)

	# Wall tiles
	var wall_texture := load(wall_tiles_path) as Texture2D
	if wall_texture != null:
		var wimage := wall_texture.get_image()
		if wimage != null:
			var w_image_width: int = wimage.get_width()
			var w_tile_count: int = int(floor(float(w_image_width) / float(tile_size)))
			var w_usable_tile_count: int = int(max(w_tile_count - 1, 0))
			_ensure_default_owned_tiles(player_data, "wall", w_usable_tile_count)
			for j in range(w_usable_tile_count):
				var w_tile_image := Image.create(tile_size, wall_tile_height, false, Image.FORMAT_RGBA8)
				w_tile_image.blit_rect(wimage, Rect2i(j * tile_size, 0, tile_size, wall_tile_height), Vector2i(0, 0))
				var w_tile_texture := ImageTexture.create_from_image(w_tile_image)
				var w_item_name := "wall-tile-%d" % j
				if not player_data.owns_item(w_item_name):
					add_entry.call(w_item_name, w_tile_texture)

static func _ensure_default_owned_tiles(player_data, kind: String, usable_tile_count: int) -> void:
	var defaults: int = int(min(3, usable_tile_count))
	for i in range(defaults):
		var owned_name := ("%s-tile-%%d" % kind) % i
		if not player_data.owns_item(owned_name):
			player_data.add_owned_item(owned_name)
