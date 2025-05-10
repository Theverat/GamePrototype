extends PathingUnit

#static func sqr(value: float) -> float:
	#return value * value

#@onready var mesh: MeshInstance3D = $MeshInstance3D
#@onready var mat: ShaderMaterial = mesh.mesh.surface_get_material(0) as ShaderMaterial
#var defaultColor: Color = Color(0.0, 0.3, 1.0)
#var attackColor: Color = Color(1.0, 0.2, 0.0)
#var attackDistSqr: float = sqr(10.0)

func _ready() -> void:
	super()

func _process(delta: float) -> void:
	super(delta)
	
	# This works
	#mat.set_shader_parameter("spikeColor", attackColor)
	#mat.set_shader_parameter("spikeBrightness", 16.0)
	
	#if follow_target:
		## TODO for some reason this does not work
		#var dist_sqr: float = global_position.distance_squared_to(follow_target.global_position)
		#var attack_fac = clamp(attackDistSqr - dist_sqr, 0.0, attackDistSqr) / attackDistSqr;
		#var color: Color = defaultColor.lerp(attackColor, attack_fac)
		#mat.set_shader_parameter("spikeColor", color)
		#var brightness: float = attack_fac * 20.0;
		#mat.set_shader_parameter("spikeBrightness", brightness)
		

func _physics_process(delta: float) -> void:
	super(delta)
	var closest_enemy: Node3D = UnitUtils.find_closest_unit(self, "faction: human")
	follow(closest_enemy)
