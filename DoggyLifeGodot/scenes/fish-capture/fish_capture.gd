extends Node2D

@onready var fish: RigidBody2D = $Camera2D/Fish
@onready var background: TextureRect = $Camera2D/Background
@onready var fisher: Sprite2D = $Camera2D/Fisher
@onready var ball: RigidBody2D = $Camera2D/Ball
@onready var dog: CharacterBody2D = $Camera2D/Dog

# Fisher is scaled 6x, so forces need to be smaller for visible arc
const THROW_FORCE: Vector2 = Vector2(500, -100) # Adjusted for 6x scale

func _ready() -> void:
	_setup_fish_bounds()
	# Assign random species
	fish.set_random_species()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_left_click()

func _setup_fish_bounds() -> void:
	# Use background offsets as bounds; vertical lower 25% (75%-100%)
	var x_min: float = background.offset_left
	var x_max: float = background.offset_right
	var y_min_all: float = background.offset_top
	var y_max_all: float = background.offset_bottom
	var height: float = y_max_all - y_min_all
	var y_min: float = y_min_all + height * 0.75
	var y_max: float = y_max_all
	var swim_rect = Rect2(Vector2(x_min, y_min), Vector2(x_max - x_min, y_max - y_min))
	fish.swim_bounds = swim_rect
	# Place fish initially inside bounds
	var pos = Vector2(randi() % int(swim_rect.size.x) + swim_rect.position.x, randi() % int(swim_rect.size.y) + swim_rect.position.y)
	fish.global_position = pos

func _on_left_click() -> void:
	if not is_instance_valid(ball) or not is_instance_valid(fisher):
		return
	# Toggle behavior: if ball not thrown, throw with fisher animation; else reset.
	if ball.has_method("is_thrown") and ball.call("is_thrown"):
		# Reset ball
		if ball.has_method("request_reset"):
			ball.call("request_reset")
		# Reset fisher arm animation
		if fisher.has_method("reset_arm"):
			fisher.call("reset_arm")
		# Reset dog position and state
		if is_instance_valid(dog) and dog.has_method("reset_dog"):
			dog.call("reset_dog")
	else:
		# Trigger fisher arm animation, then throw ball
		if fisher.has_method("trigger_throw"):
			fisher.call("trigger_throw", THROW_FORCE)
			# Connect to throw_completed signal to actually throw the ball
			if not fisher.is_connected("throw_completed", _on_fisher_throw_completed):
				fisher.connect("throw_completed", _on_fisher_throw_completed)

func _on_fisher_throw_completed() -> void:
	# Fisher arm animation complete, now throw the ball
	if is_instance_valid(ball) and ball.has_method("request_throw"):
		ball.call("request_throw", THROW_FORCE)
	# Also trigger the dog to walk and fall into water (no chasing the ball)
	if is_instance_valid(dog) and dog.has_method("trigger_fall_to_water"):
		dog.call("trigger_fall_to_water")
