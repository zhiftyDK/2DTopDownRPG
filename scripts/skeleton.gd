extends CharacterBody2D

var SPEED = 65.0
var player_chase = false
var spawned = false

@onready var player = get_tree().get_first_node_in_group("player")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO  # Reset velocity each frame
	
	if player_chase:
		var direction = (player.position - position).normalized()

		# Determine the primary movement direction
		if abs(direction.x) > abs(direction.y):
			velocity.x = direction.x * SPEED
			play_animation("walk_horizontal")
			animated_sprite_2d.flip_h = direction.x < 0
		else:
			velocity.y = direction.y * SPEED
			play_animation("walk_up" if direction.y < 0 else "walk_down")

	elif spawned:
		play_animation("idle")

	move_and_slide()  # Apply movement properly

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body == player:
		if not spawned:
			play_animation("spawn")
			await animated_sprite_2d.animation_finished
			spawned = true
		player_chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player_chase = false

# Function to play animations only if they change
func play_animation(anim_name: String) -> void:
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)
