extends CharacterBody3D

@onready var ray = $RayCast3D
@onready var groundCheck = $AreaBody3D

@export var acc : float = 0.5
@export var dec : float = 1.3
@export var airDec : float = 1.05
@export var topSpd : float = 15
@export var maxSpd : float = 30
@export var maxFallSpd : float = 12
@export var slopeFactor : float = 2
@export var AccellShiftOverSpeed : float
@export var TangentialDragShiftSpeed : float
@export var TangentialDrag : float
@export var SlopePowerShiftSpeed : float
@export var accoverSpd : Curve
@export var tangentDragOverSpd : Curve
@export var SlopePowerOverSpeed : Curve
var LandingConversionFactor : float = 2
var slopeSpdLimit : float = 10
var SlopeRunningAngleLimit : float = 0.5
var GroundStickingPower : float = -1
var slopeStandingLimit : float = 0.8
var StartDownhillMultiplier : float = -7
var UphillMultiplier : float = 0.5
var DownhillMultiplier : float  = 2
var RollingUphillBoost : float
var AirControlAmmount : float = 2
var keepNormal : Vector3
var keepNormalCounter : float


var curvePosAcc : float
var curvePosTang : float
var curvePosSlope : float
var speedMagnitude : float
var b_normalSpeed : float
var b_normalVelocity : Vector3
var b_tangentVelocity : Vector3

var onGround : bool
var wasOnAir : bool
var StopAirMovementIfNoInput : bool = false
var groundNormal : Vector3
var collisionPointNormal : Vector3

var gravity : Vector3
var moveInput : Vector3
var previousInput : Vector3
var rawInput: Vector3
var previousRawInput : Vector3
var previousRawInputForAim : Vector3

var xForm : Transform3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	previousInput = Vector3.FORWARD

func _physics_process(delta: float) -> void:
	#print("Ray origin:", $RayCast3D.global_position)
	#print("Ray target:", $RayCast3D.to_global($RayCast3D.target_position))
	print("ray: ", ray.is_colliding())
	print("rayNormal: ", ray.get_collision_normal())
	#DebugDraw3D.draw_arrow_ray(ray.position, Vector3(0, -1, 0), ray.target_position.y)
	#linear_velocity = linear_velocity + Vector3(0, -1.5, 0)
	if Input.is_action_pressed("jump"): #and ray.is_colliding():
		position += (ray.get_collision_normal() * 1.5)
		print('true')
		
	move_and_slide()
	
	#ray.target_position.y = -1.5
	#ray.global_position = global_position
	generalPhysics()
	
	#angular_velocity = Vector3.ZERO
	$CameraPiviot.global_position = global_position
	#look_at(linear_velocity, Vector3.UP)
	
	
func generalPhysics() -> void:
	
	if rawInput.length_squared() >= 0.03:
		previousRawInputForAim = rawInput * 90
		previousRawInputForAim = previousRawInputForAim.normalized()
	
	if moveInput.length_squared() >= 0.9:
		previousInput = moveInput
	
	if rawInput.length_squared() >= 0.9:
		previousInput = rawInput
		
	curvePosAcc = lerp(curvePosAcc, accoverSpd.sample((velocity.length_squared() / maxSpd)/maxSpd), get_physics_process_delta_time() * AccellShiftOverSpeed)
	curvePosTang = lerp(curvePosTang, tangentDragOverSpd.sample((velocity.length_squared()/ maxSpd)/maxSpd), get_physics_process_delta_time() * TangentialDragShiftSpeed)
	curvePosSlope = lerp(curvePosSlope, SlopePowerOverSpeed.sample((velocity.length_squared()/maxSpd)/maxSpd), get_physics_process_delta_time() * SlopePowerShiftSpeed)
	
	var XZmag = Vector3(velocity.x, 0, velocity.z).length()
	
	print("vel: ", velocity)
	print("velLength: ", velocity.length())
	
	if XZmag > maxSpd:
		var reducedSpd : Vector3 = velocity
		var keepY : float = velocity.y
		reducedSpd = reducedSpd.limit_length(maxSpd)
		reducedSpd.y = keepY
		velocity = reducedSpd
	
	if abs(velocity.y) > maxFallSpd:
		#var reducedSpd : Vector3 = velocity
		#var keepX : float = velocity.x
		#var keepZ : float = velocity.z
		#reducedSpd = reducedSpd.limit_length(maxFallSpd)
		#reducedSpd.x = keepX
		#reducedSpd.z = keepZ
		velocity.y = sign(velocity.y) * maxFallSpd
	
	if ray.is_colliding():
		groundNormal = ray.get_collision_normal()
		onGround = true
		groundMovement()
		print("groundNormal: ", groundNormal)
	else:
		groundNormal = Vector3.ZERO
		onGround = false
		airMovement()
		#print("false")
	#print(groundCheck)
	
	if onGround:
		alignWithFloor($RayCast3D.get_collision_normal())
		global_transform = global_transform.interpolate_with(xForm, 0.3)
		#transform.basis = Basis(rotAxis.normalized(), (angle)) * transform.basis
		#$dummyCopy.global_rotation = Basis(rotAxis.normalized(), angle) * $dummyCopy.global_rotation
		
		keepNormal = groundNormal
		keepNormalCounter = 0
	else:
		keepNormalCounter += 1
		if (keepNormalCounter < 5):
			alignWithFloor($RayCast3D.get_collision_normal())
			global_transform = global_transform.interpolate_with(xForm, 0.3)
			#transform.basis = Basis(rotAxis.normalized(), angle) * transform.basis
		#	$dummyCopy.global_rotation = Basis(rotAxis.normalized(), angle) * $dummyCopy.global_rotation
		else:
			rotation = Vector3(0, rotation.y, 0)
	
	move_and_slide()
	
	print("rotation:", transform.basis)
	
