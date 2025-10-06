extends Control

@onready var floor_grid: GridContainer = get_node_or_null("../DragsContainer/FloorItemsContainer/GridContainer")
@onready var wall_grid: GridContainer = get_node_or_null("../DragsContainer/WallItemsContainer/GridContainer")

const FLOOR_DIR := "res://scenes/room/decoration/floor"
const WALL_DIR := "res://scenes/room/decoration/wall"

func _ready() -> void:
	populate_grid(floor_grid, FLOOR_DIR)
	populate_grid(wall_grid, WALL_DIR)

func populate_grid(grid: GridContainer, dir_path: String) -> void:
	if grid == null:
		push_warning("Grid not found for path: %s" % dir_path)
		return
	
	# Clear existing items
	for child in grid.get_children():
		child.queue_free()
	
	var is_floor := dir_path.ends_with("/floor")
	var sheet_name := "floor-sprites.png" if is_floor else "wall-sprites.png"
	var sheet_path := dir_path.path_join(sheet_name)
	
	if not ResourceLoader.exists(sheet_path):
		push_warning("Spritesheet not found: %s" % sheet_path)
		return
	
	var sheet := load(sheet_path)
	if sheet == null or not (sheet is Texture2D):
		push_warning("Failed to load spritesheet: %s" % sheet_path)
		return
	
	if is_floor:
		# Floor: 256x96, first version only
		# Lamp (32x32) at x=0, y=0
		var lamp := AtlasTexture.new()
		lamp.atlas = sheet
		lamp.region = Rect2(0, 0, 32, 32)
		add_item_entry(grid, "lamp-sprite", lamp, is_floor)
		
		# Shelf (32x32) at x=0, y=32
		var shelf := AtlasTexture.new()
		shelf.atlas = sheet
		shelf.region = Rect2(0, 32, 32, 32)
		add_item_entry(grid, "shelf-sprite", shelf, is_floor)
		
		# Bed (48x32) at x=0, y=64
		var bed := AtlasTexture.new()
		bed.atlas = sheet
		bed.region = Rect2(0, 64, 48, 32)
		add_item_entry(grid, "bed-sprite", bed, is_floor)
	else:
		# Wall: 64x96, first version only, all 32x32
		# Window at x=0, y=0
		var window := AtlasTexture.new()
		window.atlas = sheet
		window.region = Rect2(0, 0, 32, 32)
		add_item_entry(grid, "window-sprite", window, is_floor)
		
		# Bookshelf at x=0, y=32
		var bookshelf := AtlasTexture.new()
		bookshelf.atlas = sheet
		bookshelf.region = Rect2(0, 32, 32, 32)
		add_item_entry(grid, "bookshelf-sprite", bookshelf, is_floor)
		
		# Painting at x=0, y=64
		var painting := AtlasTexture.new()
		painting.atlas = sheet
		painting.region = Rect2(0, 64, 32, 32)
		add_item_entry(grid, "painting-sprite", painting, is_floor)

func add_item_entry(grid: GridContainer, base: String, atlas: AtlasTexture, is_floor: bool) -> void:
	var display_name := base.replace("-sprite", "").replace("_", " ")
	display_name = display_name.capitalize()
	
	var display_height := 25
	var atlas_size := atlas.region.size
	var scale_factor := float(display_height) / atlas_size.y
	var display_width := int(round(atlas_size.x * scale_factor))
	
	var item := VBoxContainer.new()
	item.alignment = BoxContainer.ALIGNMENT_CENTER
	item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var preview := TextureRect.new()
	preview.texture = atlas
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.ignore_texture_size = true
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.custom_minimum_size = Vector2(display_width, display_height)
	preview.size = Vector2(display_width, display_height)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.tooltip_text = base
	
	var room := get_tree().current_scene
	if room != null and room.has_method("_on_drag_preview_gui_input"):
		preview.gui_input.connect(Callable(room, "_on_drag_preview_gui_input").bind(base, atlas, is_floor))
	
	var label := Label.new()
	label.text = display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 6)
	
	item.add_child(preview)
	item.add_child(label)
	grid.add_child(item)
