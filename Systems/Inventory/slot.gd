extends Panel

@export var item: Item = null:
	set(value):
		item = value
		if is_inside_tree():
			if value == null:
				$Icon.texture = null
				$Amount.text = ""
			else:
				$Icon.texture = value.icon
				var slot_size = custom_minimum_size if custom_minimum_size != Vector2.ZERO else size
				$Icon.size = slot_size * 0.6
				$Icon.position = (slot_size - $Icon.size) / 2
				$Icon.queue_redraw()
				$Amount.text = str(amount) if amount > 0 else ""
			queue_redraw()
			print("Ítem asignado: ", value.name if value else "null", ", Icon size: ", $Icon.size)

@export var amount: int = 0:
	set(value):
		amount = max(0, value)
		if is_inside_tree():
			$Amount.text = str(amount) if amount > 0 else ""
			if amount <= 0 and item != null:
				item = null
				$Icon.texture = null
			queue_redraw()
			print("Cantidad actualizada: ", amount)

@export var equipment_slot: String = ""
@export var is_safe_slot: bool = false

var _drag_data_cache = null

signal item_equipped(item, slot)
signal item_unequipped(item, slot)

func _ready():
	add_to_group("slots")

func set_amount(value: int):
	amount = value

func add_amount(value: int):
	set_amount(amount + value)

func update_from_group():
	if item == null:
		$Icon.texture = null
		$Amount.text = ""
	else:
		$Icon.texture = item.icon
		var slot_size = custom_minimum_size if custom_minimum_size != Vector2.ZERO else size
		$Icon.size = slot_size * 0.6
		$Icon.position = (slot_size - $Icon.size) / 2
		$Icon.queue_redraw()
		$Amount.text = str(amount) if amount > 0 else ""
	queue_redraw()
	print("Slot actualizado desde grupo: ", name, ", item: ", item.name if item else "null", ", amount: ", amount, ", caller: ", get_caller_info())
func get_caller_info() -> String:
	var stack = get_stack()
	if stack.size() > 1:
		var info = stack[1]
		return "%s() in %s:%s" % [info.get("function", "unknown"), info.get("source", "unknown"), info.get("line", "??")]
	return "unknown"

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

	if source_slot and source_slot.equipment_slot != "" and source_slot != self:
		if not inventory.unequip_item(source_slot.item, source_slot.equipment_slot):
			print("No se pudo desequipar desde slot de origen: ", source_slot.equipment_slot)
			return
		emit_signal("item_unequipped", source_slot.item, source_slot)
		print("Desequipado de slot de origen: ", source_slot.equipment_slot)
		# No asignar directamente al slot de destino; dejar que add_item lo maneje
		return

	if item == null:
		if equipment_slot != "" and data.item.is_equippable and data.item.equipment_slot == equipment_slot:
			if inventory.equip_item(data.item, source_slot if source_slot else self):
				print("Ítem equipado en slot: ", equipment_slot)
				if source_slot:
					source_slot.item = null
					source_slot.amount = 0
			return
		elif equipment_slot == "":
			# Solo mover el ítem sin duplicarlo; la redistribución ya se hizo en unequip_item
			if source_slot:
				source_slot.item = null
				source_slot.amount = 0
			print("Ítem movido a slot normal, amount: ", data.amount)
		return

	if equipment_slot != "":
		print("Slot de equipamiento ya ocupado, no se permite agregar más ítems")
		return

	if item.id == data.item.id:
		var max_stack = item.max_stack if "max_stack" in item else 99
		var total = amount + data.amount

		if total <= max_stack:
			amount = total
			if source_slot:
				source_slot.item = null
				source_slot.amount = 0
			print("Stacks fusionados, nuevo amount: ", amount)
		else:
			amount = max_stack
			if source_slot:
				source_slot.amount = total - max_stack
			print("Stack limitado, sobrante: ", data.amount)
	else:
		if equipment_slot != "" and not data.item.is_equippable:
			var temp_item = item
			var temp_amount = amount
			item = data.item
			amount = data.amount
			if source_slot:
				source_slot.item = temp_item
				source_slot.amount = temp_amount
			if temp_item:
				emit_signal("item_unequipped", temp_item, self)
				print("Ítem desequipado de: ", equipment_slot)
		elif equipment_slot == "" and data.item.is_equippable and data.item.equipment_slot != "":
			if inventory.equip_item(data.item, source_slot if source_slot else self):
				print("Ítem equipado desde slot normal")
				if source_slot:
					source_slot.item = null
					source_slot.amount = 0
			return
		else:
			var temp_item = item
			var temp_amount = amount
			item = data.item
			amount = data.amount
			if source_slot:
				source_slot.item = temp_item
				source_slot.amount = temp_amount
			print("Intercambio realizado")

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

		for slot in get_tree().get_nodes_in_group("slots"):
			if slot == self:
				continue
			var slot_rect: Rect2 = slot.get_global_rect()
			var dummy_data = {"item": _drag_data_cache.item, "amount": _drag_data_cache.amount, "source_slot": self}
			if slot_rect.has_point(get_global_mouse_position()) and slot._can_drop_data(Vector2.ZERO, dummy_data):
				drop_successful = true
				break

		if not drop_successful and not is_safe_slot:
			_show_destroy_confirmation()
		elif drop_successful and _drag_data_cache:
			# Limpiar el slot de origen solo si el drop fue exitoso
			self.item = null
			self.amount = 0

		_drag_data_cache = null

func _show_destroy_confirmation():
	if get_tree().get_nodes_in_group("destroy_dialog").size() > 0:
		return

	var dialog := ConfirmationDialog.new()
	dialog.add_to_group("destroy_dialog")
	dialog.title = "Confirmar Destrucción"
	dialog.dialog_text = "¿Deseas destruir el ítem '" + (_drag_data_cache.item.name if _drag_data_cache.item else "Ítem") + "'?"
	dialog.ok_button_text = "Destruir"
	dialog.cancel_button_text = "Cancelar"
	dialog.min_size = Vector2(300, 150)

	dialog.confirmed.connect(func():
		item = null
		amount = 0
		print("Ítem destruido: ", _drag_data_cache.item.name if _drag_data_cache.item else "null")
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	get_tree().root.add_child(dialog)
	dialog.popup_centered()
