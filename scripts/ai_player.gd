extends CharacterBody3D

const SPEED            := 5.5
const SPEED_CONTROLLED := 7.0
const GRAVITY          := 20.0
const TURN_SPEED       := 9.0
const TURN_SPEED_HUMAN := 12.0
const CAPTURE_RADIUS   := 1.1
const DRIBBLE_DISTANCE := 0.8
const BALL_HEIGHT      := 0.3
const RECAPTURE_DELAY  := 0.6
const STEAL_RANGE      := 1.0
const STEAL_VICTIM_CD  := 0.8
const KICK_FORCE       := 14.0
const KICK_FORCE_HUMAN := 16.0
const KICK_STRONG_HUMAN := 26.0
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
var _tackle_timer    : float = 0.0
var _attack_x        : float = -1.0
var _human_control   : bool = false

@onready var _visual : Node3D = $Visual


func _ready() -> void:
	add_to_group("ai_player")
	if team == "home":
		add_to_group("home_controllable")
	_attack_x = 1.0 if team == "home" else -1.0
	call_deferred("_init_visual")
	call_deferred("_find_ball")


func set_human_control(enabled: bool) -> void:
	_human_control = enabled
	if not enabled:
		velocity.x = 0.0
		velocity.z = 0.0


func is_human_controlled() -> bool:
	return _human_control


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
	if _tackle_timer > 0.0:
		_tackle_timer -= delta

	if _human_control:
		_process_human(delta)
	else:
		var dir := _compute_direction()
		_apply_movement(dir, _get_movement_speed(), delta)
		if not _has_ball() and _tackle_timer <= 0.0:
			if _try_tackle():
				_tackle_timer = 0.5

	_update_possession()
	_update_carry_and_shoot()

	if _visual and _visual.has_method("update_animation"):
		var flat_speed := Vector2(velocity.x, velocity.z).length()
		_visual.set_move_speed(flat_speed)
		_visual.update_animation(delta)


func _process_human(delta: float) -> void:
	var dir := InputHelper.movement_vector()
	var speed := SPEED_CONTROLLED
	var turn := TURN_SPEED_HUMAN
	if dir.length_squared() > 0.0:
		_facing_angle = atan2(dir.x, dir.z)
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, _facing_angle, turn * delta)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()

	if _has_ball():
		if InputHelper.kick_strong_pressed():
			_human_release(KICK_STRONG_HUMAN)
		elif InputHelper.kick_pressed():
			_human_release(KICK_FORCE_HUMAN)
	elif InputHelper.tackle_pressed():
		_try_tackle()


func _human_release(force: float) -> void:
	if not _has_ball():
		return
	if _visual and _visual.has_method("play_kick"):
		_visual.play_kick()
	_ball.release(_forward() * force)
	_recapture_timer = RECAPTURE_DELAY


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
			return ball_pos
		var track_z := clampf(ball_pos.z * 0.5, -3.5, 3.5)
		return Vector3(gk_x, 0.0, track_z)

	# Bola livre: apenas o mais próximo vai buscar
	if carrier == null:
		if _is_primary_chaser():
			return ball_pos
		var shift := clampf(ball_pos.x * 0.2, -5.0, 5.0)
		var adjusted := home_pos + Vector3(shift, 0.0, 0.0)
		adjusted.x = clampf(adjusted.x, -23.0, 23.0)
		return adjusted

	# Adversário com a bola: pressão coordenada com múltiplos jogadores
	if _is_opponent(carrier):
		var rank := _chase_rank()
		if rank == 0:
			# Mais próximo: pressiona o portador diretamente
			return ball_pos
		elif rank == 1:
			# Segundo mais próximo: intercepta o caminho entre portador e nosso gol
			return _intercept_point(carrier.global_position)
		else:
			# Demais: cobertura defensiva entre a bola e o gol
			return _defensive_cover_position(ball_pos)

	# Aliado com a bola: avança ao ataque em conjunto imediatamente
	var ball_bonus := clampf(ball_pos.x * _attack_x * 0.3, 0.0, 6.0)
	var target_x := clampf(home_pos.x + _attack_x * (12.0 + ball_bonus), -23.0, 23.0)
	return Vector3(target_x, 0.0, home_pos.z)


# Rank de proximidade à bola entre companheiros de time (sem goleiro)
func _chase_rank() -> int:
	var my_d2 := global_position.distance_squared_to(_ball.global_position)
	var rank := 0
	for ai in get_tree().get_nodes_in_group("ai_player"):
		if ai == self or ai.get("team") != team or ai.get("role") == "goalkeeper":
			continue
		if ai.global_position.distance_squared_to(_ball.global_position) < my_d2 - 0.25:
			rank += 1
	return rank


# Ponto de interceptação entre o portador e nosso gol
func _intercept_point(carrier_pos: Vector3) -> Vector3:
	var my_goal_x := -_attack_x * 25.0
	var goal_center := Vector3(my_goal_x, 0.0, 0.0)
	var pt := carrier_pos.lerp(goal_center, 0.4)
	pt.y = 0.0
	return pt


