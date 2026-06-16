class_name InputHelper

## Shared camera-relative movement input (north-side broadcast camera).


static func movement_vector() -> Vector3:
	var dir := Vector3.ZERO
	dir.x = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	dir.z = Input.get_action_strength("move_up")   - Input.get_action_strength("move_down")
	if dir.length_squared() > 0.0:
		dir = dir.normalized()
	return dir


static func kick_pressed() -> bool:
	return Input.is_action_just_pressed("kick")


static func kick_strong_pressed() -> bool:
	return Input.is_action_just_pressed("kick_strong")


static func tackle_pressed() -> bool:
	return Input.is_action_just_pressed("tackle")
