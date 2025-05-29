extends CollisionObject3D
class_name Unit
# Abstract base class for all units

class Health:
	var max_hp: float = 100.0
	var hp: float = max_hp
	
	func _init(init_hp: float) -> void:
		max_hp = init_hp
		hp = init_hp

	func is_dead() -> bool:
		return hp <= 0.0
		
	func apply_damage(value: float) -> void:
		hp = max(0.0, hp - value)
		
	func heal(value: float) -> void:
		if is_dead():
			# No necromancy
			return
		hp = min(max_hp, hp + value)

@export var collision_shape: CollisionShape3D = null
@export var attack_area: Area3D = null
@export var init_hp: float = 100.0
@onready var health: Health = Health.new(init_hp)

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	if health.is_dead():
		queue_free()
	
func _physics_process(delta: float) -> void:
	pass

# Finds the closest node that is in range and in the specified group
# group: for example "faction: nanite"
func get_closest_node_in_range(group: String) -> Node3D:
	var in_range: Array[Node3D] = attack_area.get_overlapping_bodies()
	
	var min_dist_sqr: float = 99999999.0
	var target: Node3D = null
	for node in in_range:
		if not node.is_in_group(group):
			continue
		
		var dist_sqr: float = (node.global_position - global_position).length_squared()
		
		if dist_sqr < min_dist_sqr:
			target = node
			min_dist_sqr = dist_sqr
	
	return target
