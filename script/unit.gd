extends CollisionObject3D
class_name Unit  # Abstract base class for all units

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
@onready var attack_area_coll: CollisionShape3D = attack_area.get_node("CollisionShape3D") if attack_area else null
# TODO Assuming the shape has a .radius property. So this will only work for 
# spheres, cylinders etc.
@onready var attack_range_sqr: float = Utils.sqr(attack_area_coll.shape.radius) if attack_area_coll else 0

@export var init_hp: float = 100.0
@onready var health: Health = Health.new(init_hp)

# If multiple units are in range of an AI-controlled unit, this number decides 
# which unit is picked as target (highest is picked)
# For example:
# 0 = walls (only attack if no other target in sight)
# 1 = critical infrastructure (only attack if no units which could shoot back are in sight)
# 2 = turrets, regular units
@export var target_priority: int = 2

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
	# Note: get_overlapping_bodies() sometimes returns nodes that are out
	# of range (not sure why). It seems to mostly happens with units that have
	# just been spawned, e.g. nanites coming out of the portal.
	# So we need make sure they are actually in range.
	var maybe_in_range: Array[Node3D] = attack_area.get_overlapping_bodies()
	
	var min_dist_sqr: float = 999999999.0
	var result: Node3D = null
	for node in maybe_in_range:
		if not node.is_in_group(group):
			continue
		
		var dist_sqr: float = (node.global_position - global_position).length_squared()
		
		if dist_sqr < min_dist_sqr and dist_sqr < attack_range_sqr:
			result = node
			min_dist_sqr = dist_sqr
	
	return result

# Returns the closest unit with highest priority in range
# group: for example "faction: nanite"
# default_target: target to pick when no unit of equal or higher priority is in range
func get_unit_as_target(group: String, default_target: Unit) -> Unit:
	# Note: get_overlapping_bodies() sometimes returns nodes that are out
	# of range (not sure why). It seems to mostly happens with units that have
	# just been spawned, e.g. nanites coming out of the portal.
	# So we need make sure they are actually in range.
	var maybe_in_range: Array[Node3D] = attack_area.get_overlapping_bodies()
		
	var highest_priority: int = -1
	if default_target:
		highest_priority = default_target.target_priority
	
	var min_dist_sqr: float = 999999999.0
	var target: Unit = null
	for node in maybe_in_range:
		if not node.is_in_group(group):
			continue
			
		var unit = node as Unit
		if not unit:
			continue
		
		if unit.target_priority < highest_priority:
			continue
		
		var dist_sqr: float = (node.global_position - global_position).length_squared()
		
		if dist_sqr < min_dist_sqr and dist_sqr < attack_range_sqr:
			target = unit
			min_dist_sqr = dist_sqr
			highest_priority = unit.target_priority
	
	if not target:
		target = default_target
	
	return target
