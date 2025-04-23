extends Node2D

# NODES
@onready var player_camera:Node3D = $camera_base
@onready var player_camera_visibleunits_Area3D:Area3D = $camera_base/visibleunits_area3D
@onready var ui_dragbox:NinePatchRect = $ui_dragbox

# Variables
@onready var BoxSelectionUnits_Visible:Dictionary = {}

const min_drag_squared: int = 128

# Internals
var mouse_left_click:bool = false
var drag_rect_area:Rect2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize_interface()
	

func unit_entered(unit:CharacterBody3D) -> void:
	var unit_id:int = unit.get_instance_id()
	if BoxSelectionUnits_Visible.keys().has(unit_id):return
	BoxSelectionUnits_Visible[unit_id] = unit
	print("unit entered: ", unit, " id:", unit_id, " unit_node:", unit.get_parent())
	debug_units_visible()
	
func unit_exited(unit:CharacterBody3D) -> void:
	var unit_id:int = unit.get_instance_id()
	if !BoxSelectionUnits_Visible.keys().has(unit_id):return
	BoxSelectionUnits_Visible.erase(unit_id)
	print("unit exited: ", unit, " id:", unit_id, " unit_node:", unit.get_parent())
	
	
func debug_units_visible() -> void:
	print(BoxSelectionUnits_Visible)
func initialize_interface() -> void:
	ui_dragbox.visible = false
	player_camera_visibleunits_Area3D.body_entered.connect(unit_entered)
	player_camera_visibleunits_Area3D.body_exited.connect(unit_exited)

func _input(event:InputEvent) -> void:
	if Input.is_action_just_pressed("mouse_leftclick"): # Runs once
		drag_rect_area.position = get_global_mouse_position()
		ui_dragbox.position = drag_rect_area.position
		mouse_left_click = true
	if Input.is_action_just_released("mouse_leftclick"):
		mouse_left_click = false
		ui_dragbox.visible = false
		cast_selection()


func cast_selection() -> void:
	for unit in BoxSelectionUnits_Visible.values():
		if unit is CharacterBody3D:
			if drag_rect_area.abs().has_point( player_camera.get_Vector2_from_Vector3(unit.transform.origin) ):
				unit.selected()
			else:
				unit.deselect()
	print(BoxSelectionUnits_Visible)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if mouse_left_click:
		drag_rect_area.size = get_global_mouse_position() - drag_rect_area.position
		update_ui_dragbox()
		if !ui_dragbox.visible:
			if drag_rect_area.size.length_squared() > min_drag_squared:
				ui_dragbox.visible = true
			
		

func update_ui_dragbox() -> void:
	ui_dragbox.size = abs(drag_rect_area.size)

	
	# Scale Dragbox backwards. Ninepatch doesnt allow negative Size.
	if drag_rect_area.size.x < 0:
		ui_dragbox.scale.x = -1
	else: ui_dragbox.scale.x = 1
	
	if drag_rect_area.size.y < 0:
		ui_dragbox.scale.y = -1
	else: ui_dragbox.scale.y = 1
