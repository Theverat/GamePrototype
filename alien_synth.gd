extends CharacterBody3D

var speed = 5.0

func _physics_process(delta):
	var input_vector = Vector3.ZERO

	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.z += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.z -= 1

	input_vector = input_vector.normalized()

	velocity.x = input_vector.x * speed
	velocity.z = input_vector.z * speed

	# Gravitation beachten, falls nötig:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	move_and_slide()

	# Animation ansteuern:
	if input_vector.length() > 0:
		$AnimationPlayer.play("run")
	else:
		$AnimationPlayer.stop()
