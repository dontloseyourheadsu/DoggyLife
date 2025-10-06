extends Node2D

@onready var pause_button := $Camera2D/PauseButton as Button
@onready var edit_button := $Camera2D/EditButton as Button
@onready var floor_items_grid: GridContainer = $Camera2D/DragsContainer/FloorItemsContainer/GridContainer
@onready var wall_items_grid: GridContainer = $Camera2D/DragsContainer/WallItemsContainer/GridContainer
const AudioUtilsScript = preload("res://shared/scripts/audio_utils.gd")

# Tracks whether the current left mouse press started inside either drag/drop container
var _mouse_press_began_in_drag_area: bool = false

var selected_sprite_path: String = ""

@onready var selected_sprite: TextureRect = $Camera2D/SelectedSprite
var _selected_texture: Texture2D

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
			_clear_selected_sprite()

func _clear_selected_sprite() -> void:
	if is_instance_valid(selected_sprite):
		selected_sprite.texture = null
		selected_sprite.visible = false
	_selected_texture = null

func _process(_delta: float) -> void:
	# While the left button remains pressed and the press began in the drag area,
	# continuously print the mouse position.
	if _mouse_press_began_in_drag_area:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print_debug("Mouse position: %s" % str(get_global_mouse_position()))
			# Follow mouse with the selected sprite while pressed; keep last offset behavior
			if is_instance_valid(selected_sprite) and selected_sprite.visible:
				# Infer floor vs wall by selected_sprite_path if available; default to floor offset
				var is_floor := true
				if selected_sprite_path != "":
					# naive check: if path/name contains "wall" then treat as wall
					is_floor = not selected_sprite_path.contains("wall")
				var display_width := selected_sprite.size.x if selected_sprite.size.x > 0.0 else float(selected_sprite.texture.get_width())
				var display_height := selected_sprite.size.y if selected_sprite.size.y > 0.0 else float(selected_sprite.texture.get_height())
				var offset_x := display_width * (0.5 if is_floor else 0.85)
				var offset_y := display_height * (0.25 if is_floor else 0.85)
				selected_sprite.position = get_global_mouse_position() - Vector2(offset_x, offset_y)
		else:
			# If the button is no longer pressed, stop tracking
			_mouse_press_began_in_drag_area = false
			_clear_selected_sprite()
