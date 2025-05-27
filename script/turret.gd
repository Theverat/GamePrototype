#@tool
extends Node3D

@export var center_pillar: Node3D = null
@export var gun_barrel: Node3D = null
# Bullets for hitscan turrets (e.g. gatling, railgun)
# Can be null for turrets without hitscan (e.g. rocket)
@export var hitscan_bullets: MeshInstance3D = null
@export var particle_bullets: GPUParticles3D = null
@export var particle_hitpoint: GPUParticles3D = null
@export var muzzleflash_light: OmniLight3D = null
@export var raycaster: RayCast3D = null
@export var damage_tick_interval_sec: float = 1.0 / 30.0
@export var damage_per_tick: float = 1.0
@export var rotation_speed: float = 7.0
@export var attack_range: float = 150.0 # NEU: Maximale Angriffsreichweite
@onready var gatling_fire_sound: AudioStreamPlayer3D = $"SFX shoot"

var target: Vector3 = Vector3.ZERO
var target_enemy: Node3D = null
var current_target_in_range: bool = false # NEU: Flag für Reichweite

func _ready() -> void:
	assert(gatling_fire_sound)
	assert(attack_range > 0, "Attack range must be greater than 0.") # Zusätzlicher Assert

func _process(delta: float) -> void:
	choose_target()
	rotate_center_pillar_to_target(delta)
	rotate_gun_barrel(delta)
	# Feuer nur, wenn ein Ziel innerhalb der Reichweite ist
	if current_target_in_range and hitscan_bullets:
		fire_hitscan(delta)
	else:
		# Sicherstellen, dass Sound und Effekte stoppen, wenn kein Ziel in Reichweite
		if gatling_fire_sound.playing:
			gatling_fire_sound.stop()
		muzzleflash_light.visible = false
		particle_bullets.amount_ratio = 0
		particle_bullets.visible = false # HIER: Partikel-Node unsichtbar machen wenn nicht gefeuert wird
		particle_hitpoint.visible = false # HIER: Hitpoint-Partikel unsichtbar machen


func choose_target() -> void:
	var target_valid: bool = is_instance_valid(target_enemy)
	current_target_in_range = false # Setze die Reichweite-Flag zurück

	if target_valid:
		var target_health: Health = UnitUtils.get_health_module(target_enemy)
		if target_health:
			if target_health.is_dead():
				target_valid = false
				target_enemy.queue_free()
				target_enemy = null
			else:
				# NEU: Überprüfen, ob das aktuelle Ziel noch in Reichweite ist
				var dist_sqr: float = (target_enemy.global_position - global_position).length_squared()
				if dist_sqr <= attack_range * attack_range: # Quadratische Distanz für Effizienz
					current_target_in_range = true
				else:
					target_valid = false # Ziel ist außerhalb der Reichweite, wähle neues

	if not target_valid:
		target_enemy = null
		var enemies: Array[Node] = get_tree().get_nodes_in_group("faction: nanite")

		var min_dist_sqr: float = 99999999.0
		var best_enemy: Node3D = null

		for enemy_node: Node in enemies:
			var enemy: Node3D = enemy_node as Node3D
			assert(enemy is Node3D)

			if is_instance_valid(enemy) and enemy.is_inside_tree():
				assert(get_tree() == enemy.get_tree())
				var dist_sqr: float = (enemy.global_position - global_position).length_squared()
				if dist_sqr < min_dist_sqr and dist_sqr <= attack_range * attack_range: # NEU: Nur Gegner in Reichweite betrachten
					min_dist_sqr = dist_sqr
					best_enemy = enemy

		target_enemy = best_enemy
		if target_enemy:
			current_target_in_range = true # Neues Ziel ist in Reichweite

	if target_enemy:
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
	# Drehe nur, wenn ein Ziel vorhanden ist
	if target_enemy:
		var pos: Vector3 = gun_barrel.global_position
		var to_target: Vector3 = target - pos
		var a: float = target.y - pos.y
		var c: float = to_target.length()
		var alpha: float = asin(a / c)
		gun_barrel.rotation.x = alpha
	else:
		gun_barrel.rotation.x = 0.0 # Setze die Kanone auf eine Standardposition zurück

func fire_hitscan(delta: float) -> void:
	assert(hitscan_bullets)
	assert(gun_barrel)
	assert(raycaster)
	# Firing ist true, wenn ein Ziel da und in Reichweite ist
	var firing: bool = target_enemy != null and current_target_in_range

	hitscan_bullets.visible = false
	raycaster.enabled = firing

	# Light
	var flash_on: bool = sin(Utils.elapsedSec() * 2000) > 0
	muzzleflash_light.visible = firing and flash_on

	# Partikel kontrollieren
	particle_bullets.amount_ratio = 1 if firing else 0
	particle_bullets.visible = firing # HIER: Sichtbarkeit des Partikel-Nodes an Firing koppeln
	particle_hitpoint.visible = firing # HIER: Sichtbarkeit des Hitpoint-Partikels an Firing koppeln

	if firing:
		# Sound
		if (not gatling_fire_sound.playing
				or gatling_fire_sound.get_playback_position() > 0.035):
			gatling_fire_sound.play()

		var collider: Object = null
		if raycaster.is_colliding():
			collider = raycaster.get_collider()

		if collider:
			var hitPos: Vector3 = raycaster.get_collision_point()

			# Show bullets (nur wenn tatsächlich ein Hitscan-Mesh verwendet wird)
			if hitscan_bullets:
				var pos: Vector3 = hitscan_bullets.global_position
				var target_dist: float = (hitPos - pos).length()
				hitscan_bullets.scale = Vector3(1, target_dist, 1)
				var mat: ShaderMaterial = hitscan_bullets.mesh.surface_get_material(0) as ShaderMaterial
				mat.set_shader_parameter("lengthY", target_dist)

			# Do damage
			var colliderNode: Node3D = collider as Node3D
			if colliderNode:
				var health: Health = UnitUtils.get_health_module(colliderNode)
				if health:
					health.deal_damage(damage_per_tick)
	else:  # Not firing
		if gatling_fire_sound.playing:
			gatling_fire_sound.stop()
		muzzleflash_light.visible = false
		# Die Partikel werden bereits im _process else Block ausgeschaltet,
		# daher hier nicht nochmal nötig.
