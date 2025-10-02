extends Node2D

@onready var pause_button := $Camera2D/PauseButton as Button
@onready var edit_button := $Camera2D/EditButton as Button
@onready var floor_items_grid: GridContainer = $Camera2D/DragsContainer/FloorItemsContainer/GridContainer
@onready var wall_items_grid: GridContainer = $Camera2D/DragsContainer/WallItemsContainer/GridContainer
const AudioUtilsScript = preload("res://shared/scripts/audio_utils.gd")

func _ready():
	# Connect the pause button signal
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	# Apply saved audio settings on scene load
	AudioUtilsScript.load_and_apply()
	# Wire up click handlers for the drag/drop tiles populated by the decoration script
	_wire_drag_tiles()

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
	for child in grid.get_children():
		if child is Control:
			_connect_item_recursive(child)

func _connect_item_recursive(node: Control) -> void:
	# Avoid double-connecting
	if node.has_meta("drag_item_click_connected"):
		return
	# Determine a tile name to display for this item's subtree
	var tile_name := _get_item_tile_name(node)
	# Connect this control's gui_input to print the selection
	node.gui_input.connect(Callable(self, "_on_item_gui_input").bind(tile_name))
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

func _on_item_gui_input(event: InputEvent, tile_name: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		print_debug("Selected tile: %s" % tile_name)
