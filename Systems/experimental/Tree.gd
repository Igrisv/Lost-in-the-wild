extends Node2D
class_name Tree_

@export var action_id: String = "chop_tree"
@export var health: float = 100.0
@export var max_drop_amount: int = 20
var total_dropped: int = 0  # Loot total dropeado por este árbol

func _ready() -> void:
	var callable_loot_dropped = Callable(self, "_on_loot_dropped")
	Action_Manager.loot_dropped.connect(callable_loot_dropped)
	
func interact(player: Node) -> void:
	var action_manager = Action_Manager
	var action = load("res://Data/actions/" + action_id + ".tres")
	var tool = action_manager.get_equipped_tool(player, action.required_tool_type)
	var damage = tool.resource_damage if tool and tool.item_type == Item.ItemType.TOOL else 10.0  # Daño por defecto si no hay herramienta
	if await action_manager.execute_action(action, player, self):
		health -= damage
	if total_dropped >= max_drop_amount or health <= 0:
		queue_free()
	
func _on_loot_dropped(target: Node, dropped_amount: int) -> void:
	print("Target", target, "Cantidad", dropped_amount)
	if target == self:
		total_dropped += dropped_amount
		if total_dropped >= max_drop_amount:
			queue_free()
