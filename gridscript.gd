@tool
extends Node3D

@export var grid_size = Vector2i(20, 20)
@export var cell_size = Vector2(2, 2) # Zellengröße in der XY-Ebene (Meter)
@export var grid_y_level: float = 0.0 # Y-Koordinate der Grid-Ebene

var grid_data: Array[Array]

func _ready():
	initialize_grid()

func initialize_grid():
	grid_data = []
	for _x in range(grid_size.x):
		grid_data.append([])
		for _y in range(grid_size.y):
			grid_data[_x].append(null)

func world_to_grid(world_position: Vector3) -> Vector2i:
	var grid_x = floor(world_position.x / cell_size.x)
	var grid_y = floor(world_position.z / cell_size.y) # Verwende Z für die zweite 2D-Koordinate
	return Vector2i(grid_x, grid_y)

func grid_to_world(grid_coords: Vector2i) -> Vector3:
	var world_x = grid_coords.x * cell_size.x + cell_size.x / 2
	var world_z = grid_coords.y * cell_size.y + cell_size.y / 2
	return Vector3(world_x, grid_y_level, world_z)

func is_cell_occupied(grid_coords: Vector2i) -> bool:
	if grid_coords.x >= 0 and grid_coords.x < grid_size.x and \
	   grid_coords.y >= 0 and grid_coords.y < grid_size.y:
		return grid_data[grid_coords.x][grid_coords.y] != null
	return true

func occupy_cell(grid_coords: Vector2i, object):
	if grid_coords.x >= 0 and grid_coords.x < grid_size.x and \
	   grid_coords.y >= 0 and grid_coords.y < grid_size.y:
		grid_data[grid_coords.x][grid_coords.y] = object

func free_cell(grid_coords: Vector2i):
	if grid_coords.x >= 0 and grid_coords.x < grid_size.x and \
	   grid_coords.y >= 0 and grid_coords.y < grid_size.y:
		grid_data[grid_coords.x][grid_coords.y] = null
