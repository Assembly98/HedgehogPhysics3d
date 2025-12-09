extends Node

@export var player : RigidBody3D
@onready var anim = $"../dummyCopy/AnimationPlayer"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func _physics_process(delta: float) -> void:
	anim.speed_scale = player.linear_velocity.length() / 14
	
	if $"../wallDetector".is_colliding():
		anim.play("splat")
		print("true")
	
	if abs(player.linear_velocity.length()) >= 1 and abs(player.linear_velocity.length()) <= 50:
		anim.play("jog")
	elif abs(player.linear_velocity.length()) >= 50 and abs(player.linear_velocity.length()) <= 100:
		anim.play("run")
	elif abs(player.linear_velocity.length()) > 100:
		anim.play("sprint")
	else:
		if not anim.current_animation == "splat":
			anim.play("Idle")
	
	
	if Input.is_action_pressed("jump"):
		#anim.speed_scale = 1 
		#anim.play("jump")
		anim.play("jump")
		#await(anim.animation_finished)
	if Input.is_action_just_released("jump"):
		anim.play("fallTransition")
		
	#if player.linear_velocity.y > 0 and not $"../RayCast3D".is_colliding():# and anim.animation_finished == 'jump':
	#	anim.animation_get_next("fallTransition")
	#	anim.play("fallTransition")

	if not $"../RayCast3D".is_colliding() and not Input.is_action_pressed("jump"):
		anim.speed_scale = 1
		anim.play("fall")
	else:
		if $"../wallDetector".is_colliding():
			anim.play("splat")
			print("true")
		
		if abs(player.linear_velocity.length()) >= 1 and abs(player.linear_velocity.length()) <= 50:
			anim.play("jog")
		elif abs(player.linear_velocity.length()) >= 50 and abs(player.linear_velocity.length()) <= 100:
			anim.play("run")
		elif abs(player.linear_velocity.length()) > 100:
			anim.play("sprint")
		else:
			if not anim.current_animation == "splat":
				anim.play("Idle")
		
		if Input.is_action_pressed("jump"):
		#anim.speed_scale = 1 
			#anim.play("jump")
			anim.play("jump")
		if Input.is_action_just_released("jump"):
			anim.play("fallTransition")
