# AnimationComponent.gd (Als separate Komponente)
class_name AnimationComponent
extends Node # Besser als CharacterBody3D für eine Komponente

# Pfad zum AnimationPlayer relativ zum Owner (monster_root)
# Basierend auf deinem Screenshot: monster_root -> monsterMesh -> AnimationPlayer
const ANIM_PLAYER_PATH = "monsterMesh/AnimationPlayer"
@onready var animation_player: AnimationPlayer = owner.get_node_or_null(ANIM_PLAYER_PATH)

enum AnimationState {
	IDLE,
	RUN,
	ATTACK,
	BITE,
	DYING,
	GETTING_HIT,
	STAGGER
}

var current_animation_state: AnimationState = AnimationState.IDLE

func _ready() -> void:
	assert(animation_player != null, "AnimationPlayer nicht unter Pfad '%s' im Owner gefunden." % ANIM_PLAYER_PATH)
	set_animation_state(AnimationState.IDLE) # Initialen Zustand setzen

# Diese Funktion ist die Schnittstelle für andere Komponenten
func set_animation_state(new_state: AnimationState) -> void:
	# Verhindere unnötige Zustandswechsel/Neustarts
	# (Kann später verfeinert werden, z.B. um nicht-loopende Animationen neu zu starten)
	if new_state == current_animation_state and animation_player.is_playing():
# Prüfen, ob die *korrekte* Animation für den Zustand bereits läuft
		if animation_player.current_animation == _get_animation_name(new_state):
			return

	# Optional: Prioritäten hinzufügen (z.B. DYING kann nicht unterbrochen werden)
	# if current_animation_state == AnimationState.DYING and new_state != AnimationState.DYING:
	#     return

	print("AnimationComponent: Setze Zustand auf ", AnimationState.keys()[new_state]) # Debug-Ausgabe
	current_animation_state = new_state

	var anim_to_play = _get_animation_name(new_state)

	if animation_player.has_animation(anim_to_play):
		animation_player.play(anim_to_play)
	else:
		printerr("AnimationComponent: Animation '%s' für Zustand %s nicht gefunden!" % [anim_to_play, AnimationState.keys()[new_state]])
		# Fallback zu Idle?
		var idle_anim = _get_animation_name(AnimationState.IDLE)
		if animation_player.has_animation(idle_anim):
			animation_player.play(idle_anim)
			current_animation_state = AnimationState.IDLE


# Hilfsfunktion, um Enum-Wert -> Animationsnamen zu übersetzen
func _get_animation_name(state: AnimationState) -> StringName:
	match state:
		AnimationState.IDLE:            return &"monster animations/idle"
		AnimationState.RUN:             return &"monster animations/run"
		AnimationState.ATTACK:          return &"monster animations/attack"
		AnimationState.BITE:            return &"monster animations/bite"
		AnimationState.DYING:           return &"monster animations/dying"
		AnimationState.GETTING_HIT:     return &"monster animations/getting_hit"
		AnimationState.STAGGER:         return &"monster animations/stagger"
		_:                              return &"monster animations/idle" # Fallback

# _process wird hier wahrscheinlich nicht benötigt
# func _process(delta):
#	pass
