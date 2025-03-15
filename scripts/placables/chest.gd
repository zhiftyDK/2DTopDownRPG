extends StaticBody2D

var entered = false
var opened = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body == player:
		entered = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		entered = false
		
func _process(_delta: float):
	if entered and Input.is_action_just_pressed("interact") and not opened:
		opened = true
		animated_sprite_2d.play("open")
