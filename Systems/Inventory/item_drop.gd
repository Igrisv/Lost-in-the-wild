extends CharacterBody2D
class_name ItemDrop

@export var item: Item
@export var amount: int = 1

func _ready() -> void:
	var sprite = $Sprite2D  # Asume un Sprite2D hijo llamado "Sprite"
	if sprite and item and item.icon:
		sprite.texture = item.icon
		sprite.scale = Vector2(0.5, 0.5)  # Escala opcional para visibilidad
	else:
		print("Advertencia: Sprite o icon no configurado para drop de ", item.name if item else "null")
	add_to_group("Pickupable")
	add_to_group("Interactable")  # Para que el jugador lo detecte como interactuable

func interact(player: Node) -> void:
	if item:
		Inventory.add_item(item, amount)
		print("Ítem recogido: ", item.name, " x", amount)
		queue_free()
	else:
		print("Error: No hay ítem asignado al drop")
