extends Node3D

@onready var room_dog: CharacterBody3D = $RoomDog3D
@onready var camera: Camera3D = $RoomCamera3D
@onready var back_button: Button = $UI/SafePanel/BackButton

const CLICK_INDICATOR_SCENE = preload("res://scenes/room/click_indicator_3d.tscn")

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)

func _handle_click(mouse_pos: Vector2) -> void:
	if not camera:
		return
	var origin = camera.project_ray_origin(mouse_pos)
	var normal = camera.project_ray_normal(mouse_pos)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, origin + normal * 1000.0)
	var result = space_state.intersect_ray(query)
	
	if result:
		var target_pos = result.position
		if room_dog and room_dog.has_method("go_to_global_position"):
			room_dog.go_to_global_position(target_pos)
			var indicator = CLICK_INDICATOR_SCENE.instantiate()
			add_child(indicator)
			indicator.global_position = Vector3(target_pos.x, 0.02, target_pos.z)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/room/room.tscn")
