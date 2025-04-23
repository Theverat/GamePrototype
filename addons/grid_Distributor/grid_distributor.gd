import godot

@tool
class GridDistributor(godot.EditorPlugin):
	def _edit(self, node: godot.Node) -> None:
		selected_nodes = self.get_editor_interface().get_selection().get_selected_nodes()

		if not selected_nodes:
			print("Keine Objekte ausgewählt.")
			return

		num_objects = len(selected_nodes)
		if num_objects == 0:
			return

		# Konfigurationsparameter (im Editor anpassbar)
		grid_size_x = godot.Property(godot.int, "grid_size_x", 3)
		grid_size_y = godot.Property(godot.int, "grid_size_y", (num_objects + 2) // 3 if num_objects > 0 else 1) # Default basierend auf Objektanzahl
		grid_size_z = godot.Property(godot.int, "grid_size_z", 1)
		spacing = godot.Property(godot.float, "spacing", 2.0)

		def distribute_in_grid():
			index = 0
			for x in range(grid_size_x.get()):
				for y in range(grid_size_y.get()):
					for z in range(grid_size_z.get()):
						if index < num_objects:
							node = selected_nodes[index]
							node.position = godot.Vector3(x * spacing.get(), y * spacing.get(), z * spacing.get())
							index += 1
						else:
							return

		if godot.EditorInspectorPlugin.can_handle(node):
			distribute_button = godot.Button()
			distribute_button.text = "Im Gitter verteilen"
			distribute_button.connect("pressed", distribute_in_grid)
			node.add_child(distribute_button)

	def _exit_edit(self, node: godot.Node) -> None:
		for child in node.get_children():
			if child.is_class("Button") and child.text == "Im Gitter verteilen":
				node.remove_child(child)
				child.queue_free()