func groundControl(delta : float, input : Vector3):
	#print("GC true")
	
	if (input.length_squared() != 0):
		
		var inputDir = input.normalized()
		var inputMagnitude = input.length()
		
		#var velocity = velocity
		var localVelocity = global_transform.basis.inverse() * velocity
		
		var lateralVelocity = Vector3(localVelocity.x, 0, localVelocity.z)
		var verticalVelocity = Vector3(0, localVelocity.y, 0)
		
		var normalSpd = lateralVelocity.dot(inputDir)
		var normalVelocity = inputDir * normalSpd
		var tangetVelocity = lateralVelocity - normalVelocity
		
		if (normalSpd < topSpd):
			normalSpd += (acc * delta * inputMagnitude)/2
			#normalSpd = min(normalSpd, topSpd)
			if normalSpd >= topSpd:
				normalSpd = topSpd
			
			if (normalSpd >= 0):
				normalVelocity = inputDir * normalSpd
				
			else:
				normalVelocity = inputDir * normalSpd
		
		var curvePosTang : float = (velocity.length_squared() / maxSpd) / maxSpd
		
		tangetVelocity = tangetVelocity.move_toward(Vector3.ZERO, (TangentialDrag * tangentDragOverSpd.sample(curvePosTang)) * delta * inputMagnitude)
		
		localVelocity = normalVelocity + tangetVelocity + verticalVelocity
		velocity = global_transform.basis * localVelocity
		velocity = velocity
		
		b_normalSpeed = normalSpd
		b_normalVelocity = normalVelocity
		b_tangentVelocity = tangetVelocity
		
		
		#print("Input Direction: ", inputDir)
		#print("input magnitude: ", inputMagnitude)
		#print("velocity: ", velocity)
		#print("localVelocity: ", localVelocity)
		#print("lateralVelocity: ", lateralVelocity)
		#print("verticalVelocity: ", verticalVelocity)
		#print("normalSpd: ", normalSpd)
		#print("normalVelocity: ", normalVelocity)
		#print("tangetVelocity: ", tangetVelocity)

func groundMovement():
	#print("GM true")
	slopePhysics()
	
	groundControl(1, moveInput * curvePosAcc)
	
	if (moveInput == Vector3.ZERO):
		velocity = velocity / dec
	
	speedMagnitude = velocity.length()



func slopePhysics():
	
	if (wasOnAir and onGround):
		#print("slopes")
		var addSpd : Vector3
		
		addSpd = groundNormal * LandingConversionFactor
		stickToground(GroundStickingPower)
		
		addSpd.y = 0 
		addVelocity(addSpd)
		wasOnAir = false
	
	if (velocity.length_squared() < slopeSpdLimit and SlopeRunningAngleLimit > groundNormal.y):
		transform.basis = Basis.IDENTITY
		#print("quant:", Quaternion.IDENTITY)
		addVelocity(groundNormal * 3)
	else:
		stickToground(GroundStickingPower)
	
	if (onGround and groundNormal.y < slopeStandingLimit):
		if velocity.y > StartDownhillMultiplier:
			var force : Vector3 = Vector3(0, (slopeFactor * curvePosSlope) * UphillMultiplier, 0)
			addVelocity(force)
			
		if (moveInput != Vector3.ZERO and b_normalSpeed > 0):
			var force : Vector3 = Vector3(0, (slopeFactor * curvePosSlope) * DownhillMultiplier , 0)
			addVelocity(force)
		else:
			var force : Vector3 = Vector3(0, (slopeFactor * curvePosSlope) , 0)
			addVelocity(force)

func stickToground(stickingPower : float):
	if ray.is_colliding() and not Input.is_action_pressed("jump"):
		var force : Vector3 = ray.get_collision_normal() * stickingPower
		addVelocity(force)

func addVelocity(force : Vector3):
	velocity = velocity + force

func airMovement():
	groundControl(AirControlAmmount, moveInput)
	
	velocity = velocity + Vector3(0, -1.5, 0)

	if (moveInput == Vector3.ZERO and StopAirMovementIfNoInput):
		var reducedSpd : Vector3 = velocity
		reducedSpd.x = reducedSpd.x / airDec
		reducedSpd.z = reducedSpd.z / airDec
		velocity = reducedSpd
		
	wasOnAir = true
	
	if (b_normalSpeed < 0 and not onGround):
		groundControl(1, (moveInput * 10) * acc)
	
	if velocity.y < -maxFallSpd:
		velocity = Vector3(velocity.x, -maxFallSpd, velocity.z)
	
func alignWithFloor(floorNormal):
	xForm = global_transform
	xForm.basis.y = floorNormal
	xForm.basis.x = -xForm.basis.z.cross(floorNormal)
	xForm.basis = xForm.basis.orthonormalized()
	print("floorNormal(AWF): ", floorNormal)
