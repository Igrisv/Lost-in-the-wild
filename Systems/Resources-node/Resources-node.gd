extends CharacterBody2D

@export var resource_type: String = "Carne"
@export var resource_amount: int = 1
@export var harvest_time: float = 0.5
@export var requires_tool: String = "" # ejemplo: "axe", "" si no requiere
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var player_in_range = false
var player = null
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
		player_in_range = true
		player = body

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		player = null
		

func start_harvest():
	is_being_harvested = true

	if player:
		var direction_vector = player.global_position - global_position

		if abs(direction_vector.x) > abs(direction_vector.y):
			if direction_vector.x > 0:
				# Derecha
				animated_sprite_2d.flip_h = true
				animated_sprite_2d.play("Talar_Derecha")

			else:
				# Izquierda
				animated_sprite_2d.flip_h = false
				animated_sprite_2d.play("Talar_Derecha")

		else:
			animated_sprite_2d.flip_h = false  # Asegura que flip_h no afecte verticales
			#if direction_vector.y > 0:
				#animated_sprite_2d.play("Talar_Abajo")
			#else:
				#animated_sprite_2d.play("Talar_Arriba")
	else:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play("Talar_Abajo")  # Fallback

	timer.start(harvest_time)




func _on_timer_timeout():
	var item = Inventory.item_map.get(resource_type)
	if item:
		Inventory.add_item(item, resource_amount)
		queue_free()
	else:
		push_error("Recurso no definido en item_map: %s" % resource_type)
