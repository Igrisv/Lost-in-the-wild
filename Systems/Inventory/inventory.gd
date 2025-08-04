extends Node

var item_map: Dictionary = {}
var hotbar_slots := []
var grid_slots := []
var equipment_slots := []
var chest_slots := []  # Slots del cofre

func _ready():
	# Cargar recursos de ítems
	item_map = {
		"BotasDeCuero": preload("res://Data/items/Botas_De_Cuero.tres"),
		"AguaEmbotellada": preload("res://Data/items/Agua_Embotellada.tres"),
		"CascoDeCuero": preload("res://Data/items/Casco_De_Cuero.tres"),
		"Madera": preload("res://Data/items/Madera.tres"),
		"Manzana": preload("res://Data/items/Manzana.tres"),
		"PantalonesDeCuero": preload("res://Data/items/Pantalones_De_Cuero.tres"),
		"PecheraDeCuero": preload("res://Data/items/Pechera_De_Cuero.tres"),
		"PocionDeSueño": preload("res://Data/items/Pocion_Sueño.tres"),
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

	for slot in hotbar_slots + grid_slots + chest_slots:
		if slot.item != null and slot.item.id == item.id:
			var space = slot.item.max_stack - slot.amount
			var to_add = min(remaining_amount, space)
			slot.add_amount(to_add)
			remaining_amount -= to_add
			if remaining_amount <= 0:
				return

	for slot in hotbar_slots + grid_slots + chest_slots:
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
	for slot in hotbar_slots + grid_slots + chest_slots:
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
	if item == null or item.item_type != Item.ItemType.CONSUMABLE:
		print("Este ítem no es consumible o es null: ", item.name if item else "null")
		return false

	if item.consumable_data == null:
		print("Consumible sin datos definidos para: ", item.name)
		return false

	var jugador = get_jugador()
	if not jugador:
		print("Jugador no encontrado. No se pueden aplicar efectos.")
		return false

	var check = jugador.should_consume(item.consumable_data)
	if not check.can_consume:
		print("No se consumió %s: %s" % [item.name, check.reason])
		return false

	print("Consumiendo: %s" % item.name)
	jugador.apply_consumable_effect(item.consumable_data)

	var success = use_stackable_item(item, 1)
	if not success:
		print("Error al consumir ítem: no se encontró suficiente cantidad en el inventario.")
		return false

	return true

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

func set_chest_slots(slots: Array):
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
	for slot in hotbar_slots + grid_slots + equipment_slots + chest_slots:
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
			var original_amount = source_slot.amount
			if original_amount < 1:
				print("No hay suficiente cantidad para equipar: ", item.name)
				return false

			print("Reduciendo de ", original_amount, " a ", original_amount - 1, " en slot: ", source_slot.name)
			source_slot.amount = original_amount - 1  # Reducción primero

			print("Asignando a slot: ", slot.equipment_slot)
			slot.item = item
			slot.amount = 1

			if source_slot.amount <= 0:
				print("Limpieza de slot origen: ", source_slot.name)
				source_slot.item = null

			if original_amount > 1:
				print("Redistribuyendo ", original_amount - 1, " de ", item.name)
				redistribute_item(item, source_slot, original_amount - 1)

			emit_signal("item_equipped", item, slot)
			print("Ítem equipado exitosamente: ", item.name, " en slot: ", slot.equipment_slot, ", total: ", count_item(item))
			# Asegurar que update_all_slots se ejecute solo después de todos los cambios
			call_deferred("update_all_slots")
			return true
		elif slot.item and slot.equipment_slot == item.equipment_slot:
			print("Slot de equipamiento ya ocupado: ", slot.equipment_slot)
			return false

	print("No hay slot de equipamiento disponible para: ", item.name if item else "null")
	return false

func redistribute_item(item: Item, source_slot, remaining_amount: int):
	if remaining_amount <= 0:
		return

	var slots_to_check = hotbar_slots + grid_slots
	for slot in slots_to_check:
		if slot != source_slot:  # Evitar redistribuir al slot de origen
			if slot.item == null:
				slot.item = item  # Invoca el setter de item
				slot.amount = min(remaining_amount, item.max_stack)  # Invoca el setter de amount
				remaining_amount -= slot.amount
				if remaining_amount <= 0:
					if source_slot.amount <= 0:
						source_slot.item = null  # Invoca el setter de item
					break
			elif slot.item.id == item.id:
				var space = slot.item.max_stack - slot.amount
				var to_add = min(remaining_amount, space)
				slot.amount += to_add  # Invoca el setter de amount
				remaining_amount -= to_add
				if remaining_amount <= 0:
					if source_slot.amount <= 0:
						source_slot.item = null  # Invoca el setter de item
					break

	if remaining_amount > 0:
		print("No hay espacio suficiente en el inventario para redistribuir %.1f de %s" % [remaining_amount, item.name])
		source_slot.amount = remaining_amount  # Invoca el setter de amount
		if source_slot.amount <= 0:
			source_slot.item = null  # Invoca el setter de item

	update_all_slots()  # Actualizar la UI

func unequip_item(item: Item, equipment_slot):
	for slot in equipment_slots:
		if slot.item == item and slot.equipment_slot == equipment_slot:
			var unequipped_item = slot.item
			var amount = slot.amount
			slot.item = null  # Invoca el setter de item
			slot.amount = 0   # Invoca el setter de amount

			# Usar add_item para redistribuir el ítem y fusionarlo con stacks existentes
			add_item(unequipped_item, amount)

			emit_signal("item_unequipped", unequipped_item, slot)
			print("Ítem desequipado y redistribuido: ", unequipped_item.name)
			update_all_slots()  # Actualizar la UI
			return true
	return false

func update_all_slots():
	var slots = get_tree().get_nodes_in_group("slots")
	for slot in slots:
		slot.update_from_group()

func _on_item_equipped(item, slot):
	if not item:
		print("Error: Intento de equipar un ítem nulo en slot:", slot.equipment_slot if slot else "null")
		return
	print("Señal item_equipped recibida para:", item.name, "en slot:", slot.equipment_slot)
	var jugador = get_jugador()
	if jugador:
		print("Actualizando estadísticas del jugador...")
		jugador.update_equipment_stats()
	else:
		print("ERROR: Jugador no encontrado para actualizar estadísticas")

func _on_item_unequipped(item, slot):
	print("Señal item_unequipped recibida para:", item.name if item else "null", "de slot:", slot.equipment_slot if slot else "null")
	var jugador = get_jugador()
	if jugador:
		print("Actualizando estadísticas del jugador tras desequipar...")
		jugador.update_equipment_stats()
	else:
		print("ERROR: Jugador no encontrado para actualizar estadísticas tras desequipar")

signal item_equipped(item, slot)
signal item_unequipped(item, slot)