# Posição defensiva entre a bola e o gol, espalhada pela zona Z do jogador
func _defensive_cover_position(ball_pos: Vector3) -> Vector3:
	var my_goal_x := -_attack_x * 25.0
	var target_x := lerpf(ball_pos.x, my_goal_x, 0.35)
	target_x = clampf(target_x, -23.0, 23.0)
	var cover_z := lerpf(home_pos.z, ball_pos.z * 0.4, 0.4)
	cover_z = clampf(cover_z, -15.0, 15.0)
	return Vector3(target_x, 0.0, cover_z)


# Retorna true se este jogador é o mais próximo da bola no mesmo time
func _is_primary_chaser() -> bool:
	var my_d2 := global_position.distance_squared_to(_ball.global_position)
	for ai in get_tree().get_nodes_in_group("ai_player"):
		if ai == self or ai.get("team") != team or ai.get("role") == "goalkeeper":
			continue
		if ai.global_position.distance_squared_to(_ball.global_position) < my_d2 - 0.25:
			return false
	if team == "home":
		for ally in get_tree().get_nodes_in_group("home_controllable"):
			if ally == self:
				continue
			if ally.global_position.distance_squared_to(_ball.global_position) < my_d2 - 0.25:
				return false
	return true


# Velocidade de movimento baseada na situação tática
func _get_movement_speed() -> float:
	if _has_ball() or not _ball:
		return SPEED
	var carrier: Node3D = _ball.get_carrier()
	if carrier != null and _is_opponent(carrier):
		var rank := _chase_rank()
		if rank <= 1:
			return SPEED * 1.15
	return SPEED


func _is_opponent(node: Node) -> bool:
	if node.is_in_group("home_controllable"):
		return team == "away"
	var node_team = node.get("team")
	if node_team == null:
		return team == "away"
	return node_team != team


func _apply_movement(dir: Vector3, speed: float, delta: float) -> void:
	if dir.length_squared() > 0.01:
		_facing_angle = atan2(dir.x, dir.z)
		if _visual:
			_visual.rotation.y = lerp_angle(_visual.rotation.y, _facing_angle, TURN_SPEED * delta)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()


# ── Posse de bola ─────────────────────────────────────────────────────────────

func _has_ball() -> bool:
	return _ball != null and _ball.get_carrier() == self


func on_ball_stolen() -> void:
	_recapture_timer = STEAL_VICTIM_CD


func _try_tackle() -> bool:
	if not _ball or _has_ball() or _recapture_timer > 0.0:
		return false
	if not _ball.is_carried():
		return false
	var carrier := _ball.get_carrier() as Node
	if not carrier or not _is_opponent(carrier):
		return false
	if global_position.distance_to(carrier.global_position) > STEAL_RANGE:
		return false
	# Bloqueia roubo pelas costas: o ladrão precisa estar na frente ou ao lado do portador
	var carrier_body := carrier as CharacterBody3D
	if carrier_body:
		var carrier_vel := carrier_body.velocity
		carrier_vel.y = 0.0
		if carrier_vel.length_squared() > 1.0:
			var carrier_fwd := carrier_vel.normalized()
			var carrier_to_thief := global_position - carrier_body.global_position
			carrier_to_thief.y = 0.0
			if carrier_to_thief.length_squared() > 0.01:
				# dot < -0.4 significa ladrão está diretamente atrás do portador
				if carrier_fwd.dot(carrier_to_thief.normalized()) < -0.4:
					return false
	if _ball.steal_by(self):
		if _visual and _visual.has_method("play_kick"):
			_visual.play_kick()
	return true


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

	var fwd_pos := global_position + _forward() * DRIBBLE_DISTANCE
	fwd_pos.y = BALL_HEIGHT
	_ball.carry_to(fwd_pos)

	if _human_control:
		return

	var goal_pos := Vector3(_attack_x * 25.0, 0.5, 0.0)
	if global_position.distance_to(goal_pos) <= SHOOT_RANGE:
		# Mira levemente em direção ao centro do gol
		var aim_z := clampf(-global_position.z * 0.5, -2.5, 2.5)
		var shoot_dir := (Vector3(_attack_x * 25.0, 0.5, aim_z) - global_position).normalized()
		if _visual and _visual.has_method("play_kick"):
			_visual.play_kick()
		_ball.release(shoot_dir * KICK_FORCE)
		_recapture_timer = RECAPTURE_DELAY


func _forward() -> Vector3:
	return Vector3(sin(_facing_angle), 0.0, cos(_facing_angle))


# Chamado pelo game_manager após cada gol
func reset_to_home() -> void:
	velocity = Vector3.ZERO
	global_position = home_pos
	_recapture_timer = 0.0
	_tackle_timer = 0.0
