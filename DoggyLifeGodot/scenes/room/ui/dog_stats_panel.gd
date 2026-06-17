extends PanelContainer

@onready var name_label: Label = %DogNameLabel
@onready var breed_label: Label = %DogBreedLabel
@onready var hunger_bar: TextureProgressBar = %HungerBar
@onready var thirst_bar: TextureProgressBar = %ThirstBar
@onready var hygiene_bar: TextureProgressBar = %HygieneBar
@onready var energy_bar: TextureProgressBar = %EnergyBar
@onready var love_bar: TextureProgressBar = %LoveBar

var current_dog: CharacterBody3D = null

func _ready() -> void:
	# Hide panel initially
	visible = false

func display_dog(dog: CharacterBody3D) -> void:
	current_dog = dog
	visible = true
	_update_ui()

func close_panel() -> void:
	current_dog = null
	visible = false

func _process(_delta: float) -> void:
	if visible and is_instance_valid(current_dog):
		_update_ui()

func _update_ui() -> void:
	if not is_instance_valid(current_dog):
		close_panel()
		return
		
	name_label.text = current_dog.dog_name
	breed_label.text = "%s (Speed: %.1f, Weight: %.1f)" % [current_dog.dog_breed, current_dog.movement_speed, current_dog.weight]
	
	# Update progressive bars (0-100 range)
	hunger_bar.value = current_dog.stat_hunger
	thirst_bar.value = current_dog.stat_thirst
	hygiene_bar.value = current_dog.stat_hygiene
	energy_bar.value = current_dog.stat_energy
	love_bar.value = current_dog.stat_affection
