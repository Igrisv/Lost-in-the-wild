extends Panel

@export var item: Item = null:
	set(value):
		item = value
		if value == null:
			$Icon.texture = null
			$Amount.text = ""
			return
		$Icon.texture = value.icon
		var slot_size = custom_minimum_size if custom_minimum_size != Vector2.ZERO else size
		$Icon.size = slot_size * 0.6
		$Icon.position = (slot_size - $Icon.size) / 2
		$Icon.queue_redraw()
		print("Ítem asignado: ", value.name, ", Slot size: ", slot_size, ", Icon size: ", $Icon.size)

@export var amount: int = 0:
	set(value):
		amount = value
		$Amount.text = str(value)
		if amount <= 0:
			item = null

@export var equipment_slot: String = ""
@export var is_safe_slot: bool = false  # Marca los slots válidos para evitar destrucción

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
	print("Drop data iniciado, slot equipment_slot: ", equipment_slot, ", item recibido: ", data.item.name if data and data.item else "null")
	if not data or not data.item:
		print("Datos de arrastre inválidos o ítem nulo")
		return

	var inventory = get_node("/root/Inventory")
	var source_slot = data.get("source_slot", null)

	# Desequipar si el ítem viene de un slot de equipamiento
	if source_slot and source_slot.equipment_slot != "" and source_slot != self:
		inventory.unequip_item(source_slot.item, source_slot.equipment_slot)
		emit_signal("item_unequipped", source_slot.item, source_slot)
		print("Desequipado de slot de origen: ", source_slot.equipment_slot)

	if item == null:
		if equipment_slot != "" and data.item.is_equippable and data.item.equipment_slot == equipment_slot:
			if inventory.equip_item(data.item, self):
				print("Ítem equipado en slot: ", equipment_slot)
			return
		elif equipment_slot == "":
			item = data.item
			amount = data.amount
			data.item = null
			data.amount = 0
			print("Ítem asignado a slot normal, amount: ", amount)
		return

	# Resto del código...
	if equipment_slot != "":
		print("Slot de equipamiento ya ocupado, no se permite agregar más ítems")
		return

	if item.id == data.item.id:
		var max_stack = item.max_stack if "max_stack" in item else 99
		var total = amount + data.amount

		if total <= max_stack:
			amount = total
			data.item = null
			data.amount = 0
			print("Stacks fusionados, nuevo amount: ", amount)
		else:
			amount = max_stack
			data.amount = total - max_stack
			print("Stack limitado, sobrante: ", data.amount)
	else:
		if equipment_slot != "" and not data.item.is_equippable:
			var temp_item = item
			var temp_amount = amount
			item = data.item
			amount = data.amount
			data.item = temp_item
			data.amount = temp_amount
			if temp_item:
				emit_signal("item_unequipped", temp_item, self)
				print("Ítem desequipado de: ", equipment_slot)
		elif equipment_slot == "" and data.item.is_equippable and data.item.equipment_slot != "":
			if inventory.equip_item(data.item, self):
				print("Ítem equipado desde slot normal")
			return
		else:
			var temp_item = item
			var temp_amount = amount
			item = data.item
			amount = data.amount
			data.item = temp_item
			data.amount = temp_amount
			print("Intercambio realizado")
			if source_slot and source_slot.equipment_slot != "":
				inventory.unequip_item(source_slot.item, source_slot.equipment_slot)
				emit_signal("item_unequipped", source_slot.item, source_slot)
				print("Desequipado de slot de origen: ", source_slot.equipment_slot)

func _get_drag_data(_at_position):
	if not item:
		print("No hay ítem para arrastrar")
		return null

	_drag_data_cache = {"item": item, "amount": amount, "source_slot": self}

	var preview_texture = TextureRect.new()
	preview_texture.texture = item.icon
	preview_texture.size = Vector2(16, 16)
	preview_texture.position = -Vector2(8, 8)
	var preview = Control.new()
	preview.add_child(preview_texture)
	set_drag_preview(preview)
	return _drag_data_cache

func _notification(what):
	if what == NOTIFICATION_DRAG_END and _drag_data_cache:
		var drop_successful := false

		# Verificar si el ítem fue soltado en un slot válido
		for slot in get_tree().get_nodes_in_group("slots"):
			if slot == self:
				continue
			var slot_rect: Rect2 = slot.get_global_rect()
			var dummy_data = {"item": _drag_data_cache.item, "amount": _drag_data_cache.amount, "source_slot": self}
			if slot_rect.has_point(get_global_mouse_position()) and slot._can_drop_data(Vector2.ZERO, dummy_data):
				drop_successful = true
				break

		# Si no se soltó en un slot válido, mostrar diálogo de confirmación
		if not drop_successful and not is_safe_slot:
			_show_destroy_confirmation()

		# Limpiar caché de arrastre
		_drag_data_cache = null

func _show_destroy_confirmation():
	# Evitar múltiples diálogos
	if get_tree().get_nodes_in_group("destroy_dialog").size() > 0:
		return

	var dialog := ConfirmationDialog.new()
	dialog.add_to_group("destroy_dialog")  # Agregar al grupo para rastreo
	dialog.title = "Confirmar Destrucción"
	dialog.dialog_text = "¿Deseas destruir el ítem '" + (_drag_data_cache.item.name if _drag_data_cache.item else "Ítem") + "'?"
	dialog.ok_button_text = "Destruir"
	dialog.cancel_button_text = "Cancelar"
	dialog.min_size = Vector2(300, 150)  # Tamaño mínimo para mejor visibilidad

	# Conectar señales
	dialog.confirmed.connect(func():
		item = null
		amount = 0
		print("Ítem destruido: ", _drag_data_cache.item.name if _drag_data_cache.item else "null")
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	# Agregar diálogo al árbol y centrarlo
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
