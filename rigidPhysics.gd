extends CharacterBody3D


const SPEED = 0.25
const JUMP_VELOCITY = 4.5


func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var dir2D = Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up")
	
	var dir = ($cameraOrigin.transform.basis * Vector3(dir2D.x, 0, dir2D.y))
	
	if dir2D:
		velocity.x += dir.x * SPEED
		velocity.z += dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0 , 1)
		velocity.z = move_toward(velocity.z, 0,  1)
	
	if Input.is_action_just_pressed("jump"):
		velocity.y += 8
	
	$cameraOrigin.position = position
	
	if $cameraOrigin/Camera3D.current == true:
		print("true")
	
	move_and_slide()
