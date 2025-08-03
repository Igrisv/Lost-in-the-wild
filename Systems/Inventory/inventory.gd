extends Node

var item_map: Dictionary = {}
var hotbar_slots := []
var grid_slots := []
var equipment_slots := []
var chest_slots := []  # Slots del cofre

func _ready():
	# Cargar recursos de ítems
	item_map = {
		"Tronco": preload("res://items/Tronco.tres"),
		"Comida": preload("res://items/Comida.tres"),
		"Espada": preload("res://items/Espada.tres")
	}
	for item_name in item_map.keys():
		if item_map[item_name] == null:
			push_error("Error: No se pudo cargar el ítem %s" % item_name)

func add_item(item: Item, amount: float = 1.0):
	if not item or not item_map.has(item.name):
		push_error("Ítem %s no válido o no está en item_map" % (item.name if item else "null"))
		return

	amount = max(0, amount)
	var remaining_amount = amount

	for slot in hotbar_slots + grid_slots + chest_slots:  # Incluye chest_slots
		if slot.item != null and slot.item.id == item.id:
			var space = slot.item.max_stack - slot.amount
			var to_add = min(remaining_amount, space)
			slot.add_amount(to_add)
			remaining_amount -= to_add
			if remaining_amount <= 0:
				return

	for slot in hotbar_slots + grid_slots + chest_slots:  # Incluye chest_slots
		if slot.item == null:
			var to_add = min(remaining_amount, item.max_stack)
			slot.item = item
			slot.set_amount(to_add)
			remaining_amount -= to_add
			if remaining_amount <= 0:
				return

	if remaining_amount > 0:
		print("Inventario lleno. Sobran %.1f de %s" % [remaining_amount, item.name])

func use_stackable_item(item: Item, amount: int) -> bool:
	var remaining = amount
	for slot in hotbar_slots + grid_slots + chest_slots:  # Incluye chest_slots
		if slot.item != null and slot.item.id == item.id:
			var to_remove = min(remaining, slot.amount)
			slot.add_amount(-to_remove)
			remaining -= to_remove
			if slot.amount <= 0:
				slot.item = null
			if remaining <= 0:
				return true
	return remaining <= 0

func consume_item(item: Item) -> bool:
	if item.item_type != Item.ItemType.CONSUMABLE:
		print("Este ítem no es consumible.")
		return false

	if item.consumable_data == null:
		print("Consumible sin datos definidos.")
		return false

	var jugador = get_jugador()
	if jugador:
		var check = jugador.should_consume(item.consumable_data)
		if not check.can_consume:
			print("No se consumió %s: %s" % [item.name, check.reason])
			return false

		print("Consumiste: %s" % item.name)
		jugador.apply_consumable_effect(item.consumable_data)

		var success := use_stackable_item(item, 1)
		if not success:
			print("Error al consumir ítem: no se encontró en el inventario.")
			return false
		return true
	else:
		print("Jugador no encontrado. No se pueden aplicar efectos.")
		return false

func has_item_in_hotbar(item_name: String) -> bool:
	for slot in hotbar_slots:
		if slot.item != null and slot.item.name == item_name and slot.amount > 0:
			return true
	return false

func set_hotbar_slots(slots: Array):
	hotbar_slots = slots
	_connect_signals(hotbar_slots)

func set_grid_slots(slots: Array):
	grid_slots = slots
	_connect_signals(grid_slots)

func set_equipment_slots(slots: Array):
	equipment_slots = slots
	_connect_signals(equipment_slots)

func set_chest_slots(slots: Array):  # Nuevo
	chest_slots = slots
	_connect_signals(chest_slots)

func _connect_signals(slots: Array):
	for slot in slots:
		if not slot.is_connected("item_equipped", _on_item_equipped):
			slot.connect("item_equipped", _on_item_equipped)
		if not slot.is_connected("item_unequipped", _on_item_unequipped):
			slot.connect("item_unequipped", _on_item_unequipped)

func count_item(item: Item) -> int:
	var total = 0
	for slot in hotbar_slots + grid_slots + equipment_slots + chest_slots:  # Incluye chest_slots
		if slot.item != null and slot.item.id == item.id:
			total += slot.amount
	return total

func get_jugador() -> CharacterBody2D:
	var jugadores = get_tree().get_nodes_in_group("Player")
	if jugadores.size() > 0:
		return jugadores[0]
	return null

func equip_item(item: Item, source_slot):
	if not item or not item.is_equippable:
		print("Ítem no equipable:", item.name if item else "null")
		return false

	if not source_slot:
		print("Slot de origen inválido")
		return false

	for slot in equipment_slots:
		if not slot.item and slot.equipment_slot == item.equipment_slot:
			source_slot.amount -= 1
			if source_slot.amount <= 0:
				source_slot.item = null
				source_slot.amount = 0
			slot.item = item
			slot.amount = 1  # Forzar a 1 ítem en slots de equipamiento
			emit_signal("item_equipped", item, slot)
			print("Ítem equipado exitosamente:", item.name, "en slot:", slot.equipment_slot)
			return true
		elif slot.item and slot.equipment_slot == item.equipment_slot:
			print("Slot de equipamiento ya ocupado:", slot.equipment_slot)
			return false

	print("No hay slot de equipamiento disponible para:", item.name if item else "null")
	return false

func unequip_item(item: Item, equipment_slot):
	for slot in equipment_slots:
		if slot.item == item:
			for target_slot in hotbar_slots + grid_slots:
				if not target_slot.item:
					target_slot.item = item
					target_slot.amount = 1
					slot.item = null
					slot.amount = 0
					emit_signal("item_unequipped", item, target_slot)
					return true
			print("Inventario lleno, no se pudo desequipar:", item.name)
			return false
	return false

func _on_item_equipped(item, slot):
	if not item:
		print("Error: Intento de equipar un ítem nulo en slot:", slot.equipment_slot if slot else "null")
		return
	print("Ítem equipado:", item.name, "en slot:", slot.equipment_slot)
	# Aquí puedes añadir lógica adicional (ej. aplicar efectos al jugador)

func _on_item_unequipped(item, slot):
	print("Ítem desequipado:", item.name, "de slot:", slot.equipment_slot)
	# Aquí puedes añadir lógica adicional (ej. quitar efectos al jugador)

signal item_equipped(item, slot)
signal item_unequipped(item, slot)
