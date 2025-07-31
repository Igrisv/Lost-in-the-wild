extends Node2D

@export var creature_name: String = "Conejo"
@export var preferred_item_id: String = "Carne"
@export var affection_needed: int = 3

var affection: int = 0
var player_in_range = false
var is_tamed = false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interactuar"):
		var held_item = get_tree().get_nodes_in_group("Hotbar")[0].currently_equipped
		if held_item and held_item.id == preferred_item_id:
			affection += 1
			Inventory.use_stackable_item(held_item, 1)
			print("%s se alegra. (%d/%d)" % [creature_name, affection, affection_needed])
			if affection >= affection_needed:
				tame()
		else:
			print("%s no está interesado." % creature_name)

func tame():
	is_tamed = true
	modulate = Color(0.7, 1.0, 0.7)
	print("%s ahora es tu compañero." % creature_name)
	# Aquí podrías comenzar lógica de seguimiento o vinculación

func _on_Area2D_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_Area2D_body_exited(body):
	if body.name == "Player":
		player_in_range = false
