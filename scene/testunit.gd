extends CharacterBody3D

const module_camera:GDScript = preload("res://script/module_camera.gd")

var steer_speed:float = 4
var nav_path_goal_position:Vector3


@onready var nav_agent:NavigationAgent3D = $NavigationAgent3D
@onready var nav_path_timer:Timer = $Timer

var rotation_fast:bool = false

func _ready() -> void:
	nav_agent.velocity_computed.connect(char_move)
	nav_path_timer.timeout.connect(nav_path_timer_update)
	deselect()
	
	
# LeftClick to CameraLocation
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("mouse_leftclick"):
		var mouse_pos:Vector2 = get_viewport().get_mouse_position()
		var camera:Camera3D = get_viewport().get_camera_3d()
		var camera_raycast_coords:Vector3 = module_camera.get_vector3_from_camera_raycast(camera,mouse_pos)
		if camera_raycast_coords != Vector3.ZERO:
			nav_agent.set_target_position(camera_raycast_coords)
			nav_path_goal_position = camera_raycast_coords
	
func _physics_process(delta: float) -> void:
	if nav_agent.is_navigation_finished():return
	
	var next_position:Vector3 = nav_agent.get_next_path_position()
	
	var direction:Vector3 = global_position.direction_to(next_position) * nav_agent.max_speed
	rotation_to_direction(direction, delta)
	var steer_velocity:Vector3 = (direction - velocity) * delta * steer_speed
	var new_agent_velocity:Vector3 = velocity + steer_velocity
	nav_agent.set_velocity(new_agent_velocity)

func rotation_to_direction(dir:Vector3, delta:float) -> void:
	if rotation_fast:
		rotation.y = atan2(-dir.x,-dir.z)
	else:
		var pos_2D:Vector2 = Vector2(-transform.basis.z.x, -transform.basis.z.z)
		var goal_2D:Vector2 = Vector2(dir.x,dir.z)
		rotation.y -= pos_2D.angle_to(goal_2D) *delta * steer_speed
		

func nav_path_timer_update() -> void:
	if nav_agent.is_navigation_finished():return
	nav_agent.set_target_position(nav_path_goal_position)

func char_move(new_velocity:Vector3) -> void:
	velocity = new_velocity
	move_and_slide()


func selected() -> void:
	$selected.visible = true


func deselect() -> void:
	$selected.visible = false
