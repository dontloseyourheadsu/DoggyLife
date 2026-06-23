extends StaticBody3D
class_name Bowl3D

@onready var sprite: Sprite3D = $Sprite3D
@onready var label: Label3D = $Label3D

var dog_key: String = ""
var dog_name: String = ""
var bowl_type: String = "basic"
var capacity: float = 100.0
var fullness: float = 100.0

const PLAYER_DATA_STORAGE = preload("res://storage/player_data.gd")
const BOWL_PLACEHOLDER_TEX = preload("res://sprites/decoration/bowl_placeholder.jpg")

func _ready() -> void:
	# Add to a group so they can be easily found by dogs
	add_to_group("bowls")
	# Make pickable
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	_load_stats()
	_update_visuals()

func setup(key: String, d_name: String) -> void:
	dog_key = key
	dog_name = d_name
	_load_stats()
	_update_visuals()

func _load_stats() -> void:
	if dog_key == "":
		return
	var data = PLAYER_DATA_STORAGE.get_dog_bowl(dog_key)
	bowl_type = data.get("type", "basic")
	capacity = data.get("capacity", 100.0)
	fullness = data.get("fullness", 100.0)

func save_stats() -> void:
	if dog_key == "":
		return
	var data = {
		"type": bowl_type,
		"capacity": capacity,
		"fullness": fullness
	}
	PLAYER_DATA_STORAGE.save_dog_bowl(dog_key, data)
	_update_visuals()

func _update_visuals() -> void:
	if label:
		var pct = fullness / max(1.0, capacity)
		label.text = "%s's Bowl\n[%.0f / %.0f]" % [dog_name, fullness, capacity]
		label.modulate = Color.GREEN if pct >= 0.6 else (Color.YELLOW if pct >= 0.25 else Color.RED)
	
	if sprite:
		# Tint bowl based on type
		match bowl_type:
			"silver":
				sprite.modulate = Color(0.8, 0.9, 1.0, 1.0) # Silver/cool white
			"gold":
				sprite.modulate = Color(1.0, 0.85, 0.3, 1.0) # Gold
			_:
				sprite.modulate = Color(0.6, 0.75, 1.0, 1.0) # Basic (slightly blue tint)

func refill() -> void:
	var needed = capacity - fullness
	if needed <= 0.0:
		return
	
	var current_food = PLAYER_DATA_STORAGE.get_food_stock()
	if current_food <= 0.0:
		_show_floating_text("No Food Stock!")
		return
		
	var to_add = min(needed, current_food)
	if PLAYER_DATA_STORAGE.consume_food_stock(to_add):
		fullness += to_add
		save_stats()
		_show_floating_text("+%.0f Food" % to_add)
		
		# Update UI
		var main_room = get_tree().current_scene
		if main_room and main_room.has_method("refresh_food_hud"):
			main_room.refresh_food_hud()

func eat_food(amount: float) -> float:
	"""Called by the dog. Returns the actual amount of food eaten."""
	var to_eat = min(amount, fullness)
	fullness -= to_eat
	save_stats()
	return to_eat

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		refill()

func _show_floating_text(txt: String) -> void:
	# Spawn a temporary Label3D that rises and fades
	var f_label = Label3D.new()
	f_label.text = txt
	f_label.billboard = 1 # BILLBOARD_ENABLED
	f_label.pixel_size = 0.012
	f_label.font_size = 24
	f_label.modulate = Color.YELLOW
	add_child(f_label)
	f_label.global_position = global_position + Vector3(0, 0.5, 0)
	
	var tween = create_tween()
	tween.tween_property(f_label, "global_position", f_label.global_position + Vector3(0, 0.5, 0), 0.8)
	tween.parallel().tween_property(f_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(f_label.queue_free)
