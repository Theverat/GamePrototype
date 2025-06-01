extends Unit
class_name Turret

@export var center_pillar: Node3D = null
@export var gun_barrel: Node3D = null
# Bullets for hitscan turrets (e.g. gatling, railgun)
# Can be null for turrets without hitscan (e.g. rocket)
@export var hitscan_bullets: MeshInstance3D = null
@export var particle_bullets: GPUParticles3D = null
@export var particle_hitpoint: GPUParticles3D = null
@export var muzzleflash_light: OmniLight3D = null
@export var raycaster: RayCast3D = null
@export var damage_tick_interval_sec: float = 1.0 / 30.0  # TODO use
@export var damage_per_tick: float = 1.0
@export var rotation_speed: float = 7.0
@onready var gatling_fire_sound: AudioStreamPlayer3D = $"SFX shoot"

var target_pos: Vector3 = Vector3.ZERO
var target: Node3D = null

func _ready() -> void:
	super()
	assert(gatling_fire_sound)
	raycaster.add_exception(self as CollisionObject3D)

func _process(delta: float) -> void:
	super(delta)
	
	update_target()	
	rotate_center_pillar_to_target(delta)
	rotate_gun_barrel(delta)
	
	if hitscan_bullets:
		fire_hitscan(delta)

func update_target() -> void:
	if not target or not attack_area.overlaps_body(target):
		# No target yet, or target moved out of range
		target = get_closest_node_in_range("faction: nanite")
		
	if target:
		target_pos = target.global_position
	else:
		# Could not find a target, make gun barrel rotate to resting position
		target_pos = global_position + Vector3(10, 0, 0)

func rotate_center_pillar_to_target(delta: float) -> void:
	assert(center_pillar)
	var dir = target_pos - center_pillar.global_position
	var dir2d = -Vector2(dir.x, dir.z).normalized()
	var target_angle = atan2(dir2d.x, dir2d.y)

	var rot: float = center_pillar.global_rotation.y
	center_pillar.global_rotation.y = rotate_toward(rot, target_angle,
												   rotation_speed * delta)

# Elevation
func rotate_gun_barrel(delta: float) -> void:
	assert(gun_barrel)
	var pos: Vector3 = gun_barrel.global_position
	var to_target: Vector3 = target_pos - pos
	var a: float = target_pos.y - pos.y
	var c: float = to_target.length()
	var alpha: float = asin(a / c)
	gun_barrel.rotation.x = alpha

func fire_hitscan(delta: float) -> void:
	assert(hitscan_bullets)
	assert(gun_barrel)
	assert(raycaster)
	# Firing ist true, wenn ein Ziel da und in Reichweite ist
	var firing: bool = target != null

	hitscan_bullets.visible = false
	raycaster.enabled = firing

	# Light
	var flash_on: bool = sin(Utils.elapsedSec() * 2000) > 0
	muzzleflash_light.visible = firing and flash_on

	# Partikel kontrollieren
	particle_bullets.amount_ratio = 1 if firing else 0
	particle_bullets.visible = firing
	particle_hitpoint.visible = firing

	if firing:
		# Sound
		if (not gatling_fire_sound.playing
				or gatling_fire_sound.get_playback_position() > 0.035):
			gatling_fire_sound.play()

		var collider: Object = null
		if raycaster.is_colliding():
			collider = raycaster.get_collider()

		if collider:
			# Show bullets (nur wenn tatsächlich ein Hitscan-Mesh verwendet wird)
			if hitscan_bullets:
				var hitPos: Vector3 = raycaster.get_collision_point()
				var pos: Vector3 = hitscan_bullets.global_position
				var target_dist: float = (hitPos - pos).length()
				hitscan_bullets.scale = Vector3(1, target_dist, 1)
				var mat: ShaderMaterial = hitscan_bullets.mesh.surface_get_material(0) as ShaderMaterial
				mat.set_shader_parameter("lengthY", target_dist)

			var unit: Unit = collider as Unit
			if unit:
				unit.health.apply_damage(damage_per_tick)
			
	else:  # Not firing
		if gatling_fire_sound.playing:
			gatling_fire_sound.stop()
