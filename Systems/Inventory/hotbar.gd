extends HBoxContainer

var currently_equipped: Item
signal equip(item)
signal unequip(item)

var index = 0:
	set(value):
		index = value
		if index >= get_child_count():
			index = 0
		elif index < 0:
			index = get_child_count() - 1
		queue_redraw()
		currently_equipped = get_child(index).item

# Cooldown entre usos
var last_use_time := 0.0
const USE_COOLDOWN := 0.3  # Segundos

func _draw():
	draw_rect(Rect2(get_child(index).position, get_child(index).size), Color.WHITE, false, 1)

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			index -= 1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			index += 1
		if event.button_index == MOUSE_BUTTON_LEFT:
			for i in range(get_child_count()):
				var slot = get_child(i)
				if slot.get_global_rect().has_point(event.global_position):
					index = i
					break
		if event.button_index == MOUSE_BUTTON_RIGHT:
			for i in range(get_child_count()):
				var slot = get_child(i)
				if slot.get_global_rect().has_point(event.global_position):
					if slot.item and slot.item.is_equippable:
						print("Intentando equipar con clic derecho: ", slot.item.name, ", cantidad: ", slot.amount)
						if Inventory.equip_item(slot.item, slot):
							update()
							print("Equipado exitosamente, cantidad restante: ", slot.amount, ", total: ", get_inventory_total(slot.item))
					elif slot.equipment_slot != "" and slot.item:
						print("Intentando desequipar con clic derecho: ", slot.item.name)
						if Inventory.unequip_item(slot.item, slot.equipment_slot):
							update()
							print("Desequipado exitosamente, total: ", get_inventory_total(slot.item))
					break

func get_inventory_total(item: Item) -> int:
	var inventory = Inventory
	return inventory.count_item(item) if inventory else 0

func update():
	currently_equipped = get_child(index).item

func use_current():
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_use_time < USE_COOLDOWN:
		print("Uso bloqueado por cooldown")
		return
	last_use_time = now

	var slot = get_child(index)
	if slot.item == null or slot.amount <= 0:
		print("No hay ítem para usar")
		return

	var player = Inventory.get_jugador()
	if not player:
		print("Jugador no encontrado")
		return

	match slot.item.item_type:
		Item.ItemType.CONSUMABLE:
			var action = load("res://Data/actions/consume.tres")
			if Action_Manager.await.execute_action(action, player, slot.item):
				slot.queue_redraw()  # Actualizar el slot visualmente
		Item.ItemType.TOOL:
			var interactables = get_tree().get_nodes_in_group("Interactable")
			var closest = null
			var min_distance = player.attack_range
			for node in interactables:
				var distance = player.global_position.distance_to(node.global_position)
				if distance < min_distance:
					min_distance = distance
					closest = node
			if closest and closest.has_method("interact"):
				closest.interact(player)
		Item.ItemType.WEAPON:
			var action = load("res://Data/actions/attack.tres")
			Action_Manager.execute_action(action, player, slot.item)
		Item.ItemType.PLACEABLE:
			var action = load("res://Data/actions/place.tres")
			Action_Manager.execute_action(action, player, slot.item)
