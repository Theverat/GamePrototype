extends Node

@export var gatling_turret_scene: PackedScene = null
@export var top_down_cam: TopDownCamera = null

var scene_to_place: PackedScene = null
var instance: Node3D = null

func _ready():
	$UI/AddGatlingTurret.pressed.connect(_add_gatling_turret_pressed)
	
func _process(delta: float) -> void:
	if scene_to_place:
		if instance == null:
			start_placement()
		
		var pos: Vector3 = Vector3(30, 0, 30)
		# Cast ray into scene and find hitpoint
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()		
		var camera: Camera3D = top_down_cam.camera
		var raycaster: RayCast3D = top_down_cam.raycaster
		var ray_length: float = 100
				
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * ray_length
		pos = to
		
		#raycaster.global_position = from
		#raycaster.target_position = raycaster.to_local(to)
		#
		##raycaster.target_position = camera.project_local_ray_normal(mouse_pos) * ray_length
		##print(raycaster.target_position)
		#
		##var from = camera.project_ray_origin(mouse_pos)
		##var to = from + camera.project_ray_normal(mouse_pos) * ray_length
		#raycaster.enabled = true
		#if raycaster.is_colliding():
			#print("colliding")
			#pos = raycaster.get_collision_point()
		#raycaster.enabled = false
		
		# TODO still does not work
		var exclude: Array[RID] = []
		for child: Node in instance.find_children("*", "CollisionShape3D"):
			var as_coll = child as CollisionShape3D
			var name = child.name  # TODO remove
			if as_coll:
				exclude.push_back(as_coll.shape.get_rid())
		
		var hit: UnitUtils.HitResult = UnitUtils.raycast(instance, from, to, exclude)
		
		if hit:
			pos = hit.position
		
		instance.global_position = pos
		
		if Input.is_action_pressed("accept"):
			# Finalize placement
			end_placement()
		elif Input.is_action_pressed("cancel"):
			# Cancel placement
			instance.queue_free()
			end_placement()
			
func start_placement():
	instance = scene_to_place.instantiate() as Node3D
	add_child(instance)
	
func end_placement():
	scene_to_place = null
	instance = null

func _add_gatling_turret_pressed():
	assert(gatling_turret_scene)
	scene_to_place = gatling_turret_scene
	
	#var instance: Node3D = gatling_turret_scene.instantiate() as Node3D
	#add_child(instance)
	#instance.global_position = Vector3(30, 0, 30)
