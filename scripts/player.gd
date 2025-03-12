extends CharacterBody2D

const SPEED = 130.0
const DASH_BOOST = 250.0
const ATTACK_BOOST = 130.0

var dashing = false
var attacking = false
var current_attack = 1

var last_direction = Vector2.ZERO

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	# Store last direction if moving
	if direction != Vector2.ZERO:
		last_direction = direction.normalized()
	
	# Dash logic
	if Input.is_action_just_pressed("dash") and not dashing:
		start_dash()
	
	# Attack logic (prioritizes attacks over movement)
	if Input.is_action_just_pressed("attack") and not attacking:
		start_attack()
	
	if not attacking and not dashing:
		# Apply slight rotation for diagonal movement
		if direction.x != 0 and direction.y != 0:
			animated_sprite_2d.rotation_degrees = direction.x * direction.y * -5  # Small tilt
		else:
			animated_sprite_2d.rotation_degrees = 0  # Reset when moving straight
		
		if direction.y != 0:
			play_animation("walk_up" if direction.y < 0 else "walk_down")
		elif direction.x != 0:
			play_animation("walk_horizontal")
			animated_sprite_2d.flip_h = direction.x < 0
		else:
			if last_direction.y != 0:
				play_animation("idle_up" if last_direction.y < 0 else "idle_down")
			elif last_direction.x != 0:
				play_animation("idle_horizontal")
				animated_sprite_2d.flip_h = last_direction.x < 0
	
	if not dashing:
		velocity = direction.normalized() * SPEED
	
	move_and_slide()

func start_attack():
	attacking = true

	play_animation_mouse("attack_up".replace("_", str(current_attack) + "_"), "attack_down".replace("_", str(current_attack) + "_"), "attack_horizontal".replace("_", str(current_attack) + "_"))
	current_attack = 1 if current_attack == 2 else current_attack + 1

	# Block movement until the attack animation finishes
	await animated_sprite_2d.animation_finished
	attacking = false

# Function to start dash
func start_dash():
	if last_direction == Vector2.ZERO:
		return  # Prevent dashing if no movement has happened before

	dashing = true
	velocity = last_direction.normalized() * DASH_BOOST  # Apply dash speed
	if last_direction.y != 0:
		play_animation("dash_up" if last_direction.y < 0 else "dash_down")
	elif last_direction.x != 0:
		play_animation("dash_horizontal")
		animated_sprite_2d.flip_h = last_direction.x < 0

	await animated_sprite_2d.animation_finished # Dash duration
	dashing = false  # End dash


# Function to play animations based on mouse position
func play_animation_mouse(up, down, horizontal) -> void:
	var mouse_pos = get_local_mouse_position()
	var animation = ""
	if abs(mouse_pos.x) > abs(mouse_pos.y):  # Horizontal attack
		animation = horizontal
		animated_sprite_2d.flip_h = mouse_pos.x < 0
	else:  # Vertical attack
		animation = down if mouse_pos.y > 0 else up
	animated_sprite_2d.play(animation)

# Function to play animations only if they change
func play_animation(anim_name: String) -> void:
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)
