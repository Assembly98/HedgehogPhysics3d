extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up"):
		$AnimationPlayer.play("jog")
	else:
		$AnimationPlayer.play("Idle")
