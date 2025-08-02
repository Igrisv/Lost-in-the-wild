extends Node

signal modo_edicion_cambiado(activado: bool)
signal boton_seleccionado(nombre: String)

var id_movil: bool = false
var sting_id_status: String = ""
var camera_on_editable_controls: bool = false
var modo_edicion: bool = false
# Guarda posiciones y escalas de botones por nombre
var posiciones_botones: Dictionary = {}
var escala_botones: Dictionary = {}

# Control actualmente seleccionado
var contenedor_activo: Control = null

func _ready():
	# Cargar configuración inicial desde el archivo
	cargar_configuracion()

func _process(_delta: float) -> void:
	switch()

func switch():
	sting_id_status = "Activado" if id_movil else "Desactivado"

func alternar_modo_edicion():
	modo_edicion = !modo_edicion
	emit_signal("modo_edicion_cambiado", modo_edicion)

func guardar_posicion(nombre: String, posicion: Vector2) -> void:
	posiciones_botones[nombre] = posicion

func guardar_escala(nombre: String, escala: Vector2) -> void:
	escala_botones[nombre] = escala

func cargar_posicion(nombre: String) -> Vector2:
	return posiciones_botones.get(nombre, Vector2.ZERO)

func cargar_escala(nombre: String) -> Vector2:
	return escala_botones.get(nombre, Vector2(1.0, 1.0)) # Escala predeterminada de 1.0

func set_boton_seleccionado(nuevo: Control) -> void:
	if contenedor_activo and contenedor_activo != nuevo:
		# Desactiva la selección visual del anterior
		contenedor_activo.modulate = Color.WHITE
	contenedor_activo = nuevo
	if contenedor_activo:
		contenedor_activo.modulate = Color.YELLOW
		emit_signal("boton_seleccionado", nuevo.name)
	else:
		emit_signal("boton_seleccionado", "")

func cargar_configuracion():
	var config = ConfigFile.new()
	var err = config.load("res://Scenes/Ui_Movil/Ui_Controles_Movil.cfg")
	if err != OK:
		print("No se pudo cargar archivo de configuración:", err)
		return
	for section in config.get_sections():
		for key in config.get_section_keys(section):
			if section == "posiciones":
				posiciones_botones[key] = config.get_value(section, key)
			elif section == "escalas":
				escala_botones[key] = config.get_value(section, key)
