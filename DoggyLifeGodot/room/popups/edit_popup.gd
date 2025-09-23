extends Control

@onready var scroll_container := $MarginContainer/VBoxContainer/ScrollContainer as ScrollContainer
@onready var grid_container := $MarginContainer/VBoxContainer/ScrollContainer/GridContainer as GridContainer
@onready var floor_tile_display := $MarginContainer/VBoxContainer/FloorTileTexture as TextureRect
@onready var back_button := $BackButton as Button

const TILE_SIZE = 32
const TILES_PATH = "res://room/tiles/floor-tiles.png"
var current_selected_tile: int = -1
var tile_buttons: Array[TextureButton] = []

func _ready():
	setup_containers()
	load_tiles_to_grid()
	
	# Connect back button
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

func setup_containers():	
	# Setup the texture display
	floor_tile_display.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	floor_tile_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func load_tiles_to_grid():
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
	
	# Clear existing buttons
	clear_tile_buttons()
	
	# Extract each tile and add to GridContainer
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
		tile_texture.set_size_override(Vector2(32,32))
		
		# Create TextureButton for this tile
		var tile_button = TextureButton.new()
		tile_button.texture_normal = tile_texture
		tile_button.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		# Make sure the button can receive input
		tile_button.mouse_filter = Control.MOUSE_FILTER_PASS
		tile_button.focus_mode = Control.FOCUS_ALL
		
		# Connect the button signal
		tile_button.pressed.connect(_on_tile_button_pressed.bind(i))
		
		# Add to grid and store reference
		grid_container.add_child(tile_button)
		tile_buttons.append(tile_button)

func clear_tile_buttons():
	# Remove all existing tile buttons
	for button in tile_buttons:
		if is_instance_valid(button):
			button.queue_free()
	tile_buttons.clear()
	
	# Clear grid container children
	for child in grid_container.get_children():
		child.queue_free()

func _on_tile_button_pressed(tile_index: int):
	print("Selected tile: ", tile_index)
	
	# Update visual selection (optional - add highlight)
	update_selection_visual(tile_index)
	
	# Get the selected tile texture and display it
	var selected_texture = tile_buttons[tile_index].texture_normal
	floor_tile_display.texture = selected_texture
	
	# Store current selection
	current_selected_tile = tile_index

func update_selection_visual(selected_index: int):
	# Reset all buttons to normal appearance
	for i in range(tile_buttons.size()):
		var button = tile_buttons[i]
		if i == selected_index:
			# Highlight selected button (you can customize this)
			button.modulate = Color(1.2, 1.2, 1.2)  # Slightly brighter
		else:
			button.modulate = Color.WHITE  # Normal color

func get_selected_tile_index() -> int:
	return current_selected_tile

func get_selected_tile_texture() -> Texture2D:
	if current_selected_tile >= 0 and current_selected_tile < tile_buttons.size():
		return tile_buttons[current_selected_tile].texture_normal
	return null

func _on_back_button_pressed() -> void:
	# Load room scene
	var room_scene = load("res://room/room.tscn").instantiate()
	get_tree().root.add_child(room_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = room_scene
