extends PanelContainer

@onready var name_label: Label = %DogNameLabel
@onready var breed_label: Label = %DogBreedLabel
@onready var hunger_bar: TextureProgressBar = %HungerBar
@onready var thirst_bar: TextureProgressBar = %ThirstBar
@onready var hygiene_bar: TextureProgressBar = %HygieneBar
@onready var energy_bar: TextureProgressBar = %EnergyBar
@onready var love_bar: TextureProgressBar = %LoveBar

var current_dog: CharacterBody3D = null

var bowl_label: Label = null
var refill_btn: Button = null
var dispenser_label: Label = null
var refill_dispenser_btn: Button = null

func _ready() -> void:
	# Hide panel initially
	visible = false
	
	# Add separator programmatically
	var sep = HSeparator.new()
	$MarginContainer/VBoxContainer.add_child(sep)
	
	# Add Bowl HUD container
	var bowl_box = HBoxContainer.new()
	bowl_box.alignment = BoxContainer.ALIGNMENT_CENTER
	bowl_box.add_theme_constant_override("separation", 20)
	$MarginContainer/VBoxContainer.add_child(bowl_box)
	
	bowl_label = Label.new()
	bowl_label.text = "Bowl: Basic Bowl [0/100]"
	bowl_label.add_theme_font_size_override("font_size", 16)
	bowl_box.add_child(bowl_label)
	
	refill_btn = Button.new()
	refill_btn.text = "Refill Bowl"
	refill_btn.custom_minimum_size = Vector2(120, 30)
	bowl_box.add_child(refill_btn)
	refill_btn.pressed.connect(_on_refill_pressed)
	
	# Add Dispenser HUD container
	var dispenser_box = HBoxContainer.new()
	dispenser_box.alignment = BoxContainer.ALIGNMENT_CENTER
	dispenser_box.add_theme_constant_override("separation", 20)
	$MarginContainer/VBoxContainer.add_child(dispenser_box)
	
	dispenser_label = Label.new()
	dispenser_label.text = "Dispenser: Basic [0/100]"
	dispenser_label.add_theme_font_size_override("font_size", 16)
	dispenser_box.add_child(dispenser_label)
	
	refill_dispenser_btn = Button.new()
	refill_dispenser_btn.text = "Refill Dispenser"
	refill_dispenser_btn.custom_minimum_size = Vector2(120, 30)
	dispenser_box.add_child(refill_dispenser_btn)
	refill_dispenser_btn.pressed.connect(_on_refill_dispenser_pressed)

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

func _on_refill_pressed() -> void:
	if is_instance_valid(current_dog) and is_instance_valid(current_dog.bowl_node):
		current_dog.bowl_node.refill()
		_update_ui()

func _on_refill_dispenser_pressed() -> void:
	if is_instance_valid(current_dog) and is_instance_valid(current_dog.dispenser_node):
		current_dog.dispenser_node.refill()
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

	# Update bowl info
	if is_instance_valid(current_dog) and is_instance_valid(current_dog.bowl_node):
		var bowl = current_dog.bowl_node
		bowl_label.text = "Bowl: %s [%.0f / %.0f]" % [bowl.bowl_type.capitalize(), bowl.fullness, bowl.capacity]
		refill_btn.disabled = bowl.fullness >= bowl.capacity
	else:
		bowl_label.text = "Bowl: None"
		refill_btn.disabled = true

	# Update dispenser info
	if is_instance_valid(current_dog) and is_instance_valid(current_dog.dispenser_node):
		var disp = current_dog.dispenser_node
		dispenser_label.text = "Dispenser: %s [%.0f / %.0f]" % [disp.dispenser_type.capitalize(), disp.fullness, disp.capacity]
		refill_dispenser_btn.disabled = disp.fullness >= disp.capacity
	else:
		dispenser_label.text = "Dispenser: None"
		refill_dispenser_btn.disabled = true
