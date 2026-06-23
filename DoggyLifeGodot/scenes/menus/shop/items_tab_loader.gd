# Helper for populating the Items tab (room decorations)
# Usage: ItemsTabLoader.populate(grid, player_data, floor_dir, wall_dir, add_entry)
# - grid: GridContainer where entries will be added
# - player_data: script/object exposing owns_item(name: String) and add_owned_item(name: String)
# - floor_dir, wall_dir: directories containing the spritesheets
# - add_entry: Callable(name: String, texture: Texture2D) to add entries to the grid

static func populate(_grid: GridContainer, player_data, _floor_dir: String, _wall_dir: String, add_entry: Callable) -> void:
	# Define sellable entries for caring (bowls and food)
	var items: Array = []
	
	# Load textures
	var bowl_tex = load("res://sprites/decoration/bowl_placeholder.jpg")
	var food_tex = load("res://sprites/decoration/dog_food_bag.jpg")
	
	if bowl_tex != null:
		items.append({"name": "bowl-basic", "texture": bowl_tex})
		items.append({"name": "bowl-silver", "texture": bowl_tex})
		items.append({"name": "bowl-gold", "texture": bowl_tex})
		
	if food_tex != null:
		items.append({"name": "food-small", "texture": food_tex})
		items.append({"name": "food-medium", "texture": food_tex})
		items.append({"name": "food-large", "texture": food_tex})

	for it in items:
		var entry_name: String = it["name"]
		var tex: Texture2D = it["texture"]
		if tex == null:
			continue
		
		# For display in grid, we can tint the basic/silver/gold bowls.
		# However, since add_entry takes raw texture, we can pass it as is.
		# (We will apply custom tints inside shop.gd's visual creation if needed).
		add_entry.call(entry_name, tex)
