extends CharacterBody2D

# Set your character's speed and jump strength.
# UPDATED: Increased SPEED to 300 for more noticeable movement
const SPEED = 300.0
# UPDATED: Increased JUMP_VELOCITY to -400. This will be a much more visible jump.
const JUMP_VELOCITY = -500.0

# Get the gravity value from the project settings.
# You can also just write: var gravity = 980.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Track which direction the dog is facing
var facing_right: bool = true

@onready var anim_sprite: AnimatedSprite2D = $DogAnimations

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
		# Update facing direction
		if direction > 0:
			facing_right = true
		else:
			facing_right = false
	else:
		# Apply friction (slows down)
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 4. Move the Character
	# This is the most important part. It applies the velocity.
	move_and_slide()
	
	# 5. Update animations
	_update_animation()

func _update_animation() -> void:
	if anim_sprite == null:
		return
	
	# Check if dog is in the air (jumping/falling)
	if not is_on_floor():
		# Play jump animation based on facing direction
		if facing_right:
			anim_sprite.play("jump-right")
		else:
			anim_sprite.play("jump-left")
	else:
		# Dog is on the ground
		# Check if moving
		if abs(velocity.x) > 10: # Small threshold to avoid animation jitter
			# Play walk animation based on direction
			if facing_right:
				anim_sprite.play("walk-right")
			else:
				anim_sprite.play("walk-left")
		else:
			# Idle - stop animation or play idle if you have one
			# For now, we'll just stop on the first frame
			if facing_right:
				anim_sprite.play("walk-right")
				anim_sprite.pause()
			else:
				anim_sprite.play("walk-left")
				anim_sprite.pause()
