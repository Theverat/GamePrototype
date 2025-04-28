extends RefCounted

static func get_vector3_from_camera_raycast(camera: Camera3D, camera_2D_Coords: Vector2) -> Vector3:
	var ray_origin: Vector3 = camera.project_ray_origin(camera_2D_Coords)
	var ray_direction: Vector3 = camera.project_ray_normal(camera_2D_Coords)
	var ray_end: Vector3 = ray_origin + ray_direction * 1000000.0

	var space_state = camera.get_world_3d().get_direct_space_state()
	if space_state == null:
		printerr("Direct Space State is null")
		return Vector3.ZERO

	var query = PhysicsRayQueryParameters3D.new()
	query.from = ray_origin
	query.to = ray_end
	query.collision_mask = 1 # Layer 1 ist default, ändere dies falls nötig

	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		return result.position
	else:
		return Vector3.ZERO
