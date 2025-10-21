# Helper for populating the Dogs tab (dog skins)
# Usage: DogsTabLoader.populate(grid, player_data, tile_size, add_entry)
# - grid: GridContainer where entries will be added
# - player_data: script/object exposing owns_item(name: String) and add_owned_item(name: String)
# - tile_size: int size of the dog preview frame (e.g., 32)
# - add_entry: Callable(name: String, texture: Texture2D) to add entries to the grid

static func populate(_grid: GridContainer, player_data, tile_size: int, add_entry: Callable) -> void:
	_ensure_default_owned_dog(player_data)

	var dogs := [
		{"name": "dog-samoyed", "path": "res://sprites/dogs/images/samoyed-dog.png"},
		{"name": "dog-beagle", "path": "res://sprites/dogs/images/beagle-dog.png"},
		{"name": "dog-shiba", "path": "res://sprites/dogs/images/shiba-dog.png"},
		{"name": "dog-spaniel", "path": "res://sprites/dogs/images/spaniel-brown.png"},
	]

	for d in dogs:
		var dname: String = d["name"]
		if player_data.owns_item(dname):
			continue
		var tex_path: String = d["path"]
		if not ResourceLoader.exists(tex_path):
			continue
		var tex := load(tex_path) as Texture2D
		if tex == null:
			continue
		# Use only the first 32x32 (tile_size) frame
		var dog_preview: Texture2D = _atlas(tex, Rect2(0, 0, tile_size, tile_size))
		add_entry.call(dname, dog_preview)

static func _ensure_default_owned_dog(player_data) -> void:
	var default_name := "dog-samoyed"
	if not player_data.owns_item(default_name):
		player_data.add_owned_item(default_name)

static func _atlas(sheet: Texture2D, region: Rect2) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = region
	return at
