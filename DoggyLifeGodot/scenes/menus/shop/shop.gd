extends Control


# Tabs representing the different shop sections
enum Tab {
	ITEMS,
	DOGS,
	TILES,
}

# Scroll containers (content areas)
@onready var _items_scroll: ScrollContainer = $Container/RoomItemsScrollContainer
@onready var _dogs_scroll: ScrollContainer = $Container/DogsScrollContainer
@onready var _tiles_scroll: ScrollContainer = $Container/TilesScrollContainer
@onready var _items_grid: GridContainer = $Container/RoomItemsScrollContainer/RoomItemsGridContainer
@onready var _tiles_grid: GridContainer = $Container/TilesScrollContainer/TilesGridContainer
@onready var _dogs_grid: GridContainer = $Container/DogsScrollContainer/DogsGridContainer

# Tab buttons
@onready var _items_btn: TextureButton = $Container/TabNavigation/ItemsTabButton
@onready var _dogs_btn: TextureButton = $Container/TabNavigation/DogsTabButton
@onready var _tiles_btn: TextureButton = $Container/TabNavigation/ItemsTabButton3

@onready var _price_button: TextureButton = $Container/PriceContainer
@onready var _price_label: Label = $Container/PriceContainer/PriceDisplay
@onready var _coins_display: Node = $Container/CoinsContainerDisplay
@onready var _price_item_name: Label = $Container/PriceItemName

const PLAYER_DATA_STORAGE = preload("res://storage/player_data.gd")
const ItemsTabLoader = preload("res://scenes/menus/shop/items_tab_loader.gd")
const TilesTabLoader = preload("res://scenes/menus/shop/tiles_tab_loader.gd")
const DogsTabLoader = preload("res://scenes/menus/shop/dogs_tab_loader.gd")

const FLOOR_DIR := "res://sprites/decoration/floor"
const WALL_DIR := "res://sprites/decoration/wall"
const PREVIEW_SCALE := 3
const TILE_SIZE := 32
const WALL_TILE_HEIGHT := 64
const FLOOR_TILES_PATH := "res://scenes/room/tiles/floor-tiles.png"
const WALL_TILES_PATH := "res://scenes/room/tiles/wall-tiles.png"

var _entry_nodes: Dictionary = {}
var _selected_item_name: String = ""
var _selected_item_price: int = 0
var _items_populated: bool = false
var _tiles_populated: bool = false
var _dogs_populated: bool = false

var _current_tab: Tab = Tab.ITEMS

func _ready() -> void:
	# Ensure the initial visibility reflects the default tab
	_apply_tab_visibility()
	_update_price_display(null)
	_update_item_name_display("")
	# Populate the items list initially
	_populate_items_if_needed()


