extends Area2D

signal hit(damage: int, damage_source: String)
@export var hit_source: String

func _ready():
	hit_source = get_parent().name

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("get_damage"):
		var damage = area.get_damage()
		emit_signal("hit", damage.damage, damage.damage_source)
