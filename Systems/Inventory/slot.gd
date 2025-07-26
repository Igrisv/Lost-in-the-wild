extends Panel

@export var item: Item = null:
	set(value):
		item = value
		if value == null:
			$Icon.texture = null
			$Amount.text = ""
			return
		$Icon.texture = value.icon

@export var amount : int = 0:
	set(value):
		amount = value
		$Amount.text = str(value)
		if amount <= 0:
			item = null

# Variable temporal para el arrastre
var _drag_data_cache = null

func set_amount(value : int):
	amount = value

func add_amount(value : int):
	amount += value

func _can_drop_data(_at_position, data):
	if "item" in data:
		return is_instance_of(data.item, Item)
	return false

func _drop_data(_at_position, data):
	# Si el slot está vacío, intercambiamos normalmente
	if item == null:
		item = data.item
		amount = data.amount
		data.item = null
		data.amount = 0
		return
	
	# Si el slot tiene el mismo tipo de ítem, fusionamos las cantidades
	if item.id == data.item.id:  # Asume que los Items tienen una propiedad "id" única
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
		# Si son diferentes, intercambiamos
		var temp_item = item
		var temp_amount = amount
		item = data.item
		amount = data.amount
		data.item = temp_item
		data.amount = temp_amount

func _get_drag_data(_at_position):
	if item:
		_drag_data_cache = {"item": item, "amount": amount}  # Almacenar temporalmente
		
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
		# Verificar si se soltó fuera de cualquier slot
		var drop_pos = get_global_mouse_position()
		var is_outside = true
		
		# Buscar todos los slots en el árbol (deben estar en el grupo "slots")
		for slot in get_tree().get_nodes_in_group("slots"):
			if slot.get_global_rect().has_point(drop_pos):
				is_outside = false
				break
		
		if is_outside:
			_show_destroy_confirmation()
		
		_drag_data_cache = null  # Limpiar cache

func _show_destroy_confirmation():
	var dialog = ConfirmationDialog.new()
	dialog.title = "Confirmar"
	dialog.dialog_text = "¿Deseas destruir este ítem?"
	
	# Añadir botones personalizados (opcional)
	dialog.get_ok_button().text = "Destruir"
	dialog.get_cancel_button().text = "Cancelar"
	
	dialog.confirmed.connect(
		func():
			# Eliminar el ítem
			item = null
			amount = 0
			print("Ítem destruido")
			dialog.queue_free()
	)
	
	dialog.canceled.connect(
		func():
			dialog.queue_free()
	)
	
	# Añadir a la escena y mostrar
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
