# UnitController.gd
extends Node3D

@export var unit_node_path: NodePath
@export var target_marker_path: NodePath

# Verwende die korrekten class_names für Type Hints
var _move_component: MoveToComponent # <-- Geändert
var _anim_component: AnimationComponent # <-- Korrekter Typ

var _unit: CharacterBody3D
var _target_marker: Node3D

func _ready() -> void:
	var unit_node = get_node_or_null(unit_node_path)
	assert(unit_node != null, "Einheiten-Node nicht unter Pfad gefunden: %s" % unit_node_path)
	_unit = unit_node as CharacterBody3D
	assert(_unit != null, "Node unter Pfad ist kein CharacterBody3D.")

	# --- Komponenten holen ---
	# Bewegungskomponente (Node "moveTo", Klasse MoveToComponent)
	_move_component = _unit.get_node_or_null("moveTo") as MoveToComponent # <-- Cast geändert
	assert(_move_component != null, "Bewegungskomponente ('moveTo', erwartet Typ MoveToComponent) nicht als Kind der Einheit gefunden.")

	# Animationskomponente (Node "animationComponent", Klasse AnimationComponent)
	_anim_component = _unit.get_node_or_null("animationComponent") as AnimationComponent
	assert(_anim_component != null, "Animationskomponente ('animationComponent', erwartet Typ AnimationComponent) nicht als Kind der Einheit gefunden.")

	# --- Ziel-Marker holen ---
	var marker_node = get_node_or_null(target_marker_path)
	assert(marker_node != null, "Ziel-Marker Node nicht unter Pfad gefunden: %s" % target_marker_path)
	_target_marker = marker_node as Node3D
	assert(_target_marker != null, "Node unter target_marker_path ist kein Node3D.")

	# --- Signal verbinden ---
	if _move_component.has_signal("movement_finished"):
		if not _move_component.is_connected("movement_finished", Callable(self, "_on_unit_movement_finished")):
			var err: Error = _move_component.movement_finished.connect(Callable(self, "_on_unit_movement_finished"))
			assert(err == OK, "Verbindung des movement_finished Signals fehlgeschlagen.")
	else:
		printerr("WARNUNG: Bewegungskomponente ('moveTo') hat kein 'movement_finished' Signal.")

	# --- Bewegung befehlen ---
	var target_position: Vector3 = _target_marker.global_position
	print("Befehle Einheit zur Marker-Position: ", target_position)
	if _move_component.has_method("move_to"):
		_move_component.call_deferred("move_to", target_position)
	else:
		printerr("FEHLER: Bewegungskomponente ('moveTo') hat keine 'move_to' Methode.")

	print("UnitController: Initialisierung abgeschlossen.")

func _on_unit_movement_finished() -> void:
	print("UnitController: Einheit hat den Marker erreicht!")
