extends Node3D

var score_home: int = 0
var score_away: int = 0
var _goal_cooldown: bool = false

@onready var score_label: Label = $UI/ScoreLabel
@onready var goal_label: Label = $UI/GoalLabel

var _ball: RigidBody3D = null
var _player: CharacterBody3D = null

const BALL_START := Vector3(0.0, 0.3, 0.0)
const PLAYER_START := Vector3(0.0, 0.0, 5.0)


func _ready() -> void:
	add_to_group("game_manager")
	_setup_input()
	call_deferred("_find_nodes")


func _find_nodes() -> void:
	_ball = get_tree().get_first_node_in_group("ball")
	_player = get_tree().get_first_node_in_group("player")


func register_goal(team: String) -> void:
	if _goal_cooldown:
		return
	_goal_cooldown = true

	if team == "home":
		score_home += 1
	else:
		score_away += 1

	_update_score_ui()
	_show_goal_label()
	get_tree().create_timer(2.0).timeout.connect(_reset_positions)


func _update_score_ui() -> void:
	score_label.text = "%d  —  %d" % [score_home, score_away]


func _show_goal_label() -> void:
	goal_label.visible = true
	get_tree().create_timer(1.8).timeout.connect(func(): goal_label.visible = false)


func _reset_positions() -> void:
	if _ball:
		if _ball.has_method("release"):
			_ball.release()
		_ball.linear_velocity = Vector3.ZERO
		_ball.angular_velocity = Vector3.ZERO
		_ball.global_position = BALL_START

	if _player:
		_player.velocity = Vector3.ZERO
		_player.global_position = PLAYER_START

	for ai in get_tree().get_nodes_in_group("ai_player"):
		if ai.has_method("reset_to_home"):
			ai.reset_to_home()

	_goal_cooldown = false


func _setup_input() -> void:
	_add_key_action("move_up",    [KEY_W, KEY_UP])
	_add_key_action("move_down",  [KEY_S, KEY_DOWN])
	_add_key_action("move_left",  [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("kick",       [KEY_SPACE])
	_add_key_action("kick_strong",[KEY_E])


func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
