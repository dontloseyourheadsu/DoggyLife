extends TextureRect

@onready var coin_count_display := $CoinCount as Label

const PLAYER_DATA_STORAGE = preload("res://storage/player_data.gd")

var coin_count: int = 0

func _ready() -> void:
	# Load coins
	var coins: int = PLAYER_DATA_STORAGE.get_coins_count()
	coin_count = coins
	
	coin_count_display.text = "%d" % [coins]
