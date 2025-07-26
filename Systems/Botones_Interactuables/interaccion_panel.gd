extends Control

var target_object: Node
var button_scene = preload("res://Systems/Botones_Interactuables/Boton_Interaccion.tscn")

func _ready():
	visible = false
	if not $VBoxContainer:
		print("Error: VBoxContainer no encontrado en InteractionPanel")

func show_interactions(target: Node):
	target_object = target
	visible = true
	
	# Eliminar los botones anteriores manualmente
	for child in $VBoxContainer.get_children():
		child.queue_free()
	
	var interactions = target.get_interactions()
	for action in interactions:
		var button = button_scene.instantiate()
		$VBoxContainer.add_child(button)
		button.setup(action["name"], target, action.get("condition", ""))
	
	# Posicionar cerca del objetivo
	var screen_pos = target.get_global_transform_with_canvas().origin
	var viewport = get_viewport_rect().size
	screen_pos.x = clamp(screen_pos.x, 0, viewport.x - size.x)
	screen_pos.y = clamp(screen_pos.y - size.y - 20, 0, viewport.y - size.y)
	position = screen_pos

func hide_interactions():
	visible = false
	target_object = null
	
	# Eliminar los botones al ocultar el panel
	for child in $VBoxContainer.get_children():
		child.queue_free()
