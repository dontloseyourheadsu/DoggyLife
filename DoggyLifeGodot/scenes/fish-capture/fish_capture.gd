extends Node2D

@onready var fish: RigidBody2D = $Camera2D/Fish
@onready var background: TextureRect = $Camera2D/Background
@onready var fisher: Node = $Camera2D/Fisher

const THROW_FORCE: Vector2 = Vector2(800, -400) # demo impulse; tweak as needed

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
	if not is_instance_valid(fisher):
		return
	# Toggle behavior: if ball not thrown, throw; else reset.
	# We rely on fisher.gd public API: is_ball_thrown(), trigger_throw(force), reset_ball().
	if fisher.has_method("is_ball_thrown") and fisher.call("is_ball_thrown"):
		fisher.call_deferred("reset_ball")
	else:
		fisher.call("trigger_throw", THROW_FORCE)
