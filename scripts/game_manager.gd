extends Node3D

var score_home: int = 0
var score_away: int = 0
var _goal_cooldown: bool = false

@onready var _scoreboard = $UI/Scoreboard

var _ball: RigidBody3D = null
var _controlled: CharacterBody3D = null
var _last_carrier: Node3D = null
var _home_players: Array[CharacterBody3D] = []
var _pass_switch_timer: float = 0.0
var _pass_passer: CharacterBody3D = null

const BALL_START := Vector3(0.0, 0.3, 0.0)
const INDICATOR_SCRIPT := preload("res://scripts/control_indicator.gd")


func _ready() -> void:
	add_to_group("game_manager")
	_setup_input()
	call_deferred("_find_nodes")


func _find_nodes() -> void:
	_ball = get_tree().get_first_node_in_group("ball")
	_collect_home_players()
	_setup_indicators()
	_disable_all_home_control()
	set_controlled_player(_find_closest_home_player_to_ball())


func _disable_all_home_control() -> void:
	for player in _home_players:
		if player.has_method("set_human_control"):
			player.set_human_control(false)


func _find_closest_home_player_to_ball(exclude: CharacterBody3D = null) -> CharacterBody3D:
	if _home_players.is_empty():
		_collect_home_players()
	if _home_players.is_empty():
		return null
	if not _ball:
		return _home_players[0]

	var ball_pos := _ball.global_position
	var closest: CharacterBody3D = null
	var best_dist := INF
	for player in _home_players:
		if player == exclude:
			continue
		var dist := player.global_position.distance_squared_to(ball_pos)
		if dist < best_dist:
			best_dist = dist
			closest = player
	return closest if closest != null else _home_players[0]


func _collect_home_players() -> void:
	_home_players.clear()
	for node in get_tree().get_nodes_in_group("home_controllable"):
		if node is CharacterBody3D:
			_home_players.append(node)
	_home_players.sort_custom(func(a: CharacterBody3D, b: CharacterBody3D) -> bool:
		return a.name < b.name
	)


func _setup_indicators() -> void:
	for player in _home_players:
		if player.get_node_or_null("ControlIndicator"):
			continue
		var indicator: Node3D = INDICATOR_SCRIPT.new()
		indicator.name = "ControlIndicator"
		player.add_child(indicator)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_player"):
		cycle_controlled_player()


func cycle_controlled_player() -> void:
	if _home_players.is_empty():
		_collect_home_players()
	if _home_players.is_empty() or not _ball:
		return
	var sorted := _home_players.duplicate()
	var ball_pos := _ball.global_position
	sorted.sort_custom(func(a: CharacterBody3D, b: CharacterBody3D) -> bool:
		return a.global_position.distance_squared_to(ball_pos) < b.global_position.distance_squared_to(ball_pos)
	)
	if sorted[0] == _controlled and sorted.size() > 1:
		set_controlled_player(sorted[1])
	else:
		set_controlled_player(sorted[0])


func _physics_process(delta: float) -> void:
	if not _ball:
		return

	if _pass_switch_timer > 0.0:
		_pass_switch_timer -= delta
		if _pass_switch_timer <= 0.0:
			set_controlled_player(_find_closest_home_player_to_ball(_pass_passer))
			_pass_passer = null

	var carrier: Node3D = _ball.get_carrier()
	if carrier == _last_carrier:
		return
	var prev_carrier := _last_carrier
	_last_carrier = carrier

	if carrier == null and prev_carrier == _controlled:
		# Passe ou chute: agenda troca pro jogador mais perto da bola
		_pass_passer = _controlled
		_pass_switch_timer = 0.15
	elif carrier and _is_home_controllable(carrier):
		# Companheiro capturou a bola: troca imediata e cancela timer
		_pass_switch_timer = 0.0
		_pass_passer = null
		set_controlled_player(carrier as CharacterBody3D)


func set_controlled_player(player: CharacterBody3D) -> void:
	if player == null:
		return
	if player == _controlled:
		_refresh_indicators()
		return
	if _controlled and _controlled.has_method("set_human_control"):
		_controlled.set_human_control(false)
	_controlled = player
	if _controlled.has_method("set_human_control"):
		_controlled.set_human_control(true)
	_refresh_indicators()


func _refresh_indicators() -> void:
	for player in _home_players:
		var indicator := player.get_node_or_null("ControlIndicator")
		if indicator and indicator.has_method("set_active"):
			indicator.set_active(player == _controlled)


func get_controlled_player() -> CharacterBody3D:
	return _controlled


func _is_home_controllable(node: Node) -> bool:
	return node.is_in_group("home_controllable")


func register_goal(team: String) -> void:
	if _goal_cooldown:
		return
	_goal_cooldown = true

	if team == "home":
		score_home += 1
	else:
		score_away += 1

	_update_score_ui()
	_show_goal_label(team)
	get_tree().create_timer(2.0).timeout.connect(_reset_positions)


func _update_score_ui() -> void:
	if _scoreboard:
		_scoreboard.set_scores(score_home, score_away)


func _show_goal_label(team: String) -> void:
	if _scoreboard:
		_scoreboard.play_goal(team)


func _reset_positions() -> void:
	if _ball:
		if _ball.has_method("release"):
			_ball.release()
		_ball.linear_velocity = Vector3.ZERO
		_ball.angular_velocity = Vector3.ZERO
		_ball.global_position = BALL_START
	_last_carrier = null
	_pass_switch_timer = 0.0
	_pass_passer = null

	_disable_all_home_control()
	for player in _home_players:
		if player.has_method("reset_to_home"):
			player.reset_to_home()

	for ai in get_tree().get_nodes_in_group("ai_player"):
		if ai.get("team") == "away" and ai.has_method("reset_to_home"):
			ai.reset_to_home()

	set_controlled_player(_find_closest_home_player_to_ball())
	_goal_cooldown = false


func _setup_input() -> void:
	_add_key_action("move_up",    [KEY_W, KEY_UP])
	_add_key_action("move_down",  [KEY_S, KEY_DOWN])
	_add_key_action("move_left",  [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("kick",       [KEY_SPACE])
	_add_key_action("kick_strong",[KEY_E])
	_add_key_action("tackle",     [KEY_Q])
	_add_key_action("switch_player", [KEY_TAB])


func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
