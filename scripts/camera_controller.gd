extends Camera3D

## Broadcast-style side camera, low and close to the pitch so that
## only the far (front) stand is visible behind the action.

@export var cam_height   : float = 24.0   # height above ground (steep enough to hide sky)
@export var cam_distance  : float = 31.0   # distance from field centre (Z)
@export var cam_side      : float = -1.0   # -1 = north touchline
@export var follow_speed  : float = 5.0    # lateral follow lerp speed
@export var x_damp        : float = 0.7    # how much of ball X is tracked (0–1)
@export var x_clamp       : float = 14.0   # max lateral offset from centre
@export var z_lead        : float = 0.15   # subtle dolly toward the ball depth
@export var look_height   : float = 0.5    # aim near the ground for a downward tilt

var _ball: Node3D = null


func _ready() -> void:
	fov = 55.0
	call_deferred("_find_ball")
	_update(0.0, 0.0)


func _find_ball() -> void:
	_ball = get_tree().get_first_node_in_group("ball")


func _process(delta: float) -> void:
	var target_x := 0.0
	var ball_z := 0.0
	if _ball:
		target_x = clamp(_ball.global_position.x * x_damp, -x_clamp, x_clamp)
		ball_z = _ball.global_position.z

	var new_x := lerpf(global_position.x, target_x, follow_speed * delta)
	_update(new_x, ball_z)


func _update(cam_x: float, ball_z: float) -> void:
	# Pull the camera slightly toward the ball's depth for a livelier feel
	var z := cam_side * cam_distance - cam_side * ball_z * z_lead
	global_position = Vector3(cam_x, cam_height, z)
	# Aim down across the pitch; low target keeps the sky out of frame
	look_at(Vector3(cam_x * 0.6, look_height, -cam_side * 8.0))
