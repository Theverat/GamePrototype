extends Node2D

@export var grid_script: Node2D # Referenz zum Grid-Script
@export var line_color = Color(0.5, 0.5, 0.5, 0.5)

func _draw():
	if grid_script:
		var grid_size = grid_script.grid_size
		var cell_size = grid_script.cell_size

		for i in range(grid_size.x + 1):
			var start = Vector2(i * cell_size.x, 0)
			var end = Vector2(i * cell_size.x, grid_size.y * cell_size.y)
			draw_line(start, end, line_color)

		for j in range(grid_size.y + 1):
			var start = Vector2(0, j * cell_size.y)
			var end = Vector2(grid_size.x * cell_size.x, j * cell_size.y)
			draw_line(start, end, line_color)
