extends Node3D

@export
var unit_to_spawn: PackedScene = null
@export
var interval_sec: float = 2

var last_spawn_time: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	assert(unit_to_spawn)
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - last_spawn_time > interval_sec:
		last_spawn_time = now
		var instance: Node3D = unit_to_spawn.instantiate() as Node3D
		instance.global_transform = global_transform
		get_tree().root.add_child(instance)
