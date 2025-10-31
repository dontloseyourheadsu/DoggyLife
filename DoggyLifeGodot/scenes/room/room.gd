extends Node2D

@onready var pause_button := $Camera2D/OptionsContainer/PauseButton as BaseButton
@onready var edit_button := $Camera2D/OptionsContainer/EditButton as BaseButton
@onready var shop_button := $Camera2D/OptionsContainer/ShopButton as BaseButton
@onready var floor_items_grid: GridContainer = $Camera2D/DragsContainer/FloorItemsContainer/GridContainer
@onready var wall_items_grid: GridContainer = $Camera2D/DragsContainer/WallItemsContainer/GridContainer
@onready var floor_items_container: ScrollContainer = $Camera2D/DragsContainer/FloorItemsContainer
@onready var wall_items_container: ScrollContainer = $Camera2D/DragsContainer/WallItemsContainer
@onready var floor_controls: Control = $Camera2D/FloorItemsControls
@onready var btn_rotate_left: BaseButton = $Camera2D/FloorItemsControls/RotateLeftButton
@onready var btn_rotate_right: BaseButton = $Camera2D/FloorItemsControls/RotateRightButton
@onready var btn_cancel: BaseButton = $Camera2D/FloorItemsControls/CancelButton
@onready var btn_check: BaseButton = $Camera2D/FloorItemsControls/CheckButton
@onready var btn_delete: BaseButton = $Camera2D/FloorItemsControls/DeleteButton
@onready var floor_mouse_detector: TileMapLayer = $Camera2D/FloorMouseDetector
@onready var wall_layer: ModifiableTileMapLayer = $Camera2D/WallLayer
@onready var floor_layer: TileMapLayer = $Camera2D/FloorLayer
@onready var floor_hologram_layer: TileMapLayer = $Camera2D/FloorHologramLayer
@onready var floor_items_layer: TileMapLayer = $Camera2D/FloorItemsLayer
@onready var wall_items_layer: TileMapLayer = $Camera2D/WallItemsLayer
@onready var wall_controls: Control = $Camera2D/WallItemsControls
@onready var wall_btn_cancel: BaseButton = $Camera2D/WallItemsControls/CancelButton
@onready var wall_btn_check: BaseButton = $Camera2D/WallItemsControls/CheckButton
@onready var wall_btn_switch: BaseButton = $Camera2D/WallItemsControls/SwitchButton
@onready var wall_btn_delete: BaseButton = $Camera2D/WallItemsControls/DeleteButton
@onready var room_dog: Node = get_node("Camera2D/FloorLayer/White-dog")
const AudioUtilsScript = preload("res://shared/scripts/audio_utils.gd")
# Use global class_name TileSelectionStore (defined in tile_selection_store.gd)
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

