extends Control

@onready var pause_menu: Control = $Pause_Menu
@onready var ui_movil: Control = self
@onready var camera_2d: Camera2D = $Camera2D
@onready var btn_seleccionado: Label = $Panel/Btn_Seleccionado
var is_paused = false

func _ready():
	# Cargar posiciones y escalas
	cargar_configuracion()
	
	# Conectamos cambios de edición
	ManagerMovil.connect("modo_edicion_cambiado", Callable(self, "_on_modo_edicion_cambiado"))
	
	# Entramos en modo edición automáticamente
	ManagerMovil.alternar_modo_edicion()
	
	# Aplicar posiciones y escalas iniciales
	for nodo in get_tree().get_nodes_in_group("editable_ui"):
		var pos = ManagerMovil.cargar_posicion(nodo.name)
		if pos != Vector2.ZERO:
			nodo.global_position = pos
		var scale = ManagerMovil.cargar_escala(nodo.name)
		if scale != Vector2.ZERO:
			nodo.scale = scale

func _process(_delta: float) -> void:
	if ManagerMovil.contenedor_activo != null:
		btn_seleccionado.text = "Editando: " + ManagerMovil.contenedor_activo.name
	else:
		btn_seleccionado.text = "Sin selección"
		ui_movil.visible = ManagerMovil.id_movil

	if Input.is_action_just_pressed("menu"):
		is_paused = !is_paused
		pause_menu.visible = is_paused

	camera_2d.enabled = ManagerMovil.camera_on_editable_controls

func _on_modo_edicion_cambiado(activado: bool) -> void:
	print("Edición activada: ", activado)
	set_process_input(activado)
	for nodo in get_tree().get_nodes_in_group("editable_ui"):
		nodo.edit_mode = activado
	# Guardar configuración al salir del modo edición
	if not activado:
		guardar_configuracion()

# Guardar posiciones y escalas en un solo archivo
func guardar_configuracion():
	print("Guardando configuración")
	var config = ConfigFile.new()
	for nodo in get_tree().get_nodes_in_group("editable_ui"):
		var name = nodo.name
		config.set_value("posiciones", name, nodo.global_position)
		config.set_value("escalas", name, nodo.scale)
		# Actualizar caché en ManagerMovil
		ManagerMovil.guardar_posicion(name, nodo.global_position)
		ManagerMovil.guardar_escala(name, nodo.scale)
	
	var err = config.save("res://Scenes/Ui_Movil/Ui_Controles_Movil.cfg")
	if err != OK:
		print("Error al guardar:", err)
	else:
		print("Configuración guardada exitosamente")

# Cargar posiciones y escalas desde el archivo
func cargar_configuracion():
	print("Cargando configuración")
	var config = ConfigFile.new()
	var err = config.load("res://Scenes/Ui_Movil/Ui_Controles_Movil.cfg")
	if err != OK:
		print("No se pudo cargar archivo de configuración:", err)
		return
	
	for nodo in get_tree().get_nodes_in_group("editable_ui"):
		var name = nodo.name
		if config.has_section_key("posiciones", name):
			var pos = config.get_value("posiciones", name)
			ManagerMovil.guardar_posicion(name, pos)
		if config.has_section_key("escalas", name):
			var scale = config.get_value("escalas", name)
			ManagerMovil.guardar_escala(name, scale)

# Botones del menú de pausa
func _on_resume_pressed() -> void:
	is_paused = false
	pause_menu.visible = is_paused

func _on_options_pressed() -> void:
	pass # Implementar opciones si es necesario

func _on_to_menu_pressed() -> void:
	guardar_configuracion() # Guardar antes de cambiar escena
	get_tree().change_scene_to_file("res://Scenes/Main_Menu/main_menu.tscn")

# Botones de escala
func _on_aumentar_pressed():
	if ManagerMovil.contenedor_activo:
		ManagerMovil.contenedor_activo.scale *= 1.1
		ManagerMovil.guardar_escala(ManagerMovil.contenedor_activo.name, ManagerMovil.contenedor_activo.scale)

func _on_disminuir_pressed():
	if ManagerMovil.contenedor_activo:
		ManagerMovil.contenedor_activo.scale *= 0.9
		ManagerMovil.guardar_escala(ManagerMovil.contenedor_activo.name, ManagerMovil.contenedor_activo.scale)
