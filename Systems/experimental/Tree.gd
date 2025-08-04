extends Node2D
class_name Tree_

@export var action_id: String = "chop_tree"
@export var health: float = 100.0

func interact(player: Node) -> void:
	var action_manager = Action_Manager
	var action = load("res://Data/actions/" + action_id + ".tres")
	if await action_manager.execute_action(action, player, self):
		health -= 10.0
		if health <= 0:
			queue_free()
