extends Control

func _ready():
	pass

# Go back to room scene
func _on_button_pressed() -> void:
	var room_scene = load("res://scenes/room/room.tscn").instantiate()
	get_tree().root.add_child(room_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = room_scene


func _on_minigames_list_item_selected(index: int) -> void:
	var scene
	
	print_debug(index)
	
	# Select scene to play
	if index == 0:
		scene = load("res://scenes/catch-the-ball/catch_ball_miningame.tscn").instantiate()
	else:
		return
	
	# switch to scene
	get_tree().root.add_child(scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = scene
