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
const FLOOR_TILES_PATH = "res://scenes/room/tiles/floor-tiles.png"
const WALL_TILES_PATH = "res://scenes/room/tiles/wall-tiles.png"
var current_selected_floor_tile: int = -1
var current_selected_wall_tile: int = -1
var floor_tile_buttons: Array[TextureButton] = []
var wall_tile_buttons: Array[TextureButton] = []
const TileSelectionStore = preload("res://scenes/room/tiles/tile_selection_store.gd")
const PlayerData = preload("res://storage/player_data.gd")

# Map original tile indices -> created buttons (after filtering by ownership)
var _floor_button_by_index: Dictionary = {}
var _wall_button_by_index: Dictionary = {}

func _ready():
	setup_containers()
	load_floor_tiles_to_grid()
	load_wall_tiles_to_grid()
	
	# Restore previous selection if any
	var saved_floor_idx := TileSelectionStore.get_selected_floor_tile_index(-1)
	if saved_floor_idx >= 0:
		_on_tile_button_pressed(saved_floor_idx)
	# If nothing selected (e.g., saved index not owned), select first available
	if current_selected_floor_tile < 0 and _floor_button_by_index.size() > 0:
		var keys := _floor_button_by_index.keys()
		keys.sort()
		_on_tile_button_pressed(keys[0])
	var saved_wall_idx := TileSelectionStore.get_selected_wall_tile_index(-1)
	if saved_wall_idx >= 0:
		_on_wall_tile_button_pressed(saved_wall_idx)
	if current_selected_wall_tile < 0 and _wall_button_by_index.size() > 0:
		var wkeys := _wall_button_by_index.keys()
		wkeys.sort()
		_on_wall_tile_button_pressed(wkeys[0])

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
		push_warning("Failed to load floor texture: " + FLOOR_TILES_PATH)
		return
	
	# Get the image data
	var image = main_texture.get_image()
	var image_width = image.get_width()
	var image_height = image.get_height()
	
	# Calculate number of tiles (assuming 32x32 tiles in a horizontal strip)
	var tile_count = image_width / TILE_SIZE
	# The last tile in the spritesheet is an intentionally empty tile; ignore it.
	var usable_tile_count = max(tile_count - 1, 0)
	
	clear_floor_tile_buttons()
	_floor_button_by_index.clear()
	
	# Extract each tile and add to GridContainer
	for i in range(usable_tile_count):
		# Only show if owned
		var owned_name := "floor-tile-%d" % i
		if not PlayerData.owns_item(owned_name):
			continue
		# Calculate tile position
		var tile_x = i * TILE_SIZE
		var tile_y = 0 # Since it's a horizontal strip
		
		# Create a new image for this tile
		var tile_image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
		
		# Copy the tile portion from the main image
		tile_image.blit_rect(image, Rect2i(tile_x, tile_y, TILE_SIZE, TILE_SIZE), Vector2i(0, 0))
		
		# Create texture from the tile image
		var tile_texture = ImageTexture.new()
		tile_texture.set_image(tile_image)
		tile_texture.set_size_override(Vector2(32, 32))

		# Create TextureButton for this tile
		var tile_button = TextureButton.new()
		tile_button.texture_normal = tile_texture
		tile_button.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		# Make sure the button can receive input
		tile_button.mouse_filter = Control.MOUSE_FILTER_PASS
		tile_button.focus_mode = Control.FOCUS_ALL
		# Store original index on the node
		tile_button.set_meta("tile_index", i)
		# Connect the button signal with original index
		tile_button.pressed.connect(_on_tile_button_pressed.bind(i))
		# Add to grid and store reference
		floor_grid_container.add_child(tile_button)
		floor_tile_buttons.append(tile_button)
		_floor_button_by_index[i] = tile_button

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
		push_warning("Failed to load wall texture: " + WALL_TILES_PATH)
		return
	var image = main_texture.get_image()
	var image_width = image.get_width()
	var tile_count = image_width / TILE_SIZE
	# Ignore last empty tile
	var usable_tile_count = max(tile_count - 1, 0)
	clear_wall_tile_buttons()
	_wall_button_by_index.clear()
	for i in range(usable_tile_count):
		var owned_name := "wall-tile-%d" % i
		if not PlayerData.owns_item(owned_name):
			continue
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
		tile_button.set_meta("tile_index", i)
		tile_button.pressed.connect(_on_wall_tile_button_pressed.bind(i))
		wall_grid_container.add_child(tile_button)
		wall_tile_buttons.append(tile_button)
		_wall_button_by_index[i] = tile_button

func clear_wall_tile_buttons():
	for button in wall_tile_buttons:
		if is_instance_valid(button):
			button.queue_free()
	wall_tile_buttons.clear()
	for child in wall_grid_container.get_children():
		child.queue_free()

func _on_tile_button_pressed(tile_index: int):
	# tile_index is the original tile ordinal in the spritesheet.
	if not _floor_button_by_index.has(tile_index):
		return # Not owned / not present
	var button: TextureButton = _floor_button_by_index[tile_index]
	# Update visuals: highlight only this button
	for i in range(floor_tile_buttons.size()):
		var b: TextureButton = floor_tile_buttons[i]
		b.modulate = Color(1.2, 1.2, 1.2) if b == button else Color.WHITE
	var selected_texture = button.texture_normal
	_set_display_texture(floor_tile_display, selected_texture, "Floor")
	current_selected_floor_tile = tile_index
	# Persist selection to scene store
	TileSelectionStore.set_selected_floor_tile_index(tile_index)

func _on_wall_tile_button_pressed(tile_index: int):
	if not _wall_button_by_index.has(tile_index):
		return
	var button: TextureButton = _wall_button_by_index[tile_index]
	for i in range(wall_tile_buttons.size()):
		var b: TextureButton = wall_tile_buttons[i]
		b.modulate = Color(1.2, 1.2, 1.2) if b == button else Color.WHITE
	var selected_texture = button.texture_normal
	_set_display_texture(wall_tile_display, selected_texture, "Wall")
	current_selected_wall_tile = tile_index
	# Persist selection
	TileSelectionStore.set_selected_wall_tile_index(tile_index)

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
	if current_selected_floor_tile >= 0 and _floor_button_by_index.has(current_selected_floor_tile):
		var btn: TextureButton = _floor_button_by_index[current_selected_floor_tile]
		return btn.texture_normal
	return null

func get_selected_wall_tile_texture() -> Texture2D:
	if current_selected_wall_tile >= 0 and _wall_button_by_index.has(current_selected_wall_tile):
		var btn: TextureButton = _wall_button_by_index[current_selected_wall_tile]
		return btn.texture_normal
	return null

func _on_back_button_pressed() -> void:
	# Ensure selection is saved before going back
	if current_selected_floor_tile >= 0:
		TileSelectionStore.set_selected_floor_tile_index(current_selected_floor_tile)
	if current_selected_wall_tile >= 0:
		TileSelectionStore.set_selected_wall_tile_index(current_selected_wall_tile)
	# Load room scene
	var room_scene = load("res://scenes/room/room.tscn").instantiate()
	get_tree().root.add_child(room_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = room_scene

# Internal utility to safely assign a texture to a TextureRect
func _set_display_texture(target: TextureRect, texture: Texture2D, label: String):
	if target and is_instance_valid(target):
		target.texture = texture
	else:
		push_warning(label + " tile display TextureRect missing or freed; cannot assign texture.")
