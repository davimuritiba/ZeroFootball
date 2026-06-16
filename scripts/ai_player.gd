extends CharacterBody3D

const SPEED            := 5.5
const GRAVITY          := 20.0
const TURN_SPEED       := 9.0
const CAPTURE_RADIUS   := 1.1
const DRIBBLE_DISTANCE := 0.8
const BALL_HEIGHT      := 0.3
const RECAPTURE_DELAY  := 0.6
const KICK_FORCE       := 14.0
const SHOOT_RANGE      := 9.0
const ARRIVE_DIST      := 1.2

@export var team         : String  = "away"
@export var role         : String  = "midfielder"
@export var home_pos     : Vector3 = Vector3.ZERO
@export var jersey_color : Color   = Color(0.08, 0.18, 0.72, 1.0)
@export var shorts_color : Color   = Color(0.05, 0.05, 0.15, 1.0)

var _ball            : RigidBody3D = null
var _facing_angle    : float = 0.0
var _recapture_timer : float = 0.0
var _attack_x        : float = -1.0

@onready var _visual : Node3D = $Visual


func _ready() -> void:
	add_to_group("ai_player")
	_attack_x = 1.0 if team == "home" else -1.0
	call_deferred("_init_visual")
	call_deferred("_find_ball")


func _init_visual() -> void:
	if _visual and _visual.has_method("configure"):
		_visual.configure(jersey_color, shorts_color)


func _find_ball() -> void:
	_ball = get_tree().get_first_node_in_group("ball")


func _physics_process(delta: float) -> void:
	if not _ball:
		return
	if _recapture_timer > 0.0:
		_recapture_timer -= delta

	var dir := _compute_direction()
	_apply_movement(dir, delta)
	_update_possession()
	_update_carry_and_shoot()


# ── Movimento ─────────────────────────────────────────────────────────────────

func _compute_direction() -> Vector3:
	if _has_ball():
		# Driblando: vai em direção ao gol adversário, centralizando em Z
		var goal_x := _attack_x * 24.0
		var target := Vector3(goal_x, 0.0, global_position.z * 0.3)
		var d := (target - global_position)
		d.y = 0.0
		return d.normalized()

	var target := _tactical_target()
	var to_target := target - global_position
	to_target.y = 0.0
	if to_target.length() < ARRIVE_DIST:
		return Vector3.ZERO
	return to_target.normalized()


func _tactical_target() -> Vector3:
	var ball_pos := _ball.global_position
	var carrier: Node3D = _ball.get_carrier()

	# Goleiro: fica na linha do gol rastreando a bola em Z
	if role == "goalkeeper":
		var my_goal_x := -_attack_x * 25.0
		var gk_x := my_goal_x + _attack_x * 2.5
		var dist_from_goal := absf(ball_pos.x - my_goal_x)
		if dist_from_goal < 7.0:
			return ball_pos  # Bola perto: sai para interceptar
		var track_z := clampf(ball_pos.z * 0.5, -3.5, 3.5)
		return Vector3(gk_x, 0.0, track_z)

	# Jogadores de linha: o mais próximo persegue, os outros mantêm posição
	var should_chase := false
	if carrier == null:
		should_chase = _is_primary_chaser()
	elif _is_opponent(carrier):
		should_chase = _is_primary_chaser()

	if should_chase:
		return ball_pos

	# Desloca a posição tática com base no X da bola
	var shift := clampf(ball_pos.x * 0.2, -5.0, 5.0)
	var adjusted := home_pos + Vector3(shift, 0.0, 0.0)
	adjusted.x = clampf(adjusted.x, -23.0, 23.0)
	return adjusted


# Retorna true se este jogador é o mais próximo da bola no mesmo time
func _is_primary_chaser() -> bool:
	var my_d2 := global_position.distance_squared_to(_ball.global_position)
	for ai in get_tree().get_nodes_in_group("ai_player"):
		if ai == self:
			continue
		if ai.get("team") != team:
			continue
		if ai.get("role") == "goalkeeper":
			continue
		if ai.global_position.distance_squared_to(_ball.global_position) < my_d2 - 0.25:
			return false
	return true


func _is_opponent(node: Node) -> bool:
	var node_team = node.get("team")
	if node_team == null:
		# Jogador humano não tem @export team: assume que é "home"
		return team == "away"
	return node_team != team


func _apply_movement(dir: Vector3, delta: float) -> void:
	if dir.length_squared() > 0.01:
		_facing_angle = atan2(dir.x, dir.z)
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, _facing_angle, TURN_SPEED * delta)
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()


# ── Posse de bola ─────────────────────────────────────────────────────────────

func _has_ball() -> bool:
	return _ball != null and _ball.get_carrier() == self


func _update_possession() -> void:
	if not _ball or _ball.is_carried():
		return
	if _recapture_timer > 0.0:
		return
	var flat_dist := Vector2(
		_ball.global_position.x - global_position.x,
		_ball.global_position.z - global_position.z
	).length()
	if flat_dist <= CAPTURE_RADIUS:
		_ball.attach_to(self)


func _update_carry_and_shoot() -> void:
	if not _has_ball():
		return

	# Mantém a bola à frente enquanto dribla
	var fwd_pos := global_position + _forward() * DRIBBLE_DISTANCE
	fwd_pos.y = BALL_HEIGHT
	_ball.carry_to(fwd_pos)

	# Chuta quando está perto o suficiente do gol adversário
	var goal_pos := Vector3(_attack_x * 25.0, 0.5, 0.0)
	if global_position.distance_to(goal_pos) <= SHOOT_RANGE:
		# Mira levemente em direção ao centro do gol
		var aim_z := clampf(-global_position.z * 0.5, -2.5, 2.5)
		var shoot_dir := (Vector3(_attack_x * 25.0, 0.5, aim_z) - global_position).normalized()
		_ball.release(shoot_dir * KICK_FORCE)
		_recapture_timer = RECAPTURE_DELAY


func _forward() -> Vector3:
	return Vector3(sin(_facing_angle), 0.0, cos(_facing_angle))


# Chamado pelo game_manager após cada gol
func reset_to_home() -> void:
	velocity = Vector3.ZERO
	global_position = home_pos
	_recapture_timer = 0.0
