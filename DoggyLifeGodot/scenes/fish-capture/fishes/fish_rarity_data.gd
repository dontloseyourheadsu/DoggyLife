extends Node

## Fish Rarity Database
## Defines rarity groups and bite probabilities for all fish species

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EXTRA_RARE
}

## Base bite probability for each rarity (0.0 to 1.0)
## These are the base chances before distance modifiers
const RARITY_BITE_PROBABILITY: Dictionary = {
	Rarity.COMMON: 0.70, # 70% base chance
	Rarity.UNCOMMON: 0.45, # 45% base chance
	Rarity.RARE: 0.25, # 25% base chance
	Rarity.EXTRA_RARE: 0.10 # 10% base chance
}

## Fish species organized by rarity
## Key: species filename (without .png extension)
## Value: Rarity enum
const FISH_RARITY_MAP: Dictionary = {
	# COMMON - Frequently found, easy to catch
	"bass": Rarity.COMMON,
	"catfish": Rarity.COMMON,
	"goldfish": Rarity.COMMON,
	"anchovy": Rarity.COMMON,
	
	# UNCOMMON - Moderately available
	"rainbow_trout": Rarity.UNCOMMON,
	"clownfish": Rarity.UNCOMMON,
	"surgeonfish": Rarity.UNCOMMON,
	
	# RARE - Hard to find
	"angelfish": Rarity.RARE,
	"pufferfish": Rarity.RARE,
	
	# EXTRA RARE - Very difficult to catch
	"crab_dungeness": Rarity.EXTRA_RARE
}

## Get rarity for a fish species by its texture path
static func get_fish_rarity(texture_path: String) -> Rarity:
	var filename = texture_path.get_file().get_basename()
	# Remove _outline suffix if present
	if filename.ends_with("_outline"):
		filename = filename.replace("_outline", "")
	
	if FISH_RARITY_MAP.has(filename):
		return FISH_RARITY_MAP[filename]
	
	# Default to common if not found
	return Rarity.COMMON

## Get base bite probability for a fish species
static func get_base_bite_probability(texture_path: String) -> float:
	var rarity = get_fish_rarity(texture_path)
	return RARITY_BITE_PROBABILITY[rarity]

## Get rarity name as string
static func get_rarity_name(rarity: Rarity) -> String:
	match rarity:
		Rarity.COMMON:
			return "Common"
		Rarity.UNCOMMON:
			return "Uncommon"
		Rarity.RARE:
			return "Rare"
		Rarity.EXTRA_RARE:
			return "Extra Rare"
		_:
			return "Unknown"
