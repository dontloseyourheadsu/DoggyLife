extends Control
@onready var floor_tiles_list := $MarginContainer/VBoxContainer/FloorItemList as ItemList
@onready var floor_tile_display := $MarginContainer/VBoxContainer/FloorTileTexture as TextureRect

const TILE_SIZE = 32
const TILES_PATH = "res://room/tiles/floor-tiles.png"

func _ready():
	setup_item_list()
	load_tiles_to_list()
	
	# Test without custom input handling first
	# floor_tiles_list.gui_input.connect(_handle_itemlist_input)

# Handle scrolling directly on the ItemList
func _on_itemlist_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_list(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_list(1)
	elif event is InputEventPanGesture:
		_scroll_list(event.delta.y * 3)

func _scroll_list(direction: float):
	var scroll_bar = floor_tiles_list.get_v_scroll_bar()
	var scroll_speed = 50.0  # Adjust as needed
	scroll_bar.value += direction * scroll_speed
	scroll_bar.value = clamp(scroll_bar.value, scroll_bar.min_value, scroll_bar.max_value)

func setup_item_list():
	# Configure the ItemList - keep it simple
	floor_tiles_list.icon_mode = ItemList.ICON_MODE_TOP
	floor_tiles_list.fixed_icon_size = Vector2i(32, 32)
	
	# Basic selection settings
	floor_tiles_list.select_mode = ItemList.SELECT_SINGLE
	floor_tiles_list.allow_reselect = true
	
	# Setup the texture display
	floor_tile_display.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	floor_tile_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func load_tiles_to_list():
	# Load the main texture
	var main_texture = load(TILES_PATH) as Texture2D
	if not main_texture:
		print("Failed to load texture: ", TILES_PATH)
		return
	
	# Get the image data
	var image = main_texture.get_image()
	var image_width = image.get_width()
	var image_height = image.get_height()
	
	# Calculate number of tiles (assuming 32x32 tiles in a horizontal strip)
	var tile_count = image_width / TILE_SIZE
	
	# Clear the list first
	floor_tiles_list.clear()
	
	# Extract each tile and add to ItemList
	for i in range(tile_count):
		# Calculate tile position
		var tile_x = i * TILE_SIZE
		var tile_y = 0  # Since it's a horizontal strip
		
		# Create a new image for this tile
		var tile_image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
		
		# Copy the tile portion from the main image
		tile_image.blit_rect(image, Rect2i(tile_x, tile_y, TILE_SIZE, TILE_SIZE), Vector2i(0, 0))
		
		# Create texture from the tile image
		var tile_texture = ImageTexture.new()
		tile_texture.set_image(tile_image)
		
		# Add to ItemList with empty text and the tile texture
		floor_tiles_list.add_item("", tile_texture)

# This is the signal connected in the editor
func _on_item_list_item_selected(index):
	print("Selected tile: ", index)
	
	# Get the selected tile texture
	var selected_texture = floor_tiles_list.get_item_icon(index)
	
	# Display it in the TextureRect
	floor_tile_display.texture = selected_texture
	
	# Optional: You can also handle the selection logic here
	handle_tile_selection(index, selected_texture)

func handle_tile_selection(tile_index: int, tile_texture: Texture2D):
	# This is where you handle what happens when a tile is selected
	# For example:
	# - Store the selected tile index for later use
	# - Update other UI elements
	# - Set it as the current brush
	# - etc.
	
	# Example: Store the current selection
	# current_selected_tile = tile_index
	pass
