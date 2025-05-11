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
@export
var damage_tick_interval_sec: float = 1.0 / 30.0
var damage_per_tick: float = 1.0

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
	var target_valid: bool = is_instance_valid(target_enemy)
	
	if target_valid:
		var target_health: Health = get_health_module(target_enemy)
		if target_health:
			if target_health.is_dead():
				target_valid = false
				# TODO the unit with health should probably delete itself when
				# hp go to 0 (maybe do it in Health?)
				target_enemy.queue_free()
				target_enemy = null
	
	if not target_valid:
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
	var pos: Vector3 = gun_barrel.global_position
	var to_target: Vector3 = target - pos	
	var a: float = target.y - pos.y
	var c: float = to_target.length()
	var alpha: float = asin(a / c)
	gun_barrel.rotation.x = alpha
	
func fire_hitscan(delta: float) -> void:
	assert(hitscan_bullets)
	assert(gun_barrel)
	var firing: bool = target_enemy != null
	hitscan_bullets.visible = firing
	
	if firing:
		var pos: Vector3 = hitscan_bullets.global_position
		var to_target = target - pos
		
		var from: Vector3 = gun_barrel.global_position
		var to: Vector3 = to_target * 1000
		var exclude: Array[RID] = []
		var hit: UnitUtils.HitResult = UnitUtils.raycast(self, from, to, exclude)
		
		if hit:
			print("hit: ", hit.collider.name, "(hit target: ", hit.collider == target_enemy, ")")
			
			# Show bullets
			var target_dist: float = (hit.position - pos).length()
			# Scale to stretch the bullet trail from gun to target
			hitscan_bullets.scale = Vector3(1, target_dist, 1)
			# Pass distance to shader, so it can avoid stretching the texture
			var mat: ShaderMaterial = hitscan_bullets.mesh.surface_get_material(0) as ShaderMaterial
			mat.set_shader_parameter("lengthY", target_dist)
			
			if not Engine.is_editor_hint():
				# Do damage
				var collider: Object = hit.collider
				var colliderNode: Node3D = collider as Node3D
				if colliderNode:
					var health: Health = get_health_module(colliderNode)
					
					# TODO damage tick interval
					if health:
						health.deal_damage(damage_per_tick)

static func get_health_module(node: Node3D) -> Health:
	# TODO use get_node()?
	return node.find_child("Health", false) as Health
