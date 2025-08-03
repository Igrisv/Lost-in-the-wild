extends Area2D

@onready var interaction_area = $"."
@onready var chest_ui: Control = $ChestUI
@onready var slots_container: GridContainer = $ChestUI/slots_container

var is_open: bool = false
var chest_slots := []
var player_near: bool = false

func _ready():
	if not chest_ui:
		print("Error: Nodo $ChestUI no encontrado")
	if not slots_container:
		print("Error: Nodo $ChestUI/Slots no encontrado")
	if chest_ui:
		chest_ui.visible = false
	set_process_input(true)
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	print("Cofre listo, esperando interacción")

func _input(event):
	if event.is_action_pressed("interactuar") and player_near:
		print("Tecla 'interactuar' (E) presionada, player_near = ", player_near)
		toggle_chest()

func _on_body_entered(body):
	if body.is_in_group("Player"):
		print("Jugador entró en el área del cofre")
		player_near = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		print("Jugador salió del área del cofre")
		player_near = false
		if chest_ui and chest_ui.visible:
			toggle_chest()

func toggle_chest():
	is_open = not is_open
	if chest_ui:
		chest_ui.visible = is_open
		print("Cofre toggleado, is_open = ", is_open)
		if is_open:
			if slots_container:
				chest_slots = slots_container.get_children()
				print("Slots del cofre registrados: ", chest_slots.size())
				Inventory.set_chest_slots(chest_slots)
				load_chest_state()
			else:
				print("Error: slots_container es null")
		else:
			Inventory.set_chest_slots([])
			save_chest_state()
	else:
		print("Error: chest_ui es null")

func save_chest_state():
	if chest_slots.size() > 0:
		var chest_data = {}
		for i in range(chest_slots.size()):
			var slot = chest_slots[i]
			if slot.item:
				chest_data[str(i)] = {"item_id": slot.item.id, "amount": slot.amount}
		var file = FileAccess.open("user://chest_save.dat", FileAccess.WRITE)
		if file:
			file.store_var(chest_data)
			file.close()
			print("Estado del cofre guardado")
		else:
			print("Error: No se pudo abrir el archivo para guardar")
	else:
		print("No hay slots para guardar")

func load_chest_state():
	var file = FileAccess.open("user://chest_save.dat", FileAccess.READ)
	if file:
		var chest_data = file.get_var()
		file.close()
		if slots_container and chest_data:
			for slot_index in chest_data.keys():
				var data = chest_data[slot_index]
				var item = Inventory.item_map.get(data.item_id)
				if item:
					chest_slots[int(slot_index)].item = item
					chest_slots[int(slot_index)].amount = data.amount
			print("Estado del cofre cargado")
		else:
			print("Error: slots_container o chest_data es null")
	else:
		print("No se encontró archivo de guardado")
