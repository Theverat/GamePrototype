extends Node

@export var gatling_turret_scene: PackedScene = null
@export var top_down_cam: TopDownCamera = null
@export var portal: Node3D = null

# UI
@onready var unitPanel: Control = $UI/UnitPanel
@onready var gatlingButton: Button = $UI/UnitPanel/ButtonGrid/AddGatlingTurret
@onready var endBuildPhaseButton: Button = $UI/RoundPanel/EndBuildPhaseButton
@onready var timerLabel: Label = $UI/RoundPanel/TimerLabel

var scene_to_place: PackedScene = null
var instance: Node3D = null

enum	 RoundPhase {BUILD, FIGHT}
var round: int = 1
var roundPhase: RoundPhase = RoundPhase.BUILD
var buildPhaseDurationSec: float = 120
var buildPhaseStartTimeSec: float = 0
var buildPhaseEndedByPlayer: bool = false

func _endBuildPhaseButton_pressed():
	buildPhaseEndedByPlayer = true

func nextRoundPhase(phase: RoundPhase):
	match phase:
		RoundPhase.BUILD:
			return RoundPhase.FIGHT
		RoundPhase.FIGHT:
			return RoundPhase.BUILD
			
func maybeChangePhase(elapsed: float):
	var changePhase: bool = false
	if roundPhase == RoundPhase.BUILD:
		if (elapsed - buildPhaseStartTimeSec > buildPhaseDurationSec
				or buildPhaseEndedByPlayer):
			changePhase = true
	elif roundPhase == RoundPhase.FIGHT:
		pass  # TODO end fight phase
	else:
		assert(false, "Unknown RoundPhase")
	
	if changePhase:
		roundPhase = nextRoundPhase(roundPhase)
		buildPhaseEndedByPlayer = false
		
		# Initialize new phase
		var isBuild: bool = roundPhase == RoundPhase.BUILD
		var isFight: bool = roundPhase == RoundPhase.FIGHT
		
		endBuildPhaseButton.visible = isBuild
		unitPanel.visible = isBuild
		timerLabel.visible = isBuild
		
		for spawner in portal.find_children("*", "Spawner2Component"):
			(spawner as Spawner2Component).enabled = isFight
		
		if isBuild:
			buildPhaseStartTimeSec = elapsed		

func _ready():
	gatlingButton.pressed.connect(_add_gatling_turret_pressed)
	endBuildPhaseButton.pressed.connect(_endBuildPhaseButton_pressed)
	buildPhaseStartTimeSec = Utils.elapsedSec()
	
func _process(delta: float) -> void:
	var elapsed: float = Utils.elapsedSec()
	maybeChangePhase(elapsed)
	
	if roundPhase == RoundPhase.BUILD:
		var remaining: float = buildPhaseDurationSec - (elapsed - buildPhaseStartTimeSec)
		timerLabel.text = str(ceil(remaining))
		
		if scene_to_place:
			place_instance()
			
			if Input.is_action_pressed("accept"):
				# Finalize placement
				end_placement()
			elif Input.is_action_pressed("cancel"):
				# Cancel placement
				instance.queue_free()
				end_placement()
				
func place_instance():
	if instance == null:
		instance = scene_to_place.instantiate() as Node3D
		add_child(instance)
			
	var pos: Vector3 = Vector3(30, 0, 30)
	# Cast ray into scene and find hitpoint
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()		
	var camera: Camera3D = top_down_cam.camera
	var raycaster: RayCast3D = top_down_cam.raycaster
	var ray_length: float = 100
			
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	pos = to
	
	# TODO Maybe use a collision mask to only allow buildable floor sections
	# as collision objects
	var exclude: = []
	for child: Node in instance.find_children("*"):
		var as_coll = child as CollisionShape3D
		if as_coll:
			exclude.push_back(as_coll.shape.get_rid())
		elif child.is_class("StaticBody3D"):
			exclude.push_back(child as Object)
	
	var collision_mask: int = 0xFFFFFFFF
	var collide_with_bodies: bool = true
	var hit: UnitUtils.HitResult = UnitUtils.raycast(instance, from, to, 
													collide_with_bodies,
													collision_mask, exclude)
	
	if hit: 
		pos = hit.position
	
	instance.global_position = pos
	
func end_placement():
	scene_to_place = null
	instance = null

func _add_gatling_turret_pressed():
	assert(gatling_turret_scene)
	scene_to_place = gatling_turret_scene
