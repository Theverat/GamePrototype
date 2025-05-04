extends CharacterBody3D

const MODULE_CAMERA: GDScript = preload("res://script/module_camera.gd")

@export var steer_speed: float = 4
@export var nav_path_goal_position: Vector3
@export var squad_width: int = 10
@export var squad_height: int = 10
@export var unit_scene: PackedScene
@export var waypoint_path: NodePath

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var nav_path_timer: Timer = $Timer
@onready var animation_player: AnimationPlayer = $"Synth_v_0_1/AnimationPlayer"

var rotation_fast: bool = false
var squad_members: Array[CharacterBody3D] = []

func _ready() -> void:
	if GameEvents.has_signal("spawn_squad_requested"):
		GameEvents.spawn_squad_requested.connect(_on_spawn_requested)
	nav_agent.velocity_computed.connect(char_move)
	nav_path_timer.timeout.connect(nav_path_timer_update)
	deselect()



func create_squad() -> void:
	if not is_instance_valid(self):
		return

	
	# Wait until the waypoint node is properly available
	await get_tree().process_frame
	
	var waypoint_node = get_node_or_null(waypoint_path)
	if not waypoint_node or not is_instance_valid(waypoint_node):
		#printerr("Waypoint Node nicht gefunden! Bitte im Inspector zuweisen.")
		return
	
	# Additional safety check
	if not waypoint_node.is_inside_tree():
		printerr("Waypoint Node ist nicht im Szenenbaum!")
		return

	var base_position: Vector3 = waypoint_node.global_position
	var spacing: float = 2.0
	
	for x in range(squad_width):
		for y in range(squad_height):
			var new_unit_instance = unit_scene.instantiate() as CharacterBody3D
			if not is_instance_valid(new_unit_instance):
				printerr("Fehler: Instanzierung der Unit-Szene fehlgeschlagen.")
				continue
			
			var unit_position = base_position + Vector3(x * spacing, 0, y * spacing)
			get_parent().add_child(new_unit_instance)  # Add to parent instead of self
			new_unit_instance.global_position = unit_position
			new_unit_instance.name = "SquadUnit_" + str(x) + "_" + str(y)
			squad_members.append(new_unit_instance)
			
			# NavAgent für jede Unit initialisieren
			var unit_nav_agent = NavigationAgent3D.new()
			new_unit_instance.add_child(unit_nav_agent)
			unit_nav_agent.path_max_distance = nav_agent.path_max_distance
			unit_nav_agent.max_speed = nav_agent.max_speed
			#unit_nav_agent.max_acceleration = nav_agent.max_acceleration
			#unit_nav_agent.max_velocity = nav_agent.max_velocity
			unit_nav_agent.navigation_layers = nav_agent.navigation_layers

func delete_squad() -> void:
	for unit in squad_members:
		if is_instance_valid(unit):
			unit.queue_free()
	squad_members.clear()


func _on_spawn_requested():
	call_deferred("create_squad")  # Deine bestehende Squad-Erstellungsfunktion
	print("Squad gespawnt über UI-Button!")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("mouse_leftclick"):
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var camera: Camera3D = get_viewport().get_camera_3d()
		var camera_raycast_coords: Vector3 = MODULE_CAMERA.get_vector3_from_camera_raycast(camera, mouse_pos)
		if camera_raycast_coords != Vector3.ZERO:
			for unit in squad_members:
				if is_instance_valid(unit) && unit.has_node("NavigationAgent3D"):
					var unit_nav_agent: NavigationAgent3D = unit.get_node("NavigationAgent3D") as NavigationAgent3D
					if is_instance_valid(unit_nav_agent):
						unit_nav_agent.set_target_position(camera_raycast_coords)
						unit.nav_path_goal_position = camera_raycast_coords

			nav_agent.set_target_position(camera_raycast_coords)
			nav_path_goal_position = camera_raycast_coords

func _physics_process(delta: float) -> void:
	var original_position: Vector3 = global_position
	update_animation()
	
	if nav_agent.is_navigation_finished():
		global_position = original_position
		return
	
	var next_position: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = global_position.direction_to(next_position) * nav_agent.max_speed
	rotation_to_direction(direction, delta)
	var steer_velocity: Vector3 = (direction - velocity) * delta * steer_speed
	var new_agent_velocity: Vector3 = velocity + steer_velocity
	nav_agent.set_velocity(new_agent_velocity)

	for unit in squad_members:
		if is_instance_valid(unit) && unit.has_node("NavigationAgent3D"):
			var unit_nav_agent: NavigationAgent3D = unit.get_node("NavigationAgent3D") as NavigationAgent3D
			if is_instance_valid(unit_nav_agent):
				var unit_next_position = unit_nav_agent.get_next_path_position()
				var unit_direction = unit.global_position.direction_to(unit_next_position) * unit_nav_agent.max_speed
				unit.rotation_to_direction(unit_direction, delta) # Assuming you have this on the unit.
				var unit_steer_velocity = (unit_direction - unit.velocity) * delta * steer_speed # Assuming steer_speed
				var unit_new_velocity = unit.velocity + unit_steer_velocity
				unit_nav_agent.set_velocity(unit_new_velocity)
				unit.velocity = unit_new_velocity
				unit.move_and_slide()

func rotation_to_direction(dir: Vector3, delta: float) -> void:
	if rotation_fast:
		rotation.y = atan2(-dir.x, -dir.z)
	else:
		var pos_2D: Vector2 = Vector2(-transform.basis.z.x, -transform.basis.z.z)
		var goal_2D: Vector2 = Vector2(dir.x, dir.z)
		rotation.y -= pos_2D.angle_to(goal_2D) * delta * steer_speed

func update_animation() -> void:
	if not animation_player:
		return
	
	if not nav_agent.is_navigation_finished():
		if animation_player.current_animation != "Run":
			animation_player.play("Run")
	else:
		if animation_player.current_animation != "Idle":
			if animation_player.has_animation("Idle"):
				animation_player.play("Idle")
			else:
				animation_player.stop()

func nav_path_timer_update() -> void:
	if nav_agent.is_navigation_finished():
		return
	nav_agent.set_target_position(nav_path_goal_position)

	for unit in squad_members:
		if is_instance_valid(unit) && unit.has_node("NavigationAgent3D"):
			var unit_nav_agent: NavigationAgent3D = unit.get_node("NavigationAgent3D") as NavigationAgent3D
			if is_instance_valid(unit_nav_agent):
				unit_nav_agent.set_target_position(nav_path_goal_position)

func char_move(new_velocity: Vector3) -> void:
	velocity = new_velocity
	move_and_slide()

func selected() -> void:
	$selected.visible = true

func deselect() -> void:
	$selected.visible = false
