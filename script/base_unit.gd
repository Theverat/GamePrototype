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
