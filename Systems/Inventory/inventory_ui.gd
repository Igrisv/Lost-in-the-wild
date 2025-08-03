extends Control

@onready var canvas_layer = $Ui
@onready var hotbar: HBoxContainer = $Ui/Hotbar
@onready var grid: GridContainer = $Ui/Inventario
@onready var pause_menu: Control = $Ui/Pause_Menu
@onready var equipment_slots: Control = $Ui/EquipmentSlots  # Aseguramos que sea un Control con hijos Slot

var is_paused = false
var inventory_manager

# Estados de visibilidad
var is_inventory_visible: bool = false
var is_pause_menu_visible: bool = false

func _ready():
	# Inicializar todo oculto
	canvas_layer.visible = false
	hotbar.visible = false
	grid.visible = false
	pause_menu.visible = false
	equipment_slots.visible = false  # Ocultar equipment_slots inicialmente

	# Asumimos que el manager está en un autoload llamado "InventoryManager"
	inventory_manager = Inventory
	inventory_manager.set_hotbar_slots(hotbar.get_children())
	inventory_manager.set_grid_slots(grid.get_children())
	inventory_manager.set_equipment_slots(equipment_slots.get_children())  # Añadimos equipment_slots

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

func hide_all():
	is_inventory_visible = false
	is_pause_menu_visible = false
	update_visibility()

func _on_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main_Menu/main_menu.tscn")

func _on_resume_pressed() -> void:
	is_paused = false
	pause_menu.visible = is_paused
