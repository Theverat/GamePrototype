# moveToComponent.gd
class_name MoveToComponent # Geändert für Konsistenz
extends Node

signal movement_finished

@export var speed: float = 5.0
@export var acceleration: float = 8.0
@export var target_reached_threshold: float = 0.1
@export var rotation_speed: float = 10.0
# Referenzen zu anderen Nodes/Komponenten
var _parent_body: CharacterBody3D
var _nav_agent: NavigationAgent3D
var _anim_component: AnimationComponent # <-- *** DEKLARIERT ***

# Physik-Einstellung
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) as float

func _ready() -> void:
	# Referenz zum Eltern-Node holen
	_parent_body = get_parent() as CharacterBody3D
	assert(_parent_body != null, "MoveToComponent muss ein Kind von CharacterBody3D sein.")

	# Referenz zum NavigationAgent3D holen
	_nav_agent = _parent_body.find_child("NavigationAgent3D", true, false)
	assert(_nav_agent != null, "Eltern-CharacterBody3D muss einen NavigationAgent3D als Kind haben.")

	# --- *** HINZUGEFÜGT START *** ---
	# Referenz zur Animationskomponente holen (Node heißt "animationComponent")
	_anim_component = _parent_body.get_node_or_null("animationComponent") as AnimationComponent
	assert(_anim_component != null, "Animationskomponente ('animationComponent') nicht als Kind des Parent Body gefunden.")
	# --- *** HINZUGEFÜGT ENDE *** ---

	# NavigationAgent konfigurieren
	_nav_agent.path_desired_distance = 0.5
	_nav_agent.target_desired_distance = target_reached_threshold

	# Signal verbinden
	if not _nav_agent.is_connected("navigation_finished", Callable(self, "_on_navigation_finished")):
		var err = _nav_agent.connect("navigation_finished", Callable(self, "_on_navigation_finished"))
		assert(err == OK, "Verbindung des navigation_finished Signals fehlgeschlagen.")

func _physics_process(delta: float) -> void:
	# --- Gültigkeitsprüfungen ---
	# Stelle sicher, dass die benötigten Nodes vorhanden und gültig sind.
	assert(is_instance_valid(_parent_body), "MoveToComponent: _parent_body ist ungültig.")
	assert(is_instance_valid(_nav_agent), "MoveToComponent: _nav_agent ist ungültig.")
	assert(is_instance_valid(_anim_component), "MoveToComponent: _anim_component ist ungültig.")

	# Hole die aktuelle Geschwindigkeit vom CharacterBody3D.
	var current_velocity: Vector3 = _parent_body.velocity

	# --- Schwerkraft ---
	# Wende Schwerkraft an, wenn die Einheit nicht auf dem Boden ist.
	if not _parent_body.is_on_floor():
		current_velocity.y -= gravity * delta

	# --- Horizontale Bewegung ---
	# Berechne die Zielgeschwindigkeit basierend auf dem Navigationspfad.
	var target_horizontal_velocity: Vector3 = Vector3.ZERO
	if not _nav_agent.is_navigation_finished():
		var current_pos: Vector3 = _parent_body.global_position
		var next_path_pos: Vector3 = _nav_agent.get_next_path_position()
		# Berechne die Richtung nur auf der horizontalen Ebene.
		var direction: Vector3 = (next_path_pos - current_pos)
		direction.y = 0
		# Normalisiere die Richtung und wende die Geschwindigkeit an.
		if direction.length_squared() > 0.001: # Verhindere Division durch Null.
			direction = direction.normalized()
			target_horizontal_velocity = direction * speed

	# --- Horizontale Beschleunigung ---
	# Bewege die aktuelle Geschwindigkeit schrittweise zur Zielgeschwindigkeit.
	current_velocity.x = move_toward(current_velocity.x, target_horizontal_velocity.x, acceleration * delta)
	current_velocity.z = move_toward(current_velocity.z, target_horizontal_velocity.z, acceleration * delta)

	# --- Rotation ---
	# Ermittle die horizontale Bewegungsrichtung aus der aktuellen Geschwindigkeit.
	var move_direction := Vector3(current_velocity.x, 0, current_velocity.z)

	# Nur drehen, wenn eine signifikante horizontale Bewegung stattfindet.
	if move_direction.length_squared() > 0.001: # Schwellenwert gegen Jitter.
		move_direction = move_direction.normalized()

		# Berechne die Ziel-Ausrichtung (Basis), sodass -Z in Bewegungsrichtung zeigt.
		var target_basis := Basis.looking_at(move_direction, _parent_body.up_direction)
		# Interpoliere die aktuelle Ausrichtung sanft zur Ziel-Ausrichtung (slerp).
		var current_orthonormal_basis = _parent_body.basis.orthonormalized()
		_parent_body.basis = current_orthonormal_basis.slerp(target_basis, delta * rotation_speed)

	# --- Animation ---
	# Setze den Animationszustand basierend auf der horizontalen Geschwindigkeit.
	var horizontal_speed_sq: float = Vector2(current_velocity.x, current_velocity.z).length_squared()
	if horizontal_speed_sq > 0.1: # Schwellenwert ggf. anpassen.
		_anim_component.set_animation_state(AnimationComponent.AnimationState.RUN)
	else:
		_anim_component.set_animation_state(AnimationComponent.AnimationState.IDLE)

	# --- Geschwindigkeit setzen und Bewegen ---
	# Wende die berechnete Geschwindigkeit an und führe die Bewegung aus.
	_parent_body.velocity = current_velocity
	_parent_body.move_and_slide()


func move_to(target_position: Vector3) -> void:
	assert(is_instance_valid(_nav_agent), "NavigationAgent3D ist nicht gültig.")
	_nav_agent.target_position = target_position


func stop() -> void:
	# Stelle sicher, dass die Nodes gültig sind, bevor auf sie zugegriffen wird
	if not is_instance_valid(_nav_agent) or not is_instance_valid(_parent_body): return
	_nav_agent.target_position = _parent_body.global_position
	_parent_body.velocity.x = 0
	_parent_body.velocity.z = 0
	# Explizit Idle setzen beim Stoppen
	if is_instance_valid(_anim_component):
		_anim_component.set_animation_state(AnimationComponent.AnimationState.IDLE)

func _on_navigation_finished() -> void:
	emit_signal("movement_finished")
	# Explizit Idle setzen bei Ankunft
	if is_instance_valid(_anim_component):
		_anim_component.set_animation_state(AnimationComponent.AnimationState.IDLE)
