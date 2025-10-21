# Helper for populating the Items tab (room decorations)
# Usage: ItemsTabLoader.populate(grid, player_data, floor_dir, wall_dir, add_entry)
# - grid: GridContainer where entries will be added
# - player_data: script/object exposing owns_item(name: String) and add_owned_item(name: String)
# - floor_dir, wall_dir: directories containing the spritesheets
# - add_entry: Callable(name: String, texture: Texture2D) to add entries to the grid

static func populate(_grid: GridContainer, player_data, floor_dir: String, wall_dir: String, add_entry: Callable) -> void:
	# Load sheets
	var floor_sheet_path := floor_dir.path_join("floor-sprites.png")
	var wall_sheet_path := wall_dir.path_join("wall-sprites.png")
	var floor_sheet: Texture2D = null
	var wall_sheet: Texture2D = null
	if ResourceLoader.exists(floor_sheet_path):
		floor_sheet = load(floor_sheet_path)
	if ResourceLoader.exists(wall_sheet_path):
		wall_sheet = load(wall_sheet_path)

	if floor_sheet == null and wall_sheet == null:
		push_warning("No decoration spritesheets found for shop.")
		return

	# Define sellable entries (names align with room decoration identifiers)
	var items: Array = []
	if floor_sheet != null:
		items.append({"name": "lamp-sprite", "type": "floor", "texture": _atlas(floor_sheet, Rect2(0, 0, 32, 32))})
		items.append({"name": "shelf-sprite", "type": "floor", "texture": _atlas(floor_sheet, Rect2(0, 32, 32, 32))})
		items.append({"name": "bed-sprite", "type": "floor", "texture": _compose_bed_texture(floor_sheet)})
	if wall_sheet != null:
		items.append({"name": "window-sprite", "type": "wall", "texture": _atlas(wall_sheet, Rect2(16, 0, 16, 32))})
		items.append({"name": "bookshelf-sprite", "type": "wall", "texture": _atlas(wall_sheet, Rect2(16, 32, 16, 32))})
		items.append({"name": "painting-sprite", "type": "wall", "texture": _atlas(wall_sheet, Rect2(16, 64, 16, 32))})

	for it in items:
		var entry_name: String = it["name"]
		if player_data.owns_item(entry_name):
			continue
		var tex: Texture2D = it["texture"]
		if tex == null:
			continue
		add_entry.call(entry_name, tex)

static func _atlas(sheet: Texture2D, region: Rect2) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = region
	return at

static func _compose_bed_texture(sheet: Texture2D) -> Texture2D:
	var sheet_image: Image = sheet.get_image()
	if sheet_image == null:
		# Fallback to simple atlas of first tile
		return _atlas(sheet, Rect2(0, 64, 32, 32))
	var bed_canvas_w := 48
	var bed_canvas_h := 32
	var img := Image.create(bed_canvas_w, bed_canvas_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# First 32x32 at (0,64) -> (0,0)
	img.blit_rect(sheet_image, Rect2i(0, 64, 32, 32), Vector2i(0, 0))
	# From second tile (32,64) take rightmost 16px and top 24px -> src (48,64) size (16,24)
	img.blit_rect(sheet_image, Rect2i(48, 64, 16, 24), Vector2i(32, 8))
	return ImageTexture.create_from_image(img)
