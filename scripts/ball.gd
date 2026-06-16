extends RigidBody3D

const RADIUS := 0.3

var _carrier: Node3D = null


func _ready() -> void:
	add_to_group("ball")


func is_carried() -> bool:
	return _carrier != null


## Returns the current carrier, or null if the ball is loose.
func get_carrier() -> Node3D:
	return _carrier


## Attaches the ball to a carrier (player). Ignored if already carried.
func attach_to(carrier: Node3D) -> void:
	if _carrier != null:
		return
	_carrier = carrier
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


## Places the ball at a world position while carried (called by the carrier).
func carry_to(pos: Vector3) -> void:
	global_position = pos


## Releases the ball back to physics, optionally with an impulse.
func release(impulse: Vector3 = Vector3.ZERO) -> void:
	_carrier = null
	freeze = false
	if impulse != Vector3.ZERO:
		apply_central_impulse(impulse)
