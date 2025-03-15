extends Area2D

@export var damage: int = 50
@export var damage_source: String = "Enemy"

func get_damage():
	return {
		"damage": damage,
		"damage_source": damage_source
	}
