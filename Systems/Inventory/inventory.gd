extends Control

var current_scene
var inventory: Dictionary = {
	"grid": {},
	"hotbar": {}
}

@export var hotbar: HBoxContainer
@export var grid: GridContainer
@onready var canvas_layer = $Ui


# Mapeo optimizado de ítems
var item_map: Dictionary = {}

func _ready():
	canvas_layer.visible = false  # Ocultar por defecto
	# Inicializar item_map con todos los ítems relevantes
	item_map = {
		"Carne": preload("res://items/stone.tres")
		#"Piel": preload("res://items/piel.tres"),
		#"Huesos": preload("res://items/huesos.tres"),
		#"Zanahoria": preload("res://items/zanahoria.tres"),
		#"Hierba Dulce": preload("res://items/hierba_dulce.tres"),
		#"Miel": preload("res://items/miel.tres"),
		#"Carne Cruda": preload("res://items/carne_cruda.tres"),
		#"Carne Fresca": preload("res://items/carne_fresca.tres")
	}
	
	# Validar que todos los ítems estén correctamente cargados
	for item_name in item_map.keys():
		if item_map[item_name] == null:
			print("Error: No se pudo cargar el ítem %s" % item_name)

func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			grid.visible = !grid.visible
		if event.keycode == KEY_SPACE:
			# Para pruebas, añadir un ítem aleatorio
			var random_item = item_map[item_map.keys()[randi() % item_map.size()]]
			add_item(random_item, 5)
		if event.keycode == KEY_I:  # Tecla "Inventario"
			if canvas_layer.visible:
				hide_inventory()
			else:
				show_inventory()

func show_inventory():
	canvas_layer.visible = true
	# Asegúrate de que los nodos hijos estén visibles y listos para interactuar
	if hotbar:
		hotbar.visible = true
	if grid:
		grid.visible = true

func hide_inventory():
	canvas_layer.visible = false
	# Oculta los nodos hijos para evitar interacciones no deseadas
	if hotbar:
		hotbar.visible = false
	if grid:
		grid.visible = false
	
func add_item(item: Item, amount: float = 1.0):
	if not item or not item_map.has(item.name):
		print("Error: Ítem %s no válido o no está en item_map" % (item.name if item else "null"))
		return
	
	amount = max(0, amount) # Asegurar que no se añadan cantidades negativas
	var remaining_amount = amount
	
	# Intentar stackear en la hotbar
	for slot in hotbar.get_children():
		if slot.item != null and slot.item.id == item.id:
			var available_space = slot.item.max_stack - slot.amount
			if available_space > 0:
				var to_add = min(remaining_amount, available_space)
				slot.add_amount(to_add)
				remaining_amount -= to_add
				update_hotbar_ui()
				if remaining_amount <= 0:
					return
	
	# Intentar stackear en el inventario principal
	for slot in grid.get_children():
		if slot.item != null and slot.item.id == item.id:
			var available_space = slot.item.max_stack - slot.amount
			if available_space > 0:
				var to_add = min(remaining_amount, available_space)
				slot.add_amount(to_add)
				remaining_amount -= to_add
				update_grid_ui()
				if remaining_amount <= 0:
					return
	
	# Buscar slots vacíos en la hotbar
	if remaining_amount > 0:
		for slot in hotbar.get_children():
			if slot.item == null:
				var to_add = min(remaining_amount, item.max_stack)
				slot.item = item
				slot.set_amount(to_add)
				remaining_amount -= to_add
				update_hotbar_ui()
				if remaining_amount <= 0:
					return
	
	# Buscar slots vacíos en el inventario principal
	if remaining_amount > 0:
		for slot in grid.get_children():
			if slot.item == null:
				var to_add = min(remaining_amount, item.max_stack)
				slot.item = item
				slot.set_amount(to_add)
				remaining_amount -= to_add
				update_grid_ui()
				if remaining_amount <= 0:
					return
	
	if remaining_amount > 0:
		print("No hay suficiente espacio en el inventario. Sobran %.1f unidades de %s" % [remaining_amount, item.name])

func use_stackable_item(item_name: String) -> bool:
	for slot in hotbar.get_children():
		if slot.item != null and slot.item.name == item_name and slot.amount > 0:
			slot.add_amount(-1) # Reducir en 1
			if slot.amount <= 0:
				slot.item = null
			update_hotbar_ui()
			return true
	return false

func has_item_in_hotbar(item_name: String) -> bool:
	for slot in hotbar.get_children():
		if slot.item != null and slot.item.name == item_name and slot.amount > 0:
			return true
	return false

func update_hotbar_ui():
	if hotbar and hotbar.has_method("update"):
		hotbar.update()
	else:
		for slot in hotbar.get_children():
			if slot.has_method("update"):
				slot.update()

func update_grid_ui():
	if grid and grid.has_method("update"):
		grid.update()
	else:
		for slot in grid.get_children():
			if slot.has_method("update"):
				slot.update()

func _on_hotbar_equip(item):
	if current_scene != null:
		current_scene.currently_equipped = item
