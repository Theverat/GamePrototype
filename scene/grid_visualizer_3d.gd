@tool
extends Node3D

@export var grid_script: Node3D # Referenz zum Grid-Script
@export var line_color = Color(0.5, 0.5, 0.5, 0.5)

func _ready():
	if not grid_script:
		printerr("Grid-Script nicht zugewiesen.")
		return
	draw_grid()

func draw_grid():
	if grid_script:
		var grid_size = grid_script.grid_size
		var cell_size = grid_script.cell_size
		var grid_y_level = grid_script.grid_y_level

		for i in range(grid_size.x + 1):
			var start = Vector3(i * cell_size.x, grid_y_level, 0)
			var end = Vector3(i * cell_size.x, grid_y_level, grid_size.y * cell_size.y)
			draw_line_segment(start, end, line_color)

		for j in range(grid_size.y + 1):
			var start = Vector3(0, grid_y_level, j * cell_size.y)
			var end = Vector3(grid_size.x * cell_size.x, grid_y_level, j * cell_size.y)
			draw_line_segment(start, end, line_color)

func draw_line_segment(from: Vector3, to: Vector3, color: Color):
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var points = PackedVector3Array([from, to])
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray([color, color])

	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	var line = MeshInstance3D.new()
	line.mesh = arr_mesh
	add_child(line)
