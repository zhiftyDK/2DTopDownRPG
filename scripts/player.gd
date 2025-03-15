extends CharacterBody2D

const SPEED = 130.0
const DASH_BOOST = 250.0
const ATTACK_BOOST = 130.0

var health = 500.0

var dashing = false
var attacking = false
var taking_damage = false
var dead = false
var current_attack = 1

var last_direction = Vector2.ZERO

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

# Attacks
const SWORD = preload("res://scenes/attacks/sword.tscn")
const ARROW = preload("res://scenes/attacks/arrow.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not dead:
		var direction = Input.get_vector("left", "right", "up", "down")
		
		# Store last direction if moving
		if direction != Vector2.ZERO:
			last_direction = direction.normalized()
		
		# Dash logic
		if Input.is_action_just_pressed("dash") and not dashing:
			start_dash()
		
		# Sword attack logic (prioritizes attacks over movement)
		if Input.is_action_just_pressed("sword_attack") and not attacking and not dashing:
			attack_sword()
		
		# Bow attack logic (prioritizes attacks over movement)
		if Input.is_action_just_pressed("bow_attack") and not attacking and not dashing:
			attack_bow()
		
		if not attacking and not dashing and not taking_damage:
			# Apply slight rotation for diagonal movement
			if direction.x != 0 and direction.y != 0:
				animated_sprite_2d.rotation_degrees = direction.x * direction.y * -5  # Small tilt
			else:
				animated_sprite_2d.rotation_degrees = 0  # Reset when moving straight
			
			if not ("damage" in animated_sprite_2d.animation and animated_sprite_2d.is_playing()):
				if direction.y != 0:
					play_animation("walk_up" if direction.y < 0 else "walk_down")
				elif direction.x != 0:
					play_animation("walk_horizontal")
					animated_sprite_2d.flip_h = direction.x < 0
				else:
					animate_direction(last_direction, "idle_up", "idle_horizontal", "idle_down")
		
		if not dashing:
			velocity = direction.normalized() * SPEED
		
		move_and_slide()

func _on_hitbox_hit(damage: int, damage_source: String):
	if damage_source != "Player":
		health -= damage
		taking_damage = true
		if health <= 0:
			dead = true
			play_animation("death")
			await animated_sprite_2d.animation_finished
		else:
			animate_direction(last_direction, "damage_up", "damage_horizontal", "damage_down")
			taking_damage = false

func attack_sword():
	attacking = true

	play_animation_mouse("sword_up".replace("_", str(current_attack) + "_"), "sword_down".replace("_", str(current_attack) + "_"), "sword_horizontal".replace("_", str(current_attack) + "_"))
	current_attack = 1 if current_attack == 2 else current_attack + 1
	
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	var angle_to_mouse = (mouse_pos - global_position).angle()
	var sword_distance = 10
	var sword_attack = SWORD.instantiate()
	sword_attack.damage_source = "Player"
	sword_attack.position = direction * sword_distance + Vector2(0, -5)
	sword_attack.rotation = angle_to_mouse
	add_child(sword_attack)
	
	# Block movement until the attack animation finishes
	await animated_sprite_2d.animation_finished
	sword_attack.queue_free()
	attacking = false

func attack_bow():
	attacking = true

	play_animation_mouse("bow_up", "bow_down", "bow_horizontal")
	
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	var angle_to_mouse = (mouse_pos - global_position).angle()
	var arrow_distance = 10
	var arrow_attack = ARROW.instantiate()
	arrow_attack.damage_source = "Player"
	
	arrow_attack.position = global_position + direction * arrow_distance + Vector2(0, -5)
	arrow_attack.rotation = angle_to_mouse
	
	get_tree().current_scene.add_child(arrow_attack)
	
	await animated_sprite_2d.animation_finished
	attacking = false

# Function to start dash
func start_dash():
	if last_direction == Vector2.ZERO:
		return  # Prevent dashing if no movement has happened before

	dashing = true
	hitbox.monitoring = false
	animated_sprite_2d.self_modulate.a = 0.5
	velocity = last_direction.normalized() * DASH_BOOST  # Apply dash speed
	animate_direction(last_direction, "dash_up", "dash_horizontal", "dash_down")

	await animated_sprite_2d.animation_finished # Dash duration
	animated_sprite_2d.self_modulate.a = 1
	hitbox.monitoring = true
	dashing = false  # End dash

func animate_direction(direction, up, horizontal, down):
	if direction.y != 0:
		play_animation(up if direction.y < 0 else down)
	elif direction.x != 0:
		play_animation(horizontal)
		animated_sprite_2d.flip_h = direction.x < 0

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
