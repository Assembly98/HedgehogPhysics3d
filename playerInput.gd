extends Node

@export var player : RigidBody3D

var move : Vector3
var camForward : Vector3
@export var utopiaTurning : bool
@export var inputLerpSpd : float
var utopiaInput : Vector3
@export var utopiaIntesity : float
@export var utopiaInitialInputLerpSpd : float
@export var utopiaLerpingSpd : float
@export var initalInputMag : float
@export var initalLerpedInput : float

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 6.0

var _camera_input_direction := Vector2.ZERO

@onready var _camera_pivot = $"../CameraPiviot"


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var hInput = Input.get_axis("Right", "Left")
	var vInput = Input.get_axis("Down", "Up")
	
	#print(_camera_pivot)
	
	if (_camera_pivot != null):
		var moveInp : Vector3 = Vector3(hInput, 0, vInput)
		
		initalInputMag = moveInp.length_squared()
		initalLerpedInput = lerp(initalLerpedInput, initalInputMag, utopiaInitialInputLerpSpd * delta)
		
		#print("moveInp: ", moveInp)
		
		var rotation = safeAxisAngleRot(_camera_pivot.transform.basis.y, player.groundNormal)
		var axis = rotation["axis"]
		var angle = rotation["angle"]
		
		#print("angle: ", angle)
		#print("axis: ", axis)
		
		if (!utopiaTurning):
			if (moveInp != Vector3.ZERO):
				var transformedInput : Vector3 = Quaternion(axis, angle) * (_camera_pivot.transform.basis * moveInp)
				transformedInput = player.global_transform.basis.inverse() * transformedInput
				transformedInput.y = 0.0
				player.rawInput = transformedInput
				moveInp = move.lerp(transformedInput, inputLerpSpd * delta)
				#rint("moveInp: ", moveInp)
			else:
				var transformedInput : Vector3 = Quaternion(axis, angle) * (_camera_pivot.transform.basis * moveInp)
				transformedInput = player.global_transform.basis.inverse() * transformedInput
				transformedInput.y = 0.0
				player.rawInput = transformedInput
				moveInp = move.lerp(transformedInput, (inputLerpSpd * 10) * delta)
				
		else:
			if (moveInp != Vector3.ZERO):
				var transformedInput : Vector3 = Quaternion(axis, angle) * (_camera_pivot.transform.basis * moveInp)
				transformedInput = player.global_transform.basis.inverse() * transformedInput
				transformedInput.y = 0.0
				player.rawInput = transformedInput
				moveInp = move.lerp(transformedInput, utopiaLerpingSpd * delta)
			else:
				var transformedInput : Vector3 = Quaternion(axis, angle) * (_camera_pivot.transform.basis * moveInp)
				transformedInput = player.global_transform.basis.inverse() * transformedInput
				transformedInput.y = 0.0
				player.rawInput = transformedInput
				moveInp = move.lerp(transformedInput, (utopiaLerpingSpd * 10) * delta)
				
		move = moveInp
		
		
		if (utopiaTurning):
			if (moveInp != Vector3.ZERO):
				utopiaInput = (moveInp * utopiaIntesity) * initalLerpedInput
				utopiaInput = utopiaInput.limit_length(1)
			else:
				utopiaInput = Vector3.ZERO
			
			move = utopiaInput
			
func _physics_process(delta: float) -> void:
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO
	
	player.moveInput = move
	
	#_camera_pivot.position = player.position
	
	print("camPos: ", _camera_pivot.position)
	print("playerPos: ", player.position)
	
	print("move: ", player.moveInput)


func safeAxisAngleRot(cameraUp : Vector3, groundNormal : Vector3):
	var results = {}
	
	var dot = cameraUp.normalized().dot(groundNormal.normalized())
	
	var axis = cameraUp.normalized().cross(groundNormal.normalized())
	
	if dot < -0.999 or axis.length() < 0.0001:
		var fallBack = Vector3.RIGHT
		if abs(cameraUp.normalized().dot(fallBack)) > 0.99:
			fallBack = Vector3.FORWARD
		axis = fallBack
	
	results["axis"] = axis.normalized()
	results["angle"] = cameraUp.normalized().angle_to(groundNormal.normalized())
	
	return results
