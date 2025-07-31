extends Control

@onready var canvas_layer = $Ui
@onready var hotbar: HBoxContainer = $Ui/Hotbar
@onready var grid: GridContainer = $Ui/Inventario

var inventory_manager

func _ready():
	
	canvas_layer.visible = false

	# Asumimos que el manager está en un autoload llamado "InventoryManager"
	inventory_manager = Inventory
	inventory_manager.set_hotbar_slots(hotbar.get_children())
	inventory_manager.set_grid_slots(grid.get_children())

func _input(event):
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_I:
				if canvas_layer.visible:
					hide_inventory()
				else:
					show_inventory()
			KEY_SPACE:
				var item_keys = inventory_manager.item_map.keys()
				var random_item = inventory_manager.item_map[item_keys[randi() % item_keys.size()]]
				inventory_manager.add_item(random_item, 5)

func show_inventory():
	canvas_layer.visible = true
	hotbar.visible = true
	grid.visible = true

func hide_inventory():
	canvas_layer.visible = false
	hotbar.visible = false
	grid.visible = false
