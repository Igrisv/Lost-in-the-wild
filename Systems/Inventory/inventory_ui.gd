extends Control

@onready var canvas_layer = $Ui
@onready var hotbar: HBoxContainer = $Ui/Hotbar
@onready var grid: GridContainer = $Ui/Inventario
@onready var pause_menu: Control = $Ui/Pause_Menu
@onready var equipment_slots: Control = $Ui/EquipmentSlots  # Aseguramos que sea un Control con hijos Slot
@onready var tooltip_panel: Panel = $Ui/TooltipPanel  # Referencia al tooltip
@onready var _tooltip_text: RichTextLabel = $Ui/TooltipPanel/TooltipText  # Referencia al texto del tooltip

var is_paused = false
var inventory_manager

# Estados de visibilidad
var is_inventory_visible: bool = false
var is_pause_menu_visible: bool = false

# Variables para el tooltip
var tooltip_timer: Timer = null
var hovered_slot: Node = null
const TOOLTIP_HOVER_TIME: float = 0.5 # Tiempo en segundos para mostrar el tooltip

func _ready():
	# Inicializar todo oculto
	canvas_layer.visible = false
	hotbar.visible = false
	grid.visible = false
	pause_menu.visible = false
	equipment_slots.visible = false  # Ocultar equipment_slots inicialmente
	tooltip_panel.visible = false  # Ocultar tooltip inicialmente

	# Asumimos que el manager está en un autoload llamado "InventoryManager"
	inventory_manager = Inventory
	inventory_manager.set_hotbar_slots(hotbar.get_children())
	inventory_manager.set_grid_slots(grid.get_children())
	inventory_manager.set_equipment_slots(equipment_slots.get_children())  # Añadimos equipment_slots

	# Crear e inicializar el temporizador para el tooltip
	tooltip_timer = Timer.new()
	tooltip_timer.one_shot = true
	tooltip_timer.wait_time = TOOLTIP_HOVER_TIME
	add_child(tooltip_timer)
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)

	# Conectar señales de mouse para los slots
	_connect_mouse_signals(hotbar.get_children())
	_connect_mouse_signals(grid.get_children())
	_connect_mouse_signals(equipment_slots.get_children())

func _connect_mouse_signals(slots: Array):
	for slot in slots:
		if not slot.is_connected("mouse_entered_slot", _on_mouse_entered_slot):
			slot.connect("mouse_entered_slot", _on_mouse_entered_slot)
		if not slot.is_connected("mouse_exited_slot", _on_mouse_exited_slot):
			slot.connect("mouse_exited_slot", _on_mouse_exited_slot)

func _on_mouse_entered_slot(slot: Node):
	hovered_slot = slot
	tooltip_timer.start()

func _on_mouse_exited_slot(slot: Node):
	hovered_slot = null
	tooltip_timer.stop()
	tooltip_panel.visible = false

func _on_tooltip_timer_timeout():
	if hovered_slot and hovered_slot.item:
		show_tooltip(hovered_slot.item, hovered_slot.get_global_rect().position)

