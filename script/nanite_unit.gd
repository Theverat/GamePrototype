extends PathingUnit
class_name NaniteUnit

@onready var mesh: MeshInstance3D = $Nanite_MeshInstance3D
@onready var mat: ShaderMaterial = mesh.mesh.surface_get_material(0) as ShaderMaterial
var defaultColor: Color = Color(0.0, 0.3, 1.0)
var attackColor: Color = Color(1.0, 0.2, 0.0)

@export var target_search_interval_ms: int = 1000
var last_target_search_ms: int = 0

@export var attack_dist: float = 5
@onready var attack_dist_sqr: float = Utils.sqr(attack_dist)
@export var damage_interval_ms: int = 500
@export var damage: float = 50
var last_damage_ms: int = 0

func _ready() -> void:
	super()

func _process(delta: float) -> void:
	super(delta)
	
	var elapsed = Time.get_ticks_msec()
	if elapsed - last_damage_ms < damage_interval_ms:
		# Has attacked
		mesh.set_instance_shader_parameter("spikeColor", attackColor)
		mesh.set_instance_shader_parameter("spikeBrightness", 20.0)
	else:
		# Not attacking
		mesh.set_instance_shader_parameter("spikeColor", defaultColor)
		mesh.set_instance_shader_parameter("spikeBrightness", 0.1)
		

func _physics_process(delta: float) -> void:
	super(delta)
	var elapsed_ms: int = Time.get_ticks_msec()
	
	if (not target
			or (elapsed_ms - last_target_search_ms) > target_search_interval_ms):
		#var closest_enemy: Node3D = UnitUtils.find_closest_unit(self, "faction: human")
		#set_target(closest_enemy)
		set_target(get_unit_as_target("faction: human", default_target))
		last_target_search_ms = elapsed_ms
	
	maybe_deal_damage(elapsed_ms)

# Deal damage if possible (enemy has health and attack cooldown has passed)
func maybe_deal_damage(elapsed_ms: int) -> void:
	if not target:
		return
	if elapsed_ms - last_damage_ms < damage_interval_ms:
		# Attack still on cooldown
		return
	if not attack_area.overlaps_body(target):
		# Out of range
		return
	
	var unit: Unit = target as Unit
	if unit:
		unit.health.apply_damage(damage)
		last_damage_ms = elapsed_ms
