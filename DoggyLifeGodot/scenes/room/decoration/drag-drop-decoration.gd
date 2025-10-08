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
		
		# Bed preview: compose with cropping to emulate (-16, +8) displacement without changing final size
		# 1) First 32x32 at (0,64) drawn at (0,0)
		# 2) From the second 32x32 at (32,64), cut the left 16px and the bottom 8px -> src (48,64) size (16x24)
		#    Draw that at (32,8), effectively adding 8px transparent padding at the top
		# Final canvas: width 48, height 32
		var composed_bed_texture: Texture2D = null
		var bed_canvas_w := 48
		var bed_canvas_h := 32
		var sheet_image: Image = (sheet as Texture2D).get_image()
		if sheet_image != null:
			var img := Image.create(bed_canvas_w, bed_canvas_h, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			# Blit first 32x32 at (0,0)
			img.blit_rect(sheet_image, Rect2i(0, 64, 32, 32), Vector2i(0, 0))
			# From second tile, take rightmost 16px and top 24px, draw at (32,8) to emulate -16 x, +8 y displacement
			img.blit_rect(sheet_image, Rect2i(48, 64, 16, 24), Vector2i(32, 8))
			composed_bed_texture = ImageTexture.create_from_image(img)
		else:
			# Fallback to previous single atlas region if the image can't be read
			var bed := AtlasTexture.new()
			bed.atlas = sheet
			bed.region = Rect2(0, 64, 48, 32)
			composed_bed_texture = bed
		add_item_entry(grid, "bed-sprite", composed_bed_texture, is_floor)
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

func add_item_entry(grid: GridContainer, base: String, texture: Texture2D, is_floor: bool) -> void:
	var display_name := base.replace("-sprite", "").replace("_", " ")
	display_name = display_name.capitalize()
	
	var display_height := 25
	var tex_size: Vector2
	if texture is AtlasTexture:
		tex_size = (texture as AtlasTexture).region.size
	else:
		tex_size = Vector2(texture.get_width(), texture.get_height())
	var scale_factor := float(display_height) / tex_size.y
	var display_width := int(round(tex_size.x * scale_factor))
	
	var item := VBoxContainer.new()
	item.alignment = BoxContainer.ALIGNMENT_CENTER
	item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var preview := TextureRect.new()
	preview.texture = texture
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
		preview.gui_input.connect(Callable(room, "_on_drag_preview_gui_input").bind(base, texture, is_floor))
	
	var label := Label.new()
	label.text = display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 6)
	
	item.add_child(preview)
	item.add_child(label)
	grid.add_child(item)
