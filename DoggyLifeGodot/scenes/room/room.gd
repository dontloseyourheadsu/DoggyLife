extends Node2D

@onready var pause_button := $Camera2D/PauseButton as Button
@onready var edit_button := $Camera2D/EditButton as Button
@onready var floor_items_grid: GridContainer = $Camera2D/DragsContainer/FloorItemsContainer/GridContainer
@onready var wall_items_grid: GridContainer = $Camera2D/DragsContainer/WallItemsContainer/GridContainer
@onready var floor_mouse_detector: TileMapLayer = $Camera2D/FloorMouseDetector
@onready var wall_layer: ModifiableTileMapLayer = $Camera2D/WallLayer
@onready var floor_layer: TileMapLayer = $Camera2D/FloorLayer
@onready var floor_hologram_layer: TileMapLayer = $Camera2D/FloorHologramLayer
@onready var floor_items_layer: TileMapLayer = $Camera2D/FloorItemsLayer
const AudioUtilsScript = preload("res://shared/scripts/audio_utils.gd")
const DELIMITER_ATLAS_COORDINATES := Vector2i(39, 0)
const HIDDEN_WALL_TILE_COORDINATE := Vector2i(-4, -3) # Not visible in the room, ignore for hover/tint

# FloorItems tileset source id (see room.tscn: TileSet_1mlw3 -> sources/1)
const FLOOR_ITEMS_SOURCE_ID := 1
# Mapping from item names to atlas coordinate variants in FloorItemsLayer.
# - Single-tile items map to Array[Vector2i] (each is a variant).
# - Bed maps to Array[Array[Vector2i]] where each entry is [left,right] variant.
const FLOOR_ITEM_ATLAS_VARIANTS: Dictionary = {
	"lamp-sprite": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	"shelf-sprite": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
	"bed-sprite": [
		[Vector2i(0, 2), Vector2i(1, 2)],
		[Vector2i(2, 2), Vector2i(3, 2)],
		[Vector2i(4, 2), Vector2i(5, 2)],
		[Vector2i(6, 2), Vector2i(7, 2)],
	]
}

# Tracks whether the current left mouse press started inside either drag/drop container
var _mouse_press_began_in_drag_area: bool = false

var selected_sprite_path: String = ""

@onready var selected_sprite: TextureRect = $Camera2D/SelectedSprite
var _selected_texture: Texture2D
var _last_hovered_tile: Vector2i = Vector2i(2147483647, 2147483647)
# For marking the hovered floor tile
var _marked_tile_overlay: Polygon2D = null
var _marked_tile_coords: Vector2i = Vector2i(2147483647, 2147483647)
var _marked_tile_overlay_secondary: Polygon2D = null
var _marked_tile_coords_secondary: Vector2i = Vector2i(2147483647, 2147483647)
var _dragging_floor_item: bool = false
var _debug_floor_tile_overlays: Array[Polygon2D] = []
var _marked_wall_tile_coords: Vector2i = Vector2i(2147483647, 2147483647)

func _ready():
	# Connect the pause button signal
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	# Apply saved audio settings on scene load
	AudioUtilsScript.load_and_apply()
	# Enable per-frame processing for drag and hover handling
	set_process(true)
	# Prepare the SelectedSprite so it doesn't block input and stays hidden until used
	if is_instance_valid(selected_sprite):
		selected_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_sprite.visible = false
		selected_sprite.stretch_mode = TextureRect.STRETCH_SCALE
		selected_sprite.ignore_texture_size = true
		selected_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Debug overlays disabled

