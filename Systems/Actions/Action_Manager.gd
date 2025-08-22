class_name ActionManager
extends Node

signal action_completed(action_id: String)
signal loot_dropped(value,value1)

func execute_action(action: ActionResource, player: Node, target: Node = null, item: Item = null, slot: Node = null) -> bool:
	var inventory = Inventory
	var tool = item if action.action_id == "consume_item" or action.action_id == "attack" else get_equipped_tool(player, action.required_tool_type)
	if not can_execute_action(action, player, tool):
		return false

	# Calcular valores modificados según la herramienta o ítem
	var efficiency = tool.efficiency if tool else 1.0
	var modified_stamina_cost = action.base_stamina_cost * (tool.modifiers.get("stamina_cost", 1.0) if tool else 1.0)
	var modified_execution_time = action.base_execution_time / efficiency

	# Consumir stamina (usar player pasado si existe, o buscarlo)
	var player_node = player if player else get_jugador_from_group()
	if not player_node or player_node.needs.stamina < modified_stamina_cost:
		if player_node:
			player_node.needs.stamina = 0
		return false

	# Reproducir animación y sonido
	var animation = action.animation
	if tool and tool.animation_override:
		animation = tool.animation_override
	player_node.play_animation(animation)
	if action.sound:
		player_node.play_sound(action.sound if not tool or not tool.sound_override else tool.sound_override)

	# Especial para acción de consumo
	if action.action_id == "consume_item" and item and item.item_type == Item.ItemType.CONSUMABLE:
		if item.consumable_data:
			if slot:
				var player_instance = get_jugador_from_group()  # Usar función auxiliar
				if player_instance and Inventory.consume_item(slot, player_instance):
					emit_signal("action_completed", action.action_id)
					return true
				else:
					print("Error al consumir el ítem del inventario: ", item.name, " - Player instance: ", player_instance)
					return false
			else:
				print("Error: Slot no proporcionado para consumo")
				return false
		else:
			print("Error: ConsumableData es null para: ", item.name)
			return false
		# Especial para acción de ataque
	if action.action_id == "attack" and tool and tool.item_type == Item.ItemType.WEAPON:
		modified_execution_time /= tool.attack_speed  # Ajustar tiempo por velocidad de ataque

		# Calcular daño
		var damage = tool.damage_base
		if randf() < tool.critical_chance:
			damage *= 1.5  # Crítico
		print("atacando", damage)

		if tool.is_ranged:
			if tool.is_ranged:
				# Ataque a distancia: verificar munición si es requerida
				if tool.needs_ammo:
					if not inventory.has_item_in_hotbar(tool.ammo_type) or inventory.count_item(inventory.get_item(tool.ammo_type)) <= 0:
						print("Sin munición para: ", tool.name)
						return false
					# Consumir munición
					inventory.use_stackable_item(inventory.get_item(tool.ammo_type), 1)

				# Simular recarga/carga del arma
				await get_tree().create_timer(tool.reload_time).timeout

				# Instanciar proyectil después de la recarga
				if tool.projectile_scene:
					var projectile = tool.projectile_scene.instantiate()
					projectile.global_position = player_node.global_position
					projectile.direction = (target.global_position - player_node.global_position).normalized() if target else (player_node.get_global_mouse_position() - player_node.global_position).normalized()
					projectile.speed = tool.projectile_speed
					projectile.damage = damage
					player_node.get_parent().add_child(projectile)
				else:
					print("Error: No hay escena de proyectil para arma ranged: ", tool.name)
					return false
		else:
			# Ataque cuerpo a cuerpo: detectar target en rango
			if target and player_node.global_position.distance_to(target.global_position) <= tool.attack_range and target.has_method("take_damage"):
				target.take_damage(damage)
				print("Daño melee aplicado a: ", target.name, " - Daño: ", damage)
			else:
				# Raycast fallback si no hay target válido
				var direction = (player_node.get_global_mouse_position() - player_node.global_position).normalized() if not target else (target.global_position - player_node.global_position).normalized()
				var space_state = player_node.get_world_2d().direct_space_state
				var query = PhysicsRayQueryParameters2D.create(player_node.global_position, player_node.global_position + direction * tool.attack_range)
				var result = space_state.intersect_ray(query)
				if result and result.collider.is_in_group("Enemy") and result.collider.has_method("take_damage"):
					result.collider.take_damage(damage)
					print("Daño melee aplicado via raycast a: ", result.collider.name, " - Daño: ", damage)
				else:
					print("No hay target en rango para melee")
					return false

		# Reducir durabilidad del arma
		if tool.durability > 0:
			tool.durability -= 1
			if tool.durability <= 0:
				inventory.unequip_item(tool, tool.equipment_slot)
				inventory.add_item(tool, 0)  # Elimina

		emit_signal("action_completed", action.action_id)
		return true
	
	# Esperar el tiempo de ejecución
	await get_tree().create_timer(modified_execution_time).timeout

	# Aplicar efectos
	for outcome in action.outcomes:
		apply_outcome(outcome, player_node, tool, target)

	# Reducir durabilidad de la herramienta (si no es un consumible)
	if tool and tool.durability > 0 and action.action_id != "consume_item":
		tool.durability -= 1
		if tool.durability <= 0:
			inventory.unequip_item(tool, tool.equipment_slot)
			inventory.add_item(tool, 0) # Elimina el ítem del inventario

	emit_signal("action_completed", action.action_id)
	return true

