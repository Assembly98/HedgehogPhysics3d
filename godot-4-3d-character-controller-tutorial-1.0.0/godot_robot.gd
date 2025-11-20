extends CharacterBody3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouseSensitivty := 0.25

@export_group("Movement")
@export var moveSpd := 8.0
@export var acc := 20.0
@export var rotationSpd := 12.0
@export var jumpForce := 12.0

var cameraInputDirection := Vector2.ZERO
var lastMoveDir := Vector3.BACK
var gravity := -30.0

@onready var cameraPivot : Node3D = %CameraPivot
@onready var camera : Camera3D = %Camera3D
@onready var skin : Node3D = %GobotSkin

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	var isCameraMotion := (
		event is InputEventMouseMotion and 
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if isCameraMotion:
		cameraInputDirection = event.screen_relative * mouseSensitivty

func  _physics_process(delta: float) -> void:
	cameraPivot.rotation.x += cameraInputDirection.y * delta
	cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, -PI/6.0, PI/3.0)
	
	cameraPivot.rotation.y -= cameraInputDirection.x * delta
	
	cameraInputDirection = Vector2.ZERO
	
	var rawInput := Input.get_vector('move_left', 'move_right', 'move_up', 'move_down')
	var forward := camera.global_basis.z
	var right : = camera.global_basis.x
	
	var moveDir := forward * rawInput.y + right * rawInput.x
	moveDir.y = 0.0
	moveDir = moveDir.normalized() 
	
	var velY := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(moveDir * moveSpd, acc * delta)
	velocity.y = velY + gravity * delta
	
	var jumpStart := Input.is_action_just_pressed("jump") and is_on_floor()
	
	if jumpStart:
		velocity.y += jumpForce
		
	move_and_slide()
	
	if moveDir.length() > 0.2:
		lastMoveDir = moveDir
	var targetAngle := Vector3.BACK.signed_angle_to(lastMoveDir, Vector3.UP)
	skin.global_rotation.y = lerp(skin.rotation.y, targetAngle, rotationSpd * delta)
	
	if jumpStart:
		skin.jump()
	elif not is_on_floor() and velocity.y < 0:
		skin.fall()
	elif is_on_floor():
		var groundSpd := velocity.length()
		if groundSpd > 0.0:
			skin.run()
		else:
			skin.idle()
			
	var xForm = AlignToFloor(global_transform, $RayCast3D.get_collision_normal())
	global_transform = global_transform.interpolate_with(xForm, 0.2)
func AlignToFloor(xForm, newY):
	xForm.basis.y = newY
	xForm.basis.x = -xForm.basis.z.cross(newY)
	xForm.basis = xForm.basis.orthonormalized()
	return xForm


func floorNormal():
	return get_floor_normal().angle_to(Vector3(0, -1, 0))