func _on_pause_button_pressed() -> void:
	# Load settings scene
	var settings_scene = load("res://menus/settings/quick_settings.tscn").instantiate()
	get_tree().root.add_child(settings_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = settings_scene

func _on_edit_button_pressed() -> void:
	# Load edit scene
	var edit_scene = load("res://scenes/room/popups/edit_popup.tscn").instantiate()
	get_tree().root.add_child(edit_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = edit_scene

func _on_drag_preview_gui_input(event: InputEvent, tile_name: String, texture: Texture2D, is_floor: bool) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not event.is_echo():
			# Begin drag directly from provided texture
			_mouse_press_began_in_drag_area = true
			_dragging_floor_item = is_floor
			_selected_texture = texture
			if is_instance_valid(selected_sprite):
				selected_sprite.texture = _selected_texture
				selected_sprite.visible = true
				selected_sprite.self_modulate.a = 0.6
				# Position with offsets:
				# - Horizontal: 50% width for floor, 85% width for wall
				# - Vertical:   25% height for floor, 85% height for wall
				var display_width := selected_sprite.size.x if selected_sprite.size.x > 0.0 else float(_selected_texture.get_width())
				var display_height := selected_sprite.size.y if selected_sprite.size.y > 0.0 else float(_selected_texture.get_height())
				var offset_x := display_width * (0.5 if is_floor else 0.85)
				var offset_y := display_height * (0.25 if is_floor else 0.85)
				selected_sprite.position = get_global_mouse_position() - Vector2(offset_x, offset_y)
			selected_sprite_path = tile_name
		elif not event.pressed:
			# Release ends tracking and clears selection
			_mouse_press_began_in_drag_area = false
			_dragging_floor_item = false
			_clear_selected_sprite()
			_remove_marked_tile_overlay()
			_clear_marked_wall_tile()

func _clear_selected_sprite() -> void:
	if is_instance_valid(selected_sprite):
		selected_sprite.texture = null
		selected_sprite.visible = false
	_selected_texture = null

func _process(_delta: float) -> void:
	# Track and print the hovered tile under the mouse on the FloorMouseDetector layer
	if is_instance_valid(floor_mouse_detector):
		var local_pos := floor_mouse_detector.to_local(get_global_mouse_position())
		var tile_coords: Vector2i = floor_mouse_detector.local_to_map(local_pos)
		if tile_coords != _last_hovered_tile:
			_last_hovered_tile = tile_coords

	# Mark hovered floor tile(s) with green overlay if dragging a floor item
	var dragging_floor := _mouse_press_began_in_drag_area and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _dragging_floor_item
	if dragging_floor and is_instance_valid(floor_mouse_detector) and is_instance_valid(floor_layer) and is_instance_valid(floor_hologram_layer):
		var local_pos := floor_mouse_detector.to_local(get_global_mouse_position())
		var tile_coords: Vector2i = floor_mouse_detector.local_to_map(local_pos)
		# Check if tile_coords is a used cell in FloorLayer and not a delimiter
		var used_cells: Array[Vector2i] = floor_layer.get_used_cells()
		var primary_ok := tile_coords in used_cells and floor_layer.get_cell_atlas_coords(tile_coords) != DELIMITER_ATLAS_COORDINATES
		if primary_ok:
			# Special handling for bed: needs two adjacent floor tiles (to the +X direction)
			if selected_sprite_path == "bed-sprite":
				var second := tile_coords + Vector2i(1, 0)
				var second_ok := second in used_cells and floor_layer.get_cell_atlas_coords(second) != DELIMITER_ATLAS_COORDINATES
				if second_ok:
					# Update overlays if tiles changed
					if _marked_tile_coords != tile_coords or _marked_tile_coords_secondary != second:
						_remove_marked_tile_overlay()
						_add_marked_tile_overlay(tile_coords)
						_add_secondary_marked_tile_overlay(second)
				else:
					_remove_marked_tile_overlay()
			else:
				# Single-tile item
				if _marked_tile_coords != tile_coords:
					_remove_marked_tile_overlay()
					_add_marked_tile_overlay(tile_coords)
		else:
			_remove_marked_tile_overlay()
	else:
		_remove_marked_tile_overlay()

	# Mark hovered wall tile with green tint if dragging a wall item
	var dragging_wall := _mouse_press_began_in_drag_area and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _dragging_floor_item
	if dragging_wall and is_instance_valid(wall_layer):
		var wall_local := wall_layer.to_local(get_global_mouse_position())
		var wall_coords: Vector2i = wall_layer.local_to_map(wall_local)
		var wall_used: Array[Vector2i] = wall_layer.get_used_cells()
		if wall_coords in wall_used and wall_coords != HIDDEN_WALL_TILE_COORDINATE:
			if _marked_wall_tile_coords != wall_coords:
				_clear_marked_wall_tile()
				_mark_wall_tile(wall_coords)
		else:
			_clear_marked_wall_tile()
	else:
		_clear_marked_wall_tile()

	# While the left button remains pressed and the press began in the drag area,
	# continuously print the mouse position.
	if _mouse_press_began_in_drag_area:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			# Follow mouse with the selected sprite while pressed; keep last offset behavior
			if is_instance_valid(selected_sprite) and selected_sprite.visible:
				# Infer floor vs wall by selected_sprite_path if available; default to floor offset
				var is_floor := _dragging_floor_item
				var display_width := selected_sprite.size.x if selected_sprite.size.x > 0.0 else float(selected_sprite.texture.get_width())
				var display_height := selected_sprite.size.y if selected_sprite.size.y > 0.0 else float(selected_sprite.texture.get_height())
				var offset_x := display_width * (0.5 if is_floor else 0.85)
				var offset_y := display_height * (0.25 if is_floor else 0.85)
				selected_sprite.position = get_global_mouse_position() - Vector2(offset_x, offset_y)

		else:
			# If the button is no longer pressed, stop tracking and cleanup (placement handled in _input)
			_mouse_press_began_in_drag_area = false
			_dragging_floor_item = false
			_clear_selected_sprite()
			_remove_marked_tile_overlay()
			_clear_marked_wall_tile()

func _input(event: InputEvent) -> void:
	# Place item exactly when the left mouse button is released anywhere
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not event.is_echo():
		if _mouse_press_began_in_drag_area and _dragging_floor_item and is_instance_valid(floor_mouse_detector):
			var local_pos := floor_mouse_detector.to_local(get_global_mouse_position())
			var tile_coords: Vector2i = floor_mouse_detector.local_to_map(local_pos)
			_try_place_floor_item_at(tile_coords)
			# Cleanup state
			_mouse_press_began_in_drag_area = false
			_dragging_floor_item = false
			_clear_selected_sprite()
			_remove_marked_tile_overlay()
			_clear_marked_wall_tile()

## Helper to create a diamond overlay aligned with isometric floor and return it
func _create_tile_overlay(tile_coords: Vector2i, color: Color) -> Polygon2D:
	if not (is_instance_valid(floor_layer) and is_instance_valid(floor_hologram_layer)):
		return null
	var tile_size: Vector2i = floor_layer.tile_set.tile_size
	# map_to_local returns the center of the cell in local coordinates for isometric TileMaps
	var center_local_in_floor := floor_layer.map_to_local(tile_coords)
	var center_global := floor_layer.to_global(center_local_in_floor)
	var center_in_items := floor_hologram_layer.to_local(center_global)

	var poly := Polygon2D.new()
	var points: Array[Vector2] = [
		Vector2(-tile_size.x * 0.5, 0),
		Vector2(0, -tile_size.y * 0.5),
		Vector2(tile_size.x * 0.5, 0),
		Vector2(0, tile_size.y * 0.5)
	]
	poly.polygon = points
	poly.color = color
	poly.position = center_in_items
	poly.z_index = 100
	floor_hologram_layer.add_child(poly)
	return poly

## Helper to add green diamond overlay aligned with isometric floor
func _add_marked_tile_overlay(tile_coords: Vector2i) -> void:
	var poly := _create_tile_overlay(tile_coords, Color(0, 1, 0, 0.35))
	if poly == null:
		return
	_marked_tile_overlay = poly
	_marked_tile_coords = tile_coords

func _add_secondary_marked_tile_overlay(tile_coords: Vector2i) -> void:
	var poly := _create_tile_overlay(tile_coords, Color(0, 1, 0, 0.35))
	if poly == null:
		return
	_marked_tile_overlay_secondary = poly
	_marked_tile_coords_secondary = tile_coords

# Helper to remove overlay
func _remove_marked_tile_overlay() -> void:
	if _marked_tile_overlay and is_instance_valid(_marked_tile_overlay):
		_marked_tile_overlay.queue_free()
	_marked_tile_overlay = null
	_marked_tile_coords = Vector2i(2147483647, 2147483647)
	if _marked_tile_overlay_secondary and is_instance_valid(_marked_tile_overlay_secondary):
		_marked_tile_overlay_secondary.queue_free()
	_marked_tile_overlay_secondary = null
	_marked_tile_coords_secondary = Vector2i(2147483647, 2147483647)

## Wall highlighting helpers using runtime modulate
func _mark_wall_tile(coords: Vector2i) -> void:
	if is_instance_valid(wall_layer):
		wall_layer.set_tile_modulate(coords, Color(0, 1, 0, 0.55))
		_marked_wall_tile_coords = coords

func _clear_marked_wall_tile() -> void:
	if is_instance_valid(wall_layer) and _marked_wall_tile_coords.x != 2147483647:
		wall_layer.clear_tile_modulate(_marked_wall_tile_coords)
	_marked_wall_tile_coords = Vector2i(2147483647, 2147483647)

## DEBUG helpers: show/clear red holograms for all valid FloorLayer tiles
func _debug_show_all_floor_tiles() -> void:
	if not (is_instance_valid(floor_layer) and is_instance_valid(floor_hologram_layer)):
		return
	_debug_clear_all_floor_tiles()
	var used_cells: Array[Vector2i] = floor_layer.get_used_cells()
	for coords in used_cells:
		# Skip delimiters and empty cells
		if floor_layer.get_cell_source_id(coords) == -1:
			continue
		if floor_layer.get_cell_atlas_coords(coords) == DELIMITER_ATLAS_COORDINATES:
			continue
		var poly := _create_tile_overlay(coords, Color(1, 0, 0, 0.30))
		if poly != null:
			_debug_floor_tile_overlays.append(poly)

func _debug_clear_all_floor_tiles() -> void:
	for poly in _debug_floor_tile_overlays:
		if is_instance_valid(poly):
			poly.queue_free()
	_debug_floor_tile_overlays.clear()

## Placement helpers
func _try_place_floor_item_at(primary: Vector2i) -> void:
	if not (is_instance_valid(floor_layer) and is_instance_valid(floor_items_layer)):
		return
	# Validate primary tile is a real floor tile and not a delimiter
	var used_cells: Array[Vector2i] = floor_layer.get_used_cells()
	if not (primary in used_cells) or floor_layer.get_cell_atlas_coords(primary) == DELIMITER_ATLAS_COORDINATES:
		return

	# Determine item atlas mapping
	if not FLOOR_ITEM_ATLAS_VARIANTS.has(selected_sprite_path):
		return
	var variants = FLOOR_ITEM_ATLAS_VARIANTS[selected_sprite_path]
	if variants is Array and variants.size() == 0:
		return
	# Always use the first variant at release time
	var atlas_entry = variants[0]

	if atlas_entry is Array:
		# Multi-tile (bed) – requires the adjacent tile to the +X direction
		if atlas_entry.size() < 2:
			return
		var secondary := primary + Vector2i(1, 0)
		var secondary_ok := secondary in used_cells and floor_layer.get_cell_atlas_coords(secondary) != DELIMITER_ATLAS_COORDINATES
		if not secondary_ok:
			return
		# Ensure FloorItemsLayer target cells are empty (no overlap)
		if floor_items_layer.get_cell_source_id(primary) != -1:
			return
		if floor_items_layer.get_cell_source_id(secondary) != -1:
			return
		# Place both tiles
		print("Placing %s (left): source=%d atlas=%s" % [selected_sprite_path, FLOOR_ITEMS_SOURCE_ID, str(atlas_entry[0])])
		floor_items_layer.set_cell(primary, FLOOR_ITEMS_SOURCE_ID, atlas_entry[0])
		print("Placing %s (right): source=%d atlas=%s" % [selected_sprite_path, FLOOR_ITEMS_SOURCE_ID, str(atlas_entry[1])])
		floor_items_layer.set_cell(secondary, FLOOR_ITEMS_SOURCE_ID, atlas_entry[1])
	else:
		# Single tile item
		# Ensure FloorItemsLayer target cell is empty (no overlap)
		if floor_items_layer.get_cell_source_id(primary) != -1:
			return
		print("Placing %s: source=%d atlas=%s" % [selected_sprite_path, FLOOR_ITEMS_SOURCE_ID, str(atlas_entry)])
		floor_items_layer.set_cell(primary, FLOOR_ITEMS_SOURCE_ID, atlas_entry)

	# Optional: ensure the items layer updates immediately
	floor_items_layer.notify_runtime_tile_data_update()