func show_tooltip(item: Item, position: Vector2):
	if not item:
		tooltip_panel.visible = false
		return

	var text = "[b]%s[/b]\n" % item.name
	text += "Tipo: %s\n" % Item.ItemType.keys()[item.item_type]

	# Estadísticas generales con verificación de errores
	if item.is_equippable:
		if item.protection != null and item.protection > 0:
			text += "Protección: %d\n" % item.protection
		else:
			print("Advertencia: 'protection' es null o <= 0 para el ítem: ", item.name)
		if item.mobility != null and item.mobility > 0:
			text += "Movilidad: %d\n" % item.mobility
		else:
			print("Advertencia: 'mobility' es null o <= 0 para el ítem: ", item.name)
		if item.comfort != null and item.comfort > 0:
			text += "Confort: %d\n" % item.comfort
		else:
			print("Advertencia: 'comfort' es null o <= 0 para el ítem: ", item.name)
		# Nota: 'capacity' no está definida en Item.gd, se omite
		if item.efficiency != null and item.efficiency != 1.0:
			text += "Eficiencia: %.2f\n" % item.efficiency
		else:
			print("Advertencia: 'efficiency' es null o igual a 1.0 para el ítem: ", item.name)
		if item.durability != null and item.durability > 0:
			text += "Durabilidad: %d\n" % item.durability
		else:
			print("Advertencia: 'durability' es null o <= 0 para el ítem: ", item.name)

	# Efectos de consumibles
	if item.item_type == Item.ItemType.CONSUMABLE and item.consumable_data:
		for effect in item.consumable_data.effects:
			match effect.type:
				ConsumableData.EffectType.HUNGER:
					text += "Restaura Hambre: %.1f\n" % effect.value
				ConsumableData.EffectType.THIRST:
					text += "Restaura Sed: %.1f\n" % effect.value
				ConsumableData.EffectType.SLEEP:
					text += "Restaura Sueño: %.1f\n" % effect.value
				ConsumableData.EffectType.STAMINA:
					text += "Restaura Estamina: %.1f\n" % effect.value

	# Modificadores adicionales
	if item.modifiers.size() > 0:
		text += "Modificadores:\n"
		for key in item.modifiers.keys():
			text += "- %s: %.2f\n" % [key.capitalize(), item.modifiers[key]]

	_tooltip_text.text = text
	tooltip_panel.position = position + Vector2(10, 10) # Desplazamiento para no cubrir el slot
	# Ajustar posición si se sale de la pantalla
	var screen_size = get_viewport().get_visible_rect().size
	var tooltip_size = tooltip_panel.size
	if tooltip_panel.position.x + tooltip_size.x > screen_size.x:
		tooltip_panel.position.x = screen_size.x - tooltip_size.x - 10
	if tooltip_panel.position.y + tooltip_size.y > screen_size.y:
		tooltip_panel.position.y = position.y - tooltip_size.y - 10
	tooltip_panel.visible = true

func _input(event):
	if event.is_action_pressed("inventario"):
		if not is_pause_menu_visible:  # Solo abrir inventario si el menú de pausa no está visible
			toggle_inventory()
	elif event.is_action_pressed("menu"):
		if not is_inventory_visible:  # Solo abrir menú de pausa si el inventario no está visible
			toggle_pause_menu()
	elif event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_SPACE:
				var item_keys = inventory_manager.item_map.keys()
				if item_keys.is_empty():
					print("Item map vacío. ¿Cargaste los ítems?")
					return
				var random_item = inventory_manager.item_map[item_keys[randi() % item_keys.size()]]
				inventory_manager.add_item(random_item, 5)

func toggle_inventory():
	is_inventory_visible = not is_inventory_visible
	is_pause_menu_visible = false  # Ocultar menú de pausa al abrir inventario
	update_visibility()

func toggle_pause_menu():
	is_pause_menu_visible = not is_pause_menu_visible
	is_inventory_visible = false  # Ocultar inventario al abrir menú de pausa
	update_visibility()

func update_visibility():
	canvas_layer.visible = is_inventory_visible or is_pause_menu_visible
	hotbar.visible = is_inventory_visible
	grid.visible = is_inventory_visible
	pause_menu.visible = is_pause_menu_visible
	equipment_slots.visible = is_inventory_visible  # Mostrar equipment_slots junto con el inventario
	# Ocultar tooltip si el inventario no está visible
	if not is_inventory_visible:
		tooltip_panel.visible = false
		hovered_slot = null
		tooltip_timer.stop()

func hide_all():
	is_inventory_visible = false
	is_pause_menu_visible = false
	update_visibility()

func _on_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main_Menu/main_menu.tscn")

func _on_resume_pressed() -> void:
	is_paused = false
	pause_menu.visible = is_paused