# Wall items configuration
const WALL_ITEMS_SOURCE_ID := 0 # see room.tscn: TileSet_e4auk -> sources/0
# Atlas rows per item; column is 0 for left wall, 1 for right wall
const WALL_ITEM_ROWS := {
	"window-sprite": 0,
	"bookshelf-sprite": 1,
	"painting-sprite": 2,
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

# Destination marker for dog
var _dog_dest_overlay: Polygon2D = null
var _dog_dest_coords: Vector2i = Vector2i(2147483647, 2147483647)

# Tracking currently edited floor item (only after it has been placed)
var _editing_active: bool = false
var _editing_item_name: String = ""
var _editing_primary: Vector2i = Vector2i(2147483647, 2147483647)
var _editing_secondary: Vector2i = Vector2i(2147483647, 2147483647) # Used only for multi-tile
var _editing_rotation: int = 0 # 0..3
var _editing_is_dragging: bool = false # dragging the placed item to a new tile
var _editing_drag_texture: Texture2D = null # texture used for dragging preview
# Track original position/rotation and whether this is first-time placement session
var _editing_is_newly_placed: bool = false
var _editing_original_primary: Vector2i = Vector2i(2147483647, 2147483647)
var _editing_original_secondary: Vector2i = Vector2i(2147483647, 2147483647)
var _editing_original_rotation: int = 0

# Rotation used while preview-dragging before first placement
var _preview_rotation: int = 0
const _SENTINEL := Vector2i(2147483647, 2147483647)

# Wall item editing state
var _wall_editing_active: bool = false
var _wall_editing_item_name: String = ""
var _wall_editing_coords: Vector2i = Vector2i(2147483647, 2147483647)
var _wall_editing_side: String = "" # "left" | "right"
var _wall_editing_is_newly_placed: bool = false
var _wall_original_coords: Vector2i = Vector2i(2147483647, 2147483647)
var _wall_original_side: String = ""

# Tracks which items were confirmed with the Check button (single-place items)
var _placed_items: Dictionary = {}

func _ready():
	# Connect the pause button signal
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	# Connect floor controls
	if is_instance_valid(btn_rotate_left):
		btn_rotate_left.pressed.connect(_on_rotate_left_pressed)
	if is_instance_valid(btn_rotate_right):
		btn_rotate_right.pressed.connect(_on_rotate_right_pressed)
	if is_instance_valid(btn_cancel):
		btn_cancel.pressed.connect(_on_cancel_pressed)
	if is_instance_valid(btn_check):
		btn_check.pressed.connect(_on_check_pressed)
	if is_instance_valid(btn_delete):
		btn_delete.pressed.connect(_on_delete_pressed)
	# Connect the shop button signal
	if shop_button:
		shop_button.pressed.connect(_on_shop_button_pressed)
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

	# Hide floor controls at start
	if is_instance_valid(floor_controls):
		floor_controls.visible = false

	# Hide wall controls at start and wire wall buttons
	if is_instance_valid(wall_controls):
		wall_controls.visible = false
	if is_instance_valid(wall_btn_cancel):
		wall_btn_cancel.pressed.connect(_on_wall_cancel_pressed)
	if is_instance_valid(wall_btn_check):
		wall_btn_check.pressed.connect(_on_wall_check_pressed)
	if is_instance_valid(wall_btn_switch):
		wall_btn_switch.pressed.connect(_on_wall_switch_pressed)
	if is_instance_valid(wall_btn_delete):
		wall_btn_delete.pressed.connect(_on_wall_delete_pressed)

	# Restore any previously placed items from persistent store
	_restore_persisted_items()

	# Connect dog go-to signals to clear destination marker
	if is_instance_valid(room_dog):
		if room_dog.has_signal("go_to_arrived"):
			room_dog.connect("go_to_arrived", Callable(self, "_on_dog_go_to_end"))
		if room_dog.has_signal("go_to_canceled"):
			room_dog.connect("go_to_canceled", Callable(self, "_on_dog_go_to_end"))

func _on_pause_button_pressed() -> void:
	# Load settings scene
	var settings_scene = load("res://scenes/menus/settings/quick_settings.tscn").instantiate()
	get_tree().root.add_child(settings_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = settings_scene

func _on_edit_button_pressed() -> void:
	# Load edit scene
	var edit_scene = load("res://scenes/room/popups/edit_popup.tscn").instantiate()
	get_tree().root.add_child(edit_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = edit_scene

func _on_shop_button_pressed() -> void:
	# Load shop scene
	var shop_scene = load("res://scenes/menus/shop/shop.tscn").instantiate()
	get_tree().root.add_child(shop_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = shop_scene

func _on_drag_preview_gui_input(event: InputEvent, tile_name: String, texture: Texture2D, is_floor: bool) -> void:
	# Block interactions with drag containers while editing an item
	if _editing_active or _wall_editing_active:
		return
	# Prevent starting a drag if this item was already placed/confirmed
	if is_item_placed(tile_name):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not event.is_echo():
			# Begin drag directly from provided texture
			_mouse_press_began_in_drag_area = true
			_dragging_floor_item = is_floor
			_selected_texture = texture
			_preview_rotation = 0
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
			# Special handling for bed: needs two adjacent floor tiles; direction depends on rotation
			var dragging_item := _editing_item_name if _editing_is_dragging or _editing_active else selected_sprite_path
			if dragging_item == "bed-sprite":
				var rot := _editing_rotation if _editing_active else _preview_rotation
				var offset := _bed_secondary_offset(rot)
				var second := tile_coords + offset
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
	# keep the selected sprite following the mouse.
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
			# If the button is no longer pressed, stop temporary sprite (placement handled in _input)
			_mouse_press_began_in_drag_area = false
			_dragging_floor_item = false
			_clear_selected_sprite()
			_remove_marked_tile_overlay()
			_clear_marked_wall_tile()

func _input(event: InputEvent) -> void:
	# Start re-dragging if clicking on the tracked item (press)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		# If no edit in progress, allow selecting already placed floor item by clicking it
		if not _editing_active and not _wall_editing_active:
			# Check floor items first
			if is_instance_valid(floor_items_layer):
				var local_in_items := floor_items_layer.to_local(get_global_mouse_position())
				var coords := floor_items_layer.local_to_map(local_in_items)
				if floor_items_layer.get_cell_source_id(coords) != -1:
					var atlas: Vector2i = floor_items_layer.get_cell_atlas_coords(coords)
					var found := false
					# Single-tile items
					for item_key in ["lamp-sprite", "shelf-sprite"]:
						var variants: Array = FLOOR_ITEM_ATLAS_VARIANTS[item_key]
						for i in range(variants.size()):
							if variants[i] == atlas:
								_start_tracking_item(item_key, coords, i, null, false)
								found = true
								break
						if found:
							return
					# Bed (two tiles)
					var bed_variants: Array = FLOOR_ITEM_ATLAS_VARIANTS["bed-sprite"]
					for rot in range(bed_variants.size()):
						var pair: Array = bed_variants[rot]
						if pair.size() >= 2 and (pair[0] == atlas or pair[1] == atlas):
							var primary := coords
							var off := _bed_secondary_offset(rot)
							if rot % 2 == 0:
								# Horizontal: primary uses pair[0]
								if atlas == pair[1]:
									primary = coords - off
							else:
								# Vertical: primary uses pair[1]
								if atlas == pair[0]:
									primary = coords - off
							_start_tracking_item("bed-sprite", primary, rot, null, false)
							return
			# If not a floor item, check wall items layer
			if is_instance_valid(wall_items_layer):
				var local_in_wall := wall_items_layer.to_local(get_global_mouse_position())
				var wcoords := wall_items_layer.local_to_map(local_in_wall)
				if wall_items_layer.get_cell_source_id(wcoords) != -1:
					var watlas: Vector2i = wall_items_layer.get_cell_atlas_coords(wcoords)
					var item_name := ""
					for k in WALL_ITEM_ROWS.keys():
						if WALL_ITEM_ROWS[k] == watlas.y:
							item_name = k
							break
					if item_name != "":
						_start_tracking_wall_item(item_name, wcoords, false)
						return
		if _editing_active and not _editing_is_dragging:
			var local_in_items := floor_items_layer.to_local(get_global_mouse_position())
			var coords := floor_items_layer.local_to_map(local_in_items)
			if coords == _editing_primary or (_editing_secondary != _SENTINEL and coords == _editing_secondary):
				# Remove from map while dragging
				if is_instance_valid(floor_items_layer):
					floor_items_layer.erase_cell(_editing_primary)
					if _editing_secondary != _SENTINEL:
						floor_items_layer.erase_cell(_editing_secondary)
					floor_items_layer.notify_runtime_tile_data_update()
				# Begin drag from tracked item
				_mouse_press_began_in_drag_area = true
				_dragging_floor_item = true
				_editing_is_dragging = true
				# Build preview texture for current rotation
				_editing_drag_texture = _make_preview_texture(_editing_item_name, _editing_rotation)
				if is_instance_valid(selected_sprite):
					selected_sprite.texture = _editing_drag_texture
					selected_sprite.visible = true
					selected_sprite.self_modulate.a = 0.6
					var w := selected_sprite.size.x if selected_sprite.size.x > 0.0 else float(_editing_drag_texture.get_width())
					var h := selected_sprite.size.y if selected_sprite.size.y > 0.0 else float(_editing_drag_texture.get_height())
					selected_sprite.position = get_global_mouse_position() - Vector2(w * 0.5, h * 0.25)

		# Start re-dragging a tracked wall item if clicked
		if _wall_editing_active:
			var local_in_wall := wall_items_layer.to_local(get_global_mouse_position())
			var wcoords := wall_items_layer.local_to_map(local_in_wall)
			if wcoords == _wall_editing_coords:
				if is_instance_valid(wall_items_layer):
					wall_items_layer.erase_cell(_wall_editing_coords)
					wall_items_layer.notify_runtime_tile_data_update()
				_mouse_press_began_in_drag_area = true
				_dragging_floor_item = false
				var preview := _make_wall_preview_texture(_wall_editing_item_name, _wall_editing_side)
				if is_instance_valid(selected_sprite) and preview != null:
					selected_sprite.texture = preview
					selected_sprite.visible = true
					selected_sprite.self_modulate.a = 0.6
					var w2 := selected_sprite.size.x if selected_sprite.size.x > 0.0 else float(preview.get_width())
					var h2 := selected_sprite.size.y if selected_sprite.size.y > 0.0 else float(preview.get_height())
					selected_sprite.position = get_global_mouse_position() - Vector2(w2 * 0.85, h2 * 0.85)

		# If not dragging or editing anything, interpret click as a dog move command
		if not _mouse_press_began_in_drag_area and not _editing_active and not _wall_editing_active:
			_command_dog_to_mouse(event.position)

	# Place item exactly when the left mouse button is released anywhere
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not event.is_echo():
		if _mouse_press_began_in_drag_area and _dragging_floor_item and is_instance_valid(floor_mouse_detector):
			var local_pos := floor_mouse_detector.to_local(get_global_mouse_position())
			var tile_coords: Vector2i = floor_mouse_detector.local_to_map(local_pos)
			if _editing_is_dragging and _editing_active:
				if _place_item_with_rotation_at(_editing_item_name, tile_coords, _editing_rotation):
					_editing_primary = tile_coords
					_editing_secondary = _compute_secondary_if_any(_editing_item_name, tile_coords, _editing_rotation)
				else:
					# Failed to place – restore at previous position
					_place_item_with_rotation_at(_editing_item_name, _editing_primary, _editing_rotation)
			else:
				# First-time placement from drag containers (use preview rotation)
				if _place_item_with_rotation_at(selected_sprite_path, tile_coords, _preview_rotation):
					# Begin tracking for floor items only
					if selected_sprite_path in ["lamp-sprite", "shelf-sprite", "bed-sprite"]:
						_start_tracking_item(selected_sprite_path, tile_coords, _preview_rotation, _selected_texture, true)
					else:
						_stop_tracking_and_hide_controls()
		elif _mouse_press_began_in_drag_area and not _dragging_floor_item and is_instance_valid(wall_layer):
			var wall_local := wall_layer.to_local(get_global_mouse_position())
			var wall_coords: Vector2i = wall_layer.local_to_map(wall_local)
			if _wall_editing_active:
				if _place_wall_item_at(_wall_editing_item_name, wall_coords):
					_wall_editing_coords = wall_coords
					_wall_editing_side = _detect_wall_side_from_coords(wall_coords)
				else:
					_place_wall_item_at(_wall_editing_item_name, _wall_editing_coords)
			else:
				if _place_wall_item_at(selected_sprite_path, wall_coords):
					_start_tracking_wall_item(selected_sprite_path, wall_coords, true)
				else:
					_stop_tracking_wall_and_hide_controls()
			# Cleanup temporary drag state
			_mouse_press_began_in_drag_area = false
			_dragging_floor_item = false
			_editing_is_dragging = false
			_clear_selected_sprite()
			_remove_marked_tile_overlay()
			_clear_marked_wall_tile()

## Command dog helpers
func _command_dog_to_mouse(_screen_pos: Vector2) -> void:
	if not (is_instance_valid(floor_layer) and is_instance_valid(room_dog)):
		return
	# Convert global mouse -> floor local -> tile coords
	var local_in_floor := floor_layer.to_local(get_global_mouse_position())
	var coords: Vector2i = floor_layer.local_to_map(local_in_floor)

	# Validate coords: must be used and not a delimiter
	var used: Array[Vector2i] = floor_layer.get_used_cells()
	var is_valid := (coords in used) and floor_layer.get_cell_atlas_coords(coords) != DELIMITER_ATLAS_COORDINATES
	if not is_valid:
		var nearest := _find_closest_valid_floor_tile(coords)
		if nearest.x == 2147483647:
			return
		coords = nearest

	# Compute tile center in global space
	var center_local := floor_layer.map_to_local(coords)
	var target_global := floor_layer.to_global(center_local)

	# Ask the dog to go there if it exposes the method
	if room_dog and room_dog.has_method("go_to_global_position"):
		# Mark destination on the floor overlay layer
		_set_dog_destination_marker(coords)
		room_dog.go_to_global_position(target_global)

func _set_dog_destination_marker(tile_coords: Vector2i) -> void:
	_clear_dog_destination_marker()
	var poly := _create_tile_overlay(tile_coords, Color(0.2, 0.6, 1.0, 0.45))
	if poly == null:
		return
	_dog_dest_overlay = poly
	_dog_dest_coords = tile_coords
	_dog_dest_overlay.z_index = 200

func _clear_dog_destination_marker() -> void:
	if _dog_dest_overlay and is_instance_valid(_dog_dest_overlay):
		_dog_dest_overlay.queue_free()
	_dog_dest_overlay = null
	_dog_dest_coords = Vector2i(2147483647, 2147483647)

func _on_dog_go_to_end(_pos: Vector2) -> void:
	_clear_dog_destination_marker()

func _find_closest_valid_floor_tile(target: Vector2i) -> Vector2i:
	if not is_instance_valid(floor_layer):
		return _SENTINEL
	var used: Array[Vector2i] = floor_layer.get_used_cells()
	var best := _SENTINEL
	var best_d2 := INF
	for c in used:
		if floor_layer.get_cell_source_id(c) == -1:
			continue
		if floor_layer.get_cell_atlas_coords(c) == DELIMITER_ATLAS_COORDINATES:
			continue
		var d2 := float((c.x - target.x) * (c.x - target.x) + (c.y - target.y) * (c.y - target.y))
		if d2 < best_d2:
			best_d2 = d2
			best = c
	return best

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
	# Deprecated by _place_item_with_rotation_at; kept for compatibility if referenced elsewhere
	_place_item_with_rotation_at(selected_sprite_path, primary, 0)

func _place_item_with_rotation_at(item_name: String, primary: Vector2i, rotation_idx: int) -> bool:
	if not (is_instance_valid(floor_layer) and is_instance_valid(floor_items_layer)):
		return false
	# Validate primary tile is a real floor tile and not a delimiter
	var used_cells: Array[Vector2i] = floor_layer.get_used_cells()
	if not (primary in used_cells) or floor_layer.get_cell_atlas_coords(primary) == DELIMITER_ATLAS_COORDINATES:
		return false

	if not FLOOR_ITEM_ATLAS_VARIANTS.has(item_name):
		return false
	var variants = FLOOR_ITEM_ATLAS_VARIANTS[item_name]
	if variants is Array and variants.size() == 0:
		return false

	var atlas_entry = _get_atlas_for_item(item_name, rotation_idx)
	if typeof(atlas_entry) == TYPE_NIL:
		return false

	if atlas_entry is Array:
		# Multi-tile (e.g., bed)
		if atlas_entry.size() < 2:
			return false
		var secondary := primary + _bed_secondary_offset(rotation_idx)
		var secondary_ok := secondary in used_cells and floor_layer.get_cell_atlas_coords(secondary) != DELIMITER_ATLAS_COORDINATES
		if not secondary_ok:
			return false
		# Ensure target cells are empty (no overlap)
		if floor_items_layer.get_cell_source_id(primary) != -1:
			return false
		if floor_items_layer.get_cell_source_id(secondary) != -1:
			return false
		_set_bed_cells(primary, rotation_idx, atlas_entry)
	else:
		# Single tile
		if floor_items_layer.get_cell_source_id(primary) != -1:
			return false
		floor_items_layer.set_cell(primary, FLOOR_ITEMS_SOURCE_ID, atlas_entry)

	floor_items_layer.notify_runtime_tile_data_update()
	return true

func _compute_secondary_if_any(item_name: String, primary: Vector2i, rotation_idx: int) -> Vector2i:
	if item_name == "bed-sprite":
		return primary + _bed_secondary_offset(rotation_idx)
	return _SENTINEL

func _start_tracking_item(item_name: String, primary: Vector2i, rotation_idx: int, drag_texture: Texture2D, is_newly_placed: bool) -> void:
	_editing_active = true
	_editing_item_name = item_name
	_editing_primary = primary
	_editing_rotation = rotation_idx
	_editing_secondary = _compute_secondary_if_any(item_name, primary, rotation_idx)
	_editing_drag_texture = drag_texture
	_editing_is_newly_placed = is_newly_placed
	# capture originals
	_editing_original_primary = primary
	_editing_original_secondary = _editing_secondary
	_editing_original_rotation = rotation_idx
	_show_floor_controls(true)
	_set_drag_containers_interactive(false)

func _stop_tracking_and_hide_controls() -> void:
	_editing_active = false
	_editing_item_name = ""
	_editing_primary = _SENTINEL
	_editing_secondary = _SENTINEL
	_editing_rotation = 0
	_editing_is_dragging = false
	_editing_drag_texture = null
	_editing_is_newly_placed = false
	_editing_original_primary = _SENTINEL
	_editing_original_secondary = _SENTINEL
	_editing_original_rotation = 0
	_show_floor_controls(false)
	_set_drag_containers_interactive(true)

func _show_floor_controls(p_visible: bool) -> void:
	if is_instance_valid(floor_controls):
		floor_controls.visible = p_visible

func _set_drag_containers_interactive(enabled: bool) -> void:
	var mode := Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(floor_items_container):
		floor_items_container.mouse_filter = mode
	if is_instance_valid(wall_items_container):
		wall_items_container.mouse_filter = mode
	if is_instance_valid(floor_items_grid):
		floor_items_grid.mouse_filter = mode
	if is_instance_valid(wall_items_grid):
		wall_items_grid.mouse_filter = mode

func _get_atlas_for_item(item_name: String, rotation_idx: int):
	var variants: Array = FLOOR_ITEM_ATLAS_VARIANTS[item_name]
	if item_name == "bed-sprite":
		# Return [left,right] atlas coords per rotation
		var i: int = clamp(rotation_idx % 4, 0, 3)
		return variants[i]
	else:
		var i: int = clamp(rotation_idx % 4, 0, 3)
		return variants[i]

func _bed_secondary_offset(rotation_idx: int) -> Vector2i:
	# Even rotations (0,2): +X; Odd rotations (1,3): +Y
	return Vector2i(1, 0) if (rotation_idx % 2 == 0) else Vector2i(0, 1)

func _set_bed_cells(primary: Vector2i, rotation_idx: int, atlas_pair: Array) -> void:
	var secondary := primary + _bed_secondary_offset(rotation_idx)
	if rotation_idx % 2 == 0:
		# Horizontal (+X): use [left,right]
		floor_items_layer.set_cell(primary, FLOOR_ITEMS_SOURCE_ID, atlas_pair[0])
		floor_items_layer.set_cell(secondary, FLOOR_ITEMS_SOURCE_ID, atlas_pair[1])
	else:
		# Vertical (+Y): swap so visuals align with intended orientation
		floor_items_layer.set_cell(primary, FLOOR_ITEMS_SOURCE_ID, atlas_pair[1])
		floor_items_layer.set_cell(secondary, FLOOR_ITEMS_SOURCE_ID, atlas_pair[0])

func _rotate_current(delta: int) -> void:
	# If dragging a fresh item from the UI, rotate preview
	if _mouse_press_began_in_drag_area and _dragging_floor_item and not _editing_active:
		_preview_rotation = (_preview_rotation + delta) % 4
		if is_instance_valid(selected_sprite) and selected_sprite_path != "":
			var tex := _make_preview_texture(selected_sprite_path, _preview_rotation)
			if tex != null:
				selected_sprite.texture = tex
		return

	if not _editing_active:
		return

	# If currently re-dragging an edited item, rotate the preview and update final rotation for placement
	if _editing_is_dragging:
		_editing_rotation = (_editing_rotation + delta) % 4
		if is_instance_valid(selected_sprite) and _editing_item_name != "":
			var tex2 := _make_preview_texture(_editing_item_name, _editing_rotation)
			if tex2 != null:
				selected_sprite.texture = tex2
		return

	# Rotating an item that is currently placed (not dragging): update tiles in place
	var new_rot := (_editing_rotation + delta) % 4
	# Validate space for new rotation
	var used_cells: Array[Vector2i] = floor_layer.get_used_cells()
	var new_secondary := _compute_secondary_if_any(_editing_item_name, _editing_primary, new_rot)
	if _editing_item_name == "bed-sprite":
		# New secondary must be valid floor and either empty or the current secondary
		if not (new_secondary in used_cells and floor_layer.get_cell_atlas_coords(new_secondary) != DELIMITER_ATLAS_COORDINATES):
			return
		var occ := floor_items_layer.get_cell_source_id(new_secondary)
		if occ != -1 and new_secondary != _editing_secondary:
			return
		# Apply new rotation: clear old secondary if different
		if _editing_secondary != _SENTINEL and new_secondary != _editing_secondary:
			floor_items_layer.erase_cell(_editing_secondary)
		var atlas_pair = _get_atlas_for_item(_editing_item_name, new_rot)
		_set_bed_cells(_editing_primary, new_rot, atlas_pair)
		floor_items_layer.notify_runtime_tile_data_update()
		_editing_rotation = new_rot
		_editing_secondary = new_secondary
	else:
		# Single tile: always valid, just update atlas
		var atlas = _get_atlas_for_item(_editing_item_name, new_rot)
		floor_items_layer.set_cell(_editing_primary, FLOOR_ITEMS_SOURCE_ID, atlas)
		floor_items_layer.notify_runtime_tile_data_update()
		_editing_rotation = new_rot

func _on_rotate_left_pressed() -> void:
	_rotate_current(-1)

func _on_rotate_right_pressed() -> void:
	_rotate_current(1)

func _on_cancel_pressed() -> void:
	if not _editing_active:
		return
	if is_instance_valid(floor_items_layer):
		# Revert if editing existing, erase if first-time placement
		# Clear current cells first
		floor_items_layer.erase_cell(_editing_primary)
		if _editing_secondary != _SENTINEL:
			floor_items_layer.erase_cell(_editing_secondary)
		if _editing_is_newly_placed:
			# Do not restore
			pass
		else:
			# Restore original state
			if _editing_item_name == "bed-sprite":
				var pair = _get_atlas_for_item(_editing_item_name, _editing_original_rotation)
				_set_bed_cells(_editing_original_primary, _editing_original_rotation, pair)
			else:
				var atlas = _get_atlas_for_item(_editing_item_name, _editing_original_rotation)
				floor_items_layer.set_cell(_editing_original_primary, FLOOR_ITEMS_SOURCE_ID, atlas)
		floor_items_layer.notify_runtime_tile_data_update()
	_stop_tracking_and_hide_controls()
	_clear_selected_sprite()
	_remove_marked_tile_overlay()
	_clear_marked_wall_tile()

func _on_delete_pressed() -> void:
	if not _editing_active:
		return
	if is_instance_valid(floor_items_layer):
		floor_items_layer.erase_cell(_editing_primary)
		if _editing_secondary != _SENTINEL:
			floor_items_layer.erase_cell(_editing_secondary)
		floor_items_layer.notify_runtime_tile_data_update()
	# Allow reusing this item again in the grid
	if _editing_item_name != "":
		_placed_items.erase(_editing_item_name)
		_update_drag_ui_used_state(_editing_item_name, false)
		# Remove from persistence
		TileSelectionStore.remove_placed_floor_item(_editing_item_name)
	_stop_tracking_and_hide_controls()
	_clear_selected_sprite()
	_remove_marked_tile_overlay()
	_clear_marked_wall_tile()

func _on_check_pressed() -> void:
	if not _editing_active:
		return
	# Capture item before clearing state
	var item_to_mark := _editing_item_name
	var persist_primary := _editing_primary
	var persist_rotation := _editing_rotation
	# Keep item, just stop tracking
	_stop_tracking_and_hide_controls()
	_clear_selected_sprite()
	_remove_marked_tile_overlay()
	_clear_marked_wall_tile()
	# Mark this item as placed/confirmed and dim in drag UI
	if item_to_mark != "":
		_placed_items[item_to_mark] = true
		_update_drag_ui_used_state(item_to_mark, true)
		# Persist floor item placement
		TileSelectionStore.set_placed_floor_item(item_to_mark, persist_primary, persist_rotation)

# ====================== WALL ITEMS ======================
func _detect_wall_side_from_coords(coords: Vector2i) -> String:
	if coords.x == -4:
		return "left"
	if coords.y == -3:
		return "right"
	return ""

func _get_last_tile_for_wall(side: String) -> Vector2i:
	if not is_instance_valid(wall_layer):
		return _SENTINEL
	var used: Array[Vector2i] = wall_layer.get_used_cells()
	var best := _SENTINEL
	if side == "left":
		var max_y := -2147483648
		for c in used:
			if c == HIDDEN_WALL_TILE_COORDINATE:
				continue
			if c.x == -4 and c.y > max_y:
				max_y = c.y
				best = c
	elif side == "right":
		var max_x := -2147483648
		for c in used:
			if c == HIDDEN_WALL_TILE_COORDINATE:
				continue
			if c.y == -3 and c.x > max_x:
				max_x = c.x
				best = c
	return best

func _get_wall_atlas_for(item_name: String, side: String) -> Vector2i:
	if not WALL_ITEM_ROWS.has(item_name):
		return Vector2i(-1, -1)
	var row: int = WALL_ITEM_ROWS[item_name]
	var col: int = (0 if side == "left" else 1)
	return Vector2i(col, row)

func _is_valid_wall_coord(coords: Vector2i) -> bool:
	if not is_instance_valid(wall_layer):
		return false
	if coords == HIDDEN_WALL_TILE_COORDINATE:
		return false
	var used: Array[Vector2i] = wall_layer.get_used_cells()
	if not (coords in used):
		return false
	if not (coords.x == -4 or coords.y == -3):
		return false
	return true

func _place_wall_item_at(item_name: String, coords: Vector2i) -> bool:
	if not (is_instance_valid(wall_items_layer) and _is_valid_wall_coord(coords)):
		return false
	if not WALL_ITEM_ROWS.has(item_name):
		return false
	if wall_items_layer.get_cell_source_id(coords) != -1:
		return false
	var side := _detect_wall_side_from_coords(coords)
	var atlas := _get_wall_atlas_for(item_name, side)
	if atlas.x < 0:
		return false
	wall_items_layer.set_cell(coords, WALL_ITEMS_SOURCE_ID, atlas)
	wall_items_layer.notify_runtime_tile_data_update()
	return true

func _start_tracking_wall_item(item_name: String, coords: Vector2i, is_newly_placed: bool) -> void:
	_wall_editing_active = true
	_wall_editing_item_name = item_name
	_wall_editing_coords = coords
	_wall_editing_side = _detect_wall_side_from_coords(coords)
	_wall_editing_is_newly_placed = is_newly_placed
	_wall_original_coords = coords
	_wall_original_side = _wall_editing_side
	_show_wall_controls(true)
	_show_floor_controls(false)
	_set_drag_containers_interactive(false)

func _stop_tracking_wall_and_hide_controls() -> void:
	_wall_editing_active = false
	_wall_editing_item_name = ""
	_wall_editing_coords = _SENTINEL
	_wall_editing_side = ""
	_wall_editing_is_newly_placed = false
	_wall_original_coords = _SENTINEL
	_wall_original_side = ""
	_show_wall_controls(false)
	_set_drag_containers_interactive(true)

func _show_wall_controls(p_visible: bool) -> void:
	if is_instance_valid(wall_controls):
		wall_controls.visible = p_visible

func _on_wall_cancel_pressed() -> void:
	if not _wall_editing_active:
		return
	if is_instance_valid(wall_items_layer):
		# Clear current
		wall_items_layer.erase_cell(_wall_editing_coords)
		if not _wall_editing_is_newly_placed:
			# Restore original
			var atlas := _get_wall_atlas_for(_wall_editing_item_name, _wall_original_side)
			wall_items_layer.set_cell(_wall_original_coords, WALL_ITEMS_SOURCE_ID, atlas)
		wall_items_layer.notify_runtime_tile_data_update()
	_stop_tracking_wall_and_hide_controls()
	_clear_selected_sprite()
	_clear_marked_wall_tile()

func _on_wall_check_pressed() -> void:
	if not _wall_editing_active:
		return
	var item_to_mark := _wall_editing_item_name
	var persist_coords := _wall_editing_coords
	_stop_tracking_wall_and_hide_controls()
	_clear_selected_sprite()
	_clear_marked_wall_tile()
	if item_to_mark != "":
		_placed_items[item_to_mark] = true
		_update_drag_ui_used_state(item_to_mark, true)
		# Persist wall item placement
		TileSelectionStore.set_placed_wall_item(item_to_mark, persist_coords)

func _on_wall_delete_pressed() -> void:
	if not _wall_editing_active:
		return
	if is_instance_valid(wall_items_layer):
		wall_items_layer.erase_cell(_wall_editing_coords)
		wall_items_layer.notify_runtime_tile_data_update()
	if _wall_editing_item_name != "":
		_placed_items.erase(_wall_editing_item_name)
		_update_drag_ui_used_state(_wall_editing_item_name, false)
		# Remove from persistence
		TileSelectionStore.remove_placed_wall_item(_wall_editing_item_name)
	_stop_tracking_wall_and_hide_controls()
	_clear_selected_sprite()
	_clear_marked_wall_tile()

func _on_wall_switch_pressed() -> void:
	if not _wall_editing_active:
		return
	var target_side := ("right" if _wall_editing_side == "left" else "left")
	var target_coords := _get_last_tile_for_wall(target_side)
	if target_coords == _SENTINEL:
		return
	if wall_items_layer.get_cell_source_id(target_coords) != -1:
		return
	wall_items_layer.erase_cell(_wall_editing_coords)
	var atlas := _get_wall_atlas_for(_wall_editing_item_name, target_side)
	wall_items_layer.set_cell(target_coords, WALL_ITEMS_SOURCE_ID, atlas)
	wall_items_layer.notify_runtime_tile_data_update()
	_wall_editing_coords = target_coords
	_wall_editing_side = target_side

func _make_wall_preview_texture(item_name: String, side: String) -> Texture2D:
	if not WALL_ITEM_ROWS.has(item_name):
		return null
	var sheet: Texture2D = load("res://scenes/room/decoration/wall/wall-sprites.png")
	if sheet == null:
		return null
	var row: int = WALL_ITEM_ROWS[item_name]
	var col: int = (0 if side == "left" else 1)
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(col * 32, row * 32, 32, 32)
	return at

func _make_preview_texture(item_name: String, rotation_idx: int) -> Texture2D:
	# Builds a Texture2D suitable for dragging UI based on spritesheet regions
	if item_name == "lamp-sprite" or item_name == "shelf-sprite":
		var sheet: Texture2D = load("res://scenes/room/decoration/floor/floor-sprites.png")
		if sheet == null:
			return null
		var y := 0 if item_name == "lamp-sprite" else 32
		var x := (rotation_idx % 4) * 32
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(x, y, 32, 32)
		return at
	elif item_name == "bed-sprite":
		var sheet: Texture2D = load("res://scenes/room/decoration/floor/floor-sprites.png")
		if sheet == null:
			return null
		var i := rotation_idx % 4
		var left_x := (i * 2) * 32
		var right_x := left_x + 32
		var y := 64
		var sheet_img := sheet.get_image()
		if sheet_img == null:
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(left_x, y, 64, 32)
			return at
		# Compose 48x32 preview. Rotations 2 and 4 (i=1,3) need special assembly.
		var img := Image.create(48, 32, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		if i == 1 or i == 3:
			# Take first 16px from the left tile, crop bottom (8 for rot2, 7 for rot4) and place with top padding.
			var h_crop := 24 if i == 1 else 25
			var dst_y := 8 if i == 1 else 7
			# 16px slice from LEFT tile
			img.blit_rect(sheet_img, Rect2i(left_x, y, 16, h_crop), Vector2i(0, dst_y))
			# Then take the whole RIGHT tile (32x32) and place to the right
			img.blit_rect(sheet_img, Rect2i(right_x, y, 32, 32), Vector2i(16, 0))
		else:
			# Rotations 1 and 3 (i=0,2): base 32 from LEFT tile + 16px slice from RIGHT tile
			var h_crop := 24 if i == 0 else 25
			var dst_y := 8 if i == 0 else 7
			img.blit_rect(sheet_img, Rect2i(left_x, y, 32, 32), Vector2i(0, 0))
			# Slice the rightmost 16px from the RIGHT tile
			img.blit_rect(sheet_img, Rect2i(right_x + 16, y, 16, h_crop), Vector2i(32, dst_y))
		return ImageTexture.create_from_image(img)
	return null

# ====================== USED ITEMS / UI HELPERS ======================
func is_item_placed(item_name: String) -> bool:
	# Check tracked set first
	if _placed_items.has(item_name) and _placed_items[item_name]:
		return true
	# Fallback by scanning layers (useful on first load or external changes)
	if item_name in ["lamp-sprite", "shelf-sprite"]:
		if not is_instance_valid(floor_items_layer):
			return false
		var atlas_list: Array = FLOOR_ITEM_ATLAS_VARIANTS[item_name]
		for c in floor_items_layer.get_used_cells():
			var ac := floor_items_layer.get_cell_atlas_coords(c)
			if ac in atlas_list:
				return true
		return false
	if item_name == "bed-sprite":
		if not is_instance_valid(floor_items_layer):
			return false
		var bed_variants: Array = FLOOR_ITEM_ATLAS_VARIANTS[item_name]
		for c in floor_items_layer.get_used_cells():
			var ac := floor_items_layer.get_cell_atlas_coords(c)
			for rot in range(bed_variants.size()):
				var pair: Array = bed_variants[rot]
				if ac == pair[0] or ac == pair[1]:
					return true
		return false
	# Wall items
	if item_name in WALL_ITEM_ROWS:
		if not is_instance_valid(wall_items_layer):
			return false
		var row: int = WALL_ITEM_ROWS[item_name]
		for c in wall_items_layer.get_used_cells():
			var ac2 := wall_items_layer.get_cell_atlas_coords(c)
			if ac2.y == row:
				return true
		return false
	return false

func _update_drag_ui_used_state(item_name: String, used: bool) -> void:
	var ui := get_node_or_null("Camera2D/OptionsContainer")
	if ui != null:
		# Defer to ensure UI changes happen after any queue_free/add_child cycles
		ui.call_deferred("mark_item_used", item_name, used)

# ====================== RESTORE PERSISTED ======================
func _restore_persisted_items() -> void:
	# Restore floor items
	var floor_dict: Dictionary = TileSelectionStore.get_all_placed_floor_items()
	if is_instance_valid(floor_items_layer) and is_instance_valid(floor_layer):
		for item_name in floor_dict.keys():
			var rec: Dictionary = floor_dict[item_name]
			if not rec.has("primary") or not rec.has("rotation"):
				continue
			var primary: Vector2i = rec["primary"]
			var rot_idx: int = int(rec["rotation"]) # avoid shadowing Node2D.rotation
			var ok := _place_item_with_rotation_at(item_name, primary, rot_idx)
			if ok:
				_placed_items[item_name] = true
				_update_drag_ui_used_state(item_name, true)
	# Restore wall items
	var wall_dict: Dictionary = TileSelectionStore.get_all_placed_wall_items()
	if is_instance_valid(wall_items_layer) and is_instance_valid(wall_layer):
		for wname in wall_dict.keys():
			var wrec: Dictionary = wall_dict[wname]
			if not wrec.has("coords"):
				continue
			var coords: Vector2i = wrec["coords"]
			if wall_items_layer.get_cell_source_id(coords) == -1 and _is_valid_wall_coord(coords):
				var side := _detect_wall_side_from_coords(coords)
				var atlas := _get_wall_atlas_for(wname, side)
				if atlas.x >= 0:
					wall_items_layer.set_cell(coords, WALL_ITEMS_SOURCE_ID, atlas)
					_placed_items[wname] = true
					_update_drag_ui_used_state(wname, true)
	if is_instance_valid(floor_items_layer):
		floor_items_layer.notify_runtime_tile_data_update()
	if is_instance_valid(wall_items_layer):
		wall_items_layer.notify_runtime_tile_data_update()
