extends CharacterBody2D

# Set your character's speed and jump strength.
# UPDATED: Increased SPEED to 300 for more noticeable movement
const SPEED = 300.0
# UPDATED: Increased JUMP_VELOCITY to -400. This will be a much more visible jump.
const JUMP_VELOCITY = -500.0

# Get the gravity value from the project settings.
# You can also just write: var gravity = 980.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	# 1. Add gravity
	# We only add gravity if the character is not on the floor.
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Handle Jumping
	# This checks for a jump input and if the character is on the ground.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Handle Left/Right Input
	var direction = Input.get_axis("left_move", "right_move")
	if direction:
		velocity.x = direction * SPEED
	else:
		# Apply friction (slows down)
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 4. Move the Character
	# This is the most important part. It applies the velocity.
	move_and_slide()
