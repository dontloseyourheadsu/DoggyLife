extends Node2D

@onready var dogs_list: ItemList = $Camera2D/Container/VBoxContainer/ScrollContainer/DogsList
@onready var selection_container: Control = $Camera2D/Container
@onready var dog_body: Node = $Camera2D/Dog
@onready var dog_anim: AnimatedSprite2D = $Camera2D/Dog/DogAnimations

# Map item index -> dog key (e.g. "dog-samoyed")
var _index_to_dog: Array[String] = []

func _ready() -> void:
	_populate_owned_dogs_list()

func _populate_owned_dogs_list() -> void:
	if dogs_list == null:
		return
	# Ensure icons show at 32x32
	dogs_list.fixed_icon_size = Vector2i(32, 32)
	dogs_list.clear()
	_index_to_dog.clear()

	var pd: PlayerData = PlayerData.load_player_data()
	if pd == null:
		return

	# Collect owned dog keys like "dog-samoyed"
	var dog_keys: Array[String] = []
	for item_name in pd.owned_items:
		if typeof(item_name) == TYPE_STRING and item_name.begins_with("dog-"):
			dog_keys.append(item_name)

	# Sort by name for stable order
	dog_keys.sort()

	for dog_key in dog_keys:
		var breed := _dog_key_to_breed(dog_key)
		var display := _display_name_from_breed(breed)
		var icon := _make_dog_icon_texture(breed)
		var idx := dogs_list.get_item_count()
		dogs_list.add_item(display, icon)
		dogs_list.set_item_metadata(idx, dog_key)
		_index_to_dog.append(dog_key)

func _dog_key_to_breed(dog_key: String) -> String:
	# dog_key format: "dog-<breed>"
	if dog_key.begins_with("dog-"):
		return dog_key.substr(4)
	return dog_key

func _display_name_from_breed(breed: String) -> String:
	if breed == "":
		return "Unknown"
	# Replace dashes with spaces and capitalize words
	var parts := breed.split("-")
	for i in parts.size():
		var p: String = parts[i]
		if p.length() > 0:
			parts[i] = p.left(1).to_upper() + p.substr(1)
	return " ".join(parts)

func _make_dog_icon_texture(breed: String) -> Texture2D:
	# Prefer static image first 32x32
	var image_path := "res://sprites/dogs/images/%s-dog.png" % breed
	var tex: Texture2D = load(image_path)
	if tex != null:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, 0, 32, 32)
		return at
	# Fallback to first frame of spriteframes
	var frames: SpriteFrames = load("res://sprites/dogs/spriteframes/%s-dog.tres" % breed)
	if frames != null:
		var anims := frames.get_animation_names()
		if anims.size() > 0:
			var a := anims[0]
			var icon_tex := frames.get_frame_texture(a, 0)
			if icon_tex != null:
				return icon_tex
	return null

func _on_dogs_list_item_selected(index: int) -> void:
	if dogs_list == null or dog_anim == null or dog_body == null:
		return
	# Resolve selection to dog key
	var dog_key: String = ""
	if index >= 0 and index < dogs_list.get_item_count():
		var meta = dogs_list.get_item_metadata(index)
		if typeof(meta) == TYPE_STRING:
			dog_key = String(meta)
	if dog_key == "" and index >= 0 and index < _index_to_dog.size():
		dog_key = _index_to_dog[index]
	if dog_key == "":
		return

	var breed := _dog_key_to_breed(dog_key)
	# Load the corresponding SpriteFrames resource for the AnimatedSprite2D
	var frames: SpriteFrames = load("res://sprites/dogs/spriteframes/%s-dog.tres" % breed)
	if frames == null:
		return
	dog_anim.sprite_frames = frames

	# Reveal the dog and hide selection UI
	dog_body.visible = true
	if selection_container != null:
		selection_container.visible = false
