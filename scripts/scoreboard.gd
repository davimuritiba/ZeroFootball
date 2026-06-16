extends Control

signal goal_flash_finished

@onready var _home_score: Label = %HomeScore
@onready var _away_score: Label = %AwayScore
@onready var _goal_overlay: Control = %GoalOverlay
@onready var _goal_title: Label = %GoalTitle
@onready var _goal_team: Label = %GoalTeam
@onready var _board_panel: PanelContainer = %BoardPanel

var _tween: Tween


func _ready() -> void:
	_goal_overlay.visible = false
	_goal_overlay.modulate.a = 0.0
	set_scores(0, 0)


func set_scores(home: int, away: int) -> void:
	_home_score.text = str(home)
	_away_score.text = str(away)


func play_goal(team: String) -> void:
	var is_home := team == "home"
	_goal_team.text = "CASA" if is_home else "VISITANTE"
	_goal_team.add_theme_color_override(
		"font_color",
		Color(0.95, 0.28, 0.22) if is_home else Color(0.28, 0.52, 0.98)
	)
	_goal_overlay.visible = true
	_goal_overlay.modulate.a = 0.0
	_goal_title.scale = Vector2(0.6, 0.6)
	_goal_team.scale = Vector2(0.85, 0.85)

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_goal_overlay, "modulate:a", 1.0, 0.18)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_goal_title, "scale", Vector2.ONE, 0.28)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_goal_team, "scale", Vector2.ONE, 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.04)

	_tween.chain().tween_interval(1.35)
	_tween.tween_property(_goal_overlay, "modulate:a", 0.0, 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.finished.connect(func() -> void:
		_goal_overlay.visible = false
		goal_flash_finished.emit()
	, CONNECT_ONE_SHOT)

	_pulse_board()


func _pulse_board() -> void:
	var pulse := create_tween()
	pulse.tween_property(_board_panel, "scale", Vector2(1.06, 1.06), 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pulse.tween_property(_board_panel, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
