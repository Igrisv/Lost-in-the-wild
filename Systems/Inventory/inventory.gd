extends Node

var item_map: Dictionary = {}
var hotbar_slots := []
var grid_slots := []

func _ready():
	# Cargar recursos de ítems
	item_map = {
		"Tronco": preload("res://items/Tronco.tres"),
		"Comida": preload("res://items/Comida.tres")
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

	for slot in hotbar_slots + grid_slots:
		if slot.item != null and slot.item.id == item.id:
			var space = slot.item.max_stack - slot.amount
			var to_add = min(remaining_amount, space)
			slot.add_amount(to_add)
			remaining_amount -= to_add
			if remaining_amount <= 0:
				return

	for slot in hotbar_slots + grid_slots:
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
	for slot in hotbar_slots + grid_slots:
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

		# Consumir solo UNA unidad del ítem de la pila
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

func set_grid_slots(slots: Array):
	grid_slots = slots

func count_item(item: Item) -> int:
	var total = 0
	for slot in hotbar_slots + grid_slots:
		if slot.item != null and slot.item.id == item.id:
			total += slot.amount
	return total

func get_jugador() -> CharacterBody2D:
	var jugadores = get_tree().get_nodes_in_group("Player")
	if jugadores.size() > 0:
		return jugadores[0]
	return null
