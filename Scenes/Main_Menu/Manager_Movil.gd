extends Node


var id_movil : bool = false
var sting_id_status : String = ""

	
func _process(delta: float) -> void:
	switch()

func switch():
	if id_movil:
		sting_id_status = "Activado"
	else:
		sting_id_status = "Desactivado"
