extends Control

@onready var ui_movil: Control = $"."

func _process(delta: float) -> void:
	if ManagerMovil.id_movil == true:
		ui_movil.visible = true
	else:
		ui_movil.visible = false
