extends PathingUnit
class_name MobileReactor

@onready var animation_player: AnimationPlayer = $mesh/AnimationPlayer


const SPEED = 5.0
const JUMP_VELOCITY = 4.5


func _physics_process(delta: float) -> void:
	pass
	# Add the gravity.
func _ready() -> void:
	animation_player.play("Vent")
