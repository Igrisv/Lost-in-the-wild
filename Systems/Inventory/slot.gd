extends Panel

@export var item: Item = null:
	set(value):
		item = value
		if value == null:
			$Icon.texture = null
			$Amount.text = ""
			return
		$Icon.texture = value.icon

@export var amount: int = 0:
	set(value):
		amount = value
		$Amount.text = str(value)
		if amount <= 0:
			item = null

@export var equipment_slot: String = ""  # Define si es un slot de equipamiento (ej. "Hand", "Head", "Body")

# Variable temporal para el arrastre
var _drag_data_cache = null

signal item_equipped(item, slot)
signal item_unequipped(item, slot)

func set_amount(value: int):
	amount = value

func add_amount(value: int):
	amount += value

func _can_drop_data(_at_position, data):
	if "item" in data:
		return is_instance_of(data.item, Item)
	return false

func _drop_data(_at_position, data):
	# Si el slot está vacío, manejamos según sea equipamiento o no
	if item == null:
		if equipment_slot != "" and data.item and data.item.is_equippable and data.item.equipment_slot == equipment_slot:
			# Equipar solo 1 unidad
			item = data.item
			amount = 1
			if data.amount > 1:
				data.amount -= 1  # Restar 1 del stack original
			else:
				data.item = null
				data.amount = 0
			emit_signal("item_equipped", item, self)
		elif equipment_slot == "":
			# Slot normal (hotbar o grid), comportamiento existente
			item = data.item
			amount = data.amount
			data.item = null
			data.amount = 0
		return
	
	# Si el slot tiene un ítem, manejamos según el caso
	if item.id == data.item.id:  # Fusionar cantidades
		var max_stack = item.max_stack if "max_stack" in item else 99
		var total = amount + data.amount
		
		if total <= max_stack:
			amount = total
			data.item = null
			data.amount = 0
		else:
			amount = max_stack
			data.amount = total - max_stack
	else:
		# Intercambio o desequipamiento
		if equipment_slot != "" and not data.item.is_equippable:
			# Desequipar: mover el ítem equipado a un slot normal
			var temp_item = item
			var temp_amount = amount
			item = data.item
			amount = data.amount
			data.item = temp_item
			data.amount = temp_amount
			if temp_item:
				emit_signal("item_unequipped", temp_item, self)
		elif equipment_slot == "" and data.item.is_equippable and data.item.equipment_slot == equipment_slot:
			# Equipar desde un slot normal a un slot de equipamiento
			Inventory.equip_item(data.item, data)
		else:
			# Intercambio normal entre slots
			var temp_item = item
			var temp_amount = amount
			item = data.item
			amount = data.amount
			data.item = temp_item
			data.amount = temp_amount

func _get_drag_data(_at_position):
	if item:
		_drag_data_cache = {"item": item, "amount": amount}
		
		var preview_texture = TextureRect.new()
		preview_texture.texture = item.icon
		preview_texture.size = Vector2(16, 16) 
		preview_texture.position = -Vector2(8, 8)
		var preview = Control.new()
		preview.add_child(preview_texture)
		set_drag_preview(preview)
		return self
	return null

func _notification(what):
	if what == NOTIFICATION_DRAG_END && _drag_data_cache:
		var drop_pos = get_global_mouse_position()
		var is_outside = true
		
		for slot in get_tree().get_nodes_in_group("slots"):
			if slot.get_global_rect().has_point(drop_pos):
				is_outside = false
				break
		
		if is_outside:
			_show_destroy_confirmation()
		
		_drag_data_cache = null

func _show_destroy_confirmation():
	var dialog = ConfirmationDialog.new()
	dialog.title = "Confirmar"
	dialog.dialog_text = "¿Deseas destruir este ítem?"
	
	dialog.get_ok_button().text = "Destruir"
	dialog.get_cancel_button().text = "Cancelar"
	
	dialog.confirmed.connect(
		func():
			item = null
			amount = 0
			print("Ítem destruido")
			dialog.queue_free()
	)
	
	dialog.canceled.connect(
		func():
			dialog.queue_free()
	)
	
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
