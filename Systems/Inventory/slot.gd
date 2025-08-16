extends Panel

class_name  Slot

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
signal mouse_entered_slot(slot)
signal mouse_exited_slot(slot)

func _ready():
	add_to_group("slots")
	# Conectar señales de mouse
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	emit_signal("mouse_entered_slot", self)

func _on_mouse_exited():
	emit_signal("mouse_exited_slot", self)

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
	if self.is_in_group("DeleteSlot"):
		_show_delete_confirmation(data.item, data.amount, data.source_slot)
		return
	if not data or not data.item:
		print("Datos de arrastre inválidos o ítem nulo")
		if _drag_data_cache and _drag_data_cache.source_slot:
			_drag_data_cache.source_slot.item = _drag_data_cache.item
			_drag_data_cache.source_slot.amount = _drag_data_cache.amount
			_drag_data_cache.source_slot.queue_redraw()
			print("Ítem restaurado al origen por datos inválidos: ", _drag_data_cache.item.name)
		return

	var inventory = get_node("/root/Inventory")
	var source_slot = data.get("source_slot", null)

	if source_slot and source_slot.equipment_slot != "" and source_slot != self:
		if not inventory.unequip_item(source_slot.item, source_slot.equipment_slot):
			print("No se pudo desequipar desde slot de origen: ", source_slot.equipment_slot)
			return
		emit_signal("item_unequipped", source_slot.item, source_slot)
		print("Desequipado de slot de origen: ", source_slot.equipment_slot)
		return

	if item == null:
		if equipment_slot != "" and data.item.is_equippable:
			if data.item.equipment_slot == equipment_slot:
				if inventory.equip_item(data.item, source_slot if source_slot else self):
					print("Ítem equipado en slot: ", equipment_slot)
					if source_slot and source_slot != self:
						source_slot.item = null
						source_slot.amount = 0
						source_slot.queue_redraw()
				else:
					# Restaurar si el equipamiento falla (slot incompatible o lleno)
					if source_slot and source_slot != self:
						source_slot.item = data.item
						source_slot.amount = data.amount
						source_slot.queue_redraw()
						print("Ítem restaurado al origen por fallo de equipamiento: ", data.item.name)
			else:
				# Restaurar si el equipment_slot no coincide
				if source_slot and source_slot != self:
					source_slot.item = data.item
					source_slot.amount = data.amount
					source_slot.queue_redraw()
					print("Ítem restaurado al origen por incompatibilidad de equipment_slot: ", data.item.name)
			return
		elif equipment_slot == "":
			item = data.item
			amount = data.amount
			if source_slot and source_slot != self:
				source_slot.item = null
				source_slot.amount = 0
				source_slot.queue_redraw()
			print("Ítem movido a slot normal, amount: ", amount)
			queue_redraw()
			return
		return

	if equipment_slot != "":
		print("Slot de equipamiento ya ocupado, iniciando intercambio")
		var temp_item = item
		var temp_amount = amount
		item = data.item
		amount = data.amount
		if source_slot and source_slot != self:
			source_slot.item = temp_item
			source_slot.amount = temp_amount
			source_slot.queue_redraw()
		print("Intercambio en slot de equipamiento completado")
		queue_redraw()
		return

	if item.id == data.item.id:
		var max_stack = item.max_stack if "max_stack" in item else 99
		var total = amount + data.amount

		if total <= max_stack:
			amount = total
			if source_slot and source_slot != self:
				source_slot.item = null
				source_slot.amount = 0
				source_slot.queue_redraw()
			print("Stacks fusionados, nuevo amount: ", amount)
		else:
			amount = max_stack
			if source_slot and source_slot != self:
				source_slot.amount = total - max_stack
				source_slot.queue_redraw()
			print("Stack limitado, sobrante: ", data.amount)
	else:
		var temp_item = item
		var temp_amount = amount
		item = data.item
		amount = data.amount
		if source_slot and source_slot != self:
			source_slot.item = temp_item
			source_slot.amount = temp_amount
			source_slot.queue_redraw()
		print("Intercambio realizado")
	queue_redraw()

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

		_drag_data_cache = null

func _show_delete_confirmation(dropped_item: Item, dropped_amount: int, source_slot: Node) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Confirmar Eliminación"
	dialog.dialog_text = "¿Deseas eliminar el ítem '" + dropped_item.name + "'?"
	dialog.ok_button_text = "Eliminar"
	dialog.cancel_button_text = "Cancelar"
	dialog.min_size = Vector2(300, 150)

	dialog.confirmed.connect(func():
		if source_slot:
			source_slot.item = null
			source_slot.amount = 0
			source_slot.queue_redraw()
		print("Ítem eliminado: ", dropped_item.name)
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	get_tree().root.add_child(dialog)
	dialog.popup_centered()
