# test_environment.gd
extends Node3D # Oder Node, wenn die Hauptszene kein 3D-Objekt sein muss

# === Konfiguration ===
# Optional: Exportiere den Pfad zum Node, der Gebäude enthält,
# falls sie nicht direkt unter diesem Node liegen.
# @export var buildings_container_path: NodePath = "Buildings"

# === Initialisierung ===
func _ready() -> void:
	print("Test Environment bereit. Suche nach Spawnern...")
	# Verbinde die Signale aller Spawner in der Szene.
	# Annahme: Gebäude (mit Spawnern) sind z.B. unter einem Node "Buildings"
	# oder direkt in der Szene verteilt. Wir suchen rekursiv.
	_connect_all_spawner_signals(self) # Startet die Suche vom Hauptszenen-Root


# Rekursive Funktion zum Finden und Verbinden aller Spawner-Signale
func _connect_all_spawner_signals(node: Node) -> void:
	# Prüfe, ob der aktuelle Node ein SpawnerComponent ist
	# Wichtig: Prüfe, ob es sich um das Skript handelt, nicht nur um den Klassennamen,
	# da der Szenen-Root-Name auch SpawnerComponent sein könnte.
	if node.get_script() == preload("res://spawner_component.gd"): # Passe den Pfad an, falls nötig
		var spawner = node as Node3D # Sicherstellen, dass es der richtige Typ ist
		if spawner and spawner.has_signal("unit_spawned"):
			# Verbinde das Signal mit unserer Handler-Funktion
			var error = spawner.unit_spawned.connect(_on_any_unit_spawned)
			if error == OK:
				print("  -> Verbunden: ", spawner.get_path())
			else:
				printerr("FEHLER beim Verbinden des unit_spawned Signals von ", spawner.get_path(), ": ", error)
		else:
			printerr("WARNUNG: Node gefunden, der Spawner sein sollte, aber Signal 'unit_spawned' fehlt oder Typ passt nicht: ", node.get_path())

	# Gehe durch alle Kinder des aktuellen Nodes
	for child in node.get_children():
		_connect_all_spawner_signals(child) # Rekursiver Aufruf


# === Signal Handler ===
# Wird aufgerufen, wenn *irgendein* Spawner das Signal "unit_spawned" sendet.
func _on_any_unit_spawned(unit_instance: Node3D, spawn_transform: Transform3D) -> void:
	if not is_instance_valid(unit_instance):
		printerr("Empfangene Unit-Instanz von Spawner ist ungültig.")
		return

	unit_instance.global_transform = spawn_transform
	get_tree().root.add_child(unit_instance)
	
	# Optional: Setze den Owner, damit die Unit mit der Szene gespeichert wird, falls nötig
	# unit_instance.owner = self # Oder get_tree().edited_scene_root im Editor

	print("Unit '", unit_instance.name, "' zur Szene hinzugefügt.")

	# --------------------------------------------------------------------------
	## HIER: Unit Logik nach dem Spawnen initialisieren
	# Dies ist der richtige Ort, um der Unit erste Befehle zu geben:
	# - Pfad zuweisen (z.B. zu einem Rally Point)
	# - Ziel für NavigationAgent3D setzen
	# - Unit einer Kontrollgruppe hinzufügen
	# - Standardverhalten (z.B. Idle, Guard) aktivieren
	#
	# Beispiel (wenn die Unit eine Funktion 'set_initial_target' hat):
	# if unit_instance.has_method("set_initial_target"):
	#	 unit_instance.set_initial_target(unit_container.global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))) # Zufälliges Ziel nahe Container
	# --------------------------------------------------------------------------
