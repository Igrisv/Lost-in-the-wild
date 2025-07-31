extends Node2D

@export var resource_type: String = "Carne"
@export var resource_amount: int = 1
@export var harvest_time: float = 0.5
@export var requires_tool: String = "" # ejemplo: "axe", "" si no requiere

var player_in_range = false
var is_being_harvested = false

@onready var timer = $Timer
@onready var area = $Area2D

func _ready():
	timer.timeout.connect(_on_timer_timeout)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interactuar") and not is_being_harvested:
		start_harvest()

func _on_body_entered(body):
	if body.name == "Player":
		print("Asd")
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false

func start_harvest():
	is_being_harvested = true
	$Sprite2D.modulate = Color(1, 1, 1, 0.5) # visual de que está recolectando
	timer.start(harvest_time)

func _on_timer_timeout():
	var item = Inventory.item_map.get(resource_type)
	if item:
		Inventory.add_item(item, resource_amount)
		queue_free()
	else:
		push_error("Recurso no definido en item_map: %s" % resource_type)
