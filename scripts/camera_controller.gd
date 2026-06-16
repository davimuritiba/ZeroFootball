extends Camera3D

## Broadcast-style side camera with subtle depth of field.

@export var cam_height   : float = 24.0
@export var cam_distance  : float = 28.0
@export var cam_side      : float = -1.0
@export var follow_speed  : float = 5.0
@export var x_damp        : float = 0.65
@export var x_clamp       : float = 13.0
@export var z_lead        : float = 0.12
@export var look_height   : float = 0.8

var _ball: Node3D = null


func _ready() -> void:
	fov = 44.0
	_setup_camera_attributes()
	call_deferred("_find_ball")
	_update(0.0, 0.0)


func _setup_camera_attributes() -> void:
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 65.0
	attrs.dof_blur_far_transition = 28.0
	attrs.dof_blur_amount = 0.14
	attributes = attrs


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
	look_at(Vector3(cam_x * 0.55, look_height, -cam_side * 6.0))
