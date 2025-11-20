extends CharacterBody3D

@onready var floorRay = $RayCast3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouseSensitivty := 0.25
var cameraInputDirection := Vector2.ZERO

@onready var cameraPivot : Node3D = %CameraPivot
@onready var camera : Camera3D = %Camera3D

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

func _process(delta: float) -> void:
	var jumpStart := Input.is_action_just_pressed("jump") and is_on_floor()
	
	if jumpStart:
		velocity = Vector3.UP * 24
		
	move_and_slide()

func _physics_process(delta: float) -> void:
	cameraPivot.rotation.x += cameraInputDirection.y * delta
	cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, -PI/6.0, PI/3.0)
	
	cameraPivot.rotation.y -= cameraInputDirection.x * delta
	
	cameraInputDirection = Vector2.ZERO
	
	if not is_on_floor():
		velocity -= Vector3.UP * 21# * delta
	
	var verticalVelocity : Vector3 = project_on_plane(velocity, floorRay.get_collision_normal())
	
	velocity = (Vector3.RIGHT * Input.get_axis('move_right', 'move_left') * 10) + (Vector3.FORWARD * Input.get_axis('move_up', 'move_down') * 10) * transform.basis.orthonormalized()
	
	move_and_slide()
	
	print(verticalVelocity)
static func project_on_plane(vector: Vector3, surface_normal: Vector3) -> Vector3:
	var axis1 = vector.cross(surface_normal).normalized()
	var axis2 = axis1.cross(-surface_normal).normalized()
	
	return vector.project(axis1) + vector.project(axis2)
