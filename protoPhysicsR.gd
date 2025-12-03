extends RigidBody3D

@onready var ray = $RayCast3D
@onready var groundCheck = $AreaBody3D

@export var acc : float = 0.5
@export var dec : float = 1.05
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
var groundNormal : Vector3
var collisionPointNormal : Vector3

var gravity : Vector3
var moveInput : Vector3
var previousInput : Vector3
var rawInput: Vector3
var previousRawInput : Vector3
var previousRawInputForAim : Vector3



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	previousInput = Vector3.FORWARD

func _physics_process(delta: float) -> void:
	#print("Ray origin:", $RayCast3D.global_position)
	#print("Ray target:", $RayCast3D.to_global($RayCast3D.target_position))
	print("ray: ", ray.is_colliding())
	#DebugDraw3D.draw_arrow_ray(ray.position, Vector3(0, -1, 0), ray.target_position.y)

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
		
	curvePosAcc = lerp(curvePosAcc, accoverSpd.sample((linear_velocity.length_squared() / maxSpd)/maxSpd), get_physics_process_delta_time() * AccellShiftOverSpeed)
	curvePosTang = lerp(curvePosTang, tangentDragOverSpd.sample((linear_velocity.length_squared()/ maxSpd)/maxSpd), get_physics_process_delta_time() * TangentialDragShiftSpeed)
	curvePosSlope = lerp(curvePosSlope, SlopePowerOverSpeed.sample((linear_velocity.length_squared()/maxSpd)/maxSpd), get_physics_process_delta_time() * SlopePowerShiftSpeed)
	
	var XZmag = Vector3(linear_velocity.x, 0, linear_velocity.z).length()
	
	print("vel: ", linear_velocity)
	
	if XZmag > maxSpd:
		var reducedSpd : Vector3 = linear_velocity
		var keepY : float = linear_velocity.y
		reducedSpd = reducedSpd.limit_length(maxSpd)
		reducedSpd.y = keepY
		linear_velocity = reducedSpd
	
	if abs(linear_velocity.y) > maxFallSpd:
		var reducedSpd : Vector3 = linear_velocity
		var keepX : float = linear_velocity.x
		var keepZ : float = linear_velocity.z
		reducedSpd = reducedSpd.limit_length(maxFallSpd)
		reducedSpd.x = keepX
		reducedSpd.z = keepZ
		linear_velocity = reducedSpd
	
	if ray.is_colliding():
		groundNormal = ray.get_collision_normal()
		onGround = true
		groundMovement()
		print("groundNormal: ", groundNormal)
	else:
		groundNormal = Vector3.ZERO
		onGround = false
		groundMovement()
		#print("false")
	print(groundCheck)
	
	#if onGround:
		#rotation = Quaternion(transform.basis.y, groundNormal) * rotation
		#
		#keepNormal = groundNormal
		#keepNormalCounter = 0
	#else:
		#keepNormalCounter += 1
		#if (keepNormalCounter < 5):
			#rotation = Quaternion(transform.basis.y, keepNormal) * rotation
		#else:
			#rotation = Vector3(0, rotation.y, 0)
	
	print("rotation:", rotation)
	
func groundControl(delta : float, input : Vector3):
	print("GC true")
	
	if (input.length_squared() != 0):
		
		var inputDir = input.normalized()
		var inputMagnitude = input.length()
		
		var velocity = linear_velocity
		var localVelocity = global_transform.basis.inverse() * velocity
		
		var lateralVelocity = Vector3(localVelocity.x, 0, localVelocity.z)
		var verticalVelocity = Vector3(0, localVelocity.y, 0)
		
		var normalSpd = lateralVelocity.dot(inputDir)
		var normalVelocity = inputDir * normalSpd
		var tangetVelocity = lateralVelocity - normalVelocity
		
		if (normalSpd < topSpd):
			normalSpd += acc * delta * inputMagnitude
			normalVelocity = min(normalSpd, topSpd)
			
			if (normalSpd >= 0):
				normalVelocity = inputDir * normalSpd
				
			else:
				normalVelocity = inputDir * normalSpd
		
		var curvePosTang : float = (linear_velocity.length_squared() / maxSpd) / maxSpd
		
		tangetVelocity = tangetVelocity.move_toward(Vector3.ZERO, (TangentialDrag * tangentDragOverSpd.sample(curvePosTang)) * delta * inputMagnitude)
		
		localVelocity = normalVelocity + tangetVelocity + verticalVelocity
		velocity = global_transform.basis * localVelocity
		linear_velocity = velocity
		
		b_normalSpeed = normalSpd
		b_normalVelocity = normalVelocity
		b_tangentVelocity = tangetVelocity
		
		print("Input Direction: ", inputDir)
		print("input magnitude: ", inputMagnitude)
		#print("velocity: ", velocity)
		#print("localVelocity: ", localVelocity)
		#print("lateralVelocity: ", lateralVelocity)
		#print("verticalVelocity: ", verticalVelocity)
		#print("normalSpd: ", normalSpd)
		#print("normalVelocity: ", normalVelocity)
		#print("tangetVelocity: ", tangetVelocity)

func groundMovement():
	print("GM true")
	slopePhysics()
	
	groundControl(1, moveInput * curvePosAcc)
	
	if (moveInput == Vector3.ZERO):
		linear_velocity = linear_velocity / dec
	
	speedMagnitude = linear_velocity.length()

func slopePhysics():
	
	if (wasOnAir and onGround):
		print("slopes")
		var addSpd : Vector3
		
		addSpd = groundNormal * LandingConversionFactor
		stickToground(GroundStickingPower)
		
		addSpd.y = 0 
		addVelocity(addSpd)
		wasOnAir = false
	
	if (linear_velocity.length_squared() < slopeSpdLimit and SlopeRunningAngleLimit > groundNormal.y):
		transform.basis = Quaternion.IDENTITY
		print("quant:", Quaternion.IDENTITY)
		addVelocity(groundNormal * 3)
	else:
		stickToground(GroundStickingPower)
	
	if (onGround and groundNormal.y < slopeStandingLimit):
		if linear_velocity.y > StartDownhillMultiplier:
			var force : Vector3 = Vector3(0, (slopeFactor * curvePosSlope) * UphillMultiplier, 0) * RollingUphillBoost
			addVelocity(force)
			
		if (moveInput != Vector3.ZERO and b_normalSpeed > 0):
			var force : Vector3 = Vector3(0, (slopeFactor * curvePosSlope) * DownhillMultiplier , 0)
			addVelocity(force)
		else:
			var force : Vector3 = Vector3(0, (slopeFactor * curvePosSlope) , 0)
			addVelocity(force)

func stickToground(stickingPower : float):
	
	ray.look_at(ray.get_collision_point(), position)
	#look_at(ray.get_collision_normal(), Vector3.UP)
	
	if ray.is_colliding() and not Input.is_action_pressed("jump"):
		var force : Vector3 = ray.get_collision_normal() * stickingPower
		addVelocity(force)

func addVelocity(force : Vector3):
	linear_velocity = linear_velocity + force
