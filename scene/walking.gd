# Unit.gd
extends Node3D

@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("mixamo_com")
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(name):
	if name == "mixamo_com":
		animation_player.play("mixamo_com")
