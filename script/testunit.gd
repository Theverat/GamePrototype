extends PathingUnit

#static func sqr(value: float) -> float:
	#return value * value

@onready var mesh: MeshInstance3D = $Synth_v_0_1/Armature/Skeleton3D/Ch50
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
	var elapsed = Time.get_ticks_msec()
	
	if (target == null
			or (elapsed - last_target_search_ms) > target_search_interval_ms):
		assert(false, "TODO do we still need this script?")
		#var closest_enemy: Node3D = UnitUtils.find_closest_unit(self, "faction: human")
		#set_target(closest_enemy)
		last_target_search_ms = elapsed
		
	if target:
		# Check if we are in attack range
		var dist_sqr: float = distance_sqr_to(target)
		
		if dist_sqr < attack_dist_sqr:
			pass
			#var health: Health = UnitUtils.get_health_module(target)
			#if health:
				#if elapsed - last_damage_ms > damage_interval_ms:
					#last_damage_ms = elapsed
					#health.deal_damage(damage)					
					#
					#if health.is_dead():
						## TODO the unit with health should probably delete itself 
						## when hp go to 0 (maybe do it in Health?)
						#target.queue_free()
						#set_target(null)
