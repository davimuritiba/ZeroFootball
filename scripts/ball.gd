extends RigidBody3D

const RADIUS := 0.3

var _carrier: Node3D = null


func _ready() -> void:
	add_to_group("ball")


func is_carried() -> bool:
	return _carrier != null


func get_carrier() -> Node3D:
	return _carrier


func attach_to(carrier: Node3D) -> void:
	if _carrier != null:
		return
	_carrier = carrier
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func carry_to(pos: Vector3) -> void:
	global_position = pos


func release(impulse: Vector3 = Vector3.ZERO) -> void:
	_carrier = null
	freeze = false
	if impulse != Vector3.ZERO:
		apply_central_impulse(impulse)


## Takes the ball from the current carrier (tackle / steal).
func steal_by(thief: Node3D) -> bool:
	if _carrier == null or _carrier == thief:
		return false
	var victim := _carrier
	_carrier = thief
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	if victim.has_method("on_ball_stolen"):
		victim.on_ball_stolen()
	return true
