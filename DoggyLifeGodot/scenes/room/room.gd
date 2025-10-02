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
	# Wire up click handlers for the drag/drop tiles populated by the decoration script
	_wire_drag_tiles()
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

# --- Drag/Drop tile selection wiring (debug print on click) ---
func _wire_drag_tiles() -> void:
	# Grids should already be populated because child nodes' _ready ran before this node's _ready.
	if is_instance_valid(floor_items_grid):
		_wire_grid(floor_items_grid)
		# Handle any future additions (e.g., if regenerated)
		floor_items_grid.child_entered_tree.connect(func(child: Node):
			if child.get_parent() == floor_items_grid and child is Control:
				_connect_item_recursive(child)
		)
	if is_instance_valid(wall_items_grid):
		_wire_grid(wall_items_grid)
		wall_items_grid.child_entered_tree.connect(func(child: Node):
			if child.get_parent() == wall_items_grid and child is Control:
				_connect_item_recursive(child)
		)

func _wire_grid(grid: GridContainer) -> void:
	# Connect the grid itself so clicks on empty areas are also captured,
	# and then recursively connect all Control descendants.
	_connect_item_recursive(grid)

func _connect_item_recursive(node: Control) -> void:
	# Avoid double-connecting
	if node.has_meta("drag_item_click_connected"):
		return
	# Determine a tile name to display for this item's subtree
	var tile_name := _get_item_tile_name(node)
	# Connect this control's gui_input to handle press/release, also pass the source node
	node.gui_input.connect(Callable(self, "_on_item_gui_input").bind(tile_name, node))
	node.set_meta("drag_item_click_connected", true)
	# Also connect all Control descendants so clicks on nested controls are captured
	for d in node.get_children():
		if d is Control:
			_connect_item_recursive(d)

func _get_item_tile_name(start: Node) -> String:
	# Try to find a TextureRect with tooltip_text set by the decoration script.
	var stack: Array[Node] = [start]
	while not stack.is_empty():
		var n: Node = stack.pop_back() as Node
		if n is TextureRect and n.tooltip_text != "":
			return n.tooltip_text
		if n is Label and n.text != "":
			return (n as Label).text
		for c in n.get_children():
			stack.push_back(c)
	# Fallback name if nothing found
	return "unknown"

func _on_item_gui_input(event: InputEvent, tile_name: String, source: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not event.is_echo():
			var item_container := _find_item_container(source)
			var preview_texrect := _find_preview_in_item(item_container) if item_container != null else null
			if preview_texrect != null and preview_texrect.texture != null:
				# Begin drag from a valid item: set up sprite and tracking
				_mouse_press_began_in_drag_area = true
				_selected_texture = preview_texrect.texture
				selected_sprite.texture = _selected_texture
				selected_sprite.visible = true
				selected_sprite.position = get_global_mouse_position()
				selected_sprite_path = tile_name
				print_debug("Selected tile: %s" % tile_name)
			else:
				# Clicked empty grid area: do not begin drag
				_mouse_press_began_in_drag_area = false
		elif not event.pressed:
			# Release ends tracking and clears selection
			_mouse_press_began_in_drag_area = false
			_clear_selected_sprite()

func _find_item_container(node: Control) -> Control:
	# Ascend from the source control to find the direct child of either grid (an item container)
	var cur: Node = node
	while cur != null:
		var parent := cur.get_parent()
		if parent == floor_items_grid or parent == wall_items_grid:
			return cur as Control
		# Stop if we reached the grids or we left the DragsContainer subtree
		if cur == floor_items_grid or cur == wall_items_grid or not (cur is Node):
			break
		cur = parent
	return null

func _find_preview_in_item(item_container: Control) -> TextureRect:
	if item_container == null:
		return null
	# Look for a TextureRect child (preview) within the item container
	for c in item_container.get_children():
		if c is TextureRect and (c as TextureRect).texture != null:
			return c
	# If not direct child, search recursively
	var stack: Array[Node] = []
	for child in item_container.get_children():
		stack.push_back(child)
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is TextureRect and (n as TextureRect).texture != null:
			return n
		for d in n.get_children():
			stack.push_back(d)
	return null

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
			# Follow mouse with the selected sprite while pressed
			if is_instance_valid(selected_sprite) and selected_sprite.visible:
				selected_sprite.position = get_global_mouse_position()
		else:
			# If the button is no longer pressed, stop tracking
			_mouse_press_began_in_drag_area = false
			_clear_selected_sprite()