# Función auxiliar para obtener el jugador desde el grupo
func get_jugador_from_group() -> CharacterBody2D:
	var players = get_tree().get_nodes_in_group("Player")
	return players[0] if players.size() > 0 else null

func can_execute_action(action: ActionResource, player: Node, tool: Item) -> bool:
	var inventory = Inventory
	var modified_stamina_cost = action.base_stamina_cost * (tool.modifiers.get("stamina_cost", 1.0) if tool else 1.0)
	if player.needs.stamina < modified_stamina_cost:
		return false

	if action.action_id == "consume_item":
		if not tool or tool.item_type != Item.ItemType.CONSUMABLE:
			print("El ítem no es consumible: ", tool.name if tool else "null")
			return false
		if tool.consumable_data:
			var check = player.should_consume(tool.consumable_data)
			if not check.can_consume:
				print("No se puede consumir el ítem: ", check.reason)
				return false
		else:
			print("Error: ConsumableData es null para: ", tool.name if tool else "null")
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
			if modified_value.size() < 2:
				push_error(" [Outcome: add_item] modified_value no tiene los elementos necesarios (esperado: [id, cantidad])")
				return
			
			var item_id = str(modified_value[0])
			var base_amount = int(modified_value[1])  # Cantidad base del outcome, si se usa como fallback
			var item = inventory.item_map.get(item_id, null)

			if not item:
				push_error(" [Outcome: add_item] No se encontró el ítem con id: '%s'" % item_id)
				return

		# Calcular amount dinámicamente si hay una tool equipada y target válido
			var amount = base_amount
			if tool and tool.item_type == Item.ItemType.TOOL and target and "health" in target:
				var damage = tool.resource_damage  # Daño base de la tool
				var total_health = target.health if target.health > 0 else 100.0  # Vida del target antes del daño
				var max_drop = target.max_drop_amount if target and "max_drop_amount" in target else tool.max_yield  # Límite máximo
				var damage_ratio = min(1.0, damage / total_health)  # Proporción de daño (máx 1)
				var is_critical = randf() < tool.critical_chance
				var yield_base = randi_range(tool.min_yield, tool.max_yield)
				var yield_bonus = damage_ratio * tool.yield_per_damage * max_drop
				amount = yield_base + int(yield_bonus)
				if is_critical:
					amount = int(amount * 1.5)  # Multiplicador por crítico
				amount = clamp(amount, 1, max_drop)  # Limita entre 1 y max_drop
			elif not tool:
				amount = clamp(base_amount, 1, target.max_drop_amount if target and "max_drop_amount" in target else base_amount)

		# Determinar si el ítem debe dropearse en el suelo o añadirse al inventario
			if target and target.is_in_group("ResourceNode"):  # Ejemplo: árboles, rocas, etc.
				var drop_scene = load("res://Systems/Inventory/item_drop.tscn")  # Ruta a tu escena ItemDrop
				var drop = drop_scene.instantiate()
				var dispersion_radius = 20.0  # Radio de dispersión en píxeles (ajusta según necesidad)
				var offset = Vector2(randf_range(-dispersion_radius, dispersion_radius), randf_range(-dispersion_radius, dispersion_radius))
				drop.item = item
				drop.amount = amount
				drop.global_position = target.global_position + offset
				target.get_parent().add_child(drop)
				print("Ítem dropeado: ", item.name, " x", amount, " en ", target.global_position)
				emit_signal("loot_dropped", target, amount)
			else:
				# Para criaturas u otros casos, añadir directamente al inventario
				inventory.add_item(item, amount)
				print("Ítem dropeado: ", item.name, " x", amount, " en ", target.global_position)

		"damage_tool":
			# La durabilidad se maneja en execute_action
			pass

		"damage_target":
			if not target:
				push_error(" [Outcome: damage_target] Target es nulo.")
			elif not target.has_method("take_damage"):
				push_error(" [Outcome: damage_target] Target no tiene el método 'take_damage'.")
			else:
				target.take_damage(outcome.value)
				print(" Target recibió daño:", outcome.value)
