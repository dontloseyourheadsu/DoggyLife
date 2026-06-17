extends RigidBody3D

func _ready() -> void:
	# Enable contact monitoring so we can react to bounces
	contact_monitor = true
	max_contacts_reported = 4
