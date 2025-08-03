extends HBoxContainer

var currently_equipped : Item:
	set(value):
		currently_equipped = value
		equip.emit(value)

signal equip(item)

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
const USE_COOLDOWN := 0.3 # Segundos (un poco más para seguridad)

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

	match slot.item.item_type:
		Item.ItemType.CONSUMABLE:
			print("Usando consumible:", slot.item.name)
			if Inventory.consume_item(slot.item):
				# No necesitas restar slot.amount aquí, ya se hizo en use_stackable_item()
				update()
			else:
				print("No se pudo consumir el ítem.")
		Item.ItemType.TOOL:
			print("Usar herramienta:", slot.item.name)
		Item.ItemType.WEAPON:
			print("Usar arma:", slot.item.name)
		Item.ItemType.PLACEABLE:
			print("Colocar objeto:", slot.item.name)
		_:
			print("Item sin comportamiento definido:", slot.item.name)
