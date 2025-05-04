@tool
extends CharacterBody3D # Oder KinematicBody3D oder Node3D, je nach deinem Unit-Typ

@onready var animation_player: AnimationPlayer = $monster/Skeleton3D/AnimationPlayer


enum AnimationState {
	IDLE,
	RUN,
	ATTACK,
	BITE,
	DYING,
	REACTION_1,
	REACTION_2
}

@export var current_animation_state: AnimationState = AnimationState.IDLE

func play_idle():
	animation_player.play("idle")

func play_run():
	animation_player.play("run")

func play_attack():
	animation_player.play("attack")

func play_bite():
	animation_player.play("bite")

func play_dying():
	animation_player.play("dying")

func play_reaction_1():
	animation_player.play("reaction 1")

func play_reaction_2():
	animation_player.play("reaction 2")

func _process(delta):
	match current_animation_state:
		AnimationState.IDLE:
			if not animation_player.is_playing():
				play_idle()
		AnimationState.RUN:
			if not animation_player.is_playing() or animation_player.current_animation != "run":
				play_run()
		AnimationState.ATTACK:
			if not animation_player.is_playing() or animation_player.current_animation != "attack":
				play_attack()
		AnimationState.BITE:
			if not animation_player.is_playing() or animation_player.current_animation != "bite":
				play_bite()
		AnimationState.DYING:
			if not animation_player.is_playing() or animation_player.current_animation != "dying":
				play_dying()
		AnimationState.REACTION_1:
			if not animation_player.is_playing() or animation_player.current_animation != "reaction 1":
				play_reaction_1()
		AnimationState.REACTION_2:
			if not animation_player.is_playing() or animation_player.current_animation != "reaction 2":
				play_reaction_2()

# Du kannst auch Funktionen erstellen, um den Zustand von außen zu ändern:
func set_animation_state(new_state: AnimationState):
	current_animation_state = new_state
