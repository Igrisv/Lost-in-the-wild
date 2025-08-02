extends Node

var item_map: Dictionary = {}
var hotbar_slots := []
var grid_slots := []

func _ready():
	# Preload de ítems
	item_map = {
		"Tronco": preload("res://items/Tronco.tres"),
		#"Troncon": preload("res://items/troncon.tres"),
		#"Rosa": preload("res://items/rosa.tres")
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

	# Stack en hotbar
	for slot in hotbar_slots:
		if slot.item != null and slot.item.id == item.id:
			var space = slot.item.max_stack - slot.amount
			var to_add = min(remaining_amount, space)
			slot.add_amount(to_add)
			remaining_amount -= to_add
			if remaining_amount <= 0:
				return

	# Stack en grid
	for slot in grid_slots:
		if slot.item != null and slot.item.id == item.id:
			var space = slot.item.max_stack - slot.amount
			var to_add = min(remaining_amount, space)
			slot.add_amount(to_add)
			remaining_amount -= to_add
			if remaining_amount <= 0:
				return

	# Vacíos en hotbar
	for slot in hotbar_slots:
		if slot.item == null:
			var to_add = min(remaining_amount, item.max_stack)
			slot.item = item
			slot.set_amount(to_add)
			remaining_amount -= to_add
			if remaining_amount <= 0:
				return

	# Vacíos en grid
	for slot in grid_slots:
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
