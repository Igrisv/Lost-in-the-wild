extends Control

var edit_mode := false
var dragging := false
var offset := Vector2.ZERO

func _gui_input(event):
	if not edit_mode:
		return

	# Soporte táctil y mouse
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			var mouse_pos = get_viewport().get_mouse_position()
			var rect = Rect2(global_position, size)
			if rect.has_point(mouse_pos):
				ManagerMovil.set_boton_seleccionado(self)
				dragging = true
				offset = mouse_pos - global_position
				accept_event()
		else:
			dragging = false
			accept_event()

	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and dragging:
		var mouse_pos = get_viewport().get_mouse_position()
		global_position = mouse_pos - offset
		accept_event()



func _input(event):
	if not edit_mode:
		return

	if event is InputEventScreenTouch:
		if event.pressed and get_global_rect().has_point(event.position):
			ManagerMovil.set_boton_seleccionado(self)
			dragging = true
			offset = event.position - global_position
		elif not event.pressed:
			dragging = false

	elif event is InputEventScreenDrag and dragging:
		global_position = event.position - offset
