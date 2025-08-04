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

# Función auxiliar para contar el total de un ítem en el inventario
func get_inventory_total(item: Item) -> int:
	var inventory = Inventory
	return inventory.count_item(item) if inventory else 0

func update():
	currently_equipped = get_child(index).item

# Reemplaza la función use_current en tu script hotbar.gd

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

	match slot.item.item_type:
		Item.ItemType.CONSUMABLE:
			print("Intentando consumir:", slot.item.name)
			if Inventory.consume_item(slot.item):
				print("Consumible usado exitosamente:", slot.item.name)
				slot.queue_redraw()  # Actualizar visualmente el slot
			else:
				print("Fallo al consumir:", slot.item.name)
		Item.ItemType.TOOL:
			print("Usar herramienta:", slot.item.name)
		Item.ItemType.WEAPON:
			print("Usar arma:", slot.item.name)
		Item.ItemType.PLACEABLE:
			print("Colocar objeto:", slot.item.name)
		_:
			print("Item sin comportamiento definido:", slot.item.name)
