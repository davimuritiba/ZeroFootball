extends CharacterBody3D

const SPEED             := 7.0
const GRAVITY           := 20.0
const TURN_SPEED        := 12.0

const CAPTURE_RADIUS    := 1.1
const DRIBBLE_DISTANCE  := 0.8
const BALL_HEIGHT       := 0.3
const RECAPTURE_DELAY   := 0.4
const STEAL_RANGE       := 1.5
const STEAL_VICTIM_CD   := 0.8

const KICK_FORCE        := 16.0
const KICK_STRONG_FORCE := 26.0

var team: String = "home"

@export var home_pos: Vector3 = Vector3(-6.0, 0.0, 0.0)

var _ball: RigidBody3D = null
var _facing_angle: float = 0.0
var _recapture_timer: float = 0.0
var _human_control: bool = false

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("home_controllable")
	call_deferred("_find_ball")


func _find_ball() -> void:
	_ball = get_tree().get_first_node_in_group("ball")


func set_human_control(enabled: bool) -> void:
	_human_control = enabled
	if not enabled:
		velocity.x = 0.0
		velocity.z = 0.0


func is_human_controlled() -> bool:
	return _human_control


func reset_to_home() -> void:
	velocity = Vector3.ZERO
	global_position = home_pos
	_recapture_timer = 0.0


func _physics_process(delta: float) -> void:
	if _recapture_timer > 0.0:
		_recapture_timer -= delta

	if _human_control:
		_process_human(delta)
	else:
		_process_teammate_ai(delta)

	move_and_slide()

	if _visual and _visual.has_method("update_animation"):
		var flat_speed := Vector2(velocity.x, velocity.z).length()
		_visual.set_move_speed(flat_speed)
		_visual.update_animation(delta)

	_update_possession()


func _process_human(delta: float) -> void:
	var dir := InputHelper.movement_vector()
	if dir.length_squared() > 0.0:
		_facing_angle = atan2(dir.x, dir.z)
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, _facing_angle, TURN_SPEED * delta)

	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if _has_ball():
		if InputHelper.kick_strong_pressed():
			_release_ball(KICK_STRONG_FORCE)
		elif InputHelper.kick_pressed():
			_release_ball(KICK_FORCE)
	elif InputHelper.tackle_pressed():
		_try_tackle()


func _process_teammate_ai(delta: float) -> void:
	if not _ball:
		return

	var target: Vector3
	if _ball.is_carried():
		var carrier: Node = _ball.get_carrier()
		if carrier and carrier.get("team") == team:
			# Aliado com bola: avança ao ataque (home team ataca para +X)
			var ball_pos := _ball.global_position
			var ball_bonus := clampf(ball_pos.x * 0.3, 0.0, 6.0)
			var target_x := clampf(home_pos.x + 12.0 + ball_bonus, -23.0, 23.0)
			target = Vector3(target_x, 0.0, home_pos.z)
		else:
			target = _ball.global_position
	else:
		target = _ball.global_position

	var to := target - global_position
	to.y = 0.0
	if to.length() > 1.2:
		var dir := to.normalized()
		_facing_angle = atan2(dir.x, dir.z)
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, _facing_angle, TURN_SPEED * 0.7 * delta)
		velocity.x = dir.x * SPEED * 0.85
		velocity.z = dir.z * SPEED * 0.85
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= GRAVITY * delta


func _forward() -> Vector3:
	return Vector3(sin(_facing_angle), 0.0, cos(_facing_angle))


func _has_ball() -> bool:
	return _ball != null and _ball.get_carrier() == self


func on_ball_stolen() -> void:
	_recapture_timer = STEAL_VICTIM_CD


func _is_opponent(node: Node) -> bool:
	if node.is_in_group("home_controllable"):
		return node != self
	var node_team = node.get("team")
	if node_team == null:
		return true
	return node_team != team


func _try_tackle() -> void:
	if not _ball or _has_ball() or _recapture_timer > 0.0:
		return
	if not _ball.is_carried():
		return
	var carrier := _ball.get_carrier() as Node
	if not carrier or not _is_opponent(carrier):
		return
	if global_position.distance_to(carrier.global_position) > STEAL_RANGE:
		return
	if _ball.steal_by(self):
		if _visual and _visual.has_method("play_kick"):
			_visual.play_kick()


func _update_possession() -> void:
	if not _ball:
		return

	if _has_ball():
		var target := global_position + _forward() * DRIBBLE_DISTANCE
		target.y = BALL_HEIGHT
		_ball.carry_to(target)
		return

	if _recapture_timer > 0.0 or _ball.is_carried():
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
	if _visual and _visual.has_method("play_kick"):
		_visual.play_kick()
	var impulse := _forward() * force
	_ball.release(impulse)
	_recapture_timer = RECAPTURE_DELAY
