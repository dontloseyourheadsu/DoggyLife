extends Control

@onready var floor_scroll_container := $MarginContainer/VBoxContainer/FloorScrollContainer as ScrollContainer
@onready var floor_grid_container := $MarginContainer/VBoxContainer/FloorScrollContainer/FloorGridContainer as GridContainer
@onready var wall_scroll_container := $MarginContainer/VBoxContainer/WallScrollContainer as ScrollContainer
@onready var wall_grid_container := $MarginContainer/VBoxContainer/WallScrollContainer/WallGridContainer as GridContainer
@onready var floor_tile_display := $MarginContainer/VBoxContainer/FloorTileTexture as TextureRect
@onready var wall_tile_display := $MarginContainer/VBoxContainer/WallTileTexture as TextureRect
@onready var back_button := $BackButton as Button

const TILE_SIZE = 32
const WALL_TILE_HEIGHT = 64 # wall tiles are twice as tall
const FLOOR_TILES_PATH = "res://room/tiles/floor-tiles.png"
const WALL_TILES_PATH = "res://room/tiles/wall-tiles.png"
var current_selected_floor_tile: int = -1
var current_selected_wall_tile: int = -1
var floor_tile_buttons: Array[TextureButton] = []
var wall_tile_buttons: Array[TextureButton] = []

func _ready():
	setup_containers()
	load_floor_tiles_to_grid()
	load_wall_tiles_to_grid()
	
	# Connect back button
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

func setup_containers():	
	# Setup the texture display
	floor_tile_display.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	floor_tile_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if wall_tile_display:
		wall_tile_display.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		wall_tile_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func load_floor_tiles_to_grid():
	var main_texture = load(FLOOR_TILES_PATH) as Texture2D
	if not main_texture:
		print("Failed to load floor texture: ", FLOOR_TILES_PATH)
		return
	
	# Get the image data
	var image = main_texture.get_image()
	var image_width = image.get_width()
	var image_height = image.get_height()
	
	# Calculate number of tiles (assuming 32x32 tiles in a horizontal strip)
	var tile_count = image_width / TILE_SIZE
	
	clear_floor_tile_buttons()
	
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
		floor_grid_container.add_child(tile_button)
		floor_tile_buttons.append(tile_button)

func clear_floor_tile_buttons():
	for button in floor_tile_buttons:
		if is_instance_valid(button):
			button.queue_free()
	floor_tile_buttons.clear()
	for child in floor_grid_container.get_children():
		child.queue_free()

func load_wall_tiles_to_grid():
	var main_texture = load(WALL_TILES_PATH) as Texture2D
	if not main_texture:
		print("Failed to load wall texture: ", WALL_TILES_PATH)
		return
	var image = main_texture.get_image()
	var image_width = image.get_width()
	var tile_count = image_width / TILE_SIZE
	clear_wall_tile_buttons()
	for i in range(tile_count):
		var tile_x = i * TILE_SIZE
		var tile_image = Image.create(TILE_SIZE, WALL_TILE_HEIGHT, false, Image.FORMAT_RGBA8)
		tile_image.blit_rect(image, Rect2i(tile_x, 0, TILE_SIZE, WALL_TILE_HEIGHT), Vector2i(0, 0))
		var tile_texture = ImageTexture.new()
		tile_texture.set_image(tile_image)
		tile_texture.set_size_override(Vector2(TILE_SIZE, WALL_TILE_HEIGHT))
		var tile_button = TextureButton.new()
		tile_button.texture_normal = tile_texture
		tile_button.custom_minimum_size = Vector2(TILE_SIZE, WALL_TILE_HEIGHT)
		tile_button.mouse_filter = Control.MOUSE_FILTER_PASS
		tile_button.focus_mode = Control.FOCUS_ALL
		tile_button.pressed.connect(_on_wall_tile_button_pressed.bind(i))
		wall_grid_container.add_child(tile_button)
		wall_tile_buttons.append(tile_button)

func clear_wall_tile_buttons():
	for button in wall_tile_buttons:
		if is_instance_valid(button):
			button.queue_free()
	wall_tile_buttons.clear()
	for child in wall_grid_container.get_children():
		child.queue_free()

func _on_tile_button_pressed(tile_index: int):
	print("Selected floor tile: ", tile_index)
	update_floor_selection_visual(tile_index)
	var selected_texture = floor_tile_buttons[tile_index].texture_normal
	_set_display_texture(floor_tile_display, selected_texture, "Floor")
	current_selected_floor_tile = tile_index

func _on_wall_tile_button_pressed(tile_index: int):
	print("Selected wall tile: ", tile_index)
	update_wall_selection_visual(tile_index)
	var selected_texture = wall_tile_buttons[tile_index].texture_normal
	_set_display_texture(wall_tile_display, selected_texture, "Wall")
	current_selected_wall_tile = tile_index

func update_floor_selection_visual(selected_index: int):
	for i in range(floor_tile_buttons.size()):
		var button = floor_tile_buttons[i]
		button.modulate = Color(1.2, 1.2, 1.2) if i == selected_index else Color.WHITE

func update_wall_selection_visual(selected_index: int):
	for i in range(wall_tile_buttons.size()):
		var button = wall_tile_buttons[i]
		button.modulate = Color(1.2, 1.2, 1.2) if i == selected_index else Color.WHITE

func get_selected_floor_tile_index() -> int:
	return current_selected_floor_tile

func get_selected_wall_tile_index() -> int:
	return current_selected_wall_tile

func get_selected_floor_tile_texture() -> Texture2D:
	if current_selected_floor_tile >= 0 and current_selected_floor_tile < floor_tile_buttons.size():
		return floor_tile_buttons[current_selected_floor_tile].texture_normal
	return null

func get_selected_wall_tile_texture() -> Texture2D:
	if current_selected_wall_tile >= 0 and current_selected_wall_tile < wall_tile_buttons.size():
		return wall_tile_buttons[current_selected_wall_tile].texture_normal
	return null

func _on_back_button_pressed() -> void:
	# Load room scene
	var room_scene = load("res://room/room.tscn").instantiate()
	get_tree().root.add_child(room_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = room_scene

# Internal utility to safely assign a texture to a TextureRect
func _set_display_texture(target: TextureRect, texture: Texture2D, label: String):
	if target and is_instance_valid(target):
		target.texture = texture
	else:
		push_warning(label + " tile display TextureRect missing or freed; cannot assign texture.")
