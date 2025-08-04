# action_manager.gd
class_name ActionManager
extends Node

signal action_completed(action_id: String)

func execute_action(action: ActionResource, player: Node, target: Node = null) -> bool:
	var inventory = Inventory
	var tool = get_equipped_tool(player, action.required_tool_type)
	if not can_execute_action(action, player, tool):
		return false

	# Calcular valores modificados según la herramienta
	var efficiency = tool.efficiency if tool else 1.0
	var modified_stamina_cost = action.base_stamina_cost * (tool.modifiers.get("stamina_cost", 1.0) if tool else 1.0)
	var modified_execution_time = action.base_execution_time / efficiency

	# Consumir stamina
	player.needs.stamina -= modified_stamina_cost
	if player.needs.stamina < 0:
		player.needs.stamina = 0
		return false

	# Reproducir animación y sonido
	player.play_animation(action.animation if not tool or not tool.animation_override else tool.animation_override)
	if action.sound:
		player.play_sound(action.sound)

	# Esperar el tiempo de ejecución
	await get_tree().create_timer(modified_execution_time).timeout

	# Aplicar efectos
	for outcome in action.outcomes:
		apply_outcome(outcome, player, tool, target)

	# Reducir durabilidad de la herramienta
	if tool and tool.durability > 0:
		tool.durability -= 1
		if tool.durability <= 0:
			inventory.unequip_item(tool, tool.equipment_slot)
			inventory.add_item(tool, 0) # Elimina el ítem del inventario

	emit_signal("action_completed", action.action_id)
	return true

func can_execute_action(action: ActionResource, player: Node, tool: Item) -> bool:
	var inventory = Inventory
	var modified_stamina_cost = action.base_stamina_cost * (tool.modifiers.get("stamina_cost", 1.0) if tool else 1.0)
	if player.needs.stamina < modified_stamina_cost:
		return false

	if action.required_tool_type and (not tool or tool.id != action.required_tool_type):
		return false

	return true

func get_equipped_tool(player: Node, required_tool_type: String) -> Item:
	var inventory = Inventory
	for slot in inventory.equipment_slots:
		if slot.item and slot.item.item_type == Item.ItemType.TOOL and slot.item.id == required_tool_type:
			return slot.item
	return null

func apply_outcome(outcome: Outcome, player: Node, tool: Item, target: Node) -> void:
	var inventory = Inventory
	var modified_value = outcome.value
	if outcome.type == "add_item" and tool and tool.modifiers.has("extra_yield"):
		modified_value = [outcome.value[0], outcome.value[1] + tool.modifiers["extra_yield"]]

	match outcome.type:
		"add_item":
			var item = inventory.item_map.get(modified_value[0], null)
			if item:
				inventory.add_item(item, modified_value[1])
		"damage_tool":
			# La durabilidad se maneja en execute_action
			pass
		"damage_target":
			if target and target.has_method("take_damage"):
				target.take_damage(outcome.value)
