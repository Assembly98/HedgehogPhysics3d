extends RigidBody3D

@onready var floorRay = $RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !grounded():
		linear_velocity -= Vector3.UP * 10 * delta
	else:
		Vector3.ZERO
		
	var rawInput := Input.get_vector('move_left', 'move_right', 'move_up', 'move_down')
	#var forward := camera.global_basis.z
	#var right : = camera.global_basis.x
	print(rawInput)
	print(grounded())
	print(linear_velocity)
	
	angular_velocity = floorRay.get_collision_normal()
	
func grounded():
	return floorRay.is_colliding()

static func project_on_plane(vector: Vector3, surface_normal: Vector3) -> Vector3:
	var axis1 = vector.cross(surface_normal).normalized()
	var axis2 = axis1.cross(-surface_normal).normalized()
	
	return vector.project(axis1) + vector.project(axis2)
