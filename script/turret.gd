#@tool
extends Node3D

@export
var center_pillar: Node3D = null
@export
var gun_barrel: Node3D = null
# Bullets for hitscan turrets (e.g. gatling, railgun)
# Can be null for turrets without hitscan (e.g. rocket)
@export
var hitscan_bullets: MeshInstance3D = null

var rotation_speed: float = 5.0
var target: Vector3 = Vector3.ZERO
var target_enemy: Node3D = null

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	choose_target()
	rotate_center_pillar_to_target(delta)
	rotate_gun_barrel(delta)
	if hitscan_bullets:
		fire_hitscan(delta)
	
func choose_target() -> void:
	if not is_instance_valid(target_enemy):
		# Target enemy dead, choose a new one
		target_enemy = null
		var enemies: Array[Node] = get_tree().get_nodes_in_group("faction: nanite")
		
		var min_dist_sqr: float = 99999999.0
		for enemy_node: Node in enemies:
			var enemy: Node3D = enemy_node as Node3D
			assert(enemy is Node3D)
			
			if is_instance_valid(enemy) and enemy.is_inside_tree():
				assert(get_tree() == enemy.get_tree())
				var dist_sqr: float = (enemy.global_position - global_position).length_squared()
				if dist_sqr < min_dist_sqr:
					min_dist_sqr = dist_sqr
					target_enemy = enemy
		
		#if target_enemy:
			#print("Picked new enemy:", target_enemy.name)
	
	if target_enemy:
		# Target enemy still alive, track it
		target = target_enemy.global_position

func rotate_center_pillar_to_target(delta: float) -> void:
	assert(center_pillar)
		
	var dir = target - center_pillar.global_position
	var dir2d = -Vector2(dir.x, dir.z).normalized()
	var target_angle = atan2(dir2d.x, dir2d.y)
	
	var rot: float = center_pillar.global_rotation.y
	center_pillar.global_rotation.y = rotate_toward(rot, target_angle, 
												   rotation_speed * delta)

# Elevation
func rotate_gun_barrel(delta: float) -> void:
	assert(gun_barrel)
	# TODO
	
	## We know that we are already pointing at the target in XZ, only the elevation
	## is missing
	#var dir = target - gun_barrel.global_position
	#var dir2d = Vector2(dir.y, -dir.z).normalized()  # TODO -?
	#var target_angle = atan2(dir2d.x, dir2d.y)
	#
	#var rot: float = gun_barrel.rotation.x
	#gun_barrel.rotation.x = rotate_toward(rot, target_angle, 
										 #rotation_speed * delta)
	
func fire_hitscan(delta: float) -> void:
	assert(hitscan_bullets)
	var firing: bool = target_enemy != null
	hitscan_bullets.visible = firing
	
	if firing:
		var pos: Vector3 = hitscan_bullets.global_position
		var target_dist: float = (target - pos).length()
		# Scale to stretch the bullet trail from gun to target
		hitscan_bullets.scale = Vector3(1, target_dist, 1)
		# Pass distance to shader, so it can avoid stretching the texture
		var mat: ShaderMaterial = hitscan_bullets.mesh.surface_get_material(0) as ShaderMaterial
		mat.set_shader_parameter("lengthY", target_dist)
