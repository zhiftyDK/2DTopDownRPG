extends Area2D

const SPEED = 200

@export var damage: int = 25
@export var damage_source: String = "Enemy"

var direction: Vector2

func _ready():
	direction = Vector2(1, 0).rotated(rotation)

func _on_area_entered(area: Area2D) -> void:
	if "hit_source" in area:
		if area.hit_source != damage_source:
			queue_free()

func _process(delta: float) -> void:
	position += direction * SPEED * delta

func get_damage():
	return {
		"damage": damage,
		"damage_source": damage_source
	}
