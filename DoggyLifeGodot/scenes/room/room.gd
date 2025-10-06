extends Node2D

@onready var pause_button := $Camera2D/PauseButton as Button
@onready var edit_button := $Camera2D/EditButton as Button
@onready var floor_items_grid: GridContainer = $Camera2D/DragsContainer/FloorItemsContainer/GridContainer
@onready var wall_items_grid: GridContainer = $Camera2D/DragsContainer/WallItemsContainer/GridContainer
@onready var floor_mouse_detector: TileMapLayer = $Camera2D/FloorMouseDetector
@onready var wall_layer: TileMapLayer = $Camera2D/WallLayer
@onready var floor_layer: TileMapLayer = $Camera2D/FloorLayer
@onready var floor_items_layer: TileMapLayer = $Camera2D/FloorItemsLayer
const AudioUtilsScript = preload("res://shared/scripts/audio_utils.gd")

# Tracks whether the current left mouse press started inside either drag/drop container
var _mouse_press_began_in_drag_area: bool = false

var selected_sprite_path: String = ""

@onready var selected_sprite: TextureRect = $Camera2D/SelectedSprite
var _selected_texture: Texture2D
var _last_hovered_tile: Vector2i = Vector2i(2147483647, 2147483647)
# For marking the hovered floor tile
var _marked_tile_overlay: Polygon2D = null
var _marked_tile_coords: Vector2i = Vector2i(2147483647, 2147483647)
var _dragging_floor_item: bool = false

func _ready():
	# Connect the pause button signal
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	# Apply saved audio settings on scene load
	AudioUtilsScript.load_and_apply()
	# Enable per-frame processing for continuous mouse position printing while pressed
	set_process(true)
	# Prepare the SelectedSprite so it doesn't block input and stays hidden until used
	if is_instance_valid(selected_sprite):
		selected_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_sprite.visible = false
		selected_sprite.stretch_mode = TextureRect.STRETCH_SCALE
		selected_sprite.ignore_texture_size = true
		selected_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Print all placed tile positions (local to the WallLayer map) as "x, y"
	if is_instance_valid(wall_layer):
		var used_cells: Array[Vector2i] = wall_layer.get_used_cells()
		for cell: Vector2i in used_cells:
			print("%d, %d" % [cell.x, cell.y])

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
			print_debug("Selected tile: %s" % tile_name)
		elif not event.pressed:
			# Release ends tracking and clears selection
			_mouse_press_began_in_drag_area = false
			_dragging_floor_item = false
			_clear_selected_sprite()
			_remove_marked_tile_overlay()
	# Mark hovered floor tile with green overlay if dragging a FLOOR item
	var dragging_floor := _mouse_press_began_in_drag_area and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _dragging_floor_item
	if dragging_floor and is_instance_valid(floor_mouse_detector) and is_instance_valid(floor_layer) and is_instance_valid(floor_items_layer):
		var local_pos := floor_mouse_detector.to_local(get_global_mouse_position())
		var tile_coords_mark: Vector2i = floor_mouse_detector.local_to_map(local_pos)
		# Check if tile_coords_mark is a used cell in FloorLayer and not a delimiter
		var used_cells: Array[Vector2i] = floor_layer.get_used_cells()
		var DELIMITER_ATLAS_COORDINATES := Vector2i(39, 0)
		if tile_coords_mark in used_cells and floor_layer.get_cell_atlas_coords(tile_coords_mark) != DELIMITER_ATLAS_COORDINATES:
			if _marked_tile_coords != tile_coords_mark:
				_remove_marked_tile_overlay()
				_add_marked_tile_overlay(tile_coords_mark)
		else:
			_remove_marked_tile_overlay()
	else:
		_remove_marked_tile_overlay()

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
			print_debug("Hover tile: %d, %d" % [tile_coords.x, tile_coords.y])

	# Mark hovered floor tile with green overlay if dragging a floor item
	var dragging_floor := _mouse_press_began_in_drag_area and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var is_floor_item := selected_sprite_path != "" and not selected_sprite_path.contains("wall")
	if dragging_floor and is_floor_item and is_instance_valid(floor_mouse_detector) and is_instance_valid(floor_items_grid):
		var local_pos := floor_mouse_detector.to_local(get_global_mouse_position())
		var tile_coords: Vector2i = floor_mouse_detector.local_to_map(local_pos)
		# Check if tile_coords is a used cell in FloorLayer and not a delimiter
		if is_instance_valid(wall_layer):
			var floor_layer = get_node_or_null("Camera2D/FloorLayer")
			if floor_layer:
				var used_cells: Array[Vector2i] = floor_layer.get_used_cells()
				var DELIMITER_ATLAS_COORDINATES := Vector2i(39, 0)
				if tile_coords in used_cells and floor_layer.get_cell_atlas_coords(tile_coords) != DELIMITER_ATLAS_COORDINATES:
					# Mark this tile
					if _marked_tile_coords != tile_coords:
						_remove_marked_tile_overlay()
						_add_marked_tile_overlay(tile_coords)
				else:
					_remove_marked_tile_overlay()
			else:
				_remove_marked_tile_overlay()
		else:
			_remove_marked_tile_overlay()
	else:
		_remove_marked_tile_overlay()

	# While the left button remains pressed and the press began in the drag area,
	# continuously print the mouse position.
	if _mouse_press_began_in_drag_area:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print_debug("Mouse position: %s" % str(get_global_mouse_position()))
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
			# If the button is no longer pressed, stop tracking
			_mouse_press_began_in_drag_area = false
			_clear_selected_sprite()

## Helper to add green diamond overlay aligned with isometric floor
func _add_marked_tile_overlay(tile_coords: Vector2i) -> void:
	if not (is_instance_valid(floor_layer) and is_instance_valid(floor_items_layer)):
		return
	var tile_size: Vector2i = floor_layer.tile_set.tile_size
	var center_local_in_floor := floor_layer.map_to_local(tile_coords) + Vector2(tile_size.x, tile_size.y) * 0.5
	var center_global := floor_layer.to_global(center_local_in_floor)
	var center_in_items := floor_items_layer.to_local(center_global)

	var poly := Polygon2D.new()
	var points: Array[Vector2] = [
		Vector2(-tile_size.x * 0.5, 0),
		Vector2(0, -tile_size.y * 0.5),
		Vector2(tile_size.x * 0.5, 0),
		Vector2(0, tile_size.y * 0.5)
	]
	poly.polygon = points
	poly.color = Color(0, 1, 0, 0.35)
	poly.position = center_in_items
	poly.z_index = 100
	floor_items_layer.add_child(poly)
	_marked_tile_overlay = poly
	_marked_tile_coords = tile_coords

# Helper to remove overlay
func _remove_marked_tile_overlay() -> void:
	if _marked_tile_overlay and is_instance_valid(_marked_tile_overlay):
		_marked_tile_overlay.queue_free()
	_marked_tile_overlay = null
	_marked_tile_coords = Vector2i(2147483647, 2147483647)
