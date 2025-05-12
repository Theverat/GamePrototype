extends Node3D

@export var enabled: bool = true
@export var unit_to_spawn: PackedScene = null
@export var interval_sec: float = 2.0
@export var radius: float = 1.0

var last_spawn_time: float = 0

func _ready() -> void:
	if not enabled and unit_to_spawn:
		print("Info: Spawner disabled (Unit: ", unit_to_spawn.get_path(), ")")

func _process(delta: float) -> void:
	assert(unit_to_spawn)
	assert(interval_sec > 0)
	assert(radius > 0)
	
	if not enabled:
		return
	
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - last_spawn_time > interval_sec:
		last_spawn_time = now
		var instance: Node3D = unit_to_spawn.instantiate() as Node3D
		var pos: Vector3 = global_position
		
		var rand_radius: float = randf_range(0, radius)
		var rand_angle: float = randf_range(-PI, PI)
		var offset: Vector3 = Vector3(cos(rand_angle), 0, sin(rand_angle)) * rand_radius
		
		get_tree().root.add_child(instance)
		instance.global_position = pos + offset
