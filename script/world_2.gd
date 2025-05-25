extends Node
class_name Level

@export var gatling_turret_scene: PackedScene = null
@export var top_down_cam: TopDownCamera = null

# UI
@onready var unitPanel: Control = $UI/UnitPanel
@onready var gatlingButton: Button = $UI/UnitPanel/ButtonGrid/AddGatlingTurret
@onready var endBuildPhaseButton: Button = $UI/RoundPanel/EndBuildPhaseButton
@onready var timerLabel: Label = $UI/RoundPanel/TimerLabel
@onready var metalAmountLabel: Label = $UI/UnitPanel/MetalNameLabel/MetalAmountLabel

class BuildableUnit:
	var cost_metal: int
	var button: Button
	var scene: PackedScene

var buildable_units: Array[BuildableUnit] = []
var buildable_gatling: BuildableUnit = null

var unit_to_place: BuildableUnit = null
var instance: Node3D = null

enum	 RoundPhase {BUILD, FIGHT}
var round: int = 1
var roundPhase: RoundPhase = RoundPhase.BUILD
var phaseStartTimeSec: float = 0
var buildPhaseDurationSec: float = 120
var buildPhaseEndedByPlayer: bool = false
var fightPhaseDurationSec: float = 240

# Resources
var base_metal_per_round = 200
var metal: int = base_metal_per_round

func _ready():
	# Add buildable units
	buildable_gatling = BuildableUnit.new()
	buildable_gatling.cost_metal = 100
	buildable_gatling.button = gatlingButton
	buildable_gatling.scene = gatling_turret_scene
	buildable_units.push_back(buildable_gatling)
	
	gatlingButton.pressed.connect(_add_gatling_turret_pressed)
	endBuildPhaseButton.pressed.connect(_endBuildPhaseButton_pressed)
	phaseStartTimeSec = Utils.elapsedSec()
	
func _process(delta: float) -> void:
	var elapsed: float = Utils.elapsedSec()
	maybeChangePhase(elapsed)
	
	var phaseDurationSec: float = 0
	match roundPhase:
		RoundPhase.BUILD: phaseDurationSec = buildPhaseDurationSec
		RoundPhase.FIGHT: phaseDurationSec = fightPhaseDurationSec
		_: assert(false, "Unknown RoundPhase")
		
	var remaining: float = phaseDurationSec - (elapsed - phaseStartTimeSec)
	timerLabel.text = str(ceil(remaining))
	
	metalAmountLabel.text = str(metal)	
	
	if roundPhase == RoundPhase.BUILD:
		# Enable/disable buttons depending on amount of resources
		for buildable_unit in buildable_units:
			buildable_unit.button.disabled = metal < buildable_unit.cost_metal
		
		if unit_to_place:
			place_instance()
			
			if Input.is_action_pressed("accept"):
				# Finalize placement
				end_placement()
			elif Input.is_action_pressed("cancel"):
				# Cancel placement
				instance.queue_free()
				end_placement()

func _endBuildPhaseButton_pressed():
	buildPhaseEndedByPlayer = true

func nextRoundPhase(phase: RoundPhase):
	match phase:
		RoundPhase.BUILD:
			return RoundPhase.FIGHT
		RoundPhase.FIGHT:
			return RoundPhase.BUILD
			
func maybeChangePhase(elapsed: float):
	var elapsedInPhase = elapsed - phaseStartTimeSec
	var changePhase: bool = false
	match roundPhase:
		RoundPhase.BUILD:
			if (elapsedInPhase > buildPhaseDurationSec
					or buildPhaseEndedByPlayer):
				changePhase = true
		RoundPhase.FIGHT:
			if (elapsedInPhase > fightPhaseDurationSec):
				changePhase = true
		_:
			assert(false, "Unknown RoundPhase")
	
	if changePhase:
		roundPhase = nextRoundPhase(roundPhase)
		buildPhaseEndedByPlayer = false
		
		# Initialize new phase
		var isBuild: bool = roundPhase == RoundPhase.BUILD
		var isFight: bool = roundPhase == RoundPhase.FIGHT
		
		endBuildPhaseButton.visible = isBuild
		unitPanel.visible = isBuild
		timerLabel.visible = isBuild or isFight
		
		# Enable/disable spawners
		for portal in find_children("Portal*"):
			for spawner in portal.find_children("*", "Spawner2Component"):
				(spawner as Spawner2Component).enabled = isFight
				
		# Give resources to the player
		if isBuild:
			metal += base_metal_per_round
		
		phaseStartTimeSec = elapsed		
				
func place_instance():
	if instance == null:
		instance = unit_to_place.scene.instantiate() as Node3D
		add_child(instance)
			
	var pos: Vector3 = Vector3(30, 0, 30)
	# Cast ray into scene and find hitpoint
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()		
	var camera: Camera3D = top_down_cam.camera
	var raycaster: RayCast3D = top_down_cam.raycaster
	var ray_length: float = 300
			
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
	metal -= unit_to_place.cost_metal
	unit_to_place = null
	instance = null

func _add_gatling_turret_pressed():
	assert(buildable_gatling)
	unit_to_place = buildable_gatling