func _on_back_button_pressed() -> void:
	# Load room scene
	var room_scene = load("res://scenes/room/room.tscn").instantiate()
	get_tree().root.add_child(room_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = room_scene


# --- Tab switching logic ---
func _on_items_tab_button_pressed() -> void:
	_set_tab(Tab.ITEMS)
	_populate_items_if_needed()

func _on_dogs_tab_button_pressed() -> void:
	_set_tab(Tab.DOGS)

func _on_items_tab_button_3_pressed() -> void:
	_set_tab(Tab.TILES)

func _set_tab(tab: Tab) -> void:
	if _current_tab == tab:
		return
	_current_tab = tab
	_clear_selection()
	_apply_tab_visibility()
	if tab == Tab.ITEMS:
		_populate_items_if_needed()
	elif tab == Tab.TILES:
		_populate_tiles_if_needed()
	elif tab == Tab.DOGS:
		_populate_dogs_if_needed()

func _apply_tab_visibility() -> void:
	# Hide all sections first
	_set_all_sections_visible(false)

	# Show only the active section
	match _current_tab:
		Tab.ITEMS:
			_items_scroll.visible = true
		Tab.DOGS:
			_dogs_scroll.visible = true
		Tab.TILES:
			_tiles_scroll.visible = true

	_update_tab_button_states()

func _populate_items_if_needed() -> void:
	if _items_populated:
		return
	_populate_items_grid()
	_items_populated = true

func _populate_items_grid() -> void:
	# Clear existing
	for child in _items_grid.get_children():
		child.queue_free()
	_entry_nodes.clear()

	# Delegate population to loader
	ItemsTabLoader.populate(
		_items_grid,
		PLAYER_DATA_STORAGE,
		FLOOR_DIR,
		WALL_DIR,
		func(entry_name: String, tex: Texture2D) -> void:
			_add_item_entry(entry_name, tex)
	)

func _populate_tiles_if_needed() -> void:
	if _tiles_populated:
		return
	_populate_tiles_grid()
	_tiles_populated = true

func _populate_dogs_if_needed() -> void:
	if _dogs_populated:
		return
	_populate_dogs_grid()
	_dogs_populated = true

func _populate_dogs_grid() -> void:
	# Clear existing
	for child in _dogs_grid.get_children():
		child.queue_free()
	_entry_nodes.clear()

	# Delegate population to loader
	DogsTabLoader.populate(
		_dogs_grid,
		PLAYER_DATA_STORAGE,
		TILE_SIZE,
		func(entry_name: String, tex: Texture2D) -> void:
			_add_item_entry(entry_name, tex, _dogs_grid)
	)

func _ensure_default_owned_dog() -> void:
	var default_name := "dog-samoyed"
	if not PLAYER_DATA_STORAGE.owns_item(default_name):
		PLAYER_DATA_STORAGE.add_owned_item(default_name)

func _populate_tiles_grid() -> void:
	# Clear existing
	for child in _tiles_grid.get_children():
		child.queue_free()
	_entry_nodes.clear()

	# Delegate population to loader
	TilesTabLoader.populate(
		_tiles_grid,
		PLAYER_DATA_STORAGE,
		FLOOR_TILES_PATH,
		WALL_TILES_PATH,
		TILE_SIZE,
		WALL_TILE_HEIGHT,
		func(entry_name: String, tex: Texture2D) -> void:
			_add_item_entry(entry_name, tex, _tiles_grid)
	)


func _ensure_default_owned_tiles(kind: String, usable_tile_count: int) -> void:
	var defaults: int = int(min(3, usable_tile_count))
	for i in range(defaults):
		var owned_name := ("%s-tile-%%d" % kind) % i
		if not PLAYER_DATA_STORAGE.owns_item(owned_name):
			PLAYER_DATA_STORAGE.add_owned_item(owned_name)

func _atlas(sheet: Texture2D, region: Rect2) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = region
	return at

func _compose_bed_texture(sheet: Texture2D) -> Texture2D:
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

func _add_item_entry(item_name: String, texture: Texture2D, target_grid: GridContainer = null) -> void:
	if target_grid == null:
		target_grid = _items_grid
	# Visuals
	var base_display_height := 25
	var display_height: int = int(round(float(base_display_height) * PREVIEW_SCALE))
	var tex_size: Vector2
	if texture is AtlasTexture:
		tex_size = (texture as AtlasTexture).region.size
	else:
		tex_size = Vector2(texture.get_width(), texture.get_height())
	var scale_factor: float = float(display_height) / max(1.0, float(tex_size.y))
	var display_width: int = int(round(float(tex_size.x) * scale_factor))

	var item := VBoxContainer.new()
	item.alignment = BoxContainer.ALIGNMENT_CENTER
	item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Capture mouse on the container so clicks anywhere on the grid entry select it
	item.mouse_filter = Control.MOUSE_FILTER_STOP

	var preview := TextureRect.new()
	preview.texture = texture
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.ignore_texture_size = true
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.custom_minimum_size = Vector2(display_width, display_height)
	preview.size = Vector2(display_width, display_height)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Let the parent VBoxContainer receive the click anywhere on the item
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	# Use unified display-name formatter so we never show the "sprite" suffix
	label.text = _format_item_display_name(item_name)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", int(round(6.0 * PREVIEW_SCALE)))
	# Pass clicks to the parent so the whole item is clickable
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	item.add_child(preview)
	item.add_child(label)
	target_grid.add_child(item)

	# Interaction: select on click anywhere inside the item
	item.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_item(item_name, item)
	)

	_entry_nodes[item_name] = item

