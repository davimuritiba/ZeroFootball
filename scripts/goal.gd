extends Area3D

@export var team: String = "home"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("ball"):
		return
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm:
		gm.register_goal(team)
