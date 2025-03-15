extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var hitbox: Area2D = $Hitbox

const SWORD = preload("res://scenes/attacks/sword.tscn")

const SPEED = 65.0
const ATTACK_SPEED = 150.0
const RADIUS = 30.0
const ATTACK_TIME = 5.0

var health = 150.0

var player_chase = false
var spawned = false
var can_attack = true
var taking_damage = false
var sword_attack
var randomnum

func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	randomnum = rng.randf()

func _physics_process(delta):
	if spawned and not taking_damage:
		if player_chase:
			var distance = global_position.distance_to(player.global_position)
			if distance <= RADIUS:
				if can_attack:
					timer.start()
					can_attack = false
					attack()
				elif "attack" in animated_sprite_2d.animation and not animated_sprite_2d.is_playing():
					sword_attack.queue_free()
					velocity = Vector2.ZERO
					play_animation("idle")
				elif "damage" in animated_sprite_2d.animation and not animated_sprite_2d.is_playing():
					velocity = Vector2.ZERO
					play_animation("idle")
			else:
				move_to_player(delta)
		else:
			if sword_attack:
				sword_attack.queue_free()
			velocity = Vector2.ZERO
			play_animation("idle")
		move_and_slide()

func _on_timer_timeout() -> void:
	can_attack = true

func attack():
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * ATTACK_SPEED
	animate_direction(direction, "attack_up", "attack_horizontal", "attack_down")
	var sword_rotation = (player.global_position - global_position).angle()
	var sword_distance = 10
	sword_attack = SWORD.instantiate()
	sword_attack.position = direction * sword_distance + Vector2(0, -5)
	sword_attack.rotation = sword_rotation
	add_child(sword_attack)

func move_to_player(delta):
	var direction = (get_circle_position(randomnum) - global_position).normalized()
	move(direction, SPEED, delta)
	animate_direction(direction, "walk_up", "walk_horizontal", "walk_down")

func animate_direction(direction, up, horizontal, down):
	if direction.x != 0 and direction.y != 0:
		if abs(direction.x) > abs(direction.y):
			play_animation(horizontal)
			animated_sprite_2d.flip_h = direction.x < 0
		else:
			play_animation(up if direction.y < 0 else down)
	elif direction.x != 0:
		play_animation(horizontal)
		animated_sprite_2d.flip_h = direction.x < 0
	elif direction.y != 0:
		play_animation(up if direction.y < 0 else down)

func move(direction, speed, delta):
	var desired_velocity =  direction * speed
	var steering = (desired_velocity - velocity) * delta * 2.5
	velocity += steering

func get_circle_position(random):
	var kill_circle_centre = player.global_position
	#Distance from center to circumference of circle
	var angle = random * PI * 2;
	var x = kill_circle_centre.x + cos(angle) * RADIUS;
	var y = kill_circle_centre.y + sin(angle) * RADIUS;

	return Vector2(x, y)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body == player:
		player_chase = true
		if not spawned:
			play_animation("spawn")
			await animated_sprite_2d.animation_finished
			spawned = true
			hitbox.monitoring = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player_chase = false

func _on_hitbox_hit(damage: int, damage_source: String) -> void:
	if damage_source == "Player":
		health -= damage
		taking_damage = true
		if health <= 0:
			play_animation("death")
			await animated_sprite_2d.animation_finished
			queue_free()
		else:
			var direction = (player.global_position - global_position).normalized()
			animate_direction(direction, "damage_up", "damage_horizontal", "damage_down")
			await animated_sprite_2d.animation_finished
			taking_damage = false

# Function to play animations only if they change
func play_animation(anim_name: String) -> void:
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)
