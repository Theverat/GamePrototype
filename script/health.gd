extends Node
class_name Health

@export var max_hp: float = 100.0
@onready var hp: float = max_hp

func is_dead() -> bool:
	return hp <= 0.0
	
func deal_damage(damage: float) -> void:
	hp = max(0.0, hp - damage)

# TODO
#  - regen?
#  - armor?
#  - damage types? (fire, emp, acid, ...)
