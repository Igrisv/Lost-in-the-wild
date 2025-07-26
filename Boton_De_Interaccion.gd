extends Button

var action_name: String
var target_object: Node
var required_condition: String

func _ready():
	pressed.connect(_on_button_pressed)
	#mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(action: String, target: Node, condition: String):
	action_name = action
	target_object = target
	required_condition = condition
	text = action_name
	disabled = not _check_condition()

func _check_condition() -> bool:
	if not target_object:
		return false
	match required_condition:
		"is_dead":
			return target_object.is_dead
		"not_tamed":
			return not target_object.is_tamed
		"has_loot":
			return not target_object.remaining_loot.is_empty()
		"is_alive":
			return not target_object.is_dead and target_object.health > 0
		_:
			return true
	return false

func _on_button_pressed():
	if not disabled and target_object and target_object.has_method("perform_interaction"):
		target_object.perform_interaction(action_name)
	queue_free()

#func _on_mouse_entered():
	#if not disabled:
		#$HoverSound.play()  # Añade un nodo AudioStreamPlayer llamado "HoverSound" si quieres sonido

func _on_mouse_exited():
	pass
