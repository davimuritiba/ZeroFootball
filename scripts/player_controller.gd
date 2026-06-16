extends CharacterBody3D

const SPEED             := 7.0
const GRAVITY           := 20.0
const TURN_SPEED        := 12.0

# Possession tuning
const CAPTURE_RADIUS    := 1.1    # distance to grab a loose ball
const DRIBBLE_DISTANCE  := 0.8    # how far in front the ball sits while carried
const BALL_HEIGHT       := 0.3    # carried ball centre height (ball radius)
const RECAPTURE_DELAY    := 0.4   # seconds before the ball can be regrabbed

# Temporary release action (full action set comes later)
const KICK_FORCE        := 16.0
const KICK_STRONG_FORCE := 26.0

var team: String = "home"

var _ball: RigidBody3D = null
var _facing_angle: float = 0.0
var _recapture_timer: float = 0.0

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("player")
	call_deferred("_find_ball")


func _find_ball() -> void:
	_ball = get_tree().get_first_node_in_group("ball")


func _physics_process(delta: float) -> void:
	if _recapture_timer > 0.0:
		_recapture_timer -= delta

	var dir := Vector3.ZERO
	dir.x = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	dir.z = Input.get_action_strength("move_up")   - Input.get_action_strength("move_down")

	if dir.length_squared() > 0.0:
		dir = dir.normalized()
		_facing_angle = atan2(dir.x, dir.z)
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, _facing_angle, TURN_SPEED * delta)

	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	move_and_slide()

	_update_possession()

	# Temporary release controls; richer actions will be added later
	if _has_ball():
		if Input.is_action_just_pressed("kick_strong"):
			_release_ball(KICK_STRONG_FORCE)
		elif Input.is_action_just_pressed("kick"):
			_release_ball(KICK_FORCE)


func _forward() -> Vector3:
	return Vector3(sin(_facing_angle), 0.0, cos(_facing_angle))


func _has_ball() -> bool:
	return _ball != null and _ball.has_method("get_carrier") and _ball.get_carrier() == self


func _update_possession() -> void:
	if not _ball:
		return

	if _has_ball():
		# Keep the ball glued just in front of the player
		var target := global_position + _forward() * DRIBBLE_DISTANCE
		target.y = BALL_HEIGHT
		_ball.carry_to(target)
		return

	# Try to capture a loose ball
	if _recapture_timer > 0.0:
		return
	if _ball.is_carried():
		return
	var flat_dist := Vector2(
		_ball.global_position.x - global_position.x,
		_ball.global_position.z - global_position.z
	).length()
	if flat_dist <= CAPTURE_RADIUS:
		_ball.attach_to(self)


func _release_ball(force: float) -> void:
	if not _has_ball():
		return
	var impulse := _forward() * force
	_ball.release(impulse)
	_recapture_timer = RECAPTURE_DELAY
