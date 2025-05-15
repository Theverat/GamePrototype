class_name UnitUtils

static func find_closest_unit(node: Node3D, group: String) -> Node3D:
	var closest_unit: Node3D = null
	var units: Array[Node] = node.get_tree().get_nodes_in_group(group)
	
	var min_dist_sqr: float = 99999999.0
	for unit_node: Node in units:
		var unit: Node3D = unit_node as Node3D
		assert(unit is Node3D)
		
		if is_instance_valid(unit):
			var dist_sqr: float = (unit.global_position - node.global_position).length_squared()
			if dist_sqr < min_dist_sqr:
				min_dist_sqr = dist_sqr
				closest_unit = unit
	return closest_unit
	
static func get_health_module(node: Node3D) -> Health:
	# TODO use get_node()?
	return node.find_child("Health", false) as Health
	
class HitResult:
	# collider: The colliding object.
	var collider: Object
	#collider_id: The colliding object's ID.
	var collider_id: int  # TODO correct type?
	#normal: The object's surface normal at the intersection point, or Vector3(0, 0, 0) if the ray starts inside the shape and PhysicsRayQueryParameters3D.hit_from_inside is true.
	var normal: Vector3
	#position: The intersection point.
	var position: Vector3
	#face_index: The face index at the intersection point.
	#Note: Returns a valid number only if the intersected shape is a ConcavePolygonShape3D. Otherwise, -1 is returned.
	var face_index: int  # TODO correct type?
	#rid: The intersecting object's RID.
	var rid: RID
	#shape: The shape index of the colliding shape.
	var shape: int  # TODO correct type?

# exclude can contain Objects or RIDs
static func raycast(node: Node3D, from: Vector3, to: Vector3, 
					collide_with_bodies: bool = true,
					collision_mask: int = 0xFFFFFFFF, 
					exclude = []) -> HitResult:
	var space_state = node.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to, collision_mask, exclude)
	query.collide_with_bodies = collide_with_bodies
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result.is_empty():
		return null
	else:
		var hitResult: HitResult = HitResult.new()
		hitResult.collider = result["collider"]
		hitResult.collider_id = result["collider_id"]
		hitResult.normal = result["normal"]
		hitResult.position = result["position"]
		hitResult.face_index = result["face_index"]
		hitResult.rid = result["rid"]
		hitResult.shape = result["shape"]
		return hitResult
