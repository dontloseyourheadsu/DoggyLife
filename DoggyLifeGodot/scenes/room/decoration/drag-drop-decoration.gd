extends Control

@onready var floor_grid: GridContainer = get_node_or_null("../DragsContainer/FloorItemsContainer/GridContainer")
@onready var wall_grid: GridContainer = get_node_or_null("../DragsContainer/WallItemsContainer/GridContainer")

const FLOOR_DIR := "res://scenes/room/decoration/floor"
const WALL_DIR := "res://scenes/room/decoration/wall"

func _ready() -> void:
	populate_grid(floor_grid, FLOOR_DIR)
	populate_grid(wall_grid, WALL_DIR)

func populate_grid(grid: GridContainer, dir_path: String) -> void:
	if grid == null:
		push_warning("Grid not found for path: %s" % dir_path)
		return
	
	# Clear existing items
	for child in grid.get_children():
		child.queue_free()
	
	var files := []
	# Use DirAccess static helper to list files in Godot 4.x
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
		files = DirAccess.get_files_at(dir_path)
	else:
		push_warning("Directory does not exist: %s" % dir_path)
		return
	
	for file in files:
		if not file.ends_with(".png"):
			continue
		var file_path := dir_path.path_join(file)
		add_item_to_grid(grid, file_path)

func add_item_to_grid(grid: GridContainer, texture_path: String) -> void:
	var base := texture_path.get_file().get_basename() # e.g., "bed-sprite"
	var display_name := base.replace("-sprite", "").replace("_", " ")
	display_name = display_name.capitalize()
	
	var tex := load(texture_path)
	if tex == null or not (tex is Texture2D):
		push_warning("Failed to load texture: %s" % texture_path)
		return
	
	# Build an AtlasTexture to show only the first frame.
	var frame_width := 48 if ("bed" in base) else 32
	var frame_height := 32
	
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(Vector2.ZERO, Vector2(frame_width, frame_height))
	
	var display_height := 25
	# Derive a scale factor from the desired height so width stays proportional
	var scale_factor := float(display_height) / float(frame_height)
	var display_width := int(round(float(frame_width) * scale_factor))
	
	# Item container (vertical): preview + label
	var item := VBoxContainer.new()
	item.alignment = BoxContainer.ALIGNMENT_CENTER
	item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var preview := TextureRect.new()
	preview.texture = atlas
	# Scale the texture to the control's rect so it can be smaller than the source frame
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	# Ensure the control can be smaller than the source texture and keep pixel art crisp
	preview.ignore_texture_size = true
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.custom_minimum_size = Vector2(display_width, display_height)
	preview.size = Vector2(display_width, display_height)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.tooltip_text = base

	# Connect the preview click directly to the Room script, binding the tile id and texture
	var room := get_tree().current_scene
	if room != null and room.has_method("_on_drag_preview_gui_input"):
		preview.gui_input.connect(Callable(room, "_on_drag_preview_gui_input").bind(base, atlas))
	
	var label := Label.new()
	label.text = display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 6)
	
	item.add_child(preview)
	item.add_child(label)
	grid.add_child(item)
