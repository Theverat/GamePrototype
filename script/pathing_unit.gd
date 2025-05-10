extends CharacterBody3D
class_name PathingUnit

@export var nav_agent: NavigationAgent3D
@export var turn_speed: float = 4

# A target node we are trying to follow
var follow_target: Node3D = null

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if follow_target:
		set_movement_target(follow_target.global_position)
		
	move(delta)
	
func set_movement_target(point: Vector3) -> void:
	nav_agent.set_target_position(point)
	
func follow(target: Node3D) -> void:
	follow_target = target
	
func move(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		return
		
	var next_position: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = global_position.direction_to(next_position)
	rotate_to(direction, delta)
	
	velocity = direction * nav_agent.max_speed
	
	var pos: Vector3 = global_position
	#global_position += velocity * delta
	nav_agent.set_velocity(velocity)
	move_and_slide()

func rotate_to(dir: Vector3, delta: float) -> void:
	var pos_2D: Vector2 = Vector2(-transform.basis.z.x, -transform.basis.z.z)
	var goal_2D: Vector2 = Vector2(dir.x, dir.z)
	rotation.y -= pos_2D.angle_to(goal_2D) * delta * turn_speed
