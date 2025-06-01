extends Unit
class_name PathingUnit

@export var body: CharacterBody3D
@export var nav_agent: NavigationAgent3D
@export var turn_speed: float = 4
@export var max_dist_to_target: float = 100.0
var frame = 0

# A target node we are trying to follow
var target: Node3D = null
@onready var max_dist_to_target_sqr: float = Utils.sqr(max_dist_to_target)
# Target that is used if no other targets are in a certain range
var default_target: Node3D = null
# Max allowed squared distance between target's current position and
# nav_agent.target_position before a new path has to be computed.
# This is used to improve perfomrance by minimizing path updates (if the unit 
# we are following has barely moved, we don't need to find a new path)
var new_path_distsqr_thresh: float = Utils.sqr(3)

func _ready() -> void:
	super()
	assert(body)
	assert(nav_agent)

func _process(delta: float) -> void:
	super(delta)

func _physics_process(delta: float) -> void:
	super(delta)
	if target:
		# Check if the target has moved so far from its original position
		# that we need to recompute the path
		var target_pos: Vector3 = target.global_position
		var target_pos_diff: float = target_pos.distance_squared_to(nav_agent.target_position)
		if target_pos_diff > new_path_distsqr_thresh:
			set_movement_target(target_pos)
		
	move(delta)
	
func set_movement_target(point: Vector3) -> void:
	print("Expensive: nav_agent.set_target_position()")
	nav_agent.set_target_position(point)
	
func set_target(new_target: Node3D) -> void:	
	if default_target:
		# We have a fallback and should check if the new target 
		# is inside the allowed range
		if new_target and distance_sqr_to(new_target) < max_dist_to_target_sqr:
			target = new_target
		else:
			target = default_target
	else:
		# No fallback, so just use the given target
		target = new_target
	
func get_target() -> Node3D:
	return target
	
func set_default_target(new_target: Node3D) -> void:
	default_target = new_target
	
func get_default_target() -> Node3D:
	return default_target
	
func move(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		return
		
	var next_position: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = global_position.direction_to(next_position)
	rotate_to(direction, delta)
	
	body.velocity = direction * nav_agent.max_speed
	
	var pos: Vector3 = global_position
	#global_position += velocity * delta
	nav_agent.set_velocity(body.velocity)
	body.move_and_slide()

func rotate_to(dir: Vector3, delta: float) -> void:
	var pos_2D: Vector2 = Vector2(-transform.basis.z.x, -transform.basis.z.z)
	var goal_2D: Vector2 = Vector2(dir.x, dir.z)
	rotation.y -= pos_2D.angle_to(goal_2D) * delta * turn_speed

func distance_to(node: Node3D) -> float:
	return global_position.distance_to(node.global_position)
	
func distance_sqr_to(node: Node3D) -> float:
	return global_position.distance_squared_to(node.global_position)
