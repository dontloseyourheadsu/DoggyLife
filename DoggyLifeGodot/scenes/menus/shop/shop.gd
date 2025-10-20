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

# Tab buttons
@onready var _items_btn: TextureButton = $Container/TabNavigation/ItemsTabButton
@onready var _dogs_btn: TextureButton = $Container/TabNavigation/DogsTabButton
@onready var _tiles_btn: TextureButton = $Container/TabNavigation/ItemsTabButton3

var _current_tab: Tab = Tab.ITEMS

func _ready() -> void:
	# Ensure the initial visibility reflects the default tab
	_apply_tab_visibility()


func _on_back_button_pressed() -> void:
	# Load room scene
	var room_scene = load("res://scenes/room/room.tscn").instantiate()
	get_tree().root.add_child(room_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = room_scene


# --- Tab switching logic ---
func _on_items_tab_button_pressed() -> void:
		_set_tab(Tab.ITEMS)

func _on_dogs_tab_button_pressed() -> void:
	_set_tab(Tab.DOGS)

func _on_items_tab_button_3_pressed() -> void:
	_set_tab(Tab.TILES)

func _set_tab(tab: Tab) -> void:
	if _current_tab == tab:
		return
	_current_tab = tab
	_apply_tab_visibility()

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