func _select_item(item_name: String, item_node: Control) -> void:
	_selected_item_name = item_name
	_selected_item_price = _get_item_price(item_name)
	_update_price_display(_selected_item_price)
	_update_item_name_display(item_name)
	# Highlight selected
	for k in _entry_nodes.keys():
		var n: Control = _entry_nodes[k]
		if is_instance_valid(n):
			n.self_modulate = Color(1, 1, 1, 1)
	if is_instance_valid(item_node):
		item_node.self_modulate = Color(1, 1, 0.8, 1)
	# Enable/disable buy button
	_price_button.disabled = PLAYER_DATA_STORAGE.get_coins_count() < _selected_item_price

func _update_price_display(price) -> void:
	if price == null or int(price) <= 0:
		_price_label.text = "--"
		_price_button.disabled = true
	else:
		_price_label.text = str(int(price))
		_price_button.disabled = false

func _on_price_container_pressed() -> void:
	if _selected_item_name == "" or _selected_item_price <= 0:
		return
	# Ensure not owned
	if PLAYER_DATA_STORAGE.owns_item(_selected_item_name):
		return
	# Try to spend coins
	var ok := PLAYER_DATA_STORAGE.spend_coins(_selected_item_price)
	if not ok:
		# Not enough coins
		return
	PLAYER_DATA_STORAGE.add_owned_item(_selected_item_name)
	# Remove from grid
	if _entry_nodes.has(_selected_item_name):
		var node: Control = _entry_nodes[_selected_item_name]
		if is_instance_valid(node):
			node.queue_free()
		_entry_nodes.erase(_selected_item_name)
	# Clear selection and UI
	_selected_item_name = ""
	_selected_item_price = 0
	_update_price_display(null)
	_update_item_name_display("")
	# Update coin HUD
	if is_instance_valid(_coins_display) and _coins_display.has_method("refresh"):
		_coins_display.refresh()

func _get_item_price(item_name: String) -> int:
	# Deterministic mapping within 8..15
	if item_name.begins_with("floor-tile-"):
		return 4
	if item_name.begins_with("wall-tile-"):
		return 6
	if item_name.begins_with("dog-"):
		return 6
	match item_name:
		"lamp-sprite":
			return 10
		"shelf-sprite":
			return 9
		"bed-sprite":
			return 15
		"window-sprite":
			return 8
		"bookshelf-sprite":
			return 12
		"painting-sprite":
			return 11
		_:
			return 8

func _set_all_sections_visible(visible_flag: bool) -> void:
	_items_scroll.visible = visible_flag
	_dogs_scroll.visible = visible_flag
	_tiles_scroll.visible = visible_flag

func _update_tab_button_states() -> void:
	# Light styling cue: dim inactive tabs
	var active: Color = Color(1, 1, 1, 1)
	var inactive: Color = Color(1, 1, 1, 0.5)
	_items_btn.modulate = active if _current_tab == Tab.ITEMS else inactive
	_dogs_btn.modulate = active if _current_tab == Tab.DOGS else inactive
	_tiles_btn.modulate = active if _current_tab == Tab.TILES else inactive

# --- Selection helpers ---
func _clear_selection() -> void:
	_selected_item_name = ""
	_selected_item_price = 0
	_update_price_display(null)
	_update_item_name_display("")
	# Reset any highlight
	for k in _entry_nodes.keys():
		var n: Control = _entry_nodes[k]
		if is_instance_valid(n):
			n.self_modulate = Color(1, 1, 1, 1)

func _update_item_name_display(item_name: String) -> void:
	if item_name == null or item_name == "":
		_price_item_name.text = ""
		return
	_price_item_name.text = "%s:" % _format_item_display_name(item_name)

func _format_item_display_name(raw_name: String) -> String:
	var s := raw_name
	# Strip common suffixes or words we don't want in the display
	s = s.replace("-sprite", "")
	s = s.replace(" sprite", "")
	# Normalize separators to spaces
	s = s.replace("_", " ").replace("-", " ")
	# Trim and capitalize for user-facing label
	s = s.strip_edges()
	return s.capitalize()
