# spawner_component.gd
@tool
extends Node3D

## Signal, das ausgelöst wird, wenn eine Einheit erfolgreich gespawnt wurde.
## Übergibt die Instanz der gespawnten Einheit.
signal unit_spawned(unit_instance: Node3D)

## Die Szene der Einheit, die gespawnt werden soll.
@export var unit_scene: PackedScene:
	get: return unit_scene
	set(value):
		unit_scene = value
		if Engine.is_editor_hint():
			notify_property_list_changed() # Aktualisiert den Inspector, falls nötig

## Optional: Ein Marker3D oder Node3D, der die genaue Spawn-Position und -Ausrichtung vorgibt.
## Wenn nicht gesetzt, wird die Position/Rotation des SpawnerComponent selbst verwendet.
@export var spawn_point_node: NodePath

## Zeit in Sekunden zwischen automatischen Spawns. Nur relevant, wenn spawn_automatically = true.
@export var spawn_interval: float = 5.0:
	get: return spawn_interval
	set(value):
		spawn_interval = value
		if spawn_timer != null:
			spawn_timer.wait_time = spawn_interval

## Aktiviert automatisches Spawnen über den Timer.
@export var spawn_automatically: bool = false:
	get: return spawn_automatically
	set(value):
		spawn_automatically = value
		_update_timer_state()

## Maximale Anzahl an Einheiten, die dieser Spawner erstellen kann (-1 für unendlich).
@export var spawn_limit: int = -1

## Referenz zum SpawnPoint Node.
@onready var spawn_point: Node3D = get_node_or_null(spawn_point_node) if spawn_point_node else null
## Referenz zum Timer Node.
@onready var spawn_timer: Timer = $SpawnTimer

var _spawn_count: int = 0

func _ready() -> void:
	# Stelle sicher, dass der Timer korrekt konfiguriert ist
	if spawn_timer:
		spawn_timer.wait_time = spawn_interval
		spawn_timer.one_shot = false # Timer soll wiederholt auslösen
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
		_update_timer_state()
	else:
		printerr("SpawnerComponent benötigt einen Kind-Node vom Typ Timer mit dem Namen 'SpawnTimer'.")


func _get_property_list():
	# Diese Funktion ist optional, kann aber helfen, den Inspector aufzuräumen
	# oder dynamische Properties hinzuzufügen, z.B. basierend auf anderen Settings.
	# Vorerst lassen wir sie leer oder implementieren sie später bei Bedarf.
	return []

## Versucht, eine Einheit zu spawnen.
## Gibt die gespawnte Einheit zurück oder null bei Fehlschlag.
func spawn_unit() -> Node3D:
	# Prüfen, ob eine Unit-Szene zugewiesen ist
	if not unit_scene:
		printerr("Keine unit_scene im SpawnerComponent zugewiesen.")
		return null

	# Prüfen, ob das Spawn-Limit erreicht ist
	if spawn_limit != -1 and _spawn_count >= spawn_limit:
		# Optional: Timer stoppen, wenn Limit erreicht ist
		if spawn_timer and spawn_automatically:
			spawn_timer.stop()
			# print("Spawn-Limit erreicht.") # Optionales Debugging
		return null

	# Unit-Szene instanziieren
	var unit_instance: Node3D = unit_scene.instantiate() as Node3D
	if not is_instance_valid(unit_instance):
		printerr("Instanziierung der unit_scene fehlgeschlagen.")
		return null

	# Spawn-Transformation bestimmen
	var spawn_transform: Transform3D
	if is_instance_valid(spawn_point):
		spawn_transform = spawn_point.global_transform
	else:
		spawn_transform = global_transform # Fallback auf die Spawner-Position/Rotation

	# Die Unit hinzufügen: Statt sie hier direkt zur Szene hinzuzufügen,
	# senden wir ein Signal. Das Eltern-Skript (z.B. das Spiel-Management)
	# kann dann entscheiden, wo die Unit im Szenenbaum platziert wird.
	# unit_instance.global_transform = spawn_transform # Setze Transform, BEVOR das Signal gesendet wird.

	_spawn_count += 1
	unit_spawned.emit(unit_instance, spawn_transform) # Signal senden mit Instanz und gewünschter Transform

	print("Einheit gespawnt: ", unit_instance.name, " (Total: ", _spawn_count, ")")
	return unit_instance


## Wird aufgerufen, wenn der SpawnTimer abläuft.
func _on_spawn_timer_timeout() -> void:
	spawn_unit()


## Startet oder stoppt den Timer basierend auf spawn_automatically.
func _update_timer_state() -> void:
	if not spawn_timer:
		return
	if spawn_automatically and not Engine.is_editor_hint(): # Prüfen, ob das Spiel tatsächlich läuft		# Nur starten, wenn nicht bereits gestartet und Limit nicht erreicht
		if spawn_timer.is_stopped() and (spawn_limit == -1 or _spawn_count < spawn_limit):
			spawn_timer.start()
	else:
		if not spawn_timer.is_stopped():
			spawn_timer.stop()

# --- Öffentliche Methoden für externe Steuerung (z.B. durch UI oder Wave-Manager) ---

## Startet das automatische Spawnen (falls nicht schon aktiv).
func start_spawning() -> void:
	spawn_automatically = true
	_update_timer_state()

## Stoppt das automatische Spawnen.
func stop_spawning() -> void:
	spawn_automatically = false
	_update_timer_state()

## Setzt den Spawn-Zähler zurück.
func reset_spawn_count() -> void:
	_spawn_count = 0
	# Timer ggf. neu starten, wenn er wegen Limit gestoppt war
	_update_timer_state()

# Optional: Funktion, um eine bestimmte Anzahl Units auf einmal zu spawnen (für Wellen)
# func spawn_burst(count: int) -> Array[Node3D]:
#	 var spawned_units: Array[Node3D] = []
#	 for i in range(count):
#		 var unit = spawn_unit()
#		 if is_instance_valid(unit):
#			 spawned_units.append(unit)
#		 else:
#			 break # Abbrechen, wenn Limit erreicht oder Fehler auftritt
#	 return spawned_units
