extends PathingUnit
class_name MobileReactor

@onready var animation_venter: AnimationPlayer = $mesh/AnimationVenter
@onready var animation_driver: AnimationPlayer = $mesh/AnimationDriver
@export var reactor_waypoint: Node3D = null

const SPEED = 5.0
const TURN_VELOCITY = 4.5


func _physics_process(delta: float) -> void:
	super(delta)
	if body.velocity != Vector3.ZERO:
		animation_driver.play("Drive_Forward")
	else:
		animation_driver.stop()
		
	
func _ready() -> void:
	super()
	animation_venter.play("Vent")
	target = reactor_waypoint
	
