@tool
extends Node3D

@export
var center_pillar: Node3D = null
var gun_barrel: Node3D = null

var rotation_speed: float = 50
var target: Vector3 = Vector3.ZERO
var target_enemy: Node3D = null

func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	choose_target()
	rotate_center_pillar_to_target(delta)
	
	
func choose_target() -> void:	
	if target_enemy == null:
		# Target enemy dead, choose a new one
		var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
		
		var min_dist_sqr: float = 99999999.0
		for enemy_node: Node in enemies:
			var enemy: Node3D = enemy_node as Node3D
			assert(enemy is Node3D)
			
			var dist_sqr: float = (enemy.global_position - global_position).length_squared()
			if dist_sqr < min_dist_sqr:
				min_dist_sqr = dist_sqr
				target_enemy = enemy
	
	if target_enemy:
		# Target enemy still alive, track it
		target = target_enemy.global_position


func rotate_center_pillar_to_target(delta: float) -> void:
	assert(center_pillar)

	var curr_dir = -global_transform.basis.z
	var curr_dir2d = Vector2(curr_dir.x, curr_dir.z).normalized()
	var curr_angle = atan2(curr_dir2d.x, curr_dir2d.y)
		
	var dir = target - global_position
	var dir2d = -Vector2(dir.x, dir.z).normalized()
	var target_angle = atan2(dir2d.x, dir2d.y)
	
	#var target_angle = turret.global_position.angle_to_point(get_global_mouse_position()) + PI/2.0
	center_pillar.global_rotation.y = rotate_toward(center_pillar.global_rotation.y, target_angle, rotation_speed * delta)
